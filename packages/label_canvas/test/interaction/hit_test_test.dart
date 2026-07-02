import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/element_bounds.dart';
import 'package:label_canvas/src/interaction/hit_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

RectangleElement _rect(
  String id, {
  Point position = const Point.zero(),
  Size2D size = const Size2D(width: 10, height: 10),
  int zIndex = 0,
  bool visible = true,
  bool locked = false,
  String layerId = 'layer-1',
}) => RectangleElement(
  id: id,
  name: id,
  position: position,
  size: size,
  zIndex: zIndex,
  visible: visible,
  locked: locked,
  layerId: layerId,
);

const _layer = LabelLayer(id: 'layer-1', name: 'Base', order: 0);

void main() {
  group('isElementInteractable', () {
    test(
      'true for a visible, unlocked element on a visible, unlocked layer',
      () {
        expect(isElementInteractable(_rect('a'), [_layer]), isTrue);
      },
    );

    test('false when the element itself is hidden', () {
      expect(
        isElementInteractable(_rect('a', visible: false), [_layer]),
        isFalse,
      );
    });

    test('false when the element itself is locked', () {
      expect(
        isElementInteractable(_rect('a', locked: true), [_layer]),
        isFalse,
      );
    });

    test('false when the owning layer is hidden', () {
      const hiddenLayer = LabelLayer(
        id: 'layer-1',
        name: 'Base',
        order: 0,
        visible: false,
      );
      expect(isElementInteractable(_rect('a'), [hiddenLayer]), isFalse);
    });

    test('false when the owning layer is locked', () {
      const lockedLayer = LabelLayer(
        id: 'layer-1',
        name: 'Base',
        order: 0,
        locked: true,
      );
      expect(isElementInteractable(_rect('a'), [lockedLayer]), isFalse);
    });

    test('true when no matching layer is found (defaults interactable)', () {
      expect(
        isElementInteractable(_rect('a', layerId: 'missing'), [_layer]),
        isTrue,
      );
    });
  });

  group('hitTestElement', () {
    test('returns the element under the pointer', () {
      final elements = [_rect('a', position: const Point(x: 0, y: 0))];
      final hit = hitTestElement(
        elements: elements,
        layers: const [_layer],
        pointerMm: const Point(x: 5, y: 5),
      );
      expect(hit, 'a');
    });

    test('returns null when nothing is under the pointer', () {
      final elements = [_rect('a')];
      final hit = hitTestElement(
        elements: elements,
        layers: const [_layer],
        pointerMm: const Point(x: 500, y: 500),
      );
      expect(hit, isNull);
    });

    test(
      'picks the topmost (highest zIndex) element among overlapping ones',
      () {
        final elements = [_rect('back', zIndex: 0), _rect('front', zIndex: 1)];
        final hit = hitTestElement(
          elements: elements,
          layers: const [_layer],
          pointerMm: const Point(x: 5, y: 5),
        );
        expect(hit, 'front');
      },
    );

    test('skips locked elements, falling through to one underneath', () {
      final elements = [
        _rect('back', zIndex: 0),
        _rect('front', zIndex: 1, locked: true),
      ];
      final hit = hitTestElement(
        elements: elements,
        layers: const [_layer],
        pointerMm: const Point(x: 5, y: 5),
      );
      expect(hit, 'back');
    });

    test('skips hidden elements entirely', () {
      final elements = [_rect('a', visible: false)];
      final hit = hitTestElement(
        elements: elements,
        layers: const [_layer],
        pointerMm: const Point(x: 5, y: 5),
      );
      expect(hit, isNull);
    });
  });

  group('hitTestHandle', () {
    const bounds = ElementBounds(
      position: Point(x: 0, y: 0),
      size: Size2D(width: 10, height: 10),
    );

    test('finds a handle within the hit radius', () {
      final handle = hitTestHandle(
        bounds: bounds,
        pointerMm: const Point(x: 0.5, y: 0.5), // near topLeft (0,0)
        hitRadiusMm: 2,
      );
      expect(handle, ResizeHandle.topLeft);
    });

    test('returns null when nothing is within the hit radius', () {
      final handle = hitTestHandle(
        bounds: bounds,
        pointerMm: const Point(x: 5, y: 5), // dead center, far from any handle
        hitRadiusMm: 1,
      );
      expect(handle, isNull);
    });
  });

  group('elementsInMarquee', () {
    test('includes elements fully inside the marquee', () {
      final elements = [
        _rect(
          'a',
          position: const Point(x: 2, y: 2),
          size: const Size2D(width: 4, height: 4),
        ),
      ];
      final result = elementsInMarquee(
        elements: elements,
        layers: const [_layer],
        corner1: const Point.zero(),
        corner2: const Point(x: 20, y: 20),
      );
      expect(result, {'a'});
    });

    test('includes elements that only partially overlap the marquee', () {
      final elements = [
        _rect(
          'a',
          position: const Point(x: -5, y: -5),
          size: const Size2D(width: 10, height: 10),
        ),
      ];
      final result = elementsInMarquee(
        elements: elements,
        layers: const [_layer],
        corner1: const Point.zero(),
        corner2: const Point(x: 20, y: 20),
      );
      expect(result, {'a'});
    });

    test('excludes elements entirely outside the marquee', () {
      final elements = [_rect('a', position: const Point(x: 100, y: 100))];
      final result = elementsInMarquee(
        elements: elements,
        layers: const [_layer],
        corner1: const Point.zero(),
        corner2: const Point(x: 20, y: 20),
      );
      expect(result, isEmpty);
    });

    test('excludes locked/hidden elements even if geometrically inside', () {
      final elements = [_rect('a', locked: true)];
      final result = elementsInMarquee(
        elements: elements,
        layers: const [_layer],
        corner1: const Point.zero(),
        corner2: const Point(x: 20, y: 20),
      );
      expect(result, isEmpty);
    });

    test('works regardless of which corner order is passed', () {
      final elements = [
        _rect(
          'a',
          position: const Point(x: 2, y: 2),
          size: const Size2D(width: 4, height: 4),
        ),
      ];
      final result = elementsInMarquee(
        elements: elements,
        layers: const [_layer],
        corner1: const Point(x: 20, y: 20),
        corner2: const Point.zero(),
      );
      expect(result, {'a'});
    });
  });
}
