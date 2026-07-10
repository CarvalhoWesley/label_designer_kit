import 'package:label_core/label_core.dart';
import 'package:test/test.dart';

void main() {
  group('LabelDocument.blank', () {
    test('produces a document with one layer and a default page', () {
      final document = LabelDocument.blank();

      expect(document.version, labelDocumentSchemaVersion);
      expect(document.layers, hasLength(1));
      expect(document.elements, isEmpty);
      expect(document.page.width, 100);
      expect(document.page.height, 50);
    });
  });

  group('LabelDocument JSON round-trip', () {
    test('matches the .label schema documented in ARCHITECTURE.md', () {
      final now = DateTime.utc(2026, 7, 2);
      final document = LabelDocument(
        name: 'Etiqueta Produto',
        page: const PageConfig(
          width: 100,
          height: 50,
          dpi: Dpi.dpi203,
          margins: EdgeInsets.all(2),
        ),
        layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
        styles: const [
          LabelStyle(
            id: 'style-titulo',
            name: 'Título',
            spec: TextStyleSpec(fontFamily: 'Roboto', fontSize: 4, bold: true),
          ),
        ],
        variables: const [
          LabelVariable(name: 'produto', type: VariableType.string),
          LabelVariable(name: 'preco', type: VariableType.number),
        ],
        elements: const [
          TextElement(
            id: 'el-1',
            name: 'Nome do produto',
            position: Point(x: 5, y: 5),
            size: Size2D(width: 40, height: 8),
            layerId: 'layer-1',
            content: '{{ produto }}',
            styleId: 'style-titulo',
          ),
        ],
        metadata: DocumentMetadata(
          author: 'carvalho.wesley@g3soft.com.br',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final json = document.toJson();
      expect(json['version'], 1);
      expect(json['page'], containsPair('dpi', 203));

      final decoded = LabelDocument.fromJson(json);
      expect(decoded, document);
    });

    test('decodes documents that omit optional lists', () {
      final json = {
        'version': 1,
        'name': 'Mínima',
        'page': {'width': 50, 'height': 30, 'dpi': 203},
        'metadata': {
          'createdAt': '2026-07-02T00:00:00.000Z',
          'updatedAt': '2026-07-02T00:00:00.000Z',
        },
      };

      final decoded = LabelDocument.fromJson(json);
      expect(decoded.layers, isEmpty);
      expect(decoded.styles, isEmpty);
      expect(decoded.variables, isEmpty);
      expect(decoded.elements, isEmpty);
      expect(decoded.metadata.history, isEmpty);
      expect(decoded.page.columns, 1);
      expect(decoded.page.columnGap, 0);
    });

    test('round-trips columns/columnGap through JSON', () {
      final now = DateTime.utc(2026, 7, 2);
      final document = LabelDocument(
        name: 'Rolo de 2 colunas',
        page: const PageConfig(width: 50, height: 30, columns: 2, columnGap: 3),
        metadata: DocumentMetadata(createdAt: now, updatedAt: now),
      );

      final json = document.toJson();
      expect(json['page'], containsPair('columns', 2));
      expect(json['page'], containsPair('columnGap', 3.0));

      final decoded = LabelDocument.fromJson(json);
      expect(decoded, document);
      expect(decoded.page.columns, 2);
      expect(decoded.page.columnGap, 3);
    });
  });

  group('DocumentMetadata', () {
    test('round-trips history entries through JSON', () {
      final now = DateTime.utc(2026, 7, 2);
      final metadata = DocumentMetadata(
        createdAt: now,
        updatedAt: now,
        history: const ['v1 criado por carvalho.wesley@g3soft.com.br'],
      );
      expect(DocumentMetadata.fromJson(metadata.toJson()), metadata);
    });
  });

  group('LabelDocument.copyWith', () {
    test('appending an element does not mutate the original document', () {
      final document = LabelDocument.blank();
      const newElement = RectangleElement(
        id: 'el-1',
        name: 'Caixa',
        position: Point(x: 0, y: 0),
        size: Size2D(width: 10, height: 10),
        layerId: 'layer-1',
      );

      final updated = document.copyWith(elements: [newElement]);

      expect(document.elements, isEmpty);
      expect(updated.elements, [newElement]);
    });
  });

  group('PageConfig', () {
    test('round-trips through JSON preserving DPI as an integer', () {
      const page = PageConfig(width: 100, height: 50, dpi: Dpi.dpi300);
      final decoded = PageConfig.fromJson(page.toJson());
      expect(decoded, page);
      expect(page.toJson()['dpi'], 300);
    });
  });

  group('LabelVariable', () {
    test('round-trips through JSON including defaultValue', () {
      const variable = LabelVariable(
        name: 'estoque',
        type: VariableType.number,
        defaultValue: 0,
        description: 'Quantidade em estoque',
      );
      expect(LabelVariable.fromJson(variable.toJson()), variable);
    });
  });

  group('LabelStyle', () {
    test('round-trips through JSON', () {
      const style = LabelStyle(
        id: 'style-1',
        name: 'Corpo',
        spec: TextStyleSpec(fontSize: 3),
      );
      expect(LabelStyle.fromJson(style.toJson()), style);
    });
  });
}
