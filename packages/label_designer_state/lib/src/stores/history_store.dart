import 'package:label_core/label_core.dart';
import 'package:label_history/label_history.dart';
import 'package:label_serialization/label_serialization.dart';
import 'package:mobx/mobx.dart';

import 'document_store.dart';

part 'history_store.g.dart';

/// Thin reactive wrapper over [HistoryManager] (see
/// `docs/ARCHITECTURE.md` section 13): every [Command] dispatched here is
/// applied to [DocumentStore], keeping `canUndo`/`canRedo` observable so
/// the UI (toolbar buttons, keyboard shortcuts) can react without polling.
class HistoryStore = HistoryStoreBase with _$HistoryStore;

abstract class HistoryStoreBase with Store {
  HistoryStoreBase(
    this._documentStore, {
    LabelDocumentCodec codec = const LabelDocumentCodec(),
  }) : _codec = codec,
       _historyManager = HistoryManager(_documentStore.document);

  final DocumentStore _documentStore;
  final LabelDocumentCodec _codec;
  HistoryManager _historyManager;

  @observable
  bool canUndo = false;

  @observable
  bool canRedo = false;

  /// Runs [command] against the current document and pushes it onto the
  /// undo stack, clearing any previously undone (redo) branch.
  @action
  void execute(Command command) {
    _documentStore.replaceDocument(_historyManager.execute(command));
    _syncFlags();
  }

  @action
  void undo() {
    _documentStore.replaceDocument(_historyManager.undo());
    _syncFlags();
  }

  @action
  void redo() {
    _documentStore.replaceDocument(_historyManager.redo());
    _syncFlags();
  }

  /// Replaces the current document with [newDocument] and resets history —
  /// use when opening a different `.label` file, not for in-place edits.
  @action
  void loadDocument(LabelDocument newDocument) {
    _historyManager = HistoryManager(newDocument);
    _documentStore.replaceDocument(newDocument);
    _syncFlags();
  }

  /// Convenience wrapper: decodes [json] via [label_serialization] and
  /// loads the result, resetting history.
  void loadFromJson(String json) => loadDocument(_codec.decode(json));

  /// Moves the element identified by [elementId] from [from] to [to] as
  /// one undo step. `label_canvas` calls this instead of constructing a
  /// [MoveCommand] itself, so it never needs to depend on `label_history`
  /// directly.
  void moveElement({
    required String elementId,
    required Point from,
    required Point to,
  }) => execute(MoveCommand(elementId: elementId, from: from, to: to));

  /// Moves every element in [from] to its counterpart in [to] as a single
  /// undo step — used when dragging a multi-element selection, where one
  /// undo should revert the whole drag, not one element at a time.
  ///
  /// [from] and [to] must have the same keys (element ids).
  void moveElements({
    required Map<String, Point> from,
    required Map<String, Point> to,
  }) {
    assert(
      from.keys.toSet().containsAll(to.keys),
      'from/to must cover the same element ids',
    );
    final commands = [
      for (final id in to.keys)
        MoveCommand(elementId: id, from: from[id]!, to: to[id]!),
    ];
    if (commands.isEmpty) return;
    execute(
      commands.length == 1 ? commands.single : CompositeCommand(commands),
    );
  }

  /// Resizes the element identified by [elementId] from [from] to [to].
  void resizeElement({
    required String elementId,
    required Size2D from,
    required Size2D to,
  }) => execute(ResizeCommand(elementId: elementId, from: from, to: to));

  /// Resizes AND (if the anchor moved) repositions an element as a single
  /// undo step. `label_canvas` calls this — not [resizeElement] — when
  /// dragging a resize handle: keeping the opposite edge visually fixed on
  /// screen means `position` changes along with `size`, and the user
  /// expects one undo to revert the whole drag, not two.
  void resizeElementBounds({
    required String elementId,
    required Point fromPosition,
    required Point toPosition,
    required Size2D fromSize,
    required Size2D toSize,
  }) {
    final commands = [
      if (fromSize != toSize)
        ResizeCommand(elementId: elementId, from: fromSize, to: toSize),
      if (fromPosition != toPosition)
        MoveCommand(elementId: elementId, from: fromPosition, to: toPosition),
    ];
    if (commands.isEmpty) return;
    execute(
      commands.length == 1 ? commands.single : CompositeCommand(commands),
    );
  }

  /// Rotates the element identified by [elementId] from [from] to [to]
  /// degrees.
  void rotateElement({
    required String elementId,
    required double from,
    required double to,
  }) => execute(RotateCommand(elementId: elementId, from: from, to: to));

  /// Adds [element] to the document (top-level, or inside the
  /// [GroupElement] identified by [parentId]).
  void addElement(LabelElement element, {String? parentId, int? index}) =>
      execute(AddCommand(element: element, parentId: parentId, index: index));

  /// Removes the element identified by [elementId] from the document.
  void deleteElement(String elementId) =>
      execute(DeleteCommand.capture(_documentStore.document, elementId));

  /// Replaces the whole top-level element list as a single undo step —
  /// used by `label_designer` for operations that restructure the element
  /// list itself rather than editing one element's fields: grouping/
  /// ungrouping (replacing N siblings with one `GroupElement`, or vice
  /// versa) and reordering `zIndex` for bring-to-front/send-to-back.
  /// Mirrors [LayerStore]'s internal `_updateLayer`, which does the same
  /// for `document.layers`.
  void replaceElements(List<LabelElement> newElements) {
    execute(
      ChangeDocumentCommand<List<LabelElement>>(
        oldValue: _documentStore.elements,
        newValue: newElements,
        apply: (document, value) => document.copyWith(elements: value),
      ),
    );
  }

  /// Renames the document as a single undo step.
  void renameDocument(String name) {
    final command = _renameCommand(name);
    if (command != null) execute(command);
  }

  /// Changes the document's page configuration (size, unit, dpi,
  /// orientation, margins) as a single undo step.
  void updatePageConfig(PageConfig page) {
    final command = _pageConfigCommand(page);
    if (command != null) execute(command);
  }

  /// Renames the document and/or changes its page configuration as one
  /// undo step — used by the "document properties" dialog, where the user
  /// edits both fields before pressing a single "Save".
  void updateDocumentMeta({String? name, PageConfig? page}) {
    final commands = [
      if (name != null) _renameCommand(name),
      if (page != null) _pageConfigCommand(page),
    ].whereType<Command>().toList();
    if (commands.isEmpty) return;
    execute(
      commands.length == 1 ? commands.single : CompositeCommand(commands),
    );
  }

  ChangeDocumentCommand<String>? _renameCommand(String name) {
    if (name == _documentStore.document.name) return null;
    return ChangeDocumentCommand<String>(
      oldValue: _documentStore.document.name,
      newValue: name,
      apply: (document, value) => document.copyWith(name: value),
    );
  }

  ChangeDocumentCommand<PageConfig>? _pageConfigCommand(PageConfig page) {
    if (page == _documentStore.document.page) return null;
    return ChangeDocumentCommand<PageConfig>(
      oldValue: _documentStore.document.page,
      newValue: page,
      apply: (document, value) => document.copyWith(page: value),
    );
  }

  /// Convenience wrapper: encodes the current document via
  /// [label_serialization]. Writing the result to disk is the consuming
  /// app's responsibility (see `docs/ARCHITECTURE.md` section 20).
  String encodeToJson() => _codec.encode(_documentStore.document);

  void _syncFlags() {
    canUndo = _historyManager.canUndo;
    canRedo = _historyManager.canRedo;
  }
}
