import 'dart:math' as math;

import 'package:label_core/label_core.dart';

/// The rotation (degrees, clockwise, normalized to `[0, 360)`) that would
/// point the rotation handle — which rests directly above the element at
/// 0° — at [pointerMm], given the element's [center].
///
/// When [snapIncrementDegrees] is set (e.g. from `ViewportStore.snapEnabled`),
/// the result is rounded to the nearest multiple of it.
double rotationAngleForPointer(
  Point center,
  Point pointerMm, {
  double? snapIncrementDegrees,
}) {
  final dx = pointerMm.x - center.x;
  final dy = pointerMm.y - center.y;
  var degrees = math.atan2(dx, -dy) * 180 / math.pi;
  degrees = (degrees % 360 + 360) % 360;
  if (snapIncrementDegrees != null && snapIncrementDegrees > 0) {
    degrees = (degrees / snapIncrementDegrees).round() * snapIncrementDegrees;
    degrees = (degrees % 360 + 360) % 360;
  }
  return degrees;
}
