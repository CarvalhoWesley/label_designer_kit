import 'package:label_core/label_core.dart';
import 'package:label_history/label_history.dart';
import 'package:test/test.dart';

RectangleElement _rect(String id, {double x = 0, double y = 0}) {
  return RectangleElement(
    id: id,
    name: id,
    position: Point(x: x, y: y),
    size: const Size2D(width: 10, height: 5),
    layerId: 'layer-1',
  );
}

void main() {
  group('findElementById', () {
    test('finds a top-level element', () {
      final elements = [_rect('a'), _rect('b')];
      expect(findElementById(elements, 'b'), equals(_rect('b')));
    });

    test('finds an element nested inside a group', () {
      final child = _rect('child');
      final group = GroupElement(
        id: 'group-1',
        name: 'Group',
        position: const Point.zero(),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [child],
      );
      expect(findElementById([group], 'child'), equals(child));
    });

    test('returns null when nothing matches', () {
      expect(findElementById([_rect('a')], 'missing'), isNull);
    });
  });

  group('locateElement', () {
    test('reports null parentId and the index for a top-level element', () {
      final elements = [_rect('a'), _rect('b')];
      final location = locateElement(elements, 'b')!;
      expect(location.parentId, isNull);
      expect(location.index, 1);
    });

    test('reports the owning group id and index for a nested element', () {
      final child = _rect('child');
      final group = GroupElement(
        id: 'group-1',
        name: 'Group',
        position: const Point.zero(),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [_rect('sibling'), child],
      );
      final location = locateElement([group], 'child')!;
      expect(location.parentId, 'group-1');
      expect(location.index, 1);
    });

    test('resolves parentId correctly for doubly-nested groups', () {
      final grandchild = _rect('grandchild');
      final innerGroup = GroupElement(
        id: 'inner',
        name: 'Inner',
        position: const Point.zero(),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [grandchild],
      );
      final outerGroup = GroupElement(
        id: 'outer',
        name: 'Outer',
        position: const Point.zero(),
        size: const Size2D(width: 30, height: 30),
        layerId: 'layer-1',
        children: [innerGroup],
      );
      final location = locateElement([outerGroup], 'grandchild')!;
      expect(location.parentId, 'inner');
      expect(location.index, 0);
    });
  });

  group('replaceElementById', () {
    test('replaces a top-level element', () {
      final elements = [_rect('a'), _rect('b')];
      final result = replaceElementById(
        elements,
        'a',
        (e) => (e as RectangleElement).copyWith(name: 'renamed'),
      );
      expect(result[0].name, 'renamed');
      expect(result[1], equals(elements[1]));
    });

    test('replaces an element nested inside a group, preserving the group', () {
      final group = GroupElement(
        id: 'group-1',
        name: 'Group',
        position: const Point.zero(),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [_rect('child')],
      );
      final result = replaceElementById(
        [group],
        'child',
        (e) => (e as RectangleElement).copyWith(name: 'renamed'),
      );
      final resultGroup = result.single as GroupElement;
      expect(resultGroup.id, 'group-1');
      expect(resultGroup.children.single.name, 'renamed');
    });

    test('throws ArgumentError when the id does not exist', () {
      expect(
        () => replaceElementById([_rect('a')], 'missing', (e) => e),
        throwsArgumentError,
      );
    });
  });

  group('removeElementById', () {
    test('removes a top-level element', () {
      final result = removeElementById([_rect('a'), _rect('b')], 'a');
      expect(result, hasLength(1));
      expect(result.single.id, 'b');
    });

    test('removes a nested element, preserving its siblings', () {
      final group = GroupElement(
        id: 'group-1',
        name: 'Group',
        position: const Point.zero(),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [_rect('child-1'), _rect('child-2')],
      );
      final result = removeElementById([group], 'child-1');
      final resultGroup = result.single as GroupElement;
      expect(resultGroup.children, hasLength(1));
      expect(resultGroup.children.single.id, 'child-2');
    });

    test('throws ArgumentError when the id does not exist', () {
      expect(
        () => removeElementById([_rect('a')], 'missing'),
        throwsArgumentError,
      );
    });
  });

  group('insertElementAt', () {
    test('inserts at the given top-level index', () {
      final result = insertElementAt([_rect('a'), _rect('c')], _rect('b'), 1);
      expect(result.map((e) => e.id), ['a', 'b', 'c']);
    });

    test('appends at the end when index is null', () {
      final result = insertElementAt([_rect('a')], _rect('b'), null);
      expect(result.map((e) => e.id), ['a', 'b']);
    });

    test('inserts into a group when parentId is given', () {
      final group = GroupElement(
        id: 'group-1',
        name: 'Group',
        position: const Point.zero(),
        size: const Size2D(width: 20, height: 20),
        layerId: 'layer-1',
        children: [_rect('child-1')],
      );
      final result = insertElementAt(
        [group],
        _rect('child-2'),
        0,
        parentId: 'group-1',
      );
      final resultGroup = result.single as GroupElement;
      expect(resultGroup.children.map((e) => e.id), ['child-2', 'child-1']);
    });

    test(
      'throws ArgumentError when parentId points at a non-group element',
      () {
        expect(
          () => insertElementAt([_rect('a')], _rect('b'), 0, parentId: 'a'),
          throwsArgumentError,
        );
      },
    );
  });
}
