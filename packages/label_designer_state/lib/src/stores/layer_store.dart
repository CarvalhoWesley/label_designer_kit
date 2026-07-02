import 'package:label_core/label_core.dart';
import 'package:label_history/label_history.dart';
import 'package:mobx/mobx.dart';

import 'document_store.dart';
import 'history_store.dart';

part 'layer_store.g.dart';

/// Order, visibility and lock state of a [LabelDocument]'s layers.
///
/// Edits go through [HistoryStore] via [ChangeDocumentCommand], the same
/// way [PropertyStore] edits elements — layers are undo-able too, since
/// they're as much a part of the document as the elements on them.
class LayerStore = LayerStoreBase with _$LayerStore;

abstract class LayerStoreBase with Store {
  LayerStoreBase(this._documentStore, this._historyStore);

  final DocumentStore _documentStore;
  final HistoryStore _historyStore;

  /// Layers in paint order (back to front).
  @computed
  List<LabelLayer> get layers =>
      [...(_documentStore.layers)]..sort((a, b) => a.order.compareTo(b.order));

  /// The elements placed on [layerId], in their current z-order.
  List<LabelElement> elementsOf(String layerId) => _documentStore.elements
      .where((element) => element.layerId == layerId)
      .toList();

  @action
  void setVisible(String layerId, {required bool visible}) =>
      _updateLayer(layerId, (layer) => layer.copyWith(visible: visible));

  @action
  void setLocked(String layerId, {required bool locked}) =>
      _updateLayer(layerId, (layer) => layer.copyWith(locked: locked));

  @action
  void reorder(String layerId, int newOrder) =>
      _updateLayer(layerId, (layer) => layer.copyWith(order: newOrder));

  void _updateLayer(
    String layerId,
    LabelLayer Function(LabelLayer layer) update,
  ) {
    final oldLayers = _documentStore.document.layers;
    final newLayers = [
      for (final layer in oldLayers)
        layer.id == layerId ? update(layer) : layer,
    ];
    _historyStore.execute(
      ChangeDocumentCommand<List<LabelLayer>>(
        oldValue: oldLayers,
        newValue: newLayers,
        apply: (document, value) => document.copyWith(layers: value),
      ),
    );
  }
}
