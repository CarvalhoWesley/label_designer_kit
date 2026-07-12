import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:label_barcode/label_barcode.dart';
import 'package:label_core/label_core.dart';

import 'image_resolver.dart';

/// Paints one already-resolved [ResolvedElement] onto a [Canvas].
///
/// Position, rotation and opacity handling is identical for every payload
/// type and lives in [paint]; the `switch` over [ResolvedPayload]
/// dispatches only the type-specific drawing, one private method per
/// payload — a sealed-class `switch` instead of a formal Visitor since
/// there is exactly one consumer (this class), unlike `LabelElement`
/// where several packages need to handle every subtype.
class ElementPainter {
  ElementPainter({required this.imageResolver});

  final ImageResolver imageResolver;

  static const _placeholderFill = Color(0xFFEEEEEE);
  static const _placeholderStroke = Color(0xFFCC0000);
  static const _ink = Color(0xFF000000);

  Future<void> paint(Canvas canvas, ResolvedElement element) async {
    final box = Size(
      element.widthDots.toDouble(),
      element.heightDots.toDouble(),
    );
    final needsLayer = element.opacity < 1;

    canvas.save();
    if (needsLayer) {
      final alpha = (element.opacity.clamp(0.0, 1.0) * 255).round();
      canvas.saveLayer(null, Paint()..color = Color.fromARGB(alpha, 0, 0, 0));
    }

    canvas.translate(
      element.xDots + element.widthDots / 2,
      element.yDots + element.heightDots / 2,
    );
    if (element.rotationDegrees != 0) {
      canvas.rotate(element.rotationDegrees * math.pi / 180);
    }
    canvas.translate(-box.width / 2, -box.height / 2);

    switch (element.payload) {
      case ResolvedTextPayload payload:
        _paintText(canvas, box, payload);
      case ResolvedBarcodePayload payload:
        _paintBarcode(canvas, box, payload);
      case ResolvedQrCodePayload payload:
        _paintQrCode(canvas, box, payload);
      case ResolvedImagePayload payload:
        await _paintImage(canvas, box, payload);
      case ResolvedShapePayload payload:
        _paintShape(canvas, box, payload);
    }

    if (needsLayer) canvas.restore();
    canvas.restore();
  }

