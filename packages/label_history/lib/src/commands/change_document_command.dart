import 'package:label_core/label_core.dart';

import '../command.dart';

/// Changes a single document-level field (e.g. `LabelDocument.layers`,
/// `LabelDocument.page`) that isn't tied to one specific [LabelElement].
///
/// Mirrors [ChangePropertyCommand]'s design: the caller (e.g.
/// `label_designer_state`'s `LayerStore`) supplies [apply], a closure that
/// knows how to write [T] onto [LabelDocument] via `copyWith`.
class ChangeDocumentCommand<T> implements Command {
  const ChangeDocumentCommand({
    required this.oldValue,
    required this.newValue,
    required this.apply,
  });

  final T oldValue;
  final T newValue;
  final LabelDocument Function(LabelDocument document, T value) apply;

  @override
  LabelDocument execute(LabelDocument document) => apply(document, newValue);

  @override
  LabelDocument undo(LabelDocument document) => apply(document, oldValue);
}
