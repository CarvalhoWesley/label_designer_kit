import 'package:mobx/mobx.dart';

part 'selection_store.g.dart';

/// Tracks which element ids are currently selected on the canvas.
///
/// Holds ids rather than [LabelElement] instances so it never goes stale
/// when [DocumentStore.document] is replaced — consumers look elements up
/// by id (e.g. via `PropertyStore.selectedElements`) each time they react.
class SelectionStore = SelectionStoreBase with _$SelectionStore;

abstract class SelectionStoreBase with Store {
  @observable
  ObservableSet<String> selectedIds = ObservableSet<String>();

  @computed
  bool get hasSelection => selectedIds.isNotEmpty;

  @computed
  bool get hasMultipleSelected => selectedIds.length > 1;

  /// The selected id, when exactly one element is selected; `null`
  /// otherwise (none or multiple selected).
  @computed
  String? get singleSelectedId =>
      selectedIds.length == 1 ? selectedIds.single : null;

  /// Selects [id]. Replaces the current selection unless [addToSelection]
  /// is `true`, in which case [id] is added to it (shift/ctrl-click).
  @action
  void select(String id, {bool addToSelection = false}) {
    if (!addToSelection) {
      selectedIds.clear();
    }
    selectedIds.add(id);
  }

  /// Replaces the current selection with exactly [ids].
  @action
  void selectAll(Iterable<String> ids) {
    selectedIds
      ..clear()
      ..addAll(ids);
  }

  /// Adds/removes [id] from the current selection, keeping the rest.
  @action
  void toggle(String id) {
    if (!selectedIds.remove(id)) {
      selectedIds.add(id);
    }
  }

  @action
  void deselect(String id) => selectedIds.remove(id);

  @action
  void clear() => selectedIds.clear();
}