  void _paintText(Canvas canvas, Size box, ResolvedTextPayload payload) {
    final style = payload.style;
    final textPainter = TextPainter(
      text: TextSpan(
        text: payload.text,
        style: TextStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSizeDots.toDouble(),
          fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
          decoration: style.underline
              ? TextDecoration.underline
              : TextDecoration.none,
          color: Color(style.color),
        ),
      ),
      textAlign: _textAlign(style.alignment),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: box.width);
    textPainter.paint(canvas, Offset.zero);
  }

  TextAlign _textAlign(TextAlignment alignment) => switch (alignment) {
    TextAlignment.left => TextAlign.left,
    TextAlignment.center => TextAlign.center,
    TextAlignment.right => TextAlign.right,
    TextAlignment.justify => TextAlign.justify,
  };

  void _paintBarcode(Canvas canvas, Size box, ResolvedBarcodePayload payload) {
    final encoder = linearBarcodeEncoders[payload.symbology];
    if (encoder == null) {
      _paintPlaceholder(canvas, box);
      return;
    }

    final BarcodeSymbol symbol;
    try {
      symbol = encoder.encode(payload.data);
    } on BarcodeEncodingException {
      _paintPlaceholder(canvas, box);
      return;
    }

    // A custom textSizeDots reserves exactly that much line-height (times
    // 1.25 for descenders/leading) instead of the auto-derived 20% of the
    // box; 0 (the default) keeps the original box.height-relative sizing —
    // see BarcodeElement.textSize.
    final customFontSize = payload.textSizeDots > 0
        ? payload.textSizeDots.toDouble()
        : null;
    final textHeight = payload.showText
        ? (customFontSize != null ? customFontSize * 1.25 : box.height * 0.2)
        : 0.0;
    final fontSize = customFontSize ?? (textHeight * 0.8);
    final barsHeight = box.height - textHeight;
    final paint = Paint()..color = _ink;
    for (final module in symbol.modules) {
      canvas.drawRect(
        Rect.fromLTWH(
          module.left * box.width,
          module.top * barsHeight,
          module.width * box.width,
          module.height * barsHeight,
        ),
        paint,
      );
    }

    if (payload.showText) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: payload.data,
          style: TextStyle(fontSize: fontSize, color: _ink),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: box.width);
      textPainter.paint(
        canvas,
        Offset((box.width - textPainter.width) / 2, barsHeight),
      );
    }
  }

  void _paintQrCode(Canvas canvas, Size box, ResolvedQrCodePayload payload) {
    final BarcodeSymbol symbol;
    try {
      symbol = qrCodeEncoder.encode(
        payload.data,
        level: payload.errorCorrectionLevel,
      );
    } on BarcodeEncodingException {
      _paintPlaceholder(canvas, box);
      return;
    }

    final paint = Paint()..color = _ink;
    for (final module in symbol.modules) {
      canvas.drawRect(
        Rect.fromLTWH(
          module.left * box.width,
          module.top * box.height,
          module.width * box.width,
          module.height * box.height,
        ),
        paint,
      );
    }
  }

  Future<void> _paintImage(
    Canvas canvas,
    Size box,
    ResolvedImagePayload payload,
  ) async {
    final bytes = await imageResolver(payload.source);
    if (bytes == null) {
      _paintPlaceholder(canvas, box);
      return;
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final hasCrop =
        payload.cropXDots != null &&
        payload.cropYDots != null &&
        payload.cropWidthDots != null &&
        payload.cropHeightDots != null;
    final srcRect = hasCrop
        ? Rect.fromLTWH(
            payload.cropXDots!.toDouble(),
            payload.cropYDots!.toDouble(),
            payload.cropWidthDots!.toDouble(),
            payload.cropHeightDots!.toDouble(),
          )
        : Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    final boxFit = switch (payload.fit) {
      ImageFit.contain => BoxFit.contain,
      ImageFit.cover => BoxFit.cover,
      ImageFit.fill => BoxFit.fill,
      ImageFit.fitWidth => BoxFit.fitWidth,
      ImageFit.fitHeight => BoxFit.fitHeight,
      ImageFit.none => BoxFit.none,
    };
    final fitted = applyBoxFit(boxFit, srcRect.size, box);
    final dstSize = fitted.destination;
    final dstRect =
        Offset(
          (box.width - dstSize.width) / 2,
          (box.height - dstSize.height) / 2,
        ) &
        dstSize;

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    image.dispose();
  }

  void _paintShape(Canvas canvas, Size box, ResolvedShapePayload payload) {
    final style = payload.style;
    final rect = Offset.zero & box;

    if (style.fillColor != null) {
      _drawShapeGeometry(
        canvas,
        payload.kind,
        rect,
        payload.cornerRadiusDots.toDouble(),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Color(style.fillColor!),
      );
    }

    if (style.strokeWidthDots > 0) {
      _drawShapeGeometry(
        canvas,
        payload.kind,
        rect,
        payload.cornerRadiusDots.toDouble(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.strokeWidthDots.toDouble()
          ..color = Color(style.strokeColor),
      );
    }
  }

  void _drawShapeGeometry(
    Canvas canvas,
    ShapeKind kind,
    Rect rect,
    double cornerRadius,
    Paint paint,
  ) {
    switch (kind) {
      case ShapeKind.rectangle:
        if (cornerRadius > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
            paint,
          );
        } else {
          canvas.drawRect(rect, paint);
        }
      case ShapeKind.ellipse:
      case ShapeKind.circle:
        canvas.drawOval(rect, paint);
      case ShapeKind.line:
        canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    }
  }

  void _paintPlaceholder(Canvas canvas, Size box) {
    final rect = Offset.zero & box;
    canvas.drawRect(rect, Paint()..color = _placeholderFill);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _placeholderStroke,
    );
  }
}
