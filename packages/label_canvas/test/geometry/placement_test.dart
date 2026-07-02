import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/placement.dart';
import 'package:label_core/label_core.dart';

const _layers = [LabelLayer(id: 'layer-1', name: 'Base', order: 0)];

const _child = RectangleElement(
  id: 'child-1',
  name: 'Filho',
  position: Point(x: 0, y: 0),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

void main() {
  test(
    'a top-level (non-group) element places at its own position/rotation',
    () {
      const element = RectangleElement(
        id: 'r-1',
        name: 'Rect',
        position: Point(x: 5, y: 5),
        size: Size2D(width: 10, height: 20),
        rotation: 30,
        layerId: 'layer-1',
      );
      final placed = paintOrder([element], _layers);
      expect(placed, hasLength(1));
      expect(placed.single.placement.center, const Point(x: 10, y: 15));
      expect(placed.single.placement.rotationDegrees, 30);
    },
  );

  test('a group produces no placement of its own, only its children', () {
    final placed = paintOrder([
      const GroupElement(
        id: 'group-1',
        name: 'Grupo',
        position: Point(x: 0, y: 0),
        size: Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [_child],
      ),
    ], _layers);
    expect(placed, hasLength(1));
    expect(placed.single.element.id, 'child-1');
  });

  test('an unrotated group offsets children by its own position', () {
    final placed = paintOrder([
      GroupElement(
        id: 'group-1',
        name: 'Grupo',
        position: const Point(x: 30, y: 40),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [_child.copyWith(position: const Point(x: 2, y: 3))],
      ),
    ], _layers);
    // child absolute top-left = group.position + child.position = (32,43);
    // center = top-left + half size (5,5) = (37,48).
    expect(placed.single.placement.center, const Point(x: 37, y: 48));
    expect(placed.single.placement.rotationDegrees, 0);
  });

  test(
    'a 90deg group rotation moves a top-left child into the top-right quadrant',
    () {
      // Same fixture as label_layout_engine's group_rotation_test.dart, so
      // both engines must agree pixel-for-pixel on where a rotated group's
      // children land.
      final placed = paintOrder([
        const GroupElement(
          id: 'group-1',
          name: 'Grupo',
          position: Point(x: 0, y: 0),
          size: Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          rotation: 90,
          children: [_child],
        ),
      ], _layers);
      expect(placed.single.placement.center.x, closeTo(15, 1e-9));
      expect(placed.single.placement.center.y, closeTo(5, 1e-9));
      expect(placed.single.placement.rotationDegrees, 90);
    },
  );

  test('child rotation adds to the inherited group rotation', () {
    final placed = paintOrder([
      GroupElement(
        id: 'group-1',
        name: 'Grupo',
        position: const Point(x: 0, y: 0),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        rotation: 30,
        children: [_child.copyWith(rotation: 15)],
      ),
    ], _layers);
    expect(placed.single.placement.rotationDegrees, 45);
  });

  test('nested groups compose rotation and position across two levels', () {
    final placed = paintOrder([
      const GroupElement(
        id: 'outer',
        name: 'Externo',
        position: Point(x: 0, y: 0),
        size: Size2D(width: 40, height: 40),
        layerId: 'layer-1',
        rotation: 90,
        children: [
          GroupElement(
            id: 'inner',
            name: 'Interno',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 20, height: 20),
            layerId: 'layer-1',
            children: [_child],
          ),
        ],
      ),
    ], _layers);
    // Same worked example as label_layout_engine's nested-groups test:
    // child absolute center = (35, 5), absolute rotation = 90.
    expect(placed.single.placement.center.x, closeTo(35, 1e-9));
    expect(placed.single.placement.center.y, closeTo(5, 1e-9));
    expect(placed.single.placement.rotationDegrees, 90);
  });

  test('hidden elements are skipped', () {
    final placed = paintOrder([
      _child.copyWith(id: 'hidden', visible: false),
      _child.copyWith(id: 'visible'),
    ], _layers);
    expect(placed.map((p) => p.element.id), ['visible']);
  });

  test('elements on a hidden layer are skipped', () {
    const hiddenLayer = LabelLayer(
      id: 'layer-1',
      name: 'Base',
      order: 0,
      visible: false,
    );
    final placed = paintOrder([_child], const [hiddenLayer]);
    expect(placed, isEmpty);
  });

  test(
    'positionOverrides/sizeOverrides/rotationOverrides replace the element fields',
    () {
      const element = RectangleElement(
        id: 'r-1',
        name: 'Rect',
        position: Point(x: 0, y: 0),
        size: Size2D(width: 10, height: 10),
        layerId: 'layer-1',
      );
      final placed = paintOrder(
        [element],
        _layers,
        positionOverrides: {'r-1': const Point(x: 100, y: 100)},
        sizeOverrides: {'r-1': const Size2D(width: 20, height: 20)},
        rotationOverrides: {'r-1': 45},
      );
      expect(placed.single.placement.center, const Point(x: 110, y: 110));
      expect(placed.single.placement.size, const Size2D(width: 20, height: 20));
      expect(placed.single.placement.rotationDegrees, 45);
    },
  );

  test('overriding a group\'s position moves its children along with it', () {
    final placed = paintOrder(
      [
        const GroupElement(
          id: 'group-1',
          name: 'Grupo',
          position: Point(x: 0, y: 0),
          size: Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          children: [_child],
        ),
      ],
      _layers,
      positionOverrides: {'group-1': const Point(x: 50, y: 50)},
    );
    // child absolute top-left = overridden group position + child position
    // = (50,50); center = (55,55).
    expect(placed.single.placement.center, const Point(x: 55, y: 55));
  });

  test('sorts by zIndex ascending, globally across nested groups', () {
    final placed = paintOrder([
      _child.copyWith(id: 'top-level-low', zIndex: 1),
      GroupElement(
        id: 'group-1',
        name: 'Grupo',
        position: const Point(x: 0, y: 0),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [_child.copyWith(id: 'nested-high', zIndex: 10)],
      ),
      _child.copyWith(id: 'top-level-high', zIndex: 5),
    ], _layers);
    expect(placed.map((p) => p.element.id), [
      'top-level-low',
      'top-level-high',
      'nested-high',
    ]);
  });
}
