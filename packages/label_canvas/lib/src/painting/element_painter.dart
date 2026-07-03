import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:label_core/label_core.dart';

import '../geometry/canvas_transform.dart';
import '../geometry/placement.dart';
import 'image_decode_cache.dart';

/// Paints one [LabelElement] directly onto [canvas] at [placement] —
/// `label_canvas`'s own direct, editable rendering of the model, never via
/// `label_layout_engine` or any `label_renderer_*` (see
/// `docs/ARCHITECTURE.md` section 15).
///
/// Barcode/QR/table content isn't decoded or laid out here (that's
/// `label_barcode`/renderer territory) — those types draw a labeled
/// placeholder box instead, exactly like a real design tool shows an
/// unresolved asset. Images are the one exception: a `data:` URI source is
/// self-contained (no I/O needed to resolve it), so [imageCache] decodes
/// and draws it for real; anything else (file path, URL, asset key) still
/// falls back to the placeholder.
class ElementPainter implements LabelElementVisitor<void> {
  ElementPainter({
    required this.canvas,
    required this.transform,
    required this.placement,
    this.imageCache,
  });

  final Canvas canvas;
  final CanvasTransform transform;
  final ElementPlacement placement;
  final ImageDecodeCache? imageCache;

  Rect get _localRectPx {
    final halfW = transform.lengthToPx(placement.size.width) / 2;
    final halfH = transform.lengthToPx(placement.size.height) / 2;
    return Rect.fromLTRB(-halfW, -halfH, halfW, halfH);
  }

