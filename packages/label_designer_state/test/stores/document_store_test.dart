import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:test/test.dart';

RectangleElement _rect(String id) => RectangleElement(
  id: id,
  name: id,
  position: const Point.zero(),
  size: const Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

void main() {
  test('exposes the initial document and its derived collections', () {
    final document = LabelDocument.blank(
      name: 'Doc',
    ).copyWith(elements: [_rect('a')]);
    final store = DocumentStore(document);

    expect(store.document, document);
    expect(store.elements, [_rect('a')]);
    expect(store.layers, document.layers);
  });

  test('replaceDocument swaps the observable document', () {
    final store = DocumentStore(LabelDocument.blank(name: 'Doc'));
    final next = store.document.copyWith(elements: [_rect('a')]);

    store.replaceDocument(next);

    expect(store.document, next);
    expect(store.elements, [_rect('a')]);
  });
}
