import 'package:label_core/label_core.dart';

import '../command.dart';
import '../element_geometry.dart';
import '../element_tree.dart';

/// Moves the element identified by [elementId] from [from] to [to].
class MoveCommand implements Command {
  const MoveCommand({
    required this.elementId,
    required this.from,
    required this.to,
  });

  final String elementId;
  final Point from;
  final Point to;

  @override
  LabelDocument execute(LabelDocument document) => _moveTo(document, to);

  @override
  LabelDocument undo(LabelDocument document) => _moveTo(document, from);

  LabelDocument _moveTo(LabelDocument document, Point position) {
    final elements = replaceElementById(
      document.elements,
      elementId,
      (element) => moveElement(element, position),
    );
    return document.copyWith(elements: elements);
  }
}
