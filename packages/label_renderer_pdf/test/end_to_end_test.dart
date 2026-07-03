import 'dart:convert';
import 'dart:typed_data';

import 'package:label_core/label_core.dart';
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:label_renderer_pdf/label_renderer_pdf.dart';
import 'package:test/test.dart';

/// Full-pipeline smoke test: LabelDocument -> LabelLayoutEngine ->
/// PdfRenderer -> PDF bytes. Mirrors label_renderer_canvas's
/// end_to_end_test.dart with the same sample label, so the two renderers
/// are exercised against an equivalent document. See docs/ROADMAP.md,
/// etapa 15.
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
  test(
    'LabelDocument -> LabelLayoutEngine -> PdfRenderer produces a valid PDF',
    () async {
      final document = _sampleProductLabel();
      const layoutEngine = LabelLayoutEngine();
      const renderer = PdfRenderer();

      final resolved = layoutEngine.resolve(document, {
        'produto': 'Parafuso Sextavado M6',
        'preco': 3.9,
        'codigo': 'PROD-000123',
      });

      final bytes = await renderer.render(resolved, const PdfRendererOptions());

      expect(bytes.sublist(0, 4), Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));
      final text = latin1.decode(bytes, allowInvalid: true);
      expect(text, contains('%%EOF'));

      final match = RegExp(
        r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]',
      ).firstMatch(text);
      expect(match, isNotNull);
      final expectedWidthPt = Dpi.dpi203.mmToDots(100) * 72 / 203;
      final expectedHeightPt = Dpi.dpi203.mmToDots(50) * 72 / 203;
      expect(double.parse(match!.group(1)!), closeTo(expectedWidthPt, 0.5));
      expect(double.parse(match.group(2)!), closeTo(expectedHeightPt, 0.5));
    },
  );

  test('the same document renders twice without throwing (package:pdf embeds a '
      'random per-file /ID by design, so — unlike label_renderer_canvas\'s PNG '
      'output — byte-for-byte determinism does not apply here)', () async {
    final document = _sampleProductLabel();
    const layoutEngine = LabelLayoutEngine();
    const renderer = PdfRenderer();
    final data = {'produto': 'Parafuso', 'preco': 1.5, 'codigo': 'ABC'};

    final resolved = layoutEngine.resolve(document, data);
    await renderer.render(resolved, const PdfRendererOptions());
    await expectLater(
      renderer.render(resolved, const PdfRendererOptions()),
      completes,
    );
  });
}
