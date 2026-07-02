import 'package:equatable/equatable.dart';

import '../elements/label_element.dart';
import '../elements/text_style_spec.dart' show TextAlignment;

/// The kind of primitive shape a [ResolvedShapePayload] represents.
///
/// Collapses [RectangleElement], [EllipseElement], [CircleElement] and
/// [LineElement] into one payload type since a renderer draws all four
/// from the same bounding box + style — only the drawing primitive
/// differs.
enum ShapeKind { rectangle, ellipse, circle, line }

/// [TextStyleSpec] with every millimeter measurement converted to dots by
/// the Layout Engine.
///
/// Kept as its own type instead of reusing `TextStyleSpec` directly so a
/// renderer can never accidentally receive a millimeter value — the
/// framework-wide rule that only the Layout Engine knows about DPI/dots
/// is enforced by the type system here, not just by convention.
class ResolvedTextStyle extends Equatable {
  const ResolvedTextStyle({
    required this.fontFamily,
    required this.fontSizeDots,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.color,
    required this.alignment,
  });

  final String fontFamily;
  final int fontSizeDots;
  final bool bold;
  final bool italic;
  final bool underline;

  /// ARGB color, e.g. `0xFF000000` for opaque black.
  final int color;
  final TextAlignment alignment;

  @override
  List<Object?> get props => [
    fontFamily,
    fontSizeDots,
    bold,
    italic,
    underline,
    color,
    alignment,
  ];
}

/// [ShapeStyleSpec] with `strokeWidth` converted from millimeters to dots.
/// See [ResolvedTextStyle] for why this is a distinct type.
class ResolvedShapeStyle extends Equatable {
  const ResolvedShapeStyle({
    required this.strokeColor,
    required this.strokeWidthDots,
    this.fillColor,
  });

  final int strokeColor;
  final int strokeWidthDots;
  final int? fillColor;

  @override
  List<Object?> get props => [strokeColor, strokeWidthDots, fillColor];
}

/// The type-specific, fully-resolved content of a [ResolvedElement].
///
/// `sealed` so every `LabelRenderer` implementation gets an exhaustive
/// `switch` when converting a [ResolvedElement] to its output format.
sealed class ResolvedPayload extends Equatable {
  const ResolvedPayload();
}

/// Final resolved text: every `{{ }}` placeholder already substituted (or
/// replaced with an error marker) by the Layout Engine. Used for
/// [TextElement], [VariableElement], [DateElement] and [TimeElement],
/// which all render the same way once resolved.
class ResolvedTextPayload extends ResolvedPayload {
  const ResolvedTextPayload({required this.text, required this.style});

  final String text;
  final ResolvedTextStyle style;

  @override
  List<Object?> get props => [text, style];
}

class ResolvedBarcodePayload extends ResolvedPayload {
  const ResolvedBarcodePayload({
    required this.data,
    required this.symbology,
    required this.showText,
    required this.moduleWidthDots,
  });

  final String data;
  final BarcodeSymbology symbology;
  final bool showText;
  final int moduleWidthDots;

  @override
  List<Object?> get props => [data, symbology, showText, moduleWidthDots];
}

class ResolvedQrCodePayload extends ResolvedPayload {
  const ResolvedQrCodePayload({
    required this.data,
    required this.errorCorrectionLevel,
  });

  final String data;
  final QrErrorCorrectionLevel errorCorrectionLevel;

  @override
  List<Object?> get props => [data, errorCorrectionLevel];
}

class ResolvedImagePayload extends ResolvedPayload {
  const ResolvedImagePayload({
    required this.source,
    required this.fit,
    this.cropXDots,
    this.cropYDots,
    this.cropWidthDots,
    this.cropHeightDots,
  });

  /// Resolved image reference (path/URL/base64), with any `{{ }}`
  /// placeholder already substituted. Decoding the actual bytes is the
  /// renderer's job.
  final String source;
  final ImageFit fit;

  /// Crop rectangle within the source image, in dots of the source's own
  /// resolution. All four are `null` together, meaning no crop.
  final int? cropXDots;
  final int? cropYDots;
  final int? cropWidthDots;
  final int? cropHeightDots;

  @override
  List<Object?> get props => [
    source,
    fit,
    cropXDots,
    cropYDots,
    cropWidthDots,
    cropHeightDots,
  ];
}

class ResolvedShapePayload extends ResolvedPayload {
  const ResolvedShapePayload({
    required this.kind,
    required this.style,
    this.cornerRadiusDots = 0,
  });

  final ShapeKind kind;
  final ResolvedShapeStyle style;

  /// Only meaningful when [kind] is [ShapeKind.rectangle].
  final int cornerRadiusDots;

  @override
  List<Object?> get props => [kind, style, cornerRadiusDots];
}
