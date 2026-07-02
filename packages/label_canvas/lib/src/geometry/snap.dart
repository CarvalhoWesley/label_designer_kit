import 'package:label_core/label_core.dart';

/// Rounds [value] to the nearest multiple of [gridSizeMm].
double snapValue(double value, double gridSizeMm) {
  if (gridSizeMm <= 0) return value;
  return (value / gridSizeMm).round() * gridSizeMm;
}

/// Rounds both axes of [point] to the nearest grid intersection.
Point snapPoint(Point point, double gridSizeMm) =>
    Point(x: snapValue(point.x, gridSizeMm), y: snapValue(point.y, gridSizeMm));
