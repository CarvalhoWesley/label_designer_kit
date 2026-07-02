// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$HistoryStore on HistoryStoreBase, Store {
  late final _$canUndoAtom = Atom(
    name: 'HistoryStoreBase.canUndo',
    context: context,
  );

  @override
  bool get canUndo {
    _$canUndoAtom.reportRead();
    return super.canUndo;
  }

  @override
  set canUndo(bool value) {
    _$canUndoAtom.reportWrite(value, super.canUndo, () {
      super.canUndo = value;
    });
  }

  late final _$canRedoAtom = Atom(
    name: 'HistoryStoreBase.canRedo',
    context: context,
  );

  @override
  bool get canRedo {
    _$canRedoAtom.reportRead();
    return super.canRedo;
  }

  @override
  set canRedo(bool value) {
    _$canRedoAtom.reportWrite(value, super.canRedo, () {
      super.canRedo = value;
    });
  }

  late final _$HistoryStoreBaseActionController = ActionController(
    name: 'HistoryStoreBase',
    context: context,
  );

  @override
  void execute(Command command) {
    final _$actionInfo = _$HistoryStoreBaseActionController.startAction(
      name: 'HistoryStoreBase.execute',
    );
    try {
      return super.execute(command);
    } finally {
      _$HistoryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void undo() {
    final _$actionInfo = _$HistoryStoreBaseActionController.startAction(
      name: 'HistoryStoreBase.undo',
    );
    try {
      return super.undo();
    } finally {
      _$HistoryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void redo() {
    final _$actionInfo = _$HistoryStoreBaseActionController.startAction(
      name: 'HistoryStoreBase.redo',
    );
    try {
      return super.redo();
    } finally {
      _$HistoryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadDocument(LabelDocument newDocument) {
    final _$actionInfo = _$HistoryStoreBaseActionController.startAction(
      name: 'HistoryStoreBase.loadDocument',
    );
    try {
      return super.loadDocument(newDocument);
    } finally {
      _$HistoryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
canUndo: ${canUndo},
canRedo: ${canRedo}
    ''';
  }
}
