import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Canvas, Color, Paint, Rect;
import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';

import 'canvas_renderer_options.dart';
import 'element_painter.dart';

/// Renders a [ResolvedDocument] to PNG bytes using `dart:ui` — real
/// typography (TTF, bold/italic, arbitrary font families) instead of a
/// bitmap font, at the cost of needing the Flutter engine (this package
/// is Flutter, not pure Dart, unlike every other package so far in this
/// workspace).
///
/// Used both for raster export and, unmodified, as the engine behind
/// `label_preview` — the preview panel calls the exact same renderer used
/// for a "PNG/JPEG export" print job, so what the user sees while editing
/// never diverges from what actually gets produced (see
/// `docs/ARCHITECTURE.md` section 16).
class CanvasRenderer implements LabelRenderer {
  const CanvasRenderer();

  @override
  Future<Uint8List> render(
    ResolvedDocument document,
    RendererOptions options,
  ) async {
    final image = await renderToImage(document, options);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Falha ao codificar o PNG do ResolvedDocument.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Same painting pipeline as [render], stopping before PNG encoding —
  /// for a caller that needs raw pixels (e.g. `label_renderer_argox_raster`
  /// thresholding to a monochrome bitmap) and would otherwise pay for a
  /// pointless PNG encode/decode round trip. Caller must `dispose()` the
  /// returned image.
  Future<ui.Image> renderToImage(
    ResolvedDocument document,
    RendererOptions options,
  ) async {
    final canvasOptions = options is CanvasRendererOptions
        ? options
        : const CanvasRendererOptions();
    final scale = canvasOptions.pixelRatio;
    final widthPx = (document.widthDots * scale).round();
    final heightPx = (document.heightDots * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
      Paint()..color = Color(canvasOptions.backgroundColor),
    );

    canvas.save();
    canvas.scale(scale);

    final elementsByZIndex = [...document.elements]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final painter = ElementPainter(imageResolver: canvasOptions.imageResolver);
    for (final element in elementsByZIndex) {
      await painter.paint(canvas, element);
    }

    canvas.restore();

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(widthPx, heightPx);
    } finally {
      picture.dispose();
    }
  }
}
