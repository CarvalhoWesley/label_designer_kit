import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_widgets/label_widgets.dart';

import '../logic/element_factory.dart';

IconData _iconFor(AddableElementType type) => switch (type) {
  AddableElementType.text => LabelIcons.textElement,
  AddableElementType.barcode => LabelIcons.barcodeElement,
  AddableElementType.qrCode => LabelIcons.qrCodeElement,
  AddableElementType.image => LabelIcons.imageElement,
  AddableElementType.rectangle => LabelIcons.rectangleElement,
  AddableElementType.ellipse => LabelIcons.ellipseElement,
  AddableElementType.circle => Icons.circle_outlined,
  AddableElementType.line => LabelIcons.lineElement,
  AddableElementType.variable => Icons.data_object,
  AddableElementType.date => Icons.calendar_today_outlined,
  AddableElementType.time => Icons.access_time,
  AddableElementType.table => LabelIcons.tableElement,
};

/// The editor's top toolbar: save, undo/redo, add-element menu, grouping,
/// paint order, delete/duplicate, zoom and view toggles.
///
/// Reactive bits (undo/redo availability, selection-gated buttons, zoom
/// level, grid/snap/ruler toggle state) are read directly off the stores
/// inside small [Observer]s; every action is a plain callback supplied by
/// `LabelDesigner`, which is the only place that knows how to turn a
/// button press into store mutations (see `docs/ARCHITECTURE.md`
/// section 6's canvas/state trade-off — the same pragmatic direct-store
/// access applies here).
class DesignerToolbar extends StatelessWidget {
  const DesignerToolbar({
    super.key,
    required this.documentStore,
    required this.historyStore,
    required this.selectionStore,
    required this.viewportStore,
    required this.onAddElement,
    required this.onGroup,
    required this.onUngroup,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onDelete,
    required this.onDuplicate,
    required this.onEditProperties,
    required this.onFitToView,
    this.onSave,
  });

  final DocumentStore documentStore;
  final HistoryStore historyStore;
  final SelectionStore selectionStore;
  final ViewportStore viewportStore;
  final ValueChanged<AddableElementType> onAddElement;
  final VoidCallback onGroup;
  final VoidCallback onUngroup;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onEditProperties;
  final VoidCallback onFitToView;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (onSave != null) ...[
            LabelToolbarButton(
              icon: Icons.save_outlined,
              tooltip: 'Salvar',
              onPressed: onSave,
            ),
            const VerticalDivider(width: 12),
          ],
          LabelToolbarButton(
            icon: Icons.settings_outlined,
            tooltip: 'Propriedades da etiqueta',
            onPressed: onEditProperties,
          ),
          const VerticalDivider(width: 12),
          Observer(
            builder: (context) => Row(
              children: [
                LabelToolbarButton(
                  icon: LabelIcons.undo,
                  tooltip: 'Desfazer (Ctrl+Z)',
                  onPressed: historyStore.canUndo ? historyStore.undo : null,
                ),
                LabelToolbarButton(
                  icon: LabelIcons.redo,
                  tooltip: 'Refazer (Ctrl+Y)',
                  onPressed: historyStore.canRedo ? historyStore.redo : null,
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 12),
          PopupMenuButton<AddableElementType>(
            tooltip: 'Adicionar elemento',
            icon: const Icon(Icons.add_circle_outline),
            onSelected: onAddElement,
            itemBuilder: (context) => [
              for (final type in AddableElementType.values)
                PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_iconFor(type), size: 18),
                      const SizedBox(width: 8),
                      Text(addableElementTypeLabel(type)),
                    ],
                  ),
                ),
            ],
          ),
          const VerticalDivider(width: 12),
          Observer(
            builder: (context) {
              final hasSelection = selectionStore.hasSelection;
              final hasMultiple = selectionStore.hasMultipleSelected;
              return Row(
                children: [
                  LabelToolbarButton(
                    icon: LabelIcons.group,
                    tooltip: 'Agrupar (Ctrl+G)',
                    onPressed: hasMultiple ? onGroup : null,
                  ),
                  LabelToolbarButton(
                    icon: LabelIcons.ungroup,
                    tooltip: 'Desagrupar (Ctrl+Shift+G)',
                    onPressed: _isSingleGroupSelected() ? onUngroup : null,
                  ),
                  LabelToolbarButton(
                    icon: LabelIcons.bringToFront,
                    tooltip: 'Trazer para frente',
                    onPressed: hasSelection ? onBringToFront : null,
                  ),
                  LabelToolbarButton(
                    icon: LabelIcons.sendToBack,
                    tooltip: 'Enviar para trás',
                    onPressed: hasSelection ? onSendToBack : null,
                  ),
                  LabelToolbarButton(
                    icon: LabelIcons.duplicate,
                    tooltip: 'Duplicar (Ctrl+D)',
                    onPressed: hasSelection ? onDuplicate : null,
                  ),
                  LabelToolbarButton(
                    icon: LabelIcons.delete,
                    tooltip: 'Excluir (Delete)',
                    onPressed: hasSelection ? onDelete : null,
                  ),
                ],
              );
            },
          ),
          const VerticalDivider(width: 12),
          Observer(
            builder: (context) => Row(
              children: [
                LabelToolbarButton(
                  icon: LabelIcons.zoomOut,
                  tooltip: 'Diminuir zoom',
                  onPressed: () => viewportStore.zoomBy(0.8),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    // 100% = actual/real size (ViewportStore.
                    // pxPerMmAtActualSize), not a raw px/mm ratio — see
                    // that constant's doc comment.
                    '${(viewportStore.zoom / ViewportStoreBase.pxPerMmAtActualSize * 100).round()}%',
                    textAlign: TextAlign.center,
                  ),
                ),
                LabelToolbarButton(
                  icon: LabelIcons.zoomIn,
                  tooltip: 'Aumentar zoom',
                  onPressed: () => viewportStore.zoomBy(1.25),
                ),
                LabelToolbarButton(
                  icon: Icons.fit_screen_outlined,
                  tooltip: 'Ajustar à tela',
                  onPressed: onFitToView,
                ),
                LabelToolbarButton(
                  icon: LabelIcons.grid,
                  tooltip: 'Grade',
                  selected: viewportStore.showGrid,
                  onPressed: viewportStore.toggleGrid,
                ),
                PopupMenuButton<double>(
                  tooltip: 'Tamanho da grade',
                  icon: const Icon(Icons.grid_4x4, size: 20),
                  onSelected: viewportStore.setGridSize,
                  itemBuilder: (context) => [
                    for (final mm in const [0.5, 1.0, 2.0, 5.0, 10.0])
                      CheckedPopupMenuItem(
                        value: mm,
                        checked: viewportStore.gridSizeMm == mm,
                        child: Text(
                          '${mm == mm.roundToDouble() ? mm.round() : mm}mm',
                        ),
                      ),
                  ],
                ),
                LabelToolbarButton(
                  icon: LabelIcons.snap,
                  tooltip: 'Ajustar à grade e a outros elementos',
                  selected: viewportStore.snapEnabled,
                  onPressed: viewportStore.toggleSnap,
                ),
                LabelToolbarButton(
                  icon: LabelIcons.ruler,
                  tooltip: 'Réguas',
                  selected: viewportStore.showRulers,
                  onPressed: viewportStore.toggleRulers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSingleGroupSelected() {
    final id = selectionStore.singleSelectedId;
    if (id == null) return false;
    return documentStore.elements.any(
      (element) => element.id == id && element is GroupElement,
    );
  }
}
