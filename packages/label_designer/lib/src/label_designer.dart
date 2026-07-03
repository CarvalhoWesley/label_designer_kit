import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:label_canvas/label_canvas.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_designer_state/label_designer_state.dart';

import 'logic/clone_element.dart';
import 'logic/element_factory.dart';
import 'logic/grouping.dart';
import 'logic/id_generator.dart';
import 'logic/z_order.dart';
import 'widgets/designer_toolbar.dart';
import 'widgets/label_properties_dialog.dart';
import 'widgets/layers_panel.dart';
import 'widgets/right_panel.dart';

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

class _DuplicateIntent extends Intent {
  const _DuplicateIntent();
}

class _GroupIntent extends Intent {
  const _GroupIntent();
}

class _UngroupIntent extends Intent {
  const _UngroupIntent();
}

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

/// Composition of the full visual editor: toolbar, layers panel, canvas,
/// and a right-hand properties/preview panel, wired to
/// `label_designer_state` and driven by keyboard shortcuts (see
/// `docs/ARCHITECTURE.md` sections 7 and 20).
///
/// Owns every `label_designer_state` store for the lifetime of the
/// widget, built from [document] once in [State.initState]. Doesn't know
/// how to save to disk or print — [onSave] just hands the current
/// [LabelDocument] to whoever embeds this widget; never imports any
/// `label_renderer_*` for a physical printer.
class LabelDesigner extends StatefulWidget {
  const LabelDesigner({super.key, required this.document, this.onSave});

  final LabelDocument document;
  final void Function(LabelDocument document)? onSave;

  @override
  State<LabelDesigner> createState() => _LabelDesignerState();
}

class _LabelDesignerState extends State<LabelDesigner> {
  late final DocumentStore documentStore;
  late final HistoryStore historyStore;
  late final SelectionStore selectionStore;
  late final ViewportStore viewportStore;
  late final CanvasStore canvasStore;
  late final PropertyStore propertyStore;
  late final LayerStore layerStore;

  String? _activeLayerId;
  RightPanelTab _rightTab = RightPanelTab.properties;

  @override
  void initState() {
    super.initState();
    documentStore = DocumentStore(widget.document);
    historyStore = HistoryStore(documentStore);
    selectionStore = SelectionStore();
    viewportStore = ViewportStore();
    canvasStore = CanvasStore();
    propertyStore = PropertyStore(documentStore, selectionStore, historyStore);
    layerStore = LayerStore(documentStore, historyStore);
    _activeLayerId = widget.document.layers.isEmpty
        ? null
        : widget.document.layers.first.id;
  }

