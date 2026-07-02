part of 'label_element.dart';

/// Stroke/fill styling shared by [RectangleElement], [EllipseElement],
/// [CircleElement] and [LineElement].
class ShapeStyleSpec extends Equatable {
  const ShapeStyleSpec({
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 0.3,
    this.fillColor,
  });

  factory ShapeStyleSpec.fromJson(Map<String, dynamic> json) {
    return ShapeStyleSpec(
      strokeColor: json['strokeColor'] as int? ?? 0xFF000000,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.3,
      fillColor: json['fillColor'] as int?,
    );
  }

  /// ARGB color of the outline.
  final int strokeColor;

  /// Outline thickness in millimeters.
  final double strokeWidth;

  /// ARGB color of the fill, or `null` for no fill (transparent).
  final int? fillColor;

  ShapeStyleSpec copyWith({
    int? strokeColor,
    double? strokeWidth,
    int? fillColor,
  }) {
    return ShapeStyleSpec(
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fillColor: fillColor ?? this.fillColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
    if (fillColor != null) 'fillColor': fillColor,
  };

  @override
  List<Object?> get props => [strokeColor, strokeWidth, fillColor];
}
