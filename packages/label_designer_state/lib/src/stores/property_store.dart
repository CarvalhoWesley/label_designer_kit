import 'package:label_core/label_core.dart';
import 'package:label_history/label_history.dart';
import 'package:mobx/mobx.dart';

import 'document_store.dart';
import 'history_store.dart';
import 'selection_store.dart';

part 'property_store.g.dart';

/// Derives the editable element(s) for the current selection and
/// dispatches [ChangePropertyCommand]s through [HistoryStore] to edit
/// them, so every property edit made in `label_property_panel` is
/// undo-able by construction.
class PropertyStore = PropertyStoreBase with _$PropertyStore;

abstract class PropertyStoreBase with Store {
  PropertyStoreBase(
    this._documentStore,
    this._selectionStore,
    this._historyStore,
  );

  final DocumentStore _documentStore;
  final SelectionStore _selectionStore;
  final HistoryStore _historyStore;

  /// The currently selected elements, looked up by id (including elements
  /// nested inside a [GroupElement]). Ids with no matching element (e.g. a
  /// stale selection right after an undo) are silently skipped.
  @computed
  List<LabelElement> get selectedElements => [
    for (final id in _selectionStore.selectedIds)
      if (findElementById(_documentStore.elements, id) case final element?)
        element,
  ];

  /// The selected element, when exactly one is selected; `null` otherwise.
  @computed
  LabelElement? get singleSelectedElement =>
      selectedElements.length == 1 ? selectedElements.single : null;

  /// Dispatches a [ChangePropertyCommand] for [elementId]. The caller
  /// supplies [apply] because each [LabelElement] subtype has its own
  /// `copyWith` — see `label_history`'s `ChangePropertyCommand` docs.
  void changeProperty<T>({
    required String elementId,
    required T oldValue,
    required T newValue,
    required LabelElement Function(LabelElement element, T value) apply,
  }) {
    _historyStore.execute(
      ChangePropertyCommand<T>(
        elementId: elementId,
        oldValue: oldValue,
        newValue: newValue,
        apply: apply,
      ),
    );
  }
}
