import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer/src/logic/grouping.dart';

RectangleElement _rect(
  String id, {
  required Point position,
  required Size2D size,
  int zIndex = 0,
}) => RectangleElement(
  id: id,
  name: id,
  position: position,
  size: size,
  layerId: 'layer-1',
  zIndex: zIndex,
);

void main() {
  group('groupElements', () {
    test('throws when fewer than 2 selected ids match', () {
      final elements = [
        _rect('a', position: const Point(x: 0, y: 0), size: const Size2D(width: 10, height: 10)),
      ];
      expect(
        () => groupElements(
          allElements: elements,
          selectedIds: {'a'},
          groupId: 'g-1',
        ),
        throwsArgumentError,
      );
    });

    test('bounding box is the union of the selected elements', () {
      final a = _rect(
        'a',
        position: const Point(x: 0, y: 0),
        size: const Size2D(width: 10, height: 10),
      );
      final b = _rect(
        'b',
        position: const Point(x: 20, y: 5),
        size: const Size2D(width: 10, height: 30),
      );

      final result = groupElements(
        allElements: [a, b],
        selectedIds: {'a', 'b'},
        groupId: 'g-1',
      );

      expect(result.group.position, const Point(x: 0, y: 0));
      expect(result.group.size, const Size2D(width: 30, height: 35));
    });

    test('children positions are rebased relative to the group', () {
      final a = _rect(
        'a',
        position: const Point(x: 5, y: 5),
        size: const Size2D(width: 10, height: 10),
      );
      final b = _rect(
        'b',
        position: const Point(x: 20, y: 15),
        size: const Size2D(width: 10, height: 10),
      );

      final result = groupElements(
        allElements: [a, b],
        selectedIds: {'a', 'b'},
        groupId: 'g-1',
      );

      final childA = result.group.children.firstWhere((e) => e.id == 'a');
      final childB = result.group.children.firstWhere((e) => e.id == 'b');
      expect(childA.position, const Point(x: 0, y: 0));
      expect(childB.position, const Point(x: 15, y: 10));
    });

    test('remainingSiblings excludes exactly the grouped elements', () {
      final a = _rect('a', position: Point.zero(), size: const Size2D(width: 10, height: 10));
      final b = _rect('b', position: Point.zero(), size: const Size2D(width: 10, height: 10));
      final c = _rect('c', position: Point.zero(), size: const Size2D(width: 10, height: 10));

      final result = groupElements(
        allElements: [a, b, c],
        selectedIds: {'a', 'c'},
        groupId: 'g-1',
      );

      expect(result.remainingSiblings.map((e) => e.id), ['b']);
    });

    test('group inherits the highest zIndex among its members', () {
      final a = _rect('a', position: Point.zero(), size: const Size2D(width: 10, height: 10), zIndex: 3);
      final b = _rect('b', position: Point.zero(), size: const Size2D(width: 10, height: 10), zIndex: 7);

      final result = groupElements(
        allElements: [a, b],
        selectedIds: {'a', 'b'},
        groupId: 'g-1',
      );

      expect(result.group.zIndex, 7);
    });
  });

  group('ungroupElement', () {
    test('is the exact inverse of groupElements for position', () {
      final a = _rect(
        'a',
        position: const Point(x: 5, y: 5),
        size: const Size2D(width: 10, height: 10),
      );
      final b = _rect(
        'b',
        position: const Point(x: 20, y: 15),
        size: const Size2D(width: 10, height: 10),
      );

      final grouped = groupElements(
        allElements: [a, b],
        selectedIds: {'a', 'b'},
        groupId: 'g-1',
      );
      final ungrouped = ungroupElement(grouped.group);

      final restoredA = ungrouped.firstWhere((e) => e.id == 'a');
      final restoredB = ungrouped.firstWhere((e) => e.id == 'b');
      expect(restoredA.position, a.position);
      expect(restoredB.position, b.position);
    });
  });
}
