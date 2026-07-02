import 'package:label_core/label_core.dart';
import 'package:label_history/label_history.dart';
import 'package:test/test.dart';

void main() {
  const base = TextElement(
    id: 'text-1',
    name: 'Texto',
    position: Point(x: 1, y: 1),
    size: Size2D(width: 10, height: 5),
    rotation: 0,
    layerId: 'layer-1',
    content: 'ola',
  );

  test('moveElement changes only position', () {
    final moved = moveElement(base, const Point(x: 9, y: 9)) as TextElement;
    expect(moved.position, const Point(x: 9, y: 9));
    expect(moved.size, base.size);
    expect(moved.content, base.content);
  });

  test('resizeElement changes only size', () {
    final resized =
        resizeElement(base, const Size2D(width: 20, height: 8)) as TextElement;
    expect(resized.size, const Size2D(width: 20, height: 8));
    expect(resized.position, base.position);
  });

  test('rotateElement changes only rotation', () {
    final rotated = rotateElement(base, 45) as TextElement;
    expect(rotated.rotation, 45);
    expect(rotated.position, base.position);
    expect(rotated.size, base.size);
  });

  test('works across every LabelElement subtype (exhaustive switch)', () {
    const rectangle = RectangleElement(
      id: 'r',
      name: 'r',
      position: Point.zero(),
      size: Size2D.zero(),
      layerId: 'layer-1',
    );
    const group = GroupElement(
      id: 'g',
      name: 'g',
      position: Point.zero(),
      size: Size2D.zero(),
      layerId: 'layer-1',
      children: [],
    );
    expect(
      moveElement(rectangle, const Point(x: 5, y: 5)).position,
      const Point(x: 5, y: 5),
    );
    expect(
      moveElement(group, const Point(x: 5, y: 5)).position,
      const Point(x: 5, y: 5),
    );
  });
}
