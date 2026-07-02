import 'package:label_core/label_core.dart';

/// Returns a copy of [element] moved to [position].
LabelElement moveElement(LabelElement element, Point position) =>
    _copyWithGeometry(element, position: position);

/// Returns a copy of [element] resized to [size].
LabelElement resizeElement(LabelElement element, Size2D size) =>
    _copyWithGeometry(element, size: size);

/// Returns a copy of [element] rotated to [rotationDegrees].
LabelElement rotateElement(LabelElement element, double rotationDegrees) =>
    _copyWithGeometry(element, rotation: rotationDegrees);

/// Every [LabelElement] subtype exposes `position`/`size`/`rotation` on the
/// same `copyWith` signature (inherited from the sealed base class), but
/// Dart has no way to call a covariant `copyWith` through the base type.
/// This exhaustive switch is the one place that bridges that gap so
/// Move/Resize/Rotate commands don't need to know about concrete subtypes.
LabelElement _copyWithGeometry(
  LabelElement element, {
  Point? position,
  Size2D? size,
  double? rotation,
}) => switch (element) {
  TextElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  BarcodeElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  QRCodeElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  ImageElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  RectangleElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  EllipseElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  CircleElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  LineElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  VariableElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  DateElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  TimeElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  TableElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
  GroupElement e => e.copyWith(
    position: position,
    size: size,
    rotation: rotation,
  ),
};
