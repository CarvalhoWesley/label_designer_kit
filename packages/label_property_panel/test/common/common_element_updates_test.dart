import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_property_panel/src/common/common_element_updates.dart';

const _text = TextElement(
  id: 't-1',
  name: 'Texto',
  position: Point.zero(),
  size: Size2D(width: 30, height: 10),
  layerId: 'layer-1',
  content: 'Olá',
);

const _rect = RectangleElement(
  id: 'r-1',
  name: 'Rect',
  position: Point.zero(),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

const _group = GroupElement(
  id: 'g-1',
  name: 'Grupo',
  position: Point.zero(),
  size: Size2D(width: 40, height: 40),
  layerId: 'layer-1',
  children: [_rect],
);

void main() {
  test('withName updates name and preserves type-specific fields', () {
    final updated = withName(_text, 'Novo nome') as TextElement;
    expect(updated.name, 'Novo nome');
    expect(updated.content, 'Olá');
  });

  test('withLayerId updates layerId across different subtypes', () {
    expect(withLayerId(_text, 'layer-2').layerId, 'layer-2');
    expect(withLayerId(_rect, 'layer-2').layerId, 'layer-2');
    expect(withLayerId(_group, 'layer-2').layerId, 'layer-2');
  });

  test('withPosition updates position only', () {
    final updated = withPosition(_rect, const Point(x: 5, y: 7));
    expect(updated.position, const Point(x: 5, y: 7));
    expect(updated.size, _rect.size);
  });

  test('withSize updates size only', () {
    final updated = withSize(_rect, const Size2D(width: 15, height: 20));
    expect(updated.size, const Size2D(width: 15, height: 20));
    expect(updated.position, _rect.position);
  });

  test('withRotation updates rotation', () {
    expect(withRotation(_rect, 45).rotation, 45);
  });

  test('withOpacity updates opacity', () {
    expect(withOpacity(_rect, 0.5).opacity, 0.5);
  });

  test('withVisible updates visible', () {
    expect(withVisible(_rect, false).visible, isFalse);
  });

  test('withLocked updates locked', () {
    expect(withLocked(_rect, true).locked, isTrue);
  });

  test('common updates preserve GroupElement.children', () {
    final updated = withOpacity(_group, 0.3) as GroupElement;
    expect(updated.opacity, 0.3);
    expect(updated.children, [_rect]);
  });
}
