import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:label_barcode/label_barcode.dart';
import 'package:label_core/label_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'image_resolver.dart';
import 'pdf_font_resolver.dart';

/// Builds one [pw.Widget] per already-resolved [ResolvedElement].
///
/// `package:pdf`'s widget layer (`pw.Positioned`/`pw.Transform`) already
/// converts a Flutter-like "distance from top" + "positive angle rotates
/// clockwise" mental model into PDF's native bottom-left-origin, Y-up,
/// mathematically-CCW-positive coordinate system — negating
/// [ResolvedElement.rotationDegrees] once here is the only adjustment
/// needed to match the exact same visual rotation direction as
/// `label_renderer_canvas`'s `ElementPainter` (`dart:ui` is Y-down, so a
/// positive `canvas.rotate` there is already clockwise). Building the
/// equivalent by hand with raw `PdfGraphics` would require mirroring
/// glyph/image content to counteract the reflection baked into a manual
/// Y-flip matrix — the widget layer avoids that whole class of bugs.
class ElementEncoder {
  ElementEncoder({
    required this.scale,
    required this.imageResolver,
    required this.fontResolver,
  });

  /// PDF points per dot (`72 / dpi`).
  final double scale;
  final ImageResolver imageResolver;
  final PdfFontResolver fontResolver;

  static const _placeholderFill = PdfColor.fromInt(0xFFEEEEEE);
  static const _placeholderStroke = PdfColor.fromInt(0xFFCC0000);

  Future<pw.Widget> encode(ResolvedElement element) async {
    final widthPt = element.widthDots * scale;
    final heightPt = element.heightDots * scale;

    final pw.Widget content;
    switch (element.payload) {
      case ResolvedTextPayload payload:
        content = _encodeText(payload);
      case ResolvedBarcodePayload payload:
        content = _encodeBarcode(payload, widthPt, heightPt);
      case ResolvedQrCodePayload payload:
        content = _encodeQrCode(payload, widthPt, heightPt);
      case ResolvedImagePayload payload:
        content = await _encodeImage(payload, widthPt, heightPt);
      case ResolvedShapePayload payload:
        content = _encodeShape(payload, widthPt, heightPt);
    }

    return pw.Positioned(
      left: element.xDots * scale,
      top: element.yDots * scale,
      child: pw.Opacity(
        opacity: element.opacity.clamp(0.0, 1.0),
        child: pw.Transform.rotate(
          angle: -element.rotationDegrees * math.pi / 180,
          child: pw.SizedBox(
            width: widthPt,
            height: heightPt,
            child: pw.Align(alignment: pw.Alignment.topLeft, child: content),
          ),
        ),
      ),
    );
  }

  pw.Widget _encodeText(ResolvedTextPayload payload) {
    final style = payload.style;
    return pw.Text(
      payload.text,
      textAlign: _textAlign(style.alignment),
      style: pw.TextStyle(
        font: _resolveFont(
          style.fontFamily,
          bold: style.bold,
          italic: style.italic,
        ),
        fontSize: style.fontSizeDots * scale,
        color: PdfColor.fromInt(style.color),
        decoration: style.underline
            ? pw.TextDecoration.underline
            : pw.TextDecoration.none,
      ),
    );
  }

  pw.TextAlign _textAlign(TextAlignment alignment) => switch (alignment) {
    TextAlignment.left => pw.TextAlign.left,
    TextAlignment.center => pw.TextAlign.center,
    TextAlignment.right => pw.TextAlign.right,
    TextAlignment.justify => pw.TextAlign.justify,
  };

  pw.Font _resolveFont(
    String fontFamily, {
    required bool bold,
    required bool italic,
  }) {
    return fontResolver(fontFamily, bold: bold, italic: italic) ??
        _base14Font(bold, italic);
  }

  pw.Font _base14Font(bool bold, bool italic) {
    if (bold && italic) return pw.Font.helveticaBoldOblique();
    if (bold) return pw.Font.helveticaBold();
    if (italic) return pw.Font.helveticaOblique();
    return pw.Font.helvetica();
  }

