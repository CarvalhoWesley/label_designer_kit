import 'package:equatable/equatable.dart';

/// Extra affine adjustments applied on top of an element's position, size
/// and rotation.
///
/// Kept separate from rotation because flips and skews are edited and
/// reasoned about independently in the property panel.
class ElementTransform extends Equatable {
  const ElementTransform({
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.skewX = 0,
    this.skewY = 0,
  });

  const ElementTransform.identity()
    : flipHorizontal = false,
      flipVertical = false,
      skewX = 0,
      skewY = 0;

  factory ElementTransform.fromJson(Map<String, dynamic> json) {
    return ElementTransform(
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
      skewX: (json['skewX'] as num?)?.toDouble() ?? 0,
      skewY: (json['skewY'] as num?)?.toDouble() ?? 0,
    );
  }

  final bool flipHorizontal;
  final bool flipVertical;

  /// Skew angle in degrees along the X axis.
  final double skewX;

  /// Skew angle in degrees along the Y axis.
  final double skewY;

  ElementTransform copyWith({
    bool? flipHorizontal,
    bool? flipVertical,
    double? skewX,
    double? skewY,
  }) {
    return ElementTransform(
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      skewX: skewX ?? this.skewX,
      skewY: skewY ?? this.skewY,
    );
  }

  Map<String, dynamic> toJson() => {
    'flipHorizontal': flipHorizontal,
    'flipVertical': flipVertical,
    'skewX': skewX,
    'skewY': skewY,
  };

  @override
  List<Object?> get props => [flipHorizontal, flipVertical, skewX, skewY];
}
