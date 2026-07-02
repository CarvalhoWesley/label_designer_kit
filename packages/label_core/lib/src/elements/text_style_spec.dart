import 'package:equatable/equatable.dart';

/// Horizontal text alignment, independent of Flutter's `TextAlign`.
enum TextAlignment { left, center, right, justify }

/// Inline typography shared by every text-like element ([TextElement],
/// [VariableElement], [DateElement], [TimeElement]).
///
/// An element may instead reference a [LabelStyle] via `styleId` to reuse a
/// named style; [TextStyleSpec] fields on the element itself take
/// precedence when both are present, allowing local overrides.
class TextStyleSpec extends Equatable {
  const TextStyleSpec({
    this.fontFamily = 'Roboto',
    this.fontSize = 4,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color = 0xFF000000,
    this.alignment = TextAlignment.left,
  });

  factory TextStyleSpec.fromJson(Map<String, dynamic> json) {
    return TextStyleSpec(
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 4,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      color: json['color'] as int? ?? 0xFF000000,
      alignment: TextAlignment.values.byName(
        json['alignment'] as String? ?? 'left',
      ),
    );
  }

  final String fontFamily;

  /// Font size in millimeters.
  final double fontSize;
  final bool bold;
  final bool italic;
  final bool underline;

  /// ARGB color, e.g. `0xFF000000` for opaque black.
  final int color;
  final TextAlignment alignment;

  TextStyleSpec copyWith({
    String? fontFamily,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    int? color,
    TextAlignment? alignment,
  }) {
    return TextStyleSpec(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      color: color ?? this.color,
      alignment: alignment ?? this.alignment,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'color': color,
    'alignment': alignment.name,
  };

  @override
  List<Object?> get props => [
    fontFamily,
    fontSize,
    bold,
    italic,
    underline,
    color,
    alignment,
  ];
}
