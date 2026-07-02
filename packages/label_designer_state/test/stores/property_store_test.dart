import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:test/test.dart';

const _text = TextElement(
  id: 't-1',
  name: 'Texto',
  position: Point.zero(),
  size: Size2D(width: 30, height: 10),
  layerId: 'layer-1',
  content: 'Antes',
);

const _rect = RectangleElement(
  id: 'r-1',
  name: 'Rect',
  position: Point.zero(),
  size: Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

({
  DocumentStore document,
  SelectionStore selection,
  HistoryStore history,
  PropertyStore property,
})
_setup() {
  final document = DocumentStore(
    LabelDocument.blank(name: 'Doc').copyWith(elements: [_text, _rect]),
  );
  final history = HistoryStore(document);
  final selection = SelectionStore();
  final property = PropertyStore(document, selection, history);
  return (
    document: document,
    selection: selection,
    history: history,
    property: property,
  );
}

void main() {
  test('selectedElements is empty with no selection', () {
    final s = _setup();
    expect(s.property.selectedElements, isEmpty);
    expect(s.property.singleSelectedElement, isNull);
  });

  test('selectedElements resolves selected ids against the document', () {
    final s = _setup();
    s.selection.select('t-1');
    expect(s.property.selectedElements, [_text]);
    expect(s.property.singleSelectedElement, _text);
  });

  test('selectedElements silently skips ids missing from the document', () {
    final s = _setup();
    s.selection.select('does-not-exist');
    expect(s.property.selectedElements, isEmpty);
  });

  test(
    'selectedElements reflects multi-selection, singleSelectedElement is null',
    () {
      final s = _setup();
      s.selection.selectAll(['t-1', 'r-1']);
      expect(s.property.selectedElements, containsAll([_text, _rect]));
      expect(s.property.singleSelectedElement, isNull);
    },
  );

  test(
    'changeProperty dispatches a ChangePropertyCommand through HistoryStore',
    () {
      final s = _setup();
      s.property.changeProperty<String>(
        elementId: 't-1',
        oldValue: 'Antes',
        newValue: 'Depois',
        apply: (element, value) =>
            (element as TextElement).copyWith(content: value),
      );

      final updated =
          s.document.elements.firstWhere((e) => e.id == 't-1') as TextElement;
      expect(updated.content, 'Depois');
      expect(s.history.canUndo, isTrue);

      s.history.undo();
      final reverted =
          s.document.elements.firstWhere((e) => e.id == 't-1') as TextElement;
      expect(reverted.content, 'Antes');
    },
  );

  test(
    'changeProperties applies an edit across ids as a single undo step',
    () {
      final s = _setup();
      s.property.changeProperties<double>(
        oldValues: {'t-1': 1, 'r-1': 1},
        newValues: {'t-1': 0.5, 'r-1': 0.5},
        apply: (element, value) => switch (element) {
          TextElement e => e.copyWith(opacity: value),
          RectangleElement e => e.copyWith(opacity: value),
          _ => throw StateError('unexpected element type'),
        },
      );

      expect(
        s.document.elements.map((e) => e.opacity),
        everyElement(0.5),
      );
      expect(s.history.canUndo, isTrue);

      s.history.undo();
      expect(s.document.elements.map((e) => e.opacity), everyElement(1));
    },
  );

  test('changeProperties skips ids whose value did not change', () {
    final s = _setup();
    s.property.changeProperties<double>(
      oldValues: {'t-1': 1, 'r-1': 1},
      newValues: {'t-1': 1, 'r-1': 0.5},
      apply: (element, value) => switch (element) {
        TextElement e => e.copyWith(opacity: value),
        RectangleElement e => e.copyWith(opacity: value),
        _ => throw StateError('unexpected element type'),
      },
    );

    // A single changed id dispatches a plain ChangePropertyCommand (not
    // wrapped in a CompositeCommand), so one undo fully reverts it.
    s.history.undo();
    expect(
      s.document.elements.map((e) => e.opacity),
      everyElement(1),
    );
  });

  test('changeProperties with no actual changes is a no-op', () {
    final s = _setup();
    s.property.changeProperties<double>(
      oldValues: {'t-1': 1, 'r-1': 1},
      newValues: {'t-1': 1, 'r-1': 1},
      apply: (element, value) => switch (element) {
        TextElement e => e.copyWith(opacity: value),
        RectangleElement e => e.copyWith(opacity: value),
        _ => throw StateError('unexpected element type'),
      },
    );

    expect(s.history.canUndo, isFalse);
  });
}
