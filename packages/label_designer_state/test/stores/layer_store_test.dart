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
}
