import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:test/test.dart';

const _layerA = LabelLayer(id: 'layer-a', name: 'A', order: 0);
const _layerB = LabelLayer(id: 'layer-b', name: 'B', order: 1);

RectangleElement _rectOnLayer(String id, String layerId) => RectangleElement(
  id: id,
  name: id,
  position: const Point.zero(),
  size: const Size2D(width: 10, height: 10),
  layerId: layerId,
);

({DocumentStore document, HistoryStore history, LayerStore layer}) _setup() {
  final document = DocumentStore(
    LabelDocument.blank(name: 'Doc').copyWith(
      layers: const [_layerA, _layerB],
      elements: [
        _rectOnLayer('r-1', 'layer-a'),
        _rectOnLayer('r-2', 'layer-b'),
      ],
    ),
  );
  final history = HistoryStore(document);
  final layer = LayerStore(document, history);
  return (document: document, history: history, layer: layer);
}

void main() {
  test('layers are exposed sorted by order', () {
    final s = _setup();
    expect(s.layer.layers.map((l) => l.id), ['layer-a', 'layer-b']);
  });

  test('elementsOf groups elements by layerId', () {
    final s = _setup();
    expect(s.layer.elementsOf('layer-a').map((e) => e.id), ['r-1']);
    expect(s.layer.elementsOf('layer-b').map((e) => e.id), ['r-2']);
  });

  test('setVisible is undo-able and only affects the targeted layer', () {
    final s = _setup();
    s.layer.setVisible('layer-a', visible: false);

    expect(
      s.layer.layers.firstWhere((l) => l.id == 'layer-a').visible,
      isFalse,
    );
    expect(s.layer.layers.firstWhere((l) => l.id == 'layer-b').visible, isTrue);
    expect(s.history.canUndo, isTrue);

    s.history.undo();
    expect(s.layer.layers.firstWhere((l) => l.id == 'layer-a').visible, isTrue);
  });

  test('setLocked and reorder update only the targeted layer', () {
    final s = _setup();
    s.layer.setLocked('layer-b', locked: true);
    expect(s.layer.layers.firstWhere((l) => l.id == 'layer-b').locked, isTrue);

    s.layer.reorder('layer-a', 5);
    expect(s.layer.layers.firstWhere((l) => l.id == 'layer-a').order, 5);
  });

  test('addLayer appends a new layer above every existing order, and is '
      'undo-able', () {
    final s = _setup();
    s.layer.addLayer(id: 'layer-c', name: 'C');

    expect(s.layer.layers.map((l) => l.id), ['layer-a', 'layer-b', 'layer-c']);
    expect(s.layer.layers.last.order, greaterThan(_layerB.order));
    expect(s.history.canUndo, isTrue);

    s.history.undo();
    expect(s.layer.layers.map((l) => l.id), ['layer-a', 'layer-b']);
  });

  test('addLayer falls back to a default name when none is given', () {
    final s = _setup();
    s.layer.addLayer(id: 'layer-c');
    expect(s.layer.layers.last.name, isNotEmpty);
  });

  test('canRemoveLayer is false only when a single layer remains', () {
    final s = _setup();
    expect(s.layer.canRemoveLayer('layer-a'), isTrue);

    s.layer.removeLayer('layer-b');
    expect(s.layer.canRemoveLayer('layer-a'), isFalse);
  });

  test('removeLayer deletes the layer and every element placed on it, as '
      'one undo step', () {
    final s = _setup();
    s.layer.removeLayer('layer-a');

    expect(s.layer.layers.map((l) => l.id), ['layer-b']);
    expect(s.document.elements.map((e) => e.id), ['r-2']);
    expect(s.history.canUndo, isTrue);

    s.history.undo();
    expect(s.layer.layers.map((l) => l.id), ['layer-a', 'layer-b']);
    expect(s.document.elements.map((e) => e.id), ['r-1', 'r-2']);
  });

  test('removeLayer is a no-op when it is the only layer left', () {
    final s = _setup();
    s.layer.removeLayer('layer-b');
    s.layer.removeLayer('layer-a'); // no-op: layer-a is now the only one
    expect(s.layer.layers.map((l) => l.id), ['layer-a']);

    // Exactly one undo step needed to get back to the original two
    // layers proves the no-op call above never pushed a second command.
    s.history.undo();
    expect(s.layer.layers.map((l) => l.id), ['layer-a', 'layer-b']);
  });
}
