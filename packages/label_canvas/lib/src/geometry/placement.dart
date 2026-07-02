import 'package:label_core/label_core.dart';

import '../interaction/visibility.dart';
import 'rotate_vector.dart';

/// Where a leaf (non-[GroupElement]) element ends up once every ancestor
/// group's position and rotation is composed in — see [paintOrder].
class ElementPlacement {
  const ElementPlacement({
    required this.center,
    required this.size,
    required this.rotationDegrees,
  });

  final Point center;
  final Size2D size;
  final double rotationDegrees;
}

class PlacedElement {
  const PlacedElement({required this.element, required this.placement});

  final LabelElement element;
  final ElementPlacement placement;
}

class _Frame {
  const _Frame({
    required this.absoluteCenter,
    required this.absoluteRotationDegrees,
    required this.pivotLocal,
  });

  static const root = _Frame(
    absoluteCenter: Point.zero(),
    absoluteRotationDegrees: 0,
    pivotLocal: Point.zero(),
  );

  final Point absoluteCenter;
  final double absoluteRotationDegrees;
  final Point pivotLocal;
}

/// Flattens [elements] — expanding any nested [GroupElement] — into the
/// leaf elements actually drawn, each carrying its ABSOLUTE center/
/// rotation composed through every ancestor group.
///
/// Deliberately mirrors `label_layout_engine`'s internal group-composition
/// algorithm (see [rotateVector]'s doc comment for why this is a small,
/// intentional duplication rather than a dependency on that package).
/// Hidden elements (or elements on a hidden layer) are skipped entirely.
///
/// [positionOverrides]/[sizeOverrides]/[rotationOverrides] (keyed by
/// element id) let the painter show a live drag/resize/rotate preview
/// without touching `DocumentStore` — see `CanvasStore`'s doc comment for
/// why a `Command` is only dispatched once, on gesture end.
///
/// Sorted by zIndex ascending (paint back-to-front), matching
/// `label_renderer_canvas`'s convention — zIndex is compared globally
/// across the whole flattened list, not just among siblings, so a group is
/// purely an organizational container, not a separate stacking context.
List<PlacedElement> paintOrder(
  List<LabelElement> elements,
  List<LabelLayer> layers, {
  Map<String, Point> positionOverrides = const {},
  Map<String, Size2D> sizeOverrides = const {},
  Map<String, double> rotationOverrides = const {},
}) {
  final result = <PlacedElement>[];

  void visit(List<LabelElement> siblings, _Frame parent) {
    for (final element in siblings) {
      if (!isElementVisible(element, layers)) continue;

      final position = positionOverrides[element.id] ?? element.position;
      final size = sizeOverrides[element.id] ?? element.size;
      final rotation = rotationOverrides[element.id] ?? element.rotation;

      final localCenter = Point(
        x: position.x + size.width / 2,
        y: position.y + size.height / 2,
      );
      final offsetFromPivot = Point(
        x: localCenter.x - parent.pivotLocal.x,
        y: localCenter.y - parent.pivotLocal.y,
      );
      final rotatedOffset = rotateVector(
        offsetFromPivot,
        parent.absoluteRotationDegrees,
      );
      final absoluteCenter = Point(
        x: parent.absoluteCenter.x + rotatedOffset.x,
        y: parent.absoluteCenter.y + rotatedOffset.y,
      );
      final absoluteRotation = parent.absoluteRotationDegrees + rotation;

      if (element is GroupElement) {
        visit(
          element.children,
          _Frame(
            absoluteCenter: absoluteCenter,
            absoluteRotationDegrees: absoluteRotation,
            pivotLocal: Point(x: size.width / 2, y: size.height / 2),
          ),
        );
        continue;
      }

      result.add(
        PlacedElement(
          element: element,
          placement: ElementPlacement(
            center: absoluteCenter,
            size: size,
            rotationDegrees: absoluteRotation,
          ),
        ),
      );
    }
  }

  visit(elements, _Frame.root);
  result.sort((a, b) => a.element.zIndex.compareTo(b.element.zIndex));
  return result;
}
