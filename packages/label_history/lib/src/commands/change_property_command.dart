import 'package:label_core/label_core.dart';

import '../command.dart';
import '../element_tree.dart';

/// Changes a single, type-specific property of the element identified by
/// [elementId] (e.g. `TextElement.content`, `RectangleElement.cornerRadius`).
///
/// [label_core]'s [LabelElement] subtypes each have their own `copyWith`
/// with different extra fields, so there is no single generic "set
/// property by name" operation. Instead, the caller (typically
/// `label_designer_state`'s `PropertyStore`, which already knows the
/// concrete element type being edited) supplies [apply]: a closure that
/// knows how to write [T] onto that concrete type.
class ChangePropertyCommand<T> implements Command {
  const ChangePropertyCommand({
    required this.elementId,
    required this.oldValue,
    required this.newValue,
    required this.apply,
  });

  final String elementId;
  final T oldValue;
  final T newValue;
  final LabelElement Function(LabelElement element, T value) apply;

  @override
  LabelDocument execute(LabelDocument document) =>
      _setValue(document, newValue);

  @override
  LabelDocument undo(LabelDocument document) => _setValue(document, oldValue);

  LabelDocument _setValue(LabelDocument document, T value) {
    final elements = replaceElementById(
      document.elements,
      elementId,
      (element) => apply(element, value),
    );
    return document.copyWith(elements: elements);
  }
}
