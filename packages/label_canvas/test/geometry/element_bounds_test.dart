import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/element_bounds.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

void main() {
  group('unrotated element', () {
    const bounds = ElementBounds(
      position: Point(x: 10, y: 10),
      size: Size2D(width: 20, height: 10),
    );

    test('center is the midpoint of the box', () {
      expect(bounds.center, const Point(x: 20, y: 15));
    });

    test('contains a point inside the box', () {
      expect(bounds.contains(const Point(x: 15, y: 12)), isTrue);
    });

    test('does not contain a point outside the box', () {
      expect(bounds.contains(const Point(x: 5, y: 5)), isFalse);
    });

    test('corners are axis-aligned', () {
      expect(bounds.corners, [
        const Point(x: 10, y: 10),
        const Point(x: 30, y: 10),
        const Point(x: 30, y: 20),
        const Point(x: 10, y: 20),
      ]);
    });

    test('topLeft handle sits at the top-left corner', () {
      final p = bounds.handlePosition(ResizeHandle.topLeft);
      expect(p.x, closeTo(10, 1e-9));
      expect(p.y, closeTo(10, 1e-9));
    });

    test('rotation handle floats above the top-center edge', () {
      final p = bounds.handlePosition(
        ResizeHandle.rotation,
        rotationHandleOffsetMm: 5,
      );
      expect(p.x, closeTo(20, 1e-9));
      expect(p.y, closeTo(5, 1e-9)); // top edge (y=10) minus offset (5)
    });
  });

  group('rotated element', () {
    // A 20x10 rectangle centered at (0,0) — deliberately non-square, since
    // a rotated square would hide rotation bugs (it maps onto itself at
    // 90deg) — rotated 90 degrees clockwise.
    const bounds = ElementBounds(
      position: Point(x: -10, y: -5),
      size: Size2D(width: 20, height: 10),
      rotationDegrees: 90,
    );

    test('a point inside the unrotated rect can fall outside once rotated', () {
      // (7, 0) is inside the unrotated 20x10 rect (|x|<=10, |y|<=5), but
      // after swapping the long axis to vertical via a 90deg rotation, the
      // rotated rect only spans |x|<=5 — so (7, 0) is now outside.
      expect(bounds.contains(const Point(x: 7, y: 0)), isFalse);
    });

    test('a point outside the unrotated rect can fall inside once rotated', () {
      // (0, 7) is outside the unrotated rect (|y|<=5 fails), but the
      // rotated rect's long axis now covers it.
      expect(bounds.contains(const Point(x: 0, y: 7)), isTrue);
    });

    test('topLeft handle rotates to the computed absolute position', () {
      final p = bounds.handlePosition(ResizeHandle.topLeft);
      // Local top-left (-10,-5) rotated 90deg clockwise:
      // (x*cos90 - y*sin90, x*sin90 + y*cos90) = (-10*0 - -5*1, -10*1 + -5*0)
      //                                        = (5, -10)
      expect(p.x, closeTo(5, 1e-9));
      expect(p.y, closeTo(-10, 1e-9));
    });

    test(
      'a 360-degree rotation returns handles to their unrotated positions',
      () {
        const full = ElementBounds(
          position: Point(x: -10, y: -5),
          size: Size2D(width: 20, height: 10),
          rotationDegrees: 360,
        );
        final p = full.handlePosition(ResizeHandle.topLeft);
        expect(p.x, closeTo(-10, 1e-9));
        expect(p.y, closeTo(-5, 1e-9));
      },
    );
  });
}
