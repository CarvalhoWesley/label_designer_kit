import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer/src/logic/z_order.dart';

RectangleElement _rect(String id, {int zIndex = 0}) => RectangleElement(
  id: id,
  name: id,
  position: const Point.zero(),
  size: const Size2D(width: 10, height: 10),
  layerId: 'layer-1',
  zIndex: zIndex,
);

void main() {
  test('bringToFront moves the selected elements to the end, in order', () {
    final elements = [_rect('a'), _rect('b'), _rect('c'), _rect('d')];
    final result = bringToFront(elements, {'a', 'c'});
    expect(result.map((e) => e.id), ['b', 'd', 'a', 'c']);
  });

  test('sendToBack moves the selected elements to the start, in order', () {
    final elements = [_rect('a'), _rect('b'), _rect('c'), _rect('d')];
    final result = sendToBack(elements, {'b', 'd'});
    expect(result.map((e) => e.id), ['b', 'd', 'a', 'c']);
  });

  test('reassigns zIndex sequentially matching the new paint order', () {
    final elements = [
      _rect('a', zIndex: 9),
      _rect('b', zIndex: 9),
      _rect('c', zIndex: 9),
    ];
    final result = bringToFront(elements, {'a'});
    expect(result.map((e) => e.zIndex).toList(), [0, 1, 2]);
    expect(result.last.id, 'a');
  });

  test('bringToFront with an empty selection leaves order unchanged', () {
    final elements = [_rect('a'), _rect('b')];
    final result = bringToFront(elements, {});
    expect(result.map((e) => e.id), ['a', 'b']);
  });

  test('bringToFront is idempotent for an already-front selection', () {
    final elements = [_rect('a'), _rect('b')];
    final once = bringToFront(elements, {'b'});
    final twice = bringToFront(once, {'b'});
    expect(twice.map((e) => e.id), once.map((e) => e.id));
  });
}
