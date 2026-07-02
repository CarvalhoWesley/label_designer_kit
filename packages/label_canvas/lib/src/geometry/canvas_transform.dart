import 'dart:ui';

import 'package:label_core/label_core.dart';

/// Converts between millimeters (the [LabelDocument] coordinate space) and
/// on-screen pixels, given the current zoom/pan — the same `originOffset +
/// mm * pixelsPerMm` convention `label_widgets`' `LabelRuler` uses, so the
/// canvas and its rulers always agree on where 0mm sits.
class CanvasTransform {
  const CanvasTransform({required this.zoom, required this.pan});

  /// Pixels per millimeter.
  final double zoom;

  /// Pixel offset of the mm origin `(0, 0)`.
  final Point pan;

  Offset mmToPx(Point mm) => Offset(pan.x + mm.x * zoom, pan.y + mm.y * zoom);

  Point pxToMm(Offset px) =>
      Point(x: (px.dx - pan.x) / zoom, y: (px.dy - pan.y) / zoom);

  /// Converts a length (not a point) from mm to px — no pan offset applies.
  double lengthToPx(double mm) => mm * zoom;

  /// Converts a length (not a point) from px to mm — no pan offset applies.
  double lengthToMm(double px) => px / zoom;
}
