import 'package:label_core/label_core.dart';

import 'command.dart';

/// Owns the undo/redo stacks and the current [LabelDocument] produced by
/// replaying [Command]s on top of the document it was created with.
///
/// Pure Dart, no MobX: `label_designer_state`'s `HistoryStore` wraps this
/// class to expose it reactively to the UI.
class HistoryManager {
  HistoryManager(LabelDocument document) : _document = document;

  LabelDocument _document;
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  /// The document resulting from every executed/redone command minus every
  /// undone one, in order.
  LabelDocument get document => _document;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Runs [command] against the current document, pushes it onto the undo
  /// stack and clears the redo stack (a fresh action invalidates any
  /// previously undone branch of history).
  LabelDocument execute(Command command) {
    _document = command.execute(_document);
    _undoStack.add(command);
    _redoStack.clear();
    return _document;
  }

  /// Reverts the most recently executed/redone command, if any.
  LabelDocument undo() {
    if (!canUndo) return _document;
    final command = _undoStack.removeLast();
    _document = command.undo(_document);
    _redoStack.add(command);
    return _document;
  }

  /// Re-applies the most recently undone command, if any.
  LabelDocument redo() {
    if (!canRedo) return _document;
    final command = _redoStack.removeLast();
    _document = command.execute(_document);
    _undoStack.add(command);
    return _document;
  }

  /// Drops all history without changing [document] — e.g. right after a
  /// different document has been loaded from disk.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
