import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_widgets/label_widgets.dart';

import '../logic/id_generator.dart';

/// Lists a document's [LabelLayer]s: visibility/lock toggles, up/down
/// reordering, create/delete, and which layer newly-added elements land
/// on (see `docs/ARCHITECTURE.md` section 14 — `LayerStore` already
/// existed since etapa 8, but had no UI anywhere in the workspace until
/// this panel).
///
/// [activeLayerId]/[onActiveLayerChanged] are owned by `LabelDesigner`
/// itself, not `LayerStore` — "which layer new elements go on" is
/// `label_designer`'s own composition-level concern, not part of the
/// document or reusable state layer.
class LayersPanel extends StatelessWidget {
  const LayersPanel({
    super.key,
    required this.layerStore,
    required this.activeLayerId,
    required this.onActiveLayerChanged,
  });

  final LayerStore layerStore;
  final String? activeLayerId;
  final ValueChanged<String> onActiveLayerChanged;

  void _swap(List<LabelLayer> layers, int i, int j) {
    final orderI = layers[i].order;
    final orderJ = layers[j].order;
    layerStore.reorder(layers[i].id, orderJ);
    layerStore.reorder(layers[j].id, orderI);
  }

  void _addLayer() {
    final id = generateLayerId();
    layerStore.addLayer(id: id);
    onActiveLayerChanged(id);
  }

  Future<void> _removeLayer(BuildContext context, LabelLayer layer) async {
    final elementCount = layerStore.elementsOf(layer.id).length;
    if (elementCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir camada'),
          content: Text(
            'A camada "${layer.name}" tem $elementCount '
            '${elementCount == 1 ? 'elemento' : 'elementos'}. Excluir a '
            'camada também exclui esses elementos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    layerStore.removeLayer(layer.id);
    // The removed layer may have been the active one new elements land
    // on — `LabelDesigner` doesn't itself know layers can disappear, so
    // this panel is responsible for steering it back to a layer that
    // still exists.
    if (layer.id == activeLayerId) {
      final remaining = layerStore.layers;
      if (remaining.isNotEmpty) onActiveLayerChanged(remaining.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Camadas',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              LabelToolbarButton(
                icon: Icons.add,
                tooltip: 'Nova camada',
                onPressed: _addLayer,
              ),
            ],
          ),
        ),
        Expanded(
          child: Observer(
            builder: (context) {
              final layers = layerStore.layers;
              return ListView.builder(
                itemCount: layers.length,
                itemBuilder: (context, index) {
                  final layer = layers[index];
                  final isActive = layer.id == activeLayerId;
                  return ListTile(
                    dense: true,
                    selected: isActive,
                    onTap: () => onActiveLayerChanged(layer.id),
                    leading: LabelToolbarButton(
                      icon: layer.visible
                          ? LabelIcons.visible
                          : LabelIcons.hidden,
                      tooltip: layer.visible
                          ? 'Ocultar camada'
                          : 'Mostrar camada',
                      onPressed: () => layerStore.setVisible(
                        layer.id,
                        visible: !layer.visible,
                      ),
                    ),
                    title: Text(
                      layer.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LabelToolbarButton(
                          icon: layer.locked
                              ? LabelIcons.lock
                              : LabelIcons.unlock,
                          tooltip: layer.locked
                              ? 'Desbloquear camada'
                              : 'Bloquear camada',
                          onPressed: () => layerStore.setLocked(
                            layer.id,
                            locked: !layer.locked,
                          ),
                        ),
                        LabelToolbarButton(
                          icon: Icons.arrow_upward,
                          tooltip: 'Mover para cima',
                          onPressed: index > 0
                              ? () => _swap(layers, index, index - 1)
                              : null,
                        ),
                        LabelToolbarButton(
                          icon: Icons.arrow_downward,
                          tooltip: 'Mover para baixo',
                          onPressed: index < layers.length - 1
                              ? () => _swap(layers, index, index + 1)
                              : null,
                        ),
                        LabelToolbarButton(
                          icon: LabelIcons.delete,
                          tooltip: layerStore.canRemoveLayer(layer.id)
                              ? 'Excluir camada'
                              : 'Não é possível excluir a única camada',
                          onPressed: layerStore.canRemoveLayer(layer.id)
                              ? () => _removeLayer(context, layer)
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
