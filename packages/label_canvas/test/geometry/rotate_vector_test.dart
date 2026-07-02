import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/rotate_vector.dart';
import 'package:label_core/label_core.dart';

void main() {
  test('0 degrees is a no-op', () {
    const v = Point(x: 3, y: 4);
    expect(rotateVector(v, 0), v);
  });

  test('90 degrees clockwise maps +Y-up to +X (screen convention)', () {
    // (0, -1) is "up" on screen (Y grows downward); rotating 90deg
    // clockwise should point it to (1, 0), i.e. "right".
    final result = rotateVector(const Point(x: 0, y: -1), 90);
    expect(result.x, closeTo(1, 1e-9));
    expect(result.y, closeTo(0, 1e-9));
  });

  test('180 degrees negates both axes', () {
    final result = rotateVector(const Point(x: 2, y: 3), 180);
    expect(result.x, closeTo(-2, 1e-9));
    expect(result.y, closeTo(-3, 1e-9));
  });

  test('360 degrees returns to the original vector', () {
    final result = rotateVector(const Point(x: 5, y: -2), 360);
    expect(result.x, closeTo(5, 1e-9));
    expect(result.y, closeTo(-2, 1e-9));
  });

  test('preserves vector length for any angle', () {
    const v = Point(x: 6, y: 8); // length 10
    for (final degrees in [15, 47, 123, 271]) {
      final result = rotateVector(v, degrees.toDouble());
      final length = (result.x * result.x + result.y * result.y);
      expect(length, closeTo(100, 1e-6));
    }
  });
}
