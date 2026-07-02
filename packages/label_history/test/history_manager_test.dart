import 'package:label_core/label_core.dart';
import 'package:label_history/label_history.dart';
import 'package:test/test.dart';

LabelDocument _blankDocument() => LabelDocument.blank(name: 'Doc');

RectangleElement _rect(String id) => RectangleElement(
  id: id,
  name: id,
  position: const Point.zero(),
  size: const Size2D(width: 10, height: 10),
  layerId: 'layer-1',
);

void main() {
  test('execute applies the command and updates document', () {
    final manager = HistoryManager(_blankDocument());
    final result = manager.execute(AddCommand(element: _rect('a')));
    expect(result.elements, hasLength(1));
    expect(manager.document.elements, hasLength(1));
    expect(manager.canUndo, isTrue);
    expect(manager.canRedo, isFalse);
  });

  test('undo reverts the last command', () {
    final manager = HistoryManager(_blankDocument());
    manager.execute(AddCommand(element: _rect('a')));
    final result = manager.undo();
    expect(result.elements, isEmpty);
    expect(manager.canUndo, isFalse);
    expect(manager.canRedo, isTrue);
  });

  test('redo re-applies an undone command', () {
    final manager = HistoryManager(_blankDocument());
    manager.execute(AddCommand(element: _rect('a')));
    manager.undo();
    final result = manager.redo();
    expect(result.elements, hasLength(1));
    expect(manager.canUndo, isTrue);
    expect(manager.canRedo, isFalse);
  });

  test('executing a new command after undo clears the redo stack', () {
    final manager = HistoryManager(_blankDocument());
    manager.execute(AddCommand(element: _rect('a')));
    manager.undo();
    manager.execute(AddCommand(element: _rect('b')));
    expect(manager.canRedo, isFalse);
    expect(manager.document.elements.single.id, 'b');
  });

  test('undo/redo on an empty stack is a no-op', () {
    final document = _blankDocument();
    final manager = HistoryManager(document);
    expect(manager.undo(), equals(document));
    expect(manager.redo(), equals(document));
  });

  test('clear drops history without changing the current document', () {
    final manager = HistoryManager(_blankDocument());
    manager.execute(AddCommand(element: _rect('a')));
    manager.clear();
    expect(manager.canUndo, isFalse);
    expect(manager.canRedo, isFalse);
    expect(manager.document.elements, hasLength(1));
  });

  test('multiple undo/redo round-trips restore the same document sequence', () {
    final manager = HistoryManager(_blankDocument());
    manager.execute(AddCommand(element: _rect('a')));
    manager.execute(AddCommand(element: _rect('b')));
    manager.execute(AddCommand(element: _rect('c')));

    manager.undo();
    manager.undo();
    expect(manager.document.elements.map((e) => e.id), ['a']);

    manager.redo();
    expect(manager.document.elements.map((e) => e.id), ['a', 'b']);
  });
}
