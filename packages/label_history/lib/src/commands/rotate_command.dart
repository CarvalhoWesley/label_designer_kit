import 'package:label_core/label_core.dart';

import '../command.dart';
import '../element_geometry.dart';
import '../element_tree.dart';

/// Rotates the element identified by [elementId] from [from] to [to]
/// degrees.
class RotateCommand implements Command {
  const RotateCommand({
    required this.elementId,
    required this.from,
    required this.to,
  });

  final String elementId;
  final double from;
  final double to;

  @override
  LabelDocument execute(LabelDocument document) => _rotateTo(document, to);

  @override
  LabelDocument undo(LabelDocument document) => _rotateTo(document, from);

  LabelDocument _rotateTo(LabelDocument document, double rotationDegrees) {
    final elements = replaceElementById(
      document.elements,
      elementId,
      (element) => rotateElement(element, rotationDegrees),
    );
    return document.copyWith(elements: elements);
  }
}
