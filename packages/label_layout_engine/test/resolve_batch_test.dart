import 'package:label_core/label_core.dart';
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:test/test.dart';

LabelDocument _documentWith({
  required List<LabelElement> elements,
  int columns = 1,
  double columnGap = 0,
  Dpi dpi = Dpi.dpi203,
}) {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Teste',
    page: PageConfig(
      width: 50,
      height: 30,
      dpi: dpi,
      columns: columns,
      columnGap: columnGap,
    ),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    elements: elements,
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}

void main() {
  const engine = LabelLayoutEngine();

  final elements = [
    const TextElement(
      id: 'el-1',
      name: 'Nome',
      position: Point(x: 5, y: 5),
      size: Size2D(width: 30, height: 8),
      layerId: 'layer-1',
      content: '{{ nome }}',
    ),
  ];

  group('resolveBatch with columns: 1', () {
    test(
      'is equivalent, record by record, to calling resolve() per record',
      () {
        final document = _documentWith(elements: elements);
        final records = [
          {'nome': 'A'},
          {'nome': 'B'},
          {'nome': 'C'},
        ];

        final batch = engine.resolveBatch(document, records);
        final individual = records
            .map((data) => engine.resolve(document, data))
            .toList();

        expect(batch, individual);
      },
    );
  });

  group('resolveBatch with columns: 2', () {
    test('tiles records into rows of 2 columns, offsetting the 2nd column', () {
      final document = _documentWith(elements: elements, columns: 2);
      final records = [
        {'nome': 'A'},
        {'nome': 'B'},
        {'nome': 'C'},
      ];

      final rows = engine.resolveBatch(document, records);

      expect(rows, hasLength(2));

      final firstRow = rows[0];
      expect(firstRow.elements, hasLength(2));
      final columnOffsetDots = Dpi.dpi203.mmToDots(50);
      expect(
        firstRow.elements[1].xDots,
        firstRow.elements[0].xDots + columnOffsetDots,
      );
      expect((firstRow.elements[0].payload as ResolvedTextPayload).text, 'A');
      expect((firstRow.elements[1].payload as ResolvedTextPayload).text, 'B');

      final secondRow = rows[1];
      expect(secondRow.elements, hasLength(1));
      expect((secondRow.elements[0].payload as ResolvedTextPayload).text, 'C');
    });

    test(
      'every row is sized to the full row width, even a trailing partial row',
      () {
        final document = _documentWith(elements: elements, columns: 2);
        final rows = engine.resolveBatch(document, [
          {'nome': 'A'},
          {'nome': 'B'},
          {'nome': 'C'},
        ]);

        final fullRowWidthDots = Dpi.dpi203.mmToDots(50 * 2);
        expect(rows[0].widthDots, fullRowWidthDots);
        expect(rows[1].widthDots, fullRowWidthDots);
        expect(rows[1].heightDots, Dpi.dpi203.mmToDots(30));
      },
    );

    test('columnGap adds extra offset between columns', () {
      final document = _documentWith(
        elements: elements,
        columns: 2,
        columnGap: 5,
      );
      final rows = engine.resolveBatch(document, [
        {'nome': 'A'},
        {'nome': 'B'},
      ]);

      final columnOffsetDots = Dpi.dpi203.mmToDots(55);
      expect(
        rows[0].elements[1].xDots,
        rows[0].elements[0].xDots + columnOffsetDots,
      );
      expect(rows[0].widthDots, Dpi.dpi203.mmToDots(50 * 2 + 5));
    });
  });

  group('resolveBatch with a rotated group inside a column', () {
    test(
      'composes the column offset with the group rotation, not overriding it',
      () {
        final grouped = [
          GroupElement(
            id: 'group-1',
            name: 'Grupo',
            position: const Point(x: 10, y: 10),
            size: const Size2D(width: 20, height: 20),
            layerId: 'layer-1',
            rotation: 90,
            children: const [
              RectangleElement(
                id: 'child-1',
                name: 'Caixa',
                position: Point(x: 5, y: 5),
                size: Size2D(width: 10, height: 10),
                layerId: 'layer-1',
              ),
            ],
          ),
        ];
        final document = _documentWith(elements: grouped, columns: 2);

        final rowsColumn0 = engine.resolveBatch(document, [{}]);
        final rowsColumn1 = engine.resolveBatch(document, [{}, {}]);

        final column0Element = rowsColumn0[0].elements.single;
        final column1Element = rowsColumn1[0].elements[1];

        // Rotation stays 90 for both — the column offset only shifts the
        // absolute center, it doesn't add to rotation.
        expect(column0Element.rotationDegrees, 90);
        expect(column1Element.rotationDegrees, 90);

        // Column 0's child resolves to the same absolute position a plain
        // (non-batch) resolve of this document would produce: group center
        // (20,20)mm minus half the child's own 10x10mm size => topLeft
        // (15,15)mm. Column 1 is the same shape shifted by exactly one
        // column width (50mm) in X — computed directly in mm (like the
        // production code does) rather than by adding two independently
        // rounded dot values, since mm->dots rounding isn't additive.
        expect(column0Element.xDots, Dpi.dpi203.mmToDots(15));
        expect(column1Element.xDots, Dpi.dpi203.mmToDots(15 + 50));
        expect(column1Element.yDots, column0Element.yDots);
      },
    );
  });
}
