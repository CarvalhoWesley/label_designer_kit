import 'package:label_core/label_core.dart';

import '../command.dart';
import '../element_tree.dart';

/// Removes the element identified by [elementId] from the document.
///
/// Use [DeleteCommand.capture] to build the command: it looks up the
/// element's current location in [document] (top-level or nested inside a
/// [GroupElement], and its index) so [undo] can restore it to the exact
/// same spot, regardless of what else changes to the document in between.
class DeleteCommand implements Command {
  const DeleteCommand._({
    required this.elementId,
    required this.element,
    required this.parentId,
    required this.index,
  });

  factory DeleteCommand.capture(LabelDocument document, String elementId) {
    final location = locateElement(document.elements, elementId);
    if (location == null) {
      throw ArgumentError.value(
        elementId,
        'elementId',
        'No LabelElement with this id was found in the tree',
      );
    }
    return DeleteCommand._(
      elementId: elementId,
      element: location.element,
      parentId: location.parentId,
      index: location.index,
    );
  }

  final String elementId;
  final LabelElement element;
  final String? parentId;
  final int index;

  @override
  LabelDocument execute(LabelDocument document) {
    final elements = removeElementById(document.elements, elementId);
    return document.copyWith(elements: elements);
  }

  @override
  LabelDocument undo(LabelDocument document) {
    final elements = insertElementAt(
      document.elements,
      element,
      index,
      parentId: parentId,
    );
    return document.copyWith(elements: elements);
  }
}
