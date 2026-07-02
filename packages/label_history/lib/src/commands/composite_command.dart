import 'package:label_core/label_core.dart';

import '../command.dart';

/// Bundles several [Command]s into one undo step — e.g. dragging a
/// multi-element selection is one [MoveCommand] per element, but the user
/// expects a single undo to revert the whole drag.
///
/// [execute] runs [commands] in order; [undo] reverses them in the
/// opposite order, matching how nested transactions unwind.
class CompositeCommand implements Command {
  const CompositeCommand(this.commands);

  final List<Command> commands;

  @override
  LabelDocument execute(LabelDocument document) {
    var result = document;
    for (final command in commands) {
      result = command.execute(result);
    }
    return result;
  }

  @override
  LabelDocument undo(LabelDocument document) {
    var result = document;
    for (final command in commands.reversed) {
      result = command.undo(result);
    }
    return result;
  }
}
