import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/canvas_transform.dart';
import 'package:label_core/label_core.dart';

void main() {
  test('mmToPx applies zoom and pan', () {
    const transform = CanvasTransform(zoom: 4, pan: Point(x: 10, y: 20));
    final px = transform.mmToPx(const Point(x: 5, y: 5));
    expect(px, const Offset(30, 40));
  });

  test('pxToMm is the inverse of mmToPx', () {
    const transform = CanvasTransform(zoom: 3, pan: Point(x: -8, y: 12));
    const original = Point(x: 17, y: -4);
    final roundTripped = transform.pxToMm(transform.mmToPx(original));
    expect(roundTripped.x, closeTo(original.x, 1e-9));
    expect(roundTripped.y, closeTo(original.y, 1e-9));
  });

  test('lengthToPx/lengthToMm ignore pan (lengths, not points)', () {
    const transform = CanvasTransform(zoom: 2, pan: Point(x: 100, y: 100));
    expect(transform.lengthToPx(5), 10);
    expect(transform.lengthToMm(10), 5);
  });
}
