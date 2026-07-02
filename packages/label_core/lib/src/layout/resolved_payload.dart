import 'package:equatable/equatable.dart';

import '../elements/label_element.dart';
import '../elements/text_style_spec.dart';

/// The kind of primitive shape a [ResolvedShapePayload] represents.
///
/// Collapses [RectangleElement], [EllipseElement], [CircleElement] and
/// [LineElement] into one payload type since a renderer draws all four
/// from the same bounding box + style — only the drawing primitive
/// differs.
enum ShapeKind { rectangle, ellipse, circle, line }

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
  final TextStyleSpec style;

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
  final ShapeStyleSpec style;

  /// Only meaningful when [kind] is [ShapeKind.rectangle].
  final int cornerRadiusDots;

  @override
  List<Object?> get props => [kind, style, cornerRadiusDots];
}