  @override
  void didUpdateWidget(covariant LabelDesigner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lets a consumer swap in a different LabelDocument (e.g. "open a
    // different file") just by passing a new `document`, without needing
    // a Key to force a full remount — loadDocument resets undo history,
    // since the new document isn't a further edit of the old one.
    if (oldWidget.document != widget.document) {
      historyStore.loadDocument(widget.document);
      selectionStore.clear();
      canvasStore.requestFitToView();
      setState(() {
        _activeLayerId = widget.document.layers.isEmpty
            ? null
            : widget.document.layers.first.id;
      });
    }
  }

  String? _resolveLayerId() =>
      _activeLayerId ??
      (documentStore.layers.isEmpty ? null : documentStore.layers.first.id);

  void _addElement(AddableElementType type) {
    final layerId = _resolveLayerId();
    if (layerId == null) return;
    final onLayer = layerStore.elementsOf(layerId).length;
    // Cascades successive additions of the same type so they don't stack
    // exactly on top of each other; wraps around so it stays on-page.
    final cascade = (onLayer % 6) * 4.0;
    final element = createDefaultElement(
      type: type,
      id: generateElementId(),
      layerId: layerId,
      position: Point(x: 10 + cascade, y: 10 + cascade),
    );
    historyStore.addElement(element);
    selectionStore.select(element.id);
  }

  void _deleteSelection() {
    if (!selectionStore.hasSelection) return;
    final ids = selectionStore.selectedIds;
    final remaining = documentStore.elements
        .where((element) => !ids.contains(element.id))
        .toList();
    historyStore.replaceElements(remaining);
    selectionStore.clear();
  }

  void _duplicateSelection() {
    if (!selectionStore.hasSelection) return;
    final ids = selectionStore.selectedIds;
    final selected = documentStore.elements
        .where((element) => ids.contains(element.id))
        .toList();
    final clones = [
      for (final element in selected) cloneElement(element, generateElementId),
    ];
    historyStore.replaceElements([...documentStore.elements, ...clones]);
    selectionStore.selectAll(clones.map((e) => e.id));
  }

  void _groupSelection() {
    if (!selectionStore.hasMultipleSelected) return;
    final result = groupElements(
      allElements: documentStore.elements,
      selectedIds: Set.of(selectionStore.selectedIds),
      groupId: generateElementId(),
    );
    historyStore.replaceElements([...result.remainingSiblings, result.group]);
    selectionStore.select(result.group.id);
  }

  void _ungroupSelection() {
    final id = selectionStore.singleSelectedId;
    if (id == null) return;
    final elements = documentStore.elements;
    LabelElement? target;
    for (final element in elements) {
      if (element.id == id) {
        target = element;
        break;
      }
    }
    if (target is! GroupElement) return;

    final children = ungroupElement(target);
    final remaining = elements.where((e) => e.id != id).toList();
    historyStore.replaceElements([...remaining, ...children]);
    selectionStore.selectAll(children.map((e) => e.id));
  }

  void _bringToFront() {
    if (!selectionStore.hasSelection) return;
    historyStore.replaceElements(
      bringToFront(documentStore.elements, Set.of(selectionStore.selectedIds)),
    );
  }

  void _sendToBack() {
    if (!selectionStore.hasSelection) return;
    historyStore.replaceElements(
      sendToBack(documentStore.elements, Set.of(selectionStore.selectedIds)),
    );
  }

  void _selectAll() =>
      selectionStore.selectAll(documentStore.elements.map((e) => e.id));

  void _save() => widget.onSave?.call(documentStore.document);

  void _editProperties() {
    final document = documentStore.document;
    LabelPropertiesDialog.show(
      context,
      name: document.name,
      page: document.page,
      onSave: (name, page) =>
          historyStore.updateDocumentMeta(name: name, page: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const _UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            const _RedoIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const _RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): const _DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.backspace): const _DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD):
            const _DuplicateIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG):
            const _GroupIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyG,
        ): const _UngroupIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const _SelectAllIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape):
            const _ClearSelectionIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) => historyStore.canUndo ? historyStore.undo() : null,
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) => historyStore.canRedo ? historyStore.redo() : null,
          ),
          _DeleteIntent: CallbackAction<_DeleteIntent>(
            onInvoke: (_) => _deleteSelection(),
          ),
          _DuplicateIntent: CallbackAction<_DuplicateIntent>(
            onInvoke: (_) => _duplicateSelection(),
          ),
          _GroupIntent: CallbackAction<_GroupIntent>(
            onInvoke: (_) => _groupSelection(),
          ),
          _UngroupIntent: CallbackAction<_UngroupIntent>(
            onInvoke: (_) => _ungroupSelection(),
          ),
          _SelectAllIntent: CallbackAction<_SelectAllIntent>(
            onInvoke: (_) => _selectAll(),
          ),
          _ClearSelectionIntent: CallbackAction<_ClearSelectionIntent>(
            onInvoke: (_) => selectionStore.clear(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: DesignerToolbar(
                  documentStore: documentStore,
                  historyStore: historyStore,
                  selectionStore: selectionStore,
                  viewportStore: viewportStore,
                  onAddElement: _addElement,
                  onGroup: _groupSelection,
                  onUngroup: _ungroupSelection,
                  onBringToFront: _bringToFront,
                  onSendToBack: _sendToBack,
                  onDelete: _deleteSelection,
                  onDuplicate: _duplicateSelection,
                  onEditProperties: _editProperties,
                  onFitToView: canvasStore.requestFitToView,
                  onSave: widget.onSave == null ? null : _save,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 200,
                      child: LayersPanel(
                        layerStore: layerStore,
                        activeLayerId: _activeLayerId,
                        onActiveLayerChanged: (id) =>
                            setState(() => _activeLayerId = id),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: LabelCanvas(
                        documentStore: documentStore,
                        selectionStore: selectionStore,
                        historyStore: historyStore,
                        viewportStore: viewportStore,
                        canvasStore: canvasStore,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 320,
                      child: RightPanel(
                        tab: _rightTab,
                        onTabChanged: (tab) => setState(() => _rightTab = tab),
                        documentStore: documentStore,
                        selectionStore: selectionStore,
                        propertyStore: propertyStore,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
