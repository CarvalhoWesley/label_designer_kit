// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SelectionStore on SelectionStoreBase, Store {
  Computed<bool>? _$hasSelectionComputed;

  @override
  bool get hasSelection => (_$hasSelectionComputed ??= Computed<bool>(
    () => super.hasSelection,
    name: 'SelectionStoreBase.hasSelection',
  )).value;
  Computed<bool>? _$hasMultipleSelectedComputed;

  @override
  bool get hasMultipleSelected =>
      (_$hasMultipleSelectedComputed ??= Computed<bool>(
        () => super.hasMultipleSelected,
        name: 'SelectionStoreBase.hasMultipleSelected',
      )).value;
  Computed<String?>? _$singleSelectedIdComputed;

  @override
  String? get singleSelectedId =>
      (_$singleSelectedIdComputed ??= Computed<String?>(
        () => super.singleSelectedId,
        name: 'SelectionStoreBase.singleSelectedId',
      )).value;

  late final _$selectedIdsAtom = Atom(
    name: 'SelectionStoreBase.selectedIds',
    context: context,
  );

  @override
  ObservableSet<String> get selectedIds {
    _$selectedIdsAtom.reportRead();
    return super.selectedIds;
  }

  @override
  set selectedIds(ObservableSet<String> value) {
    _$selectedIdsAtom.reportWrite(value, super.selectedIds, () {
      super.selectedIds = value;
    });
  }

  late final _$SelectionStoreBaseActionController = ActionController(
    name: 'SelectionStoreBase',
    context: context,
  );

  @override
  void select(String id, {bool addToSelection = false}) {
    final _$actionInfo = _$SelectionStoreBaseActionController.startAction(
      name: 'SelectionStoreBase.select',
    );
    try {
      return super.select(id, addToSelection: addToSelection);
    } finally {
      _$SelectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectAll(Iterable<String> ids) {
    final _$actionInfo = _$SelectionStoreBaseActionController.startAction(
      name: 'SelectionStoreBase.selectAll',
    );
    try {
      return super.selectAll(ids);
    } finally {
      _$SelectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggle(String id) {
    final _$actionInfo = _$SelectionStoreBaseActionController.startAction(
      name: 'SelectionStoreBase.toggle',
    );
    try {
      return super.toggle(id);
    } finally {
      _$SelectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deselect(String id) {
    final _$actionInfo = _$SelectionStoreBaseActionController.startAction(
      name: 'SelectionStoreBase.deselect',
    );
    try {
      return super.deselect(id);
    } finally {
      _$SelectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clear() {
    final _$actionInfo = _$SelectionStoreBaseActionController.startAction(
      name: 'SelectionStoreBase.clear',
    );
    try {
      return super.clear();
    } finally {
      _$SelectionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selectedIds: ${selectedIds},
hasSelection: ${hasSelection},
hasMultipleSelected: ${hasMultipleSelected},
singleSelectedId: ${singleSelectedId}
    ''';
  }
}
