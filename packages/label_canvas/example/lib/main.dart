import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:label_canvas/label_canvas.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_designer_state/label_designer_state.dart';

void main() {
  runApp(const CanvasPlaygroundApp());
}

/// Manual playground for `label_canvas` — a sample document with several
/// element types, wired to real `label_designer_state` stores, so
/// select/move/resize/rotate/zoom/pan/grid/snap can be exercised by hand.
/// Not code intended for the framework's end users.
class CanvasPlaygroundApp extends StatelessWidget {
  const CanvasPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'label_canvas — playground',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const _PlaygroundPage(),
    );
  }
}

LabelDocument _sampleDocument() {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Playground',
    page: const PageConfig(width: 100, height: 60, dpi: Dpi.dpi203),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
    elements: const [
      TextElement(
        id: 'title',
        name: 'Título',
        position: Point(x: 5, y: 5),
        size: Size2D(width: 60, height: 8),
        layerId: 'layer-1',
        content: '{{ produto }}',
        style: TextStyleSpec(fontSize: 5, bold: true),
      ),
      RectangleElement(
        id: 'box',
        name: 'Caixa',
        position: Point(x: 5, y: 16),
        size: Size2D(width: 30, height: 20),
        layerId: 'layer-1',
        style: ShapeStyleSpec(strokeColor: 0xFF1976D2, strokeWidth: 0.5),
        cornerRadius: 2,
      ),
      EllipseElement(
        id: 'ellipse',
        name: 'Elipse',
        position: Point(x: 40, y: 16),
        size: Size2D(width: 20, height: 12),
        layerId: 'layer-1',
        style: ShapeStyleSpec(fillColor: 0x33FF9800, strokeColor: 0xFFFF9800),
      ),
      CircleElement(
        id: 'circle',
        name: 'Círculo',
        position: Point(x: 65, y: 16),
        size: Size2D(width: 15, height: 15),
        rotation: 15,
        layerId: 'layer-1',
        style: ShapeStyleSpec(fillColor: 0x334CAF50, strokeColor: 0xFF4CAF50),
      ),
      LineElement(
        id: 'line',
        name: 'Linha',
        position: Point(x: 5, y: 40),
        size: Size2D(width: 40, height: 0),
        layerId: 'layer-1',
      ),
      BarcodeElement(
        id: 'barcode',
        name: 'Código de barras',
        position: Point(x: 5, y: 45),
        size: Size2D(width: 40, height: 12),
        rotation: 0,
        layerId: 'layer-1',
        data: '{{ codigo }}',
        symbology: BarcodeSymbology.code128,
      ),
      QRCodeElement(
        id: 'qr',
        name: 'QR',
        position: Point(x: 50, y: 32),
        size: Size2D(width: 18, height: 18),
        layerId: 'layer-1',
        data: '{{ codigo }}',
      ),
      GroupElement(
        id: 'group',
        name: 'Grupo rotacionado',
        position: Point(x: 72, y: 34),
        size: Size2D(width: 20, height: 20),
        rotation: 20,
        layerId: 'layer-1',
        children: [
          RectangleElement(
            id: 'group-a',
            name: 'a',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 8, height: 8),
            layerId: 'layer-1',
          ),
          RectangleElement(
            id: 'group-b',
            name: 'b',
            position: Point(x: 10, y: 10),
            size: Size2D(width: 8, height: 8),
            layerId: 'layer-1',
          ),
        ],
      ),
    ],
  );
}

class _PlaygroundPage extends StatefulWidget {
  const _PlaygroundPage();

  @override
  State<_PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<_PlaygroundPage> {
  late final DocumentStore documentStore;
  late final HistoryStore historyStore;
  late final SelectionStore selectionStore;
  late final ViewportStore viewportStore;
  late final CanvasStore canvasStore;

  @override
  void initState() {
    super.initState();
    documentStore = DocumentStore(_sampleDocument());
    historyStore = HistoryStore(documentStore);
    selectionStore = SelectionStore();
    viewportStore = ViewportStore()..setZoom(6);
    canvasStore = CanvasStore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('label_canvas — playground'),
        actions: [
          Observer(
            builder: (context) => IconButton(
              tooltip: 'Desfazer',
              icon: const Icon(Icons.undo),
              onPressed: historyStore.canUndo ? historyStore.undo : null,
            ),
          ),
          Observer(
            builder: (context) => IconButton(
              tooltip: 'Refazer',
              icon: const Icon(Icons.redo),
              onPressed: historyStore.canRedo ? historyStore.redo : null,
            ),
          ),
          IconButton(
            tooltip: 'Zoom +',
            icon: const Icon(Icons.zoom_in),
            onPressed: () => viewportStore.zoomBy(1.2),
          ),
          IconButton(
            tooltip: 'Zoom -',
            icon: const Icon(Icons.zoom_out),
            onPressed: () => viewportStore.zoomBy(0.8),
          ),
          Observer(
            builder: (context) => IconButton(
              tooltip: 'Grade',
              icon: Icon(
                viewportStore.showGrid ? Icons.grid_on : Icons.grid_off,
              ),
              onPressed: viewportStore.toggleGrid,
            ),
          ),
          Observer(
            builder: (context) => IconButton(
              tooltip: 'Snap',
              icon: Icon(
                viewportStore.snapEnabled
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
              ),
              onPressed: viewportStore.toggleSnap,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Clique para selecionar · arraste para mover · alças para redimensionar/girar · shift+clique = múltiplo · ctrl+scroll = zoom',
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFECEFF1),
              child: LabelCanvas(
                documentStore: documentStore,
                selectionStore: selectionStore,
                historyStore: historyStore,
                viewportStore: viewportStore,
                canvasStore: canvasStore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
