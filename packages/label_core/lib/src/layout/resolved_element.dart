import 'package:equatable/equatable.dart';

import 'resolved_payload.dart';

/// A single element after the Layout Engine has resolved every variable,
/// expression, style reference and unit conversion.
///
/// All geometry here is in **dots**, already accounting for the page's
/// DPI and, if the element was inside a `GroupElement`, the group's own
/// position/rotation composed into this element's own — the flattening
/// documented in `docs/ARCHITECTURE.md` section 9. Renderers consume this
/// directly and never need to know a group existed.
class ResolvedElement extends Equatable {
  const ResolvedElement({
    required this.id,
    required this.xDots,
    required this.yDots,
    required this.widthDots,
    required this.heightDots,
    required this.rotationDegrees,
    required this.zIndex,
    required this.opacity,
    required this.payload,
  });

  final String id;

  /// Top-left of the element's *unrotated* bounding box, in dots. A
  /// renderer applies [rotationDegrees] around this box's own center at
  /// paint time.
  final int xDots;
  final int yDots;
  final int widthDots;
  final int heightDots;
  final double rotationDegrees;
  final int zIndex;
  final double opacity;
  final ResolvedPayload payload;

  @override
  List<Object?> get props => [
    id,
    xDots,
    yDots,
    widthDots,
    heightDots,
    rotationDegrees,
    zIndex,
    opacity,
    payload,
  ];
}
