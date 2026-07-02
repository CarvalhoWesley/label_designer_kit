import 'package:label_core/label_core.dart';

import '../command.dart';
import '../element_geometry.dart';
import '../element_tree.dart';

/// Resizes the element identified by [elementId] from [from] to [to].
class ResizeCommand implements Command {
  const ResizeCommand({
    required this.elementId,
    required this.from,
    required this.to,
  });

  final String elementId;
  final Size2D from;
  final Size2D to;

  @override
  LabelDocument execute(LabelDocument document) => _resizeTo(document, to);

  @override
  LabelDocument undo(LabelDocument document) => _resizeTo(document, from);

  LabelDocument _resizeTo(LabelDocument document, Size2D size) {
    final elements = replaceElementById(
      document.elements,
      elementId,
      (element) => resizeElement(element, size),
    );
    return document.copyWith(elements: elements);
  }
}
