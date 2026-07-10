import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer/src/logic/clone_element.dart';

const _rect = RectangleElement(
  id: 'r-1',
  name: 'Retângulo',
  position: Point(x: 10, y: 10),
  size: Size2D(width: 20, height: 20),
  layerId: 'layer-1',
);

const _group = GroupElement(
  id: 'g-1',
  name: 'Grupo',
  position: Point(x: 5, y: 5),
  size: Size2D(width: 30, height: 30),
  layerId: 'layer-1',
  children: [_rect],
);

void main() {
  test('cloneElement assigns a fresh id from nextId', () {
    final ids = ['new-id'];
    final clone = cloneElement(_rect, () => ids.removeAt(0));
    expect(clone.id, 'new-id');
    expect(clone.id, isNot(_rect.id));
  });

  test('cloneElement offsets the position by the given offset', () {
    final clone = cloneElement(
      _rect,
      () => 'new-id',
      offset: const Point(x: 5, y: 7),
    );
    expect(clone.position, const Point(x: 15, y: 17));
  });

  test('cloneElement preserves every other field', () {
    final clone = cloneElement(_rect, () => 'new-id') as RectangleElement;
    expect(clone.size, _rect.size);
    expect(clone.layerId, _rect.layerId);
    expect(clone.name, _rect.name);
    expect(clone.style, _rect.style);
  });

  test('cloneElement recursively assigns fresh ids to group children', () {
    final ids = ['group-clone', 'child-clone'];
    final clone = cloneElement(_group, () => ids.removeAt(0)) as GroupElement;

    expect(clone.id, 'group-clone');
    expect(clone.children, hasLength(1));
    expect(clone.children.single.id, 'child-clone');
    // Children are not additionally offset — only the group itself moved.
    expect(clone.children.single.position, _rect.position);
  });

  test(
    'cloning the same element twice with a real generator never collides',
    () {
      var counter = 0;
      String next() => 'id-${counter++}';
      final a = cloneElement(_rect, next);
      final b = cloneElement(_rect, next);
      expect(a.id, isNot(b.id));
    },
  );
}
