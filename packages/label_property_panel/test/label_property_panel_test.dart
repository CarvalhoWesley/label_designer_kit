import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_property_panel/label_property_panel.dart';

const _text = TextElement(
  id: 'text-1',
  name: 'Texto',
  position: Point(x: 5, y: 5),
  size: Size2D(width: 30, height: 10),
  layerId: 'layer-1',
  content: 'Olá {{ nome }}',
);

const _barcode = BarcodeElement(
  id: 'barcode-1',
  name: 'Barras',
  position: Point(x: 5, y: 20),
  size: Size2D(width: 30, height: 10),
  layerId: 'layer-1',
  data: '123456',
  symbology: BarcodeSymbology.code128,
);

const _qrCode = QRCodeElement(
  id: 'qr-1',
  name: 'QR',
  position: Point(x: 40, y: 5),
  size: Size2D(width: 15, height: 15),
  layerId: 'layer-1',
  data: '{{ url }}',
);

const _image = ImageElement(
  id: 'image-1',
  name: 'Imagem',
  position: Point(x: 60, y: 5),
  size: Size2D(width: 15, height: 15),
  layerId: 'layer-1',
  source: 'logo.png',
);

const _rectangle = RectangleElement(
  id: 'rect-1',
  name: 'Retângulo',
  position: Point(x: 5, y: 35),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

const _ellipse = EllipseElement(
  id: 'ellipse-1',
  name: 'Elipse',
  position: Point(x: 20, y: 35),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

const _circle = CircleElement(
  id: 'circle-1',
  name: 'Círculo',
  position: Point(x: 35, y: 35),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

const _line = LineElement(
  id: 'line-1',
  name: 'Linha',
  position: Point(x: 50, y: 35),
  size: Size2D(width: 10, height: 0),
  layerId: 'layer-1',
);

const _variable = VariableElement(
  id: 'variable-1',
  name: 'Variável',
  position: Point(x: 5, y: 45),
  size: Size2D(width: 30, height: 8),
  layerId: 'layer-1',
  expression: 'preco.currency()',
);

const _date = DateElement(
  id: 'date-1',
  name: 'Data',
  position: Point(x: 40, y: 25),
  size: Size2D(width: 20, height: 6),
  layerId: 'layer-1',
);

const _time = TimeElement(
  id: 'time-1',
  name: 'Hora',
  position: Point(x: 60, y: 25),
  size: Size2D(width: 20, height: 6),
  layerId: 'layer-1',
);

const _table = TableElement(
  id: 'table-1',
  name: 'Tabela',
  position: Point(x: 5, y: 60),
  size: Size2D(width: 40, height: 20),
  layerId: 'layer-1',
  columns: [
    TableColumn(header: 'Item', dataField: 'nome', width: 20),
    TableColumn(header: 'Qtd', dataField: 'quantidade', width: 20),
  ],
  dataField: 'itens',
);

const _group = GroupElement(
  id: 'group-1',
  name: 'Grupo',
  position: Point(x: 60, y: 60),
  size: Size2D(width: 20, height: 20),
  layerId: 'layer-1',
  children: [_rectangle],
);

const _allElements = [
  _text,
  _barcode,
  _qrCode,
  _image,
  _rectangle,
  _ellipse,
  _circle,
  _line,
  _variable,
  _date,
  _time,
  _table,
  _group,
];

class _Harness {
  _Harness(List<LabelElement> elements)
    : documentStore = DocumentStore(
        LabelDocument.blank(name: 'Doc').copyWith(elements: elements),
      ) {
    historyStore = HistoryStore(documentStore);
    selectionStore = SelectionStore();
    propertyStore = PropertyStore(documentStore, selectionStore, historyStore);
  }

  final DocumentStore documentStore;
  late final HistoryStore historyStore;
  late final SelectionStore selectionStore;
  late final PropertyStore propertyStore;

  Widget build() => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 320,
        height: 900,
        child: LabelPropertyPanel(
          documentStore: documentStore,
          selectionStore: selectionStore,
          propertyStore: propertyStore,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the empty state when nothing is selected', (
    tester,
  ) async {
    final h = _Harness(_allElements);
    await tester.pumpWidget(h.build());

    expect(
      find.text('Selecione um elemento para editar suas propriedades.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders every element type without throwing when selected', (
    tester,
  ) async {
    for (final element in _allElements) {
      final h = _Harness(_allElements);
      h.selectionStore.select(element.id);
      await tester.pumpWidget(h.build());
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'failed for ${element.typeName}',
      );
    }
  });

  testWidgets('editing the name field dispatches an undo-able change', (
    tester,
  ) async {
    final h = _Harness(_allElements);
    h.selectionStore.select('text-1');
    await tester.pumpWidget(h.build());

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Novo nome');
    await tester.pump();

    final updated =
        h.documentStore.elements.firstWhere((e) => e.id == 'text-1');
    expect(updated.name, 'Novo nome');
    expect(h.historyStore.canUndo, isTrue);

    h.historyStore.undo();
    final reverted =
        h.documentStore.elements.firstWhere((e) => e.id == 'text-1');
    expect(reverted.name, 'Texto');
  });

  testWidgets('editing position X updates only the position', (
    tester,
  ) async {
    final h = _Harness(_allElements);
    h.selectionStore.select('rect-1');
    await tester.pumpWidget(h.build());

    await tester.enterText(find.widgetWithText(TextField, 'X'), '42');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final updated =
        h.documentStore.elements.firstWhere((e) => e.id == 'rect-1')
            as RectangleElement;
    expect(updated.position, const Point(x: 42, y: 35));
    expect(updated.size, _rectangle.size);
  });

  testWidgets('toggling visibility for a multi-selection is one undo step', (
    tester,
  ) async {
    final h = _Harness(_allElements);
    h.selectionStore.selectAll(['rect-1', 'ellipse-1']);
    await tester.pumpWidget(h.build());

    expect(find.text('2 elementos selecionados'), findsOneWidget);

    await tester.tap(find.byTooltip('Ocultar todos'));
    await tester.pump();

    expect(
      h.documentStore.elements
          .where((e) => e.id == 'rect-1' || e.id == 'ellipse-1')
          .every((e) => !e.visible),
      isTrue,
    );

    h.historyStore.undo();
    expect(
      h.documentStore.elements
          .where((e) => e.id == 'rect-1' || e.id == 'ellipse-1')
          .every((e) => e.visible),
      isTrue,
    );
  });

  testWidgets('changing the layer dropdown updates layerId', (tester) async {
    final withSecondLayer = LabelDocument.blank(name: 'Doc').copyWith(
      layers: const [
        LabelLayer(id: 'layer-1', name: 'Base', order: 0),
        LabelLayer(id: 'layer-2', name: 'Topo', order: 1),
      ],
      elements: [_rectangle],
    );
    final documentStore = DocumentStore(withSecondLayer);
    final historyStore = HistoryStore(documentStore);
    final selectionStore = SelectionStore()..select('rect-1');
    final propertyStore = PropertyStore(
      documentStore,
      selectionStore,
      historyStore,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 900,
            child: LabelPropertyPanel(
              documentStore: documentStore,
              selectionStore: selectionStore,
              propertyStore: propertyStore,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Base'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Topo').last);
    await tester.pumpAndSettle();

    final updated = documentStore.elements.first;
    expect(updated.layerId, 'layer-2');
  });
}
