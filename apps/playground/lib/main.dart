import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer/label_designer.dart';
import 'package:label_serialization/label_serialization.dart';

void main() => runApp(const PlaygroundApp());

/// Internal sandbox app — see `docs/ARCHITECTURE.md` section 4 and
/// `docs/ROADMAP.md` etapa 14. Never imported by the consuming user
/// project; exists only to run `LabelDesigner` end-to-end by hand during
/// development.
class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label Designer Playground',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const PlaygroundPage(),
    );
  }
}

class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({super.key});

  static const _codec = LabelDocumentCodec();

  void _handleSave(BuildContext context, LabelDocument document) {
    final json = _codec.encode(document);
    // No real file I/O here on purpose: the playground only proves the
    // LabelDesigner -> LabelDocument -> label_serialization leg of the
    // pipeline works; writing to disk/printing is the consuming app's
    // job (see docs/ARCHITECTURE.md section 20).
    debugPrint('--- LabelDocument codificado (${json.length} bytes) ---');
    debugPrint(json);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Documento codificado: ${json.length} bytes (ver console)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LabelDesigner(
        document: _sampleDocument(),
        onSave: (document) => _handleSave(context, document),
      ),
    );
  }
}

/// The same product-label fixture used by `label_renderer_canvas`'s
/// end-to-end test (see `docs/ROADMAP.md` etapa 6) — a border, a text
/// element with a `{{ }}` placeholder, a `VariableElement` exercising
/// `.currency()`, and a barcode whose data is itself an expression, with
/// every declared variable already given a sample value so the canvas,
/// property panel and preview all show something meaningful immediately.
LabelDocument _sampleDocument() {
  final now = DateTime.now();
  return LabelDocument(
    name: 'Etiqueta de exemplo',
    page: const PageConfig(width: 100, height: 50, dpi: Dpi.dpi203),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    variables: const [
      LabelVariable(name: 'produto', defaultValue: 'Parafuso Sextavado M6'),
      LabelVariable(
        name: 'preco',
        type: VariableType.number,
        defaultValue: 3.9,
      ),
      LabelVariable(name: 'codigo', defaultValue: 'PROD-000123'),
    ],
    elements: const [
      RectangleElement(
        id: 'border',
        name: 'Borda',
        position: Point(x: 1, y: 1),
        size: Size2D(width: 98, height: 48),
        layerId: 'layer-1',
        style: ShapeStyleSpec(strokeColor: 0xFF000000, strokeWidth: 0.5),
      ),
      TextElement(
        id: 'nome',
        name: 'Nome do produto',
        position: Point(x: 5, y: 5),
        size: Size2D(width: 90, height: 10),
        layerId: 'layer-1',
        content: '{{ produto }}',
        style: TextStyleSpec(fontSize: 5, bold: true),
      ),
      VariableElement(
        id: 'preco-el',
        name: 'Preço',
        position: Point(x: 5, y: 16),
        size: Size2D(width: 40, height: 8),
        layerId: 'layer-1',
        expression: 'preco.currency()',
      ),
      BarcodeElement(
        id: 'codigo-el',
        name: 'Código de barras',
        position: Point(x: 5, y: 28),
        size: Size2D(width: 60, height: 15),
        layerId: 'layer-1',
        data: '{{ codigo }}',
        symbology: BarcodeSymbology.code128,
      ),
    ],
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}
