import 'package:label_core/label_core.dart';

import 'element_bounds.dart';

/// Result of [snapToElements]: the corrected position for the element
/// being moved, plus the guide line(s) (in mm, absolute document
/// coordinates) to draw for whichever axes actually matched — empty on an
/// axis with no alignment within threshold.
class AlignmentSnapResult {
  const AlignmentSnapResult({
    required this.adjustedPosition,
    this.guidesX = const [],
    this.guidesY = const [],
  });

  final Point adjustedPosition;
  final List<double> guidesX;
  final List<double> guidesY;
}

/// Compares [moving]'s left/center/right (X) and top/center/bottom (Y)
/// edges against the same edges of every element in [others]; within
/// [thresholdMm] on a given axis, snaps that axis of [moving]'s position
/// to align exactly with the closest match — "smart guides", the same
/// element-to-element alignment most design tools show while dragging.
///
/// The two axes are resolved independently: an alignment match on X
/// doesn't require one on Y, and vice versa — a caller combining this
/// with grid snapping should fall back to the grid on whichever axis
/// didn't get an alignment match here (see `CanvasController._updateMove`).
AlignmentSnapResult snapToElements({
  required ElementBounds moving,
  required List<ElementBounds> others,
  required double thresholdMm,
}) {
  final movingLeft = moving.position.x;
  final movingRight = moving.position.x + moving.size.width;
  final movingCenterX = moving.position.x + moving.size.width / 2;
  final movingTop = moving.position.y;
  final movingBottom = moving.position.y + moving.size.height;
  final movingCenterY = moving.position.y + moving.size.height / 2;

  double? bestDx;
  double? snappedX;
  double? bestDy;
  double? snappedY;

  for (final other in others) {
    final otherLeft = other.position.x;
    final otherRight = other.position.x + other.size.width;
    final otherCenterX = other.position.x + other.size.width / 2;
    final otherTop = other.position.y;
    final otherBottom = other.position.y + other.size.height;
    final otherCenterY = other.position.y + other.size.height / 2;

    for (final movingEdge in [movingLeft, movingCenterX, movingRight]) {
      for (final otherEdge in [otherLeft, otherCenterX, otherRight]) {
        final diff = otherEdge - movingEdge;
        if (diff.abs() <= thresholdMm &&
            (bestDx == null || diff.abs() < bestDx.abs())) {
          bestDx = diff;
          snappedX = otherEdge;
        }
      }
    }

    for (final movingEdge in [movingTop, movingCenterY, movingBottom]) {
      for (final otherEdge in [otherTop, otherCenterY, otherBottom]) {
        final diff = otherEdge - movingEdge;
        if (diff.abs() <= thresholdMm &&
            (bestDy == null || diff.abs() < bestDy.abs())) {
          bestDy = diff;
          snappedY = otherEdge;
        }
      }
    }
  }

  return AlignmentSnapResult(
    adjustedPosition: Point(
      x: moving.position.x + (bestDx ?? 0),
      y: moving.position.y + (bestDy ?? 0),
    ),
    guidesX: snappedX == null ? const [] : [snappedX],
    guidesY: snappedY == null ? const [] : [snappedY],
  );
}
