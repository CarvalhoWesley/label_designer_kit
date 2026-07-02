import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_history/label_history.dart';
import 'package:label_serialization/label_serialization.dart';
import 'package:test/test.dart';

RectangleElement _rect(String id) => RectangleElement(
  id: id,
  name: id,
  position: const Point.zero(),
  size: const Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

void main() {
  test(
    'execute applies the command to DocumentStore and updates canUndo/canRedo',
    () {
      final documentStore = DocumentStore(LabelDocument.blank(name: 'Doc'));
      final historyStore = HistoryStore(documentStore);

      expect(historyStore.canUndo, isFalse);

      historyStore.execute(AddCommand(element: _rect('a')));

      expect(documentStore.elements, hasLength(1));
      expect(historyStore.canUndo, isTrue);
      expect(historyStore.canRedo, isFalse);
    },
  );

  test('undo/redo propagate to DocumentStore and flip the flags', () {
    final documentStore = DocumentStore(LabelDocument.blank(name: 'Doc'));
    final historyStore = HistoryStore(documentStore);
    historyStore.execute(AddCommand(element: _rect('a')));

    historyStore.undo();
    expect(documentStore.elements, isEmpty);
    expect(historyStore.canUndo, isFalse);
    expect(historyStore.canRedo, isTrue);

    historyStore.redo();
    expect(documentStore.elements, hasLength(1));
    expect(historyStore.canUndo, isTrue);
    expect(historyStore.canRedo, isFalse);
  });

  test('loadDocument resets history and replaces the document', () {
    final documentStore = DocumentStore(LabelDocument.blank(name: 'Doc'));
    final historyStore = HistoryStore(documentStore);
    historyStore.execute(AddCommand(element: _rect('a')));

    final other = LabelDocument.blank(name: 'Outro documento');
    historyStore.loadDocument(other);

    expect(documentStore.document, other);
    expect(historyStore.canUndo, isFalse);
    expect(historyStore.canRedo, isFalse);
  });

  test('encodeToJson/loadFromJson round-trip through label_serialization', () {
    // DocumentMetadata.toJson() always writes UTC timestamps, so the
    // fixture must already be UTC-flagged for the round-tripped document
    // to compare equal (DateTime.== requires matching zone flags, not just
    // the same instant) — see label_serialization's codec tests.
    final now = DateTime.utc(2026, 7, 2);
    final document = LabelDocument.blank(name: 'Doc').copyWith(
      elements: [_rect('a')],
      metadata: DocumentMetadata(createdAt: now, updatedAt: now),
    );
    final documentStore = DocumentStore(document);
    final historyStore = HistoryStore(documentStore);

    final json = historyStore.encodeToJson();
    expect(json, const LabelDocumentCodec().encode(document));

    historyStore.loadFromJson(json);
    expect(documentStore.document, document);
    expect(historyStore.canUndo, isFalse);
  });

  test('moveElement dispatches one undo-able MoveCommand', () {
    final documentStore = DocumentStore(
      LabelDocument.blank(name: 'Doc').copyWith(elements: [_rect('a')]),
    );
    final historyStore = HistoryStore(documentStore);

    historyStore.moveElement(
      elementId: 'a',
      from: const Point.zero(),
      to: const Point(x: 5, y: 5),
    );

    expect(documentStore.elements.single.position, const Point(x: 5, y: 5));
    historyStore.undo();
    expect(documentStore.elements.single.position, const Point.zero());
  });

  test('moveElements moves a multi-selection as a single undo step', () {
    final documentStore = DocumentStore(
      LabelDocument.blank(
        name: 'Doc',
      ).copyWith(elements: [_rect('a'), _rect('b')]),
    );
    final historyStore = HistoryStore(documentStore);

    historyStore.moveElements(
      from: {'a': const Point.zero(), 'b': const Point.zero()},
      to: {'a': const Point(x: 1, y: 1), 'b': const Point(x: 2, y: 2)},
    );

    expect(documentStore.elements[0].position, const Point(x: 1, y: 1));
    expect(documentStore.elements[1].position, const Point(x: 2, y: 2));
    expect(historyStore.canUndo, isTrue);

    historyStore.undo();
    expect(documentStore.elements[0].position, const Point.zero());
    expect(documentStore.elements[1].position, const Point.zero());
    expect(historyStore.canUndo, isFalse);
  });

  test('moveElements with a single id does not wrap in a CompositeCommand', () {
    final documentStore = DocumentStore(
      LabelDocument.blank(name: 'Doc').copyWith(elements: [_rect('a')]),
    );
    final historyStore = HistoryStore(documentStore);

    historyStore.moveElements(
      from: {'a': const Point.zero()},
      to: {'a': const Point(x: 3, y: 3)},
    );

    expect(documentStore.elements.single.position, const Point(x: 3, y: 3));
    historyStore.undo();
    expect(documentStore.elements.single.position, const Point.zero());
  });

  test('moveElements with an empty map is a no-op', () {
    final document = LabelDocument.blank(
      name: 'Doc',
    ).copyWith(elements: [_rect('a')]);
    final documentStore = DocumentStore(document);
    final historyStore = HistoryStore(documentStore);

    historyStore.moveElements(from: {}, to: {});

    expect(documentStore.document, document);
    expect(historyStore.canUndo, isFalse);
  });

  test('resizeElement dispatches one undo-able ResizeCommand', () {
    final documentStore = DocumentStore(
      LabelDocument.blank(name: 'Doc').copyWith(elements: [_rect('a')]),
    );
    final historyStore = HistoryStore(documentStore);

    historyStore.resizeElement(
      elementId: 'a',
      from: const Size2D(width: 10, height: 10),
      to: const Size2D(width: 20, height: 30),
    );

    expect(
      documentStore.elements.single.size,
      const Size2D(width: 20, height: 30),
    );
    historyStore.undo();
    expect(
      documentStore.elements.single.size,
      const Size2D(width: 10, height: 10),
    );
  });

  test(
    'resizeElementBounds dispatches size+position as a single undo step',
    () {
      final documentStore = DocumentStore(
        LabelDocument.blank(name: 'Doc').copyWith(elements: [_rect('a')]),
      );
      final historyStore = HistoryStore(documentStore);

      historyStore.resizeElementBounds(
        elementId: 'a',
        fromPosition: const Point.zero(),
        toPosition: const Point(x: -5, y: -5),
        fromSize: const Size2D(width: 10, height: 10),
        toSize: const Size2D(width: 20, height: 20),
      );

      expect(documentStore.elements.single.position, const Point(x: -5, y: -5));
      expect(
        documentStore.elements.single.size,
        const Size2D(width: 20, height: 20),
      );
      expect(historyStore.canUndo, isTrue);

      historyStore.undo();
      expect(documentStore.elements.single.position, const Point.zero());
      expect(
        documentStore.elements.single.size,
        const Size2D(width: 10, height: 10),
      );
      expect(historyStore.canUndo, isFalse); // exactly one undo step consumed
    },
  );

  test(
    'resizeElementBounds with an unchanged position dispatches size-only',
    () {
      final documentStore = DocumentStore(
        LabelDocument.blank(name: 'Doc').copyWith(elements: [_rect('a')]),
      );
      final historyStore = HistoryStore(documentStore);

      historyStore.resizeElementBounds(
        elementId: 'a',
        fromPosition: const Point.zero(),
        toPosition: const Point.zero(),
        fromSize: const Size2D(width: 10, height: 10),
        toSize: const Size2D(width: 20, height: 20),
      );

      expect(documentStore.elements.single.position, const Point.zero());
      expect(
        documentStore.elements.single.size,
        const Size2D(width: 20, height: 20),
      );
    },
  );

  test('resizeElementBounds with no change at all is a no-op', () {
    final document = LabelDocument.blank(
      name: 'Doc',
    ).copyWith(elements: [_rect('a')]);
    final documentStore = DocumentStore(document);
    final historyStore = HistoryStore(documentStore);

    historyStore.resizeElementBounds(
      elementId: 'a',
      fromPosition: const Point.zero(),
      toPosition: const Point.zero(),
      fromSize: const Size2D(width: 10, height: 10),
      toSize: const Size2D(width: 10, height: 10),
    );

    expect(documentStore.document, document);
    expect(historyStore.canUndo, isFalse);
  });

  test('rotateElement dispatches one undo-able RotateCommand', () {
    final documentStore = DocumentStore(
      LabelDocument.blank(name: 'Doc').copyWith(elements: [_rect('a')]),
    );
    final historyStore = HistoryStore(documentStore);

    historyStore.rotateElement(elementId: 'a', from: 0, to: 45);

    expect(documentStore.elements.single.rotation, 45);
    historyStore.undo();
    expect(documentStore.elements.single.rotation, 0);
  });

  test('addElement/deleteElement dispatch undo-able Add/DeleteCommand', () {
    final documentStore = DocumentStore(LabelDocument.blank(name: 'Doc'));
    final historyStore = HistoryStore(documentStore);

    historyStore.addElement(_rect('a'));
    expect(documentStore.elements, hasLength(1));

    historyStore.deleteElement('a');
    expect(documentStore.elements, isEmpty);

    historyStore.undo(); // undoes the delete
    expect(documentStore.elements, hasLength(1));

    historyStore.undo(); // undoes the add
    expect(documentStore.elements, isEmpty);
  });
}