  pw.Widget _encodeBarcode(
    ResolvedBarcodePayload payload,
    double widthPt,
    double heightPt,
  ) {
    final encoder = linearBarcodeEncoders[payload.symbology];
    if (encoder == null) return _placeholder(widthPt, heightPt);

    final BarcodeSymbol symbol;
    try {
      symbol = encoder.encode(payload.data);
    } on BarcodeEncodingException {
      return _placeholder(widthPt, heightPt);
    }

    final textHeightPt = payload.showText ? heightPt * 0.2 : 0.0;
    final barsHeightPt = heightPt - textHeightPt;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(
          height: barsHeightPt,
          child: pw.CustomPaint(
            size: PdfPoint(widthPt, barsHeightPt),
            painter: (canvas, size) =>
                _paintModules(canvas, size, symbol.modules),
          ),
        ),
        if (payload.showText)
          pw.SizedBox(
            height: textHeightPt,
            child: pw.Center(
              child: pw.Text(
                payload.data,
                style: pw.TextStyle(
                  font: pw.Font.helvetica(),
                  fontSize: textHeightPt * 0.8,
                  color: PdfColors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _encodeQrCode(
    ResolvedQrCodePayload payload,
    double widthPt,
    double heightPt,
  ) {
    final BarcodeSymbol symbol;
    try {
      symbol = qrCodeEncoder.encode(
        payload.data,
        level: payload.errorCorrectionLevel,
      );
    } on BarcodeEncodingException {
      return _placeholder(widthPt, heightPt);
    }

    return pw.CustomPaint(
      size: PdfPoint(widthPt, heightPt),
      painter: (canvas, size) => _paintModules(canvas, size, symbol.modules),
    );
  }

  /// [PdfGraphics] inside a [pw.CustomPaint] is already translated to the
  /// widget's own box, but stays in PDF's native bottom-left-origin, Y-up
  /// frame — unlike [SymbolModule.top], which (like `label_renderer_canvas`)
  /// measures from the *top*. `size.y - top - height` converts between the
  /// two for each module rectangle.
  void _paintModules(
    PdfGraphics canvas,
    PdfPoint size,
    List<SymbolModule> modules,
  ) {
    canvas.setFillColor(PdfColors.black);
    for (final module in modules) {
      final w = module.width * size.x;
      final h = module.height * size.y;
      final x = module.left * size.x;
      final y = size.y - module.top * size.y - h;
      canvas.drawRect(x, y, w, h);
    }
    canvas.fillPath();
  }

  Future<pw.Widget> _encodeImage(
    ResolvedImagePayload payload,
    double widthPt,
    double heightPt,
  ) async {
    final bytes = await imageResolver(payload.source);
    if (bytes == null) return _placeholder(widthPt, heightPt);

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return _placeholder(widthPt, heightPt);

    final hasCrop =
        payload.cropXDots != null &&
        payload.cropYDots != null &&
        payload.cropWidthDots != null &&
        payload.cropHeightDots != null;
    final cropped = hasCrop
        ? img.copyCrop(
            decoded,
            x: payload.cropXDots!,
            y: payload.cropYDots!,
            width: payload.cropWidthDots!,
            height: payload.cropHeightDots!,
          )
        : decoded;

    final provider = pw.MemoryImage(Uint8List.fromList(img.encodePng(cropped)));
    return pw.SizedBox(
      width: widthPt,
      height: heightPt,
      child: pw.Image(provider, fit: _boxFit(payload.fit)),
    );
  }

  pw.BoxFit _boxFit(ImageFit fit) => switch (fit) {
    ImageFit.contain => pw.BoxFit.contain,
    ImageFit.cover => pw.BoxFit.cover,
    ImageFit.fill => pw.BoxFit.fill,
    ImageFit.fitWidth => pw.BoxFit.fitWidth,
    ImageFit.fitHeight => pw.BoxFit.fitHeight,
    ImageFit.none => pw.BoxFit.none,
  };

  pw.Widget _encodeShape(
    ResolvedShapePayload payload,
    double widthPt,
    double heightPt,
  ) {
    final style = payload.style;
    final border = style.strokeWidthDots > 0
        ? pw.Border.all(
            color: PdfColor.fromInt(style.strokeColor),
            width: style.strokeWidthDots * scale,
          )
        : null;
    final fill = style.fillColor != null
        ? PdfColor.fromInt(style.fillColor!)
        : null;

    switch (payload.kind) {
      case ShapeKind.rectangle:
        return pw.Container(
          width: widthPt,
          height: heightPt,
          decoration: pw.BoxDecoration(
            color: fill,
            border: border,
            borderRadius: payload.cornerRadiusDots > 0
                ? pw.BorderRadius.circular(payload.cornerRadiusDots * scale)
                : null,
          ),
        );
      case ShapeKind.ellipse:
      case ShapeKind.circle:
        return pw.Container(
          width: widthPt,
          height: heightPt,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: fill,
            border: border,
          ),
        );
      case ShapeKind.line:
        return pw.CustomPaint(
          size: PdfPoint(widthPt, heightPt),
          painter: (canvas, size) {
            canvas
              ..setStrokeColor(PdfColor.fromInt(style.strokeColor))
              ..setLineWidth(style.strokeWidthDots * scale)
              ..drawLine(0, size.y, size.x, 0)
              ..strokePath();
          },
        );
    }
  }

  pw.Widget _placeholder(double widthPt, double heightPt) => pw.Container(
    width: widthPt,
    height: heightPt,
    decoration: pw.BoxDecoration(
      color: _placeholderFill,
      border: pw.Border.all(color: _placeholderStroke),
    ),
  );
}
