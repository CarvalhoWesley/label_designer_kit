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

  /// Applies the same kind of property edit across every id in
  /// [oldValues]/[newValues] as a single undo step — used by
  /// `label_property_panel` when editing a shared property (e.g. opacity,
  /// visible) across a multi-element selection, mirroring
  /// `HistoryStore.moveElements`.
  ///
  /// [oldValues] and [newValues] must have the same keys (element ids).
  /// Ids whose value did not change are skipped.
  void changeProperties<T>({
    required Map<String, T> oldValues,
    required Map<String, T> newValues,
    required LabelElement Function(LabelElement element, T value) apply,
  }) {
    assert(
      oldValues.keys.toSet().containsAll(newValues.keys),
      'oldValues/newValues must cover the same element ids',
    );
    final commands = [
      for (final id in newValues.keys)
        if (oldValues[id] != newValues[id])
          ChangePropertyCommand<T>(
            elementId: id,
            oldValue: oldValues[id] as T,
            newValue: newValues[id] as T,
            apply: apply,
          ),
    ];
    if (commands.isEmpty) return;
    _historyStore.execute(
      commands.length == 1 ? commands.single : CompositeCommand(commands),
    );
  }
}
