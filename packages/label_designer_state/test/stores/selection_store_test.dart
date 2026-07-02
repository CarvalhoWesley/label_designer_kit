import 'package:label_designer_state/label_designer_state.dart';
import 'package:test/test.dart';

void main() {
  test('select replaces the selection by default', () {
    final store = SelectionStore();
    store.select('a');
    store.select('b');
    expect(store.selectedIds, {'b'});
  });

  test('select with addToSelection keeps the previous ids', () {
    final store = SelectionStore();
    store.select('a');
    store.select('b', addToSelection: true);
    expect(store.selectedIds, {'a', 'b'});
    expect(store.hasMultipleSelected, isTrue);
  });

  test('toggle adds an unselected id and removes a selected one', () {
    final store = SelectionStore();
    store.toggle('a');
    expect(store.selectedIds, {'a'});
    store.toggle('a');
    expect(store.selectedIds, isEmpty);
  });

  test('singleSelectedId is null for none or multiple selections', () {
    final store = SelectionStore();
    expect(store.singleSelectedId, isNull);
    store.select('a');
    expect(store.singleSelectedId, 'a');
    store.select('b', addToSelection: true);
    expect(store.singleSelectedId, isNull);
  });

  test('deselect and clear', () {
    final store = SelectionStore();
    store.selectAll(['a', 'b', 'c']);
    store.deselect('b');
    expect(store.selectedIds, {'a', 'c'});
    store.clear();
    expect(store.hasSelection, isFalse);
  });
}
