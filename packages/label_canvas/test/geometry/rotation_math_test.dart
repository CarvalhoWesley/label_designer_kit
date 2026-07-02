import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/rotation_math.dart';
import 'package:label_core/label_core.dart';

void main() {
  const center = Point(x: 10, y: 10);

  test('pointer directly above the center is 0 degrees', () {
    expect(
      rotationAngleForPointer(center, const Point(x: 10, y: 0)),
      closeTo(0, 1e-9),
    );
  });

  test('pointer directly right of the center is 90 degrees', () {
    expect(
      rotationAngleForPointer(center, const Point(x: 20, y: 10)),
      closeTo(90, 1e-9),
    );
  });

  test('pointer directly below the center is 180 degrees', () {
    expect(
      rotationAngleForPointer(center, const Point(x: 10, y: 20)),
      closeTo(180, 1e-9),
    );
  });

  test('pointer directly left of the center is 270 degrees', () {
    expect(
      rotationAngleForPointer(center, const Point(x: 0, y: 10)),
      closeTo(270, 1e-9),
    );
  });

  test('result is always normalized to [0, 360)', () {
    final degrees = rotationAngleForPointer(
      center,
      const Point(x: 9, y: 10.001),
    );
    expect(degrees, greaterThanOrEqualTo(0));
    expect(degrees, lessThan(360));
  });

  test('snapIncrementDegrees rounds to the nearest multiple', () {
    // Pointer near 90deg but not exact; should snap to 90 with a 15deg grid.
    final degrees = rotationAngleForPointer(
      center,
      const Point(x: 20, y: 11),
      snapIncrementDegrees: 15,
    );
    expect(degrees, 90);
  });

  test('snap result stays normalized when rounding wraps past 360', () {
    // Just under 360 (i.e. just left of straight up) should snap to 0, not
    // 360.
    final degrees = rotationAngleForPointer(
      center,
      const Point(x: 9.99, y: 0),
      snapIncrementDegrees: 45,
    );
    expect(degrees, 0);
  });
}
