import 'package:flutter/material.dart' hide EdgeInsets;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_label_designer/flutter_label_designer.dart';

/// Proves the umbrella barrel alone — no other package import — is
/// enough to embed [LabelDesigner] and run the full
/// design -> serialize -> resolve -> render pipeline. If a future change
/// to any underlying package narrows what this barrel re-exports, this
/// test fails here instead of silently breaking every consumer. See
/// `docs/INTEGRATION.md`.
LabelDocument _sampleDocument() {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Etiqueta de exemplo',
    page: const PageConfig(width: 50, height: 30, dpi: Dpi.dpi203),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    elements: const [
      TextElement(
        id: 'nome',
        name: 'Nome do produto',
        position: Point(x: 0, y: 5),
        size: Size2D(width: 35, height: 5),
        layerId: 'layer-1',
        content: '{{ produto }}',
        style: TextStyleSpec(fontSize: 2.5, bold: true),
      ),
    ],
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}

void main() {
  // CanvasRenderer uses dart:ui directly (toImage/toByteData), which
  // needs the Flutter binding even outside a testWidgets block.
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LabelDesigner renders from the umbrella barrel alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LabelDesigner(document: _sampleDocument())),
      ),
    );
    await tester.pump();

    expect(find.byType(LabelDesigner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'serialize -> resolve -> render (PDF, PNG, PPLA) all work from the umbrella barrel alone',
    () async {
      final document = _sampleDocument();

      const codec = LabelDocumentCodec();
      final json = codec.encode(document);
      expect(codec.decode(json), document);

      const layoutEngine = LabelLayoutEngine();
      final resolved = layoutEngine.resolve(document, {'produto': 'Parafuso'});

      final pdfBytes = await const PdfRenderer().render(
        resolved,
        const PdfRendererOptions(),
      );
      expect(pdfBytes, isNotEmpty);

      final pngBytes = await const CanvasRenderer().render(
        resolved,
        const CanvasRendererOptions(),
      );
      expect(pngBytes, isNotEmpty);

      final pplaBytes = await const ArgoxRenderer().render(
        resolved,
        const ArgoxRendererOptions(),
      );
      expect(pplaBytes, isNotEmpty);
    },
  );
}
