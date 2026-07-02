/// Command Pattern and undo/redo over [LabelDocument]. See
/// `docs/ARCHITECTURE.md` section 13.
///
/// Every [Command] is a pure function of the [LabelDocument] it receives:
/// `execute`/`undo` return a new document via `copyWith`, never mutating
/// it or any nested element in place. This package has zero dependency on
/// Flutter or MobX — `label_designer_state`'s `HistoryStore` is the thin
/// reactive wrapper consumed by the UI.
library;

export 'src/command.dart';
export 'src/commands/add_command.dart';
export 'src/commands/change_document_command.dart';
export 'src/commands/change_property_command.dart';
export 'src/commands/composite_command.dart';
export 'src/commands/delete_command.dart';
export 'src/commands/move_command.dart';
export 'src/commands/resize_command.dart';
export 'src/commands/rotate_command.dart';
export 'src/element_geometry.dart';
export 'src/element_tree.dart';
export 'src/history_manager.dart';
