import 'dart:math' as math;

import 'package:label_core/label_core.dart';

/// Rotates [vector] by [degrees] clockwise around the origin `(0, 0)`.
///
/// Deliberately mirrors `label_layout_engine`'s internal
/// `rotateVector` (same formula, same convention) so a `GroupElement`'s
/// children land in the same place on the canvas as they will when
/// printed — without `label_canvas` depending on `label_layout_engine`,
/// which the architecture forbids (a renderer/editor never recomputes
/// layout via a different engine; this is pure geometry, not layout
/// resolution, so a small intentional duplication here is correct).
Point rotateVector(Point vector, double degrees) {
  if (degrees == 0) return vector;
  final radians = degrees * math.pi / 180;
  final cosT = math.cos(radians);
  final sinT = math.sin(radians);
  return Point(
    x: vector.x * cosT - vector.y * sinT,
    y: vector.x * sinT + vector.y * cosT,
  );
}