  void _paintLocal(LabelElement element, void Function(Rect localRectPx) draw) {
    canvas.save();
    final centerPx = transform.mmToPx(placement.center);
    canvas.translate(centerPx.dx, centerPx.dy);
    if (placement.rotationDegrees != 0) {
      canvas.rotate(placement.rotationDegrees * math.pi / 180);
    }
    if (element.opacity < 1) {
      canvas.saveLayer(
        _localRectPx.inflate(4),
        Paint()..color = Color.fromRGBO(0, 0, 0, element.opacity),
      );
    }
    draw(_localRectPx);
    if (element.opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  void visitText(TextElement element) {
    _paintLocal(
      element,
      (rect) => _drawText(element.content, element.style, rect),
    );
  }

  @override
  void visitVariable(VariableElement element) {
    _paintLocal(
      element,
      (rect) => _drawText('{{ ${element.expression} }}', element.style, rect),
    );
  }

  @override
  void visitDate(DateElement element) {
    _paintLocal(
      element,
      (rect) => _drawText(
        element.source == DateTimeSource.now
            ? element.format
            : '{{ ${element.variableName} }}',
        element.style,
        rect,
      ),
    );
  }

  @override
  void visitTime(TimeElement element) {
    _paintLocal(
      element,
      (rect) => _drawText(
        element.source == DateTimeSource.now
            ? element.format
            : '{{ ${element.variableName} }}',
        element.style,
        rect,
      ),
    );
  }

  @override
  void visitRectangle(RectangleElement element) {
    _paintLocal(element, (rect) {
      final radius = Radius.circular(
        transform.lengthToPx(element.cornerRadius),
      );
      final rrect = RRect.fromRectAndRadius(rect, radius);
      _fillAndStroke(element.style, path: Path()..addRRect(rrect));
    });
  }

  @override
  void visitEllipse(EllipseElement element) {
    _paintLocal(
      element,
      (rect) => _fillAndStroke(element.style, path: Path()..addOval(rect)),
    );
  }

  @override
  void visitCircle(CircleElement element) {
    _paintLocal(
      element,
      (rect) => _fillAndStroke(element.style, path: Path()..addOval(rect)),
    );
  }

  @override
  void visitLine(LineElement element) {
    // A LineElement's own position/size describe start->end directly; the
    // shared placement.center/size machinery (built for boxy elements)
    // doesn't apply cleanly, so draw it directly in absolute space instead
    // of going through _paintLocal's centered-box convention.
    final start = transform.mmToPx(element.position);
    final end = transform.mmToPx(element.endPoint);
    final paint = Paint()
      ..color = Color(
        element.strokeColor,
      ).withValues(alpha: Color(element.strokeColor).a * element.opacity)
      ..strokeWidth = math.max(1, transform.lengthToPx(element.strokeWidth))
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  void visitBarcode(BarcodeElement element) {
    _paintLocal(
      element,
      (rect) => _drawPlaceholder(rect, element.symbology.name, element.data),
    );
  }

  @override
  void visitQrCode(QRCodeElement element) {
    _paintLocal(
      element,
      (rect) => _drawPlaceholder(rect, 'QR Code', element.data),
    );
  }

  @override
  void visitImage(ImageElement element) {
    final image = imageCache?.get(element.source);
    _paintLocal(
      element,
      (rect) => image == null
          ? _drawPlaceholder(rect, 'Imagem', element.source)
          : _drawImage(image, element.fit, rect),
    );
  }

  void _drawImage(ui.Image image, ImageFit fit, Rect rectPx) {
    // Preview-only simplification: crop (cropPosition/cropSize) is honored
    // by `label_renderer_canvas`'s export/print path but not here — the
    // canvas shows the whole source image fitted into the box.
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final boxFit = switch (fit) {
      ImageFit.contain => BoxFit.contain,
      ImageFit.cover => BoxFit.cover,
      ImageFit.fill => BoxFit.fill,
      ImageFit.fitWidth => BoxFit.fitWidth,
      ImageFit.fitHeight => BoxFit.fitHeight,
      ImageFit.none => BoxFit.none,
    };
    final dstSize = applyBoxFit(boxFit, srcRect.size, rectPx.size).destination;
    final dstRect =
        Offset(
          rectPx.center.dx - dstSize.width / 2,
          rectPx.center.dy - dstSize.height / 2,
        ) &
        dstSize;
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  void visitTable(TableElement element) {
    _paintLocal(
      element,
      (rect) => _drawPlaceholder(rect, 'Tabela', element.dataField),
    );
  }

  @override
  void visitGroup(GroupElement element) {
    assert(
      false,
      'GroupElement is expanded by paintOrder() before painting — '
      'visitGroup should never be reached.',
    );
  }

  void _drawText(String content, TextStyleSpec style, Rect rectPx) {
    final baseColor = Color(style.color);
    final textStyle = TextStyle(
      color: baseColor,
      fontFamily: style.fontFamily,
      fontSize: transform.lengthToPx(style.fontSize),
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      decoration: style.underline
          ? TextDecoration.underline
          : TextDecoration.none,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: content, style: textStyle),
      textAlign: switch (style.alignment) {
        TextAlignment.left => TextAlign.left,
        TextAlignment.center => TextAlign.center,
        TextAlignment.right => TextAlign.right,
        TextAlignment.justify => TextAlign.justify,
      },
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rectPx.width);
    textPainter.paint(canvas, Offset(rectPx.left, rectPx.top));
  }

  void _fillAndStroke(ShapeStyleSpec style, {required Path path}) {
    final fillColor = style.fillColor;
    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = Color(fillColor));
    }
    if (style.strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(style.strokeColor)
          ..strokeWidth = math.max(1, transform.lengthToPx(style.strokeWidth))
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawPlaceholder(Rect rectPx, String label, String detail) {
    final border = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rectPx, Paint()..color = const Color(0x14000000));
    _drawDashedRect(rectPx, border);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label\n$detail',
        style: const TextStyle(color: Color(0xFF616161), fontSize: 10),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rectPx.width);
    textPainter.paint(
      canvas,
      Offset(
        rectPx.center.dx - textPainter.width / 2,
        rectPx.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawDashedRect(Rect rect, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    for (final edge in [
      [rect.topLeft, rect.topRight],
      [rect.topRight, rect.bottomRight],
      [rect.bottomRight, rect.bottomLeft],
      [rect.bottomLeft, rect.topLeft],
    ]) {
      final start = edge[0];
      final end = edge[1];
      final total = (end - start).distance;
      if (total == 0) continue;
      final direction = (end - start) / total;
      var travelled = 0.0;
      var draw = true;
      while (travelled < total) {
        final segment = math.min(draw ? dash : gap, total - travelled);
        if (draw) {
          canvas.drawLine(
            start + direction * travelled,
            start + direction * (travelled + segment),
            paint,
          );
        }
        travelled += segment;
        draw = !draw;
      }
    }
  }
}
