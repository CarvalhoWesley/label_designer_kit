import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/label_canvas.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

RectangleElement _rect(String id, {Point position = const Point.zero()}) =>
    RectangleElement(
      id: id,
      name: id,
      position: position,
      size: const Size2D(width: 20, height: 20),
      layerId: 'layer-1',
    );

class _Harness {
  _Harness(List<LabelElement> elements)
    : documentStore = DocumentStore(
        LabelDocument.blank(name: 'Doc').copyWith(elements: elements),
      ) {
    historyStore = HistoryStore(documentStore);
    selectionStore = SelectionStore();
    viewportStore = ViewportStore()..setZoom(1);
    canvasStore = CanvasStore();
  }

  final DocumentStore documentStore;
  late final HistoryStore historyStore;
  late final SelectionStore selectionStore;
  late final ViewportStore viewportStore;
  late final CanvasStore canvasStore;

  Widget build() => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 400,
      height: 400,
      child: LabelCanvas(
        documentStore: documentStore,
        selectionStore: selectionStore,
        historyStore: historyStore,
        viewportStore: viewportStore,
        canvasStore: canvasStore,
        showRulers: false,
      ),
    ),
  );
}

void main() {
  testWidgets('renders without throwing for an empty document', (tester) async {
    final h = _Harness(const []);
    await tester.pumpWidget(h.build());
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing with rulers enabled', (tester) async {
    final h = _Harness([_rect('a')]);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 400,
          child: LabelCanvas(
            documentStore: h.documentStore,
            selectionStore: h.selectionStore,
            historyStore: h.historyStore,
            viewportStore: h.viewportStore,
            canvasStore: h.canvasStore,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders every element type without throwing', (tester) async {
    var y = 0.0;
    LabelElement place(LabelElement Function(Point pos) build) {
      final el = build(Point(x: 0, y: y));
      y += 25;
      return el;
    }

    final elements = [
      place(
        (pos) => TextElement(
          id: 'text',
          name: 'text',
          position: pos,
          size: const Size2D(width: 20, height: 10),
          layerId: 'layer-1',
          content: 'Olá',
        ),
      ),
      place(
        (pos) => RectangleElement(
          id: 'rect',
          name: 'rect',
          position: pos,
          size: const Size2D(width: 20, height: 10),
          layerId: 'layer-1',
        ),
      ),
      place(
        (pos) => EllipseElement(
          id: 'ellipse',
          name: 'ellipse',
          position: pos,
          size: const Size2D(width: 20, height: 10),
          layerId: 'layer-1',
        ),
      ),
      place(
        (pos) => CircleElement(
          id: 'circle',
          name: 'circle',
          position: pos,
          size: const Size2D(width: 10, height: 10),
          layerId: 'layer-1',
        ),
      ),
      place(
        (pos) => LineElement(
          id: 'line',
          name: 'line',
          position: pos,
          size: const Size2D(width: 20, height: 5),
          layerId: 'layer-1',
        ),
      ),
      place(
        (pos) => BarcodeElement(
          id: 'barcode',
          name: 'barcode',
          position: pos,
          size: const Size2D(width: 30, height: 10),
          layerId: 'layer-1',
          data: '123456',
          symbology: BarcodeSymbology.code128,
        ),
      ),
      place(
        (pos) => QRCodeElement(
          id: 'qr',
          name: 'qr',
          position: pos,
          size: const Size2D(width: 15, height: 15),
          layerId: 'layer-1',
          data: 'x',
        ),
      ),
      place(
        (pos) => ImageElement(
          id: 'image',
          name: 'image',
          position: pos,
          size: const Size2D(width: 20, height: 10),
          layerId: 'layer-1',
          source: 'x',
        ),
      ),
      place(
        (pos) => VariableElement(
          id: 'var',
          name: 'var',
          position: pos,
          size: const Size2D(width: 20, height: 10),
          layerId: 'layer-1',
          expression: 'x',
        ),
      ),
      place(
        (pos) => DateElement(
          id: 'date',
          name: 'date',
          position: pos,
          size: const Size2D(width: 20, height: 10),
          layerId: 'layer-1',
        ),
      ),
      place(
        (pos) => TimeElement(
          id: 'time',
          name: 'time',
          position: pos,
          size: const Size2D(width: 20, height: 10),
          layerId: 'layer-1',
        ),
      ),
      place(
        (pos) => TableElement(
          id: 'table',
          name: 'table',
          position: pos,
          size: const Size2D(width: 30, height: 10),
          layerId: 'layer-1',
          columns: const [],
        ),
      ),
      place(
        (pos) => GroupElement(
          id: 'group',
          name: 'group',
          position: pos,
          size: const Size2D(width: 20, height: 20),
          layerId: 'layer-1',
          children: [
            RectangleElement(
              id: 'group-child',
              name: 'child',
              position: const Point.zero(),
              size: const Size2D(width: 5, height: 5),
              layerId: 'layer-1',
            ),
          ],
        ),
      ),
    ];

    final h = _Harness(elements);
    await tester.pumpWidget(h.build());
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an element selects it', (tester) async {
    final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
    await tester.pumpWidget(h.build());

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();

    expect(h.selectionStore.selectedIds, {'a'});
  });

  testWidgets('dragging a selected element moves it and repaints the preview', (
    tester,
  ) async {
    final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
    await tester.pumpWidget(h.build());
    h.selectionStore.select('a');

    final gesture = await tester.startGesture(const Offset(10, 10));
    await gesture.moveBy(const Offset(15, 15));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(h.documentStore.elements.single.position, const Point(x: 15, y: 15));
    expect(h.historyStore.canUndo, isTrue);
  });

  testWidgets('tapping empty space clears the selection', (tester) async {
    final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
    await tester.pumpWidget(h.build());
    h.selectionStore.select('a');

    await tester.tapAt(const Offset(300, 300));
    await tester.pump();

    expect(h.selectionStore.selectedIds, isEmpty);
  });

  testWidgets(
    'rebuilds when the document changes externally (Observer reacts)',
    (tester) async {
      final h = _Harness([_rect('a')]);
      await tester.pumpWidget(h.build());

      h.historyStore.addElement(
        _rect('b', position: const Point(x: 100, y: 100)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(h.documentStore.elements, hasLength(2));
    },
  );
}
