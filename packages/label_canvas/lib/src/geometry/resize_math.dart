import 'dart:math' as math;

import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

import 'element_bounds.dart';
import 'rotate_vector.dart';

/// The result of dragging a resize handle: the element's new top-left
/// [position] and [size]. Rotation never changes during a resize.
class ResizeResult {
  const ResizeResult({required this.position, required this.size});

  final Point position;
  final Size2D size;
}

/// Computes the new bounds when [handle] of an element described by
/// [original] is dragged to [pointerMm], keeping the opposite corner/edge
/// visually fixed on screen — including when the element is rotated, by
/// doing the math in the element's own unrotated local axes rather than
/// screen axes.
///
/// Edge handles ([ResizeHandle.topCenter], [.bottomCenter], [.centerLeft],
/// [.centerRight]) only resize along their one axis; corner handles resize
/// both. [minSizeMm] prevents collapsing an element to zero or negative
/// size.
ResizeResult resizeFromHandle({
  required ElementBounds original,
  required ResizeHandle handle,
  required Point pointerMm,
  double minSizeMm = 1,
}) {
  final center = original.center;
  final local = rotateVector(
    Point(x: pointerMm.x - center.x, y: pointerMm.y - center.y),
    -original.rotationDegrees,
  );
  final halfW = original.size.width / 2;
  final halfH = original.size.height / 2;

  final resizesX =
      handle != ResizeHandle.topCenter && handle != ResizeHandle.bottomCenter;
  final resizesY =
      handle != ResizeHandle.centerLeft && handle != ResizeHandle.centerRight;

  // The anchor is the opposite corner/edge in the element's own unrotated
  // local space — it must not move on screen while the dragged handle does.
  final anchorX = switch (handle) {
    ResizeHandle.topLeft ||
    ResizeHandle.centerLeft ||
    ResizeHandle.bottomLeft => halfW,
    ResizeHandle.topRight ||
    ResizeHandle.centerRight ||
    ResizeHandle.bottomRight => -halfW,
    ResizeHandle.topCenter || ResizeHandle.bottomCenter => 0.0,
    ResizeHandle.rotation => 0.0,
  };
  final anchorY = switch (handle) {
    ResizeHandle.topLeft ||
    ResizeHandle.topCenter ||
    ResizeHandle.topRight => halfH,
    ResizeHandle.bottomLeft ||
    ResizeHandle.bottomCenter ||
    ResizeHandle.bottomRight => -halfH,
    ResizeHandle.centerLeft || ResizeHandle.centerRight => 0.0,
    ResizeHandle.rotation => 0.0,
  };

  final newWidth = resizesX
      ? math.max(minSizeMm, (local.x - anchorX).abs())
      : original.size.width;
  final newHeight = resizesY
      ? math.max(minSizeMm, (local.y - anchorY).abs())
      : original.size.height;

  final draggedX = resizesX
      ? anchorX + newWidth * (local.x >= anchorX ? 1 : -1)
      : anchorX;
  final draggedY = resizesY
      ? anchorY + newHeight * (local.y >= anchorY ? 1 : -1)
      : anchorY;

  final newCenterLocal = Point(
    x: (anchorX + draggedX) / 2,
    y: (anchorY + draggedY) / 2,
  );
  final newCenterAbsolute = Point(
    x: center.x + rotateVector(newCenterLocal, original.rotationDegrees).x,
    y: center.y + rotateVector(newCenterLocal, original.rotationDegrees).y,
  );

  return ResizeResult(
    position: Point(
      x: newCenterAbsolute.x - newWidth / 2,
      y: newCenterAbsolute.y - newHeight / 2,
    ),
    size: Size2D(width: newWidth, height: newHeight),
  );
}
