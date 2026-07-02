import 'package:label_core/label_core.dart';
import 'package:label_serialization/label_serialization.dart';
import 'package:test/test.dart';

LabelDocument _sampleDocument() {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
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
      BarcodeElement(
        id: 'el-2',
        name: 'Código',
        position: Point(x: 5, y: 20),
        size: Size2D(width: 60, height: 15),
        layerId: 'layer-1',
        data: '{{ codigo }}',
        symbology: BarcodeSymbology.code128,
      ),
    ],
    metadata: DocumentMetadata(
      author: 'carvalho.wesley@g3soft.com.br',
      createdAt: now,
      updatedAt: now,
      history: const ['v1 criado'],
    ),
  );
}

void main() {
  const codec = LabelDocumentCodec();

  group('LabelDocumentCodec', () {
    test('encode() then decode() round-trips to an equal LabelDocument', () {
      final document = _sampleDocument();
      final decoded = codec.decode(codec.encode(document));
      expect(decoded, document);
    });

    test('encode() produces valid, minified-agnostic JSON', () {
      final json = codec.encode(_sampleDocument());
      expect(json, contains('"version":1'));
      expect(json, contains('"type":"text"'));
      expect(json, contains('"type":"barcode"'));
    });

    test(
      'encodeToMap()/decodeMap() round-trip without going through a String',
      () {
        final document = _sampleDocument();
        final map = codec.encodeToMap(document);
        expect(codec.decodeMap(map), document);
      },
    );

    test('decode() throws FormatException for invalid JSON', () {
      expect(() => codec.decode('{not valid json'), throwsFormatException);
    });

    test(
      'decode() rejects a document from a newer, unsupported schema version',
      () {
        final future = codec.encodeToMap(_sampleDocument());
        future['version'] = labelDocumentSchemaVersion + 1;

        expect(
          () => codec.decodeMap(future),
          throwsA(isA<UnsupportedSchemaVersionException>()),
        );
      },
    );
  });
}
