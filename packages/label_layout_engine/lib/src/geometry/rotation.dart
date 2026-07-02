import 'dart:math' as math;

import 'package:label_core/label_core.dart';

/// Rotates [vector] by [degrees] clockwise around the origin `(0, 0)`.
///
/// Used to compose a `GroupElement`'s rotation into the absolute position
/// of its children: a child's offset from the group's center is rotated
/// by the group's (and every ancestor group's) rotation before being
/// added to the group's own absolute center.
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
