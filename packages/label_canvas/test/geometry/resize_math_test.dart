import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/element_bounds.dart';
import 'package:label_canvas/src/geometry/resize_math.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

void main() {
  group('unrotated element', () {
    const original = ElementBounds(
      position: Point(x: 0, y: 0),
      size: Size2D(width: 10, height: 10),
    );

    test('dragging bottomRight grows the box, keeping topLeft fixed', () {
      final result = resizeFromHandle(
        original: original,
        handle: ResizeHandle.bottomRight,
        pointerMm: const Point(x: 20, y: 15),
      );
      expect(result.position, const Point(x: 0, y: 0));
      expect(result.size, const Size2D(width: 20, height: 15));
    });

    test(
      'dragging topLeft shrinks and moves the box, keeping bottomRight fixed',
      () {
        final result = resizeFromHandle(
          original: original,
          handle: ResizeHandle.topLeft,
          pointerMm: const Point(x: 3, y: 4),
        );
        expect(result.position, const Point(x: 3, y: 4));
        expect(result.size, const Size2D(width: 7, height: 6));
      },
    );

    test('dragging topCenter only changes height, not width or x position', () {
      final result = resizeFromHandle(
        original: original,
        handle: ResizeHandle.topCenter,
        pointerMm: const Point(x: 999, y: -5),
      );
      expect(result.size.width, 10);
      expect(result.position.x, 0);
      expect(result.size.height, 15);
      expect(result.position.y, -5);
    });

    test(
      'dragging centerRight only changes width, not height or y position',
      () {
        final result = resizeFromHandle(
          original: original,
          handle: ResizeHandle.centerRight,
          pointerMm: const Point(x: 25, y: 999),
        );
        expect(result.size.height, 10);
        expect(result.position.y, 0);
        expect(result.size.width, 25);
        expect(result.position.x, 0);
      },
    );

    test(
      'dragging past the anchor still produces a valid positive-size box',
      () {
        // Dragging bottomRight to a point left of/above topLeft should flip
        // the box rather than collapse to a negative size.
        final result = resizeFromHandle(
          original: original,
          handle: ResizeHandle.bottomRight,
          pointerMm: const Point(x: -5, y: -5),
        );
        expect(result.size.width, 5);
        expect(result.size.height, 5);
        expect(result.position, const Point(x: -5, y: -5));
      },
    );

    test('never shrinks below minSizeMm', () {
      final result = resizeFromHandle(
        original: original,
        handle: ResizeHandle.bottomRight,
        pointerMm: const Point(x: 0.1, y: 0.1),
        minSizeMm: 2,
      );
      expect(result.size.width, 2);
      expect(result.size.height, 2);
    });
  });

  group('rotated element', () {
    test('resize happens along the element local axes, not screen axes', () {
      // A 10x10 box centered at (0,0), rotated 90deg clockwise: its local
      // "right" edge now points in the absolute +Y (down) direction.
      const original = ElementBounds(
        position: Point(x: -5, y: -5),
        size: Size2D(width: 10, height: 10),
        rotationDegrees: 90,
      );
      // Drag what is now the centerRight handle (absolute position (0,5))
      // further out to (0, 20). In the element's local (unrotated) space
      // that pointer lands at local x=20 (see rotate_vector_test for the
      // rotation convention); the anchor is the opposite (left) edge at
      // local x=-5, so the new width is the distance between them: 25.
      final result = resizeFromHandle(
        original: original,
        handle: ResizeHandle.centerRight,
        pointerMm: const Point(x: 0, y: 20),
      );
      expect(result.size.width, closeTo(25, 1e-9));
      expect(result.size.height, closeTo(10, 1e-9));
    });
  });
}
