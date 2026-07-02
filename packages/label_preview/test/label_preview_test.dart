import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:label_preview/label_preview.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_canvas/label_renderer_canvas.dart';

LabelDocument _document({double width = 100, double height = 50}) {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Doc',
    page: PageConfig(width: width, height: height, dpi: Dpi.dpi203),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    elements: const [
      RectangleElement(
        id: 'rect-1',
        name: 'Retângulo',
        position: Point(x: 1, y: 1),
        size: Size2D(width: 10, height: 10),
        layerId: 'layer-1',
      ),
    ],
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}

LabelDocument _invalidDocument() {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Doc inválido',
    page: const PageConfig(width: 100, height: 50, dpi: Dpi.dpi203),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    elements: const [
      RectangleElement(
        id: 'zero',
        name: 'Zero',
        position: Point.zero(),
        // Resolves to 0 dots at 203 DPI, which LabelLayoutEngine rejects.
        size: Size2D.zero(),
        layerId: 'layer-1',
      ),
    ],
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}

/// A [LabelRenderer] whose `render` calls are driven manually, so tests can
/// assert exactly how many renders a sequence of widget rebuilds triggers
/// (debounce) without racing real `dart:ui` image encoding.
class _ControlledRenderer implements LabelRenderer {
  final List<Completer<Uint8List>> _pending = [];
  final List<ResolvedDocument> calls = [];

  @override
  Future<Uint8List> render(
    ResolvedDocument document,
    RendererOptions options,
  ) {
    calls.add(document);
    final completer = Completer<Uint8List>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext(Uint8List bytes) => _pending.removeAt(0).complete(bytes);

  void failNext(Object error) => _pending.removeAt(0).completeError(error);
}

void main() {
  late Uint8List validPng;

  setUpAll(() async {
    validPng = await const CanvasRenderer().render(
      const LabelLayoutEngine().resolve(_document(), const {}),
      const CanvasRendererOptions(),
    );
  });

  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SizedBox(width: 300, height: 200, child: child)));

  testWidgets(
    'shows a loading indicator before the first render completes, then '
    'the PNG',
    (tester) async {
      // Uses a controlled renderer rather than the real CanvasRenderer:
      // CircularProgressIndicator's animation never stops on its own, so
      // pumpAndSettle can't tell "still rendering" apart from "the real
      // dart:ui pipeline hasn't produced a frame in this test binding yet"
      // and times out. The real pipeline (LabelLayoutEngine ->
      // CanvasRenderer -> valid PNG bytes) is exercised without any widget
      // pumping in `setUpAll` above, and end-to-end in
      // `label_renderer_canvas`'s tests.
      final renderer = _ControlledRenderer();
      await tester.pumpWidget(
        wrap(LabelPreview(document: _document(), renderer: renderer)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      renderer.completeNext(validPng);
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('coalesces rapid document changes into a single debounced render', (
    tester,
  ) async {
    final renderer = _ControlledRenderer();
    const debounce = Duration(milliseconds: 300);

    await tester.pumpWidget(
      wrap(
        LabelPreview(
          document: _document(width: 100),
          renderer: renderer,
          debounce: debounce,
        ),
      ),
    );
    await tester.pump();
    expect(renderer.calls, hasLength(1));
    renderer.completeNext(validPng);
    await tester.pump();

    // Three rapid updates within one debounce window.
    await tester.pumpWidget(
      wrap(
        LabelPreview(
          document: _document(width: 101),
          renderer: renderer,
          debounce: debounce,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(
      wrap(
        LabelPreview(
          document: _document(width: 102),
          renderer: renderer,
          debounce: debounce,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(
      wrap(
        LabelPreview(
          document: _document(width: 103),
          renderer: renderer,
          debounce: debounce,
        ),
      ),
    );

    // Debounce window hasn't elapsed since the last change yet.
    await tester.pump(const Duration(milliseconds: 100));
    expect(renderer.calls, hasLength(1));

    // Now it has, and only the latest document (width 103) was rendered.
    await tester.pump(const Duration(milliseconds: 250));
    expect(renderer.calls, hasLength(2));
    expect(
      renderer.calls.last.widthDots,
      Dpi.dpi203.mmToDots(103),
    );
  });

  testWidgets(
    'keeps the last good image visible and surfaces the error when a '
    'later render fails',
    (tester) async {
      final renderer = _ControlledRenderer();
      await tester.pumpWidget(
        wrap(LabelPreview(document: _document(), renderer: renderer)),
      );
      await tester.pump();
      renderer.completeNext(validPng);
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);

      await tester.pumpWidget(
        wrap(LabelPreview(document: _document(width: 90), renderer: renderer)),
      );
      await tester.pump(const Duration(milliseconds: 350));
      renderer.failNext(StateError('falha simulada de renderização'));
      await tester.pump();

      // Old image stays on screen; the error is surfaced alongside it.
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('falha simulada'), findsOneWidget);
    },
  );

  testWidgets('surfaces a LayoutException from an invalid document', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(LabelPreview(document: _invalidDocument())));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('LayoutException'), findsOneWidget);
  });

  testWidgets('uses a custom errorBuilder when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        LabelPreview(
          document: _invalidDocument(),
          errorBuilder: (context, error) => const Text('deu ruim'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('deu ruim'), findsOneWidget);
  });
}
