// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layer_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LayerStore on LayerStoreBase, Store {
  Computed<List<LabelLayer>>? _$layersComputed;

  @override
  List<LabelLayer> get layers =>
      (_$layersComputed ??= Computed<List<LabelLayer>>(
        () => super.layers,
        name: 'LayerStoreBase.layers',
      )).value;

  late final _$LayerStoreBaseActionController = ActionController(
    name: 'LayerStoreBase',
    context: context,
  );

  @override
  void setVisible(String layerId, {required bool visible}) {
    final _$actionInfo = _$LayerStoreBaseActionController.startAction(
      name: 'LayerStoreBase.setVisible',
    );
    try {
      return super.setVisible(layerId, visible: visible);
    } finally {
      _$LayerStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLocked(String layerId, {required bool locked}) {
    final _$actionInfo = _$LayerStoreBaseActionController.startAction(
      name: 'LayerStoreBase.setLocked',
    );
    try {
      return super.setLocked(layerId, locked: locked);
    } finally {
      _$LayerStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reorder(String layerId, int newOrder) {
    final _$actionInfo = _$LayerStoreBaseActionController.startAction(
      name: 'LayerStoreBase.reorder',
    );
    try {
      return super.reorder(layerId, newOrder);
    } finally {
      _$LayerStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addLayer({required String id, String? name}) {
    final _$actionInfo = _$LayerStoreBaseActionController.startAction(
      name: 'LayerStoreBase.addLayer',
    );
    try {
      return super.addLayer(id: id, name: name);
    } finally {
      _$LayerStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeLayer(String layerId) {
    final _$actionInfo = _$LayerStoreBaseActionController.startAction(
      name: 'LayerStoreBase.removeLayer',
    );
    try {
      return super.removeLayer(layerId);
    } finally {
      _$LayerStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
layers: ${layers}
    ''';
  }
}
