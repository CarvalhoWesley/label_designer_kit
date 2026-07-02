import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

import 'rotate_vector.dart';

/// The position/size/rotation of one element's bounding box, with helpers
/// for hit-testing and locating its resize/rotation handles — the pure
/// geometry `label_canvas`'s painter and gesture handling share.
class ElementBounds {
  const ElementBounds({
    required this.position,
    required this.size,
    this.rotationDegrees = 0,
  });

  factory ElementBounds.of(LabelElement element) => ElementBounds(
    position: element.position,
    size: element.size,
    rotationDegrees: element.rotation,
  );

  /// Top-left corner in mm, *before* rotation (rotation pivots on [center]).
  final Point position;
  final Size2D size;
  final double rotationDegrees;

  Point get center =>
      Point(x: position.x + size.width / 2, y: position.y + size.height / 2);

  /// Whether [pointMm] falls inside this element's rotated rectangle.
  bool contains(Point pointMm) {
    final local = _toLocal(pointMm);
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    return local.x >= -halfW &&
        local.x <= halfW &&
        local.y >= -halfH &&
        local.y <= halfH;
  }

  /// The 4 corners of the rotated rectangle in absolute mm, clockwise from
  /// top-left: top-left, top-right, bottom-right, bottom-left.
  List<Point> get corners {
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    return [
      _fromLocal(Point(x: -halfW, y: -halfH)),
      _fromLocal(Point(x: halfW, y: -halfH)),
      _fromLocal(Point(x: halfW, y: halfH)),
      _fromLocal(Point(x: -halfW, y: halfH)),
    ];
  }

  /// Absolute mm position of [handle], including the dedicated rotation
  /// handle floating [rotationHandleOffsetMm] above the top edge.
  Point handlePosition(
    ResizeHandle handle, {
    double rotationHandleOffsetMm = 8,
  }) {
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    final local = switch (handle) {
      ResizeHandle.topLeft => Point(x: -halfW, y: -halfH),
      ResizeHandle.topCenter => Point(x: 0, y: -halfH),
      ResizeHandle.topRight => Point(x: halfW, y: -halfH),
      ResizeHandle.centerLeft => Point(x: -halfW, y: 0),
      ResizeHandle.centerRight => Point(x: halfW, y: 0),
      ResizeHandle.bottomLeft => Point(x: -halfW, y: halfH),
      ResizeHandle.bottomCenter => Point(x: 0, y: halfH),
      ResizeHandle.bottomRight => Point(x: halfW, y: halfH),
      ResizeHandle.rotation => Point(x: 0, y: -halfH - rotationHandleOffsetMm),
    };
    return _fromLocal(local);
  }

  /// [pointMm] relative to [center] with this element's rotation undone —
  /// i.e. expressed in the element's own unrotated local space.
  Point _toLocal(Point pointMm) {
    final c = center;
    return rotateVector(
      Point(x: pointMm.x - c.x, y: pointMm.y - c.y),
      -rotationDegrees,
    );
  }

  Point _fromLocal(Point local) {
    final rotated = rotateVector(local, rotationDegrees);
    final c = center;
    return Point(x: c.x + rotated.x, y: c.y + rotated.y);
  }
}
