import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_widgets/label_widgets.dart';

/// Lists a document's [LabelLayer]s: visibility/lock toggles, up/down
/// reordering, and which layer newly-added elements land on (see
/// `docs/ARCHITECTURE.md` section 14 — `LayerStore` already existed since
/// etapa 8, but had no UI anywhere in the workspace until this panel).
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

  @override
  Widget build(BuildContext context) {
    return Observer(
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
                icon: layer.visible ? LabelIcons.visible : LabelIcons.hidden,
                tooltip: layer.visible ? 'Ocultar camada' : 'Mostrar camada',
                onPressed: () =>
                    layerStore.setVisible(layer.id, visible: !layer.visible),
              ),
              title: Text(layer.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LabelToolbarButton(
                    icon: layer.locked ? LabelIcons.lock : LabelIcons.unlock,
                    tooltip: layer.locked
                        ? 'Desbloquear camada'
                        : 'Bloquear camada',
                    onPressed: () =>
                        layerStore.setLocked(layer.id, locked: !layer.locked),
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}
