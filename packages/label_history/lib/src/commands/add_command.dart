import 'package:label_core/label_core.dart';

import '../command.dart';
import '../element_tree.dart';

/// Adds [element] to the document, either top-level or as a child of the
/// [GroupElement] identified by [parentId], at [index] (appended when
/// `null`).
class AddCommand implements Command {
  const AddCommand({required this.element, this.parentId, this.index});

  final LabelElement element;
  final String? parentId;
  final int? index;

  @override
  LabelDocument execute(LabelDocument document) {
    final elements = insertElementAt(
      document.elements,
      element,
      index,
      parentId: parentId,
    );
    return document.copyWith(elements: elements);
  }

  @override
  LabelDocument undo(LabelDocument document) {
    final elements = removeElementById(document.elements, element.id);
    return document.copyWith(elements: elements);
  }
}
