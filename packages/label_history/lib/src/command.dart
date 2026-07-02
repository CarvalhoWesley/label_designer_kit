import 'package:label_core/label_core.dart';

/// A reversible change to a [LabelDocument] (GoF Command pattern).
///
/// Implementations must be pure functions of the document they receive:
/// [execute] and [undo] return a new [LabelDocument] via `copyWith`,
/// never mutating [document] or any nested element in place. This is what
/// lets [HistoryManager] replay a command (redo) by calling [execute]
/// again on whatever document is current at that time.
abstract interface class Command {
  LabelDocument execute(LabelDocument document);
  LabelDocument undo(LabelDocument document);
}
