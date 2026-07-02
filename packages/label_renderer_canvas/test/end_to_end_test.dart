import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:label_renderer_canvas/label_renderer_canvas.dart';

/// Full-pipeline smoke test: LabelDocument -> LabelLayoutEngine ->
/// CanvasRenderer -> PNG bytes — the first point in the roadmap where a
/// label actually gets "seen" as an image, not just as data. See
/// docs/ROADMAP.md, etapa 6.
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
      VariableElement(
        id: 'preco',
        name: 'Preço',
        position: Point(x: 5, y: 16),
        size: Size2D(width: 40, height: 8),
        layerId: 'layer-1',
        expression: 'preco.currency()',
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
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'LabelDocument -> LabelLayoutEngine -> CanvasRenderer produces a valid PNG',
    () async {
      final document = _sampleProductLabel();
      const layoutEngine = LabelLayoutEngine();
      const renderer = CanvasRenderer();

      final resolved = layoutEngine.resolve(document, {
        'produto': 'Parafuso Sextavado M6',
        'preco': 3.9,
        'codigo': 'PROD-000123',
      });

      final pngBytes = await renderer.render(
        resolved,
        const CanvasRendererOptions(),
      );

      // PNG magic number: 89 50 4E 47 0D 0A 1A 0A.
      expect(
        pngBytes.sublist(0, 8),
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      );

      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, Dpi.dpi203.mmToDots(100));
      expect(frame.image.height, Dpi.dpi203.mmToDots(50));
    },
  );

  test(
    'the same document renders identically for the same data (determinism)',
    () async {
      final document = _sampleProductLabel();
      const layoutEngine = LabelLayoutEngine();
      const renderer = CanvasRenderer();
      final data = {'produto': 'Parafuso', 'preco': 1.5, 'codigo': 'ABC'};

      final bytesA = await renderer.render(
        layoutEngine.resolve(document, data),
        const CanvasRendererOptions(),
      );
      final bytesB = await renderer.render(
        layoutEngine.resolve(document, data),
        const CanvasRendererOptions(),
      );

      expect(bytesA, bytesB);
    },
  );
}
