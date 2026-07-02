import 'package:label_core/label_core.dart';
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:test/test.dart';

LabelDocument _documentWith(List<LabelElement> elements) {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Teste',
    page: const PageConfig(width: 100, height: 100, dpi: Dpi.dpi203),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    elements: elements,
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}

const _child = RectangleElement(
  id: 'child-1',
  name: 'Filho',
  position: Point(x: 0, y: 0),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

void main() {
  const engine = LabelLayoutEngine();

  group('GroupElement flattening', () {
    test('a group produces no ResolvedElement of its own', () {
      final document = _documentWith([
        const GroupElement(
          id: 'group-1',
          name: 'Grupo',
          position: Point(x: 0, y: 0),
          size: Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          children: [_child],
        ),
      ]);
      final resolved = engine.resolve(document, {});
      expect(resolved.elements, hasLength(1));
      expect(resolved.elements.single.id, 'child-1');
    });

    test('an unrotated group offsets children by its own position', () {
      final document = _documentWith([
        GroupElement(
          id: 'group-1',
          name: 'Grupo',
          position: const Point(x: 30, y: 40),
          size: const Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          children: [_child.copyWith(position: const Point(x: 2, y: 3))],
        ),
      ]);
      final element = engine.resolve(document, {}).elements.single;
      // child absolute top-left = group.position + child.position
      expect(element.xDots, Dpi.dpi203.mmToDots(32));
      expect(element.yDots, Dpi.dpi203.mmToDots(43));
      expect(element.rotationDegrees, 0);
    });

    test('preserves child z-index after flattening', () {
      final document = _documentWith([
        GroupElement(
          id: 'group-1',
          name: 'Grupo',
          position: const Point(x: 0, y: 0),
          size: const Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          children: [_child.copyWith(zIndex: 5)],
        ),
      ]);
      expect(engine.resolve(document, {}).elements.single.zIndex, 5);
    });
  });

  group('rotation composition', () {
    test(
      'a 90deg group rotation moves a top-left child into the top-right quadrant',
      () {
        // Group spans (0,0)-(20,20)mm, center (10,10). Child is a 10x10mm
        // box at the group's local (0,0), i.e. the top-left quadrant,
        // with local center (5,5). Rotating the group 90deg clockwise
        // around its own center should carry that child to the top-right
        // quadrant, whose center is (15,5).
        final document = _documentWith([
          GroupElement(
            id: 'group-1',
            name: 'Grupo',
            position: const Point(x: 0, y: 0),
            size: const Size2D(width: 20, height: 20),
            layerId: 'layer-1',
            rotation: 90,
            children: [_child],
          ),
        ]);
        final element = engine.resolve(document, {}).elements.single;

        // Expected top-left of the child's (still unrotated) bbox:
        // center (15,5) minus half its own size (5,5) => (10,0).
        expect(element.xDots, Dpi.dpi203.mmToDots(10));
        expect(element.yDots, Dpi.dpi203.mmToDots(0));
        expect(element.rotationDegrees, 90);
      },
    );

    test('child rotation adds to the inherited group rotation', () {
      final document = _documentWith([
        GroupElement(
          id: 'group-1',
          name: 'Grupo',
          position: const Point(x: 0, y: 0),
          size: const Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          rotation: 30,
          children: [_child.copyWith(rotation: 15)],
        ),
      ]);
      expect(engine.resolve(document, {}).elements.single.rotationDegrees, 45);
    });

    test(
      'a 180deg rotation reflects a child straight through the group center',
      () {
        final document = _documentWith([
          GroupElement(
            id: 'group-1',
            name: 'Grupo',
            position: const Point(x: 0, y: 0),
            size: const Size2D(width: 20, height: 20),
            layerId: 'layer-1',
            rotation: 180,
            // Child at local (0,0), 10x10 -> local center (5,5), offset from
            // group center (10,10) is (-5,-5); 180deg rotation negates it to
            // (5,5), landing the child's center at (15,15).
            children: [_child],
          ),
        ]);
        final element = engine.resolve(document, {}).elements.single;
        // Expected top-left: center (15,15) minus half size (5,5) = (10,10).
        expect(element.xDots, Dpi.dpi203.mmToDots(10));
        expect(element.yDots, Dpi.dpi203.mmToDots(10));
      },
    );

    test('nested groups compose rotation and position across two levels', () {
      // Outer group: 40x40mm at (0,0), rotated 90deg.
      // Inner group: 20x20mm at local (0,0) (top-left quadrant of outer),
      // unrotated itself.
      // Innermost child: 10x10mm at inner-local (0,0).
      final document = _documentWith([
        GroupElement(
          id: 'outer',
          name: 'Externo',
          position: const Point(x: 0, y: 0),
          size: const Size2D(width: 40, height: 40),
          layerId: 'layer-1',
          rotation: 90,
          children: [
            GroupElement(
              id: 'inner',
              name: 'Interno',
              position: const Point(x: 0, y: 0),
              size: const Size2D(width: 20, height: 20),
              layerId: 'layer-1',
              children: [_child],
            ),
          ],
        ),
      ]);

      final element = engine.resolve(document, {}).elements.single;

      // Outer group center: (20,20). Inner group's local center (10,10)
      // is offset (-10,-10) from the outer pivot; rotated 90deg clockwise
      // -> (10,-10); inner absolute center = (30,10).
      // Inner group's own absolute rotation is 90 (0 + 90).
      // Child local center (5,5) is offset (-5,-5) from inner pivot
      // (10,10); rotated by the inner group's *absolute* rotation (90)
      // -> (5,-5); child absolute center = (30+5, 10-5) = (35,5).
      final expectedCenter = const Point(x: 35, y: 5);
      final expectedTopLeft = Point(
        x: expectedCenter.x - 5,
        y: expectedCenter.y - 5,
      );
      expect(element.xDots, Dpi.dpi203.mmToDots(expectedTopLeft.x));
      expect(element.yDots, Dpi.dpi203.mmToDots(expectedTopLeft.y));
      expect(element.rotationDegrees, 90);
    });
  });
}
