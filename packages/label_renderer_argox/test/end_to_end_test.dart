import 'dart:convert';

import 'package:label_core/label_core.dart';
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:label_renderer_argox/label_renderer_argox.dart';
import 'package:test/test.dart';

/// Full-pipeline smoke test: LabelDocument -> LabelLayoutEngine ->
/// ArgoxRenderer -> PPLA bytes. Mirrors the other renderers'
/// end_to_end_test.dart with an equivalent sample label. See
/// docs/ROADMAP.md, etapa 16.
LabelDocument _sampleProductLabel() {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Etiqueta Produto',
    page: const PageConfig(width: 100, height: 50, dpi: Dpi.dpi203),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
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
      BarcodeElement(
        id: 'codigo',
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

void main() {
  test(
    'LabelDocument -> LabelLayoutEngine -> ArgoxRenderer produces valid PPLA',
    () async {
      final document = _sampleProductLabel();
      const layoutEngine = LabelLayoutEngine();
      const renderer = ArgoxRenderer();

      final resolved = layoutEngine.resolve(document, {
        'produto': 'Parafuso Sextavado M6',
        'codigo': 'PROD-000123',
      });

      final bytes = await renderer.render(
        resolved,
        const ArgoxRendererOptions(),
      );
      final commands = latin1.decode(bytes);

      expect(commands, startsWith('\x02qA\r'));
      expect(commands, contains('\x02L\r'));
      expect(commands, contains('D11\r'));
      expect(commands, contains('PROD-000123'));
      expect(commands, endsWith('Q0001\rE\r'));
    },
  );

  test(
    'the same document renders identically for the same data (determinism)',
    () async {
      final document = _sampleProductLabel();
      const layoutEngine = LabelLayoutEngine();
      const renderer = ArgoxRenderer();
      final data = {'produto': 'Parafuso', 'codigo': 'ABC'};

      final bytesA = await renderer.render(
        layoutEngine.resolve(document, data),
        const ArgoxRendererOptions(),
      );
      final bytesB = await renderer.render(
        layoutEngine.resolve(document, data),
        const ArgoxRendererOptions(),
      );

      expect(bytesA, bytesB);
    },
  );
}
