import 'package:label_core/label_core.dart';
import 'package:label_expression_engine/label_expression_engine.dart';

import 'errors.dart';
import 'placeholder_resolver.dart';

/// Visits each concrete [LabelElement] subtype and produces its
/// [ResolvedPayload] — the one piece of resolution that genuinely differs
/// per element type. Position/size/rotation resolution (identical for
/// every type) stays in [LabelLayoutEngine] itself.
class PayloadResolver implements LabelElementVisitor<ResolvedPayload?> {
  PayloadResolver({
    required this.document,
    required this.data,
    required this.expressionEngine,
    required this.dpi,
  });

  final LabelDocument document;
  final Map<String, dynamic> data;
  final ExpressionEngine expressionEngine;
  final Dpi dpi;

  @override
  ResolvedPayload visitText(TextElement element) {
    return ResolvedTextPayload(
      text: resolvePlaceholders(element.content, data, expressionEngine),
      style: _resolveTextStyle(element.styleId, element.style),
    );
  }

  @override
  ResolvedPayload visitVariable(VariableElement element) {
    final result = expressionEngine.evaluate(element.expression, data);
    final text = switch (result) {
      ExpressionSuccess(:final value) => value == null ? '' : value.toString(),
      ExpressionFailure() => expressionErrorMarker,
    };
    return ResolvedTextPayload(
      text: text,
      style: _resolveTextStyle(element.styleId, element.style),
    );
  }

  @override
  ResolvedPayload visitDate(DateElement element) {
    final value = _resolveDateTimeSource(
      source: element.source,
      variableName: element.variableName,
      elementDescription: 'DateElement "${element.name}"',
    );
    return ResolvedTextPayload(
      text: _formatDateTimeValue(value, element.format),
      style: element.style,
    );
  }

  @override
  ResolvedPayload visitTime(TimeElement element) {
    final value = _resolveDateTimeSource(
      source: element.source,
      variableName: element.variableName,
      elementDescription: 'TimeElement "${element.name}"',
    );
    return ResolvedTextPayload(
      text: _formatDateTimeValue(value, element.format),
      style: element.style,
    );
  }

  @override
  ResolvedPayload visitBarcode(BarcodeElement element) {
    return ResolvedBarcodePayload(
      data: resolvePlaceholders(element.data, data, expressionEngine),
      symbology: element.symbology,
      showText: element.showText,
      moduleWidthDots: dpi.mmToDots(element.moduleWidth),
    );
  }

  @override
  ResolvedPayload visitQrCode(QRCodeElement element) {
    return ResolvedQrCodePayload(
      data: resolvePlaceholders(element.data, data, expressionEngine),
      errorCorrectionLevel: element.errorCorrectionLevel,
    );
  }

  @override
  ResolvedPayload visitImage(ImageElement element) {
    final cropPosition = element.cropPosition;
    final cropSize = element.cropSize;
    return ResolvedImagePayload(
      source: resolvePlaceholders(element.source, data, expressionEngine),
      fit: element.fit,
      cropXDots: cropPosition == null ? null : dpi.mmToDots(cropPosition.x),
      cropYDots: cropPosition == null ? null : dpi.mmToDots(cropPosition.y),
      cropWidthDots: cropSize == null ? null : dpi.mmToDots(cropSize.width),
      cropHeightDots: cropSize == null ? null : dpi.mmToDots(cropSize.height),
    );
  }

  @override
  ResolvedPayload visitRectangle(RectangleElement element) {
    return ResolvedShapePayload(
      kind: ShapeKind.rectangle,
      style: element.style,
      cornerRadiusDots: dpi.mmToDots(element.cornerRadius),
    );
  }

  @override
  ResolvedPayload visitEllipse(EllipseElement element) {
    return ResolvedShapePayload(kind: ShapeKind.ellipse, style: element.style);
  }

  @override
  ResolvedPayload visitCircle(CircleElement element) {
    return ResolvedShapePayload(kind: ShapeKind.circle, style: element.style);
  }

  @override
  ResolvedPayload visitLine(LineElement element) {
    return ResolvedShapePayload(
      kind: ShapeKind.line,
      style: ShapeStyleSpec(
        strokeColor: element.strokeColor,
        strokeWidth: element.strokeWidth,
      ),
    );
  }

  @override
  ResolvedPayload? visitTable(TableElement element) {
    // TableElement rendering is a future roadmap step (see
    // docs/ROADMAP.md); positioning still happens, but it paints nothing
    // until a ResolvedTablePayload and matching renderer support exist.
    return null;
  }

  @override
  ResolvedPayload visitGroup(GroupElement element) {
    throw UnsupportedError(
      'GroupElement has no payload of its own — LabelLayoutEngine flattens '
      'it into its children before payload resolution runs.',
    );
  }

  TextStyleSpec _resolveTextStyle(String? styleId, TextStyleSpec inlineStyle) {
    if (styleId == null) return inlineStyle;
    for (final style in document.styles) {
      if (style.id == styleId) return style.spec;
    }
    return inlineStyle;
  }

  Object? _resolveDateTimeSource({
    required DateTimeSource source,
    required String? variableName,
    required String elementDescription,
  }) {
    switch (source) {
      case DateTimeSource.now:
        return DateTime.now();
      case DateTimeSource.variable:
        if (variableName == null) {
          throw LayoutException(
            '$elementDescription usa DateTimeSource.variable mas não '
            'declara variableName.',
          );
        }
        return data[variableName];
    }
  }

  String _formatDateTimeValue(Object? value, String pattern) {
    if (value == null) return expressionErrorMarker;
    final formatFunction = expressionEngine.functions['format'];
    if (formatFunction == null) return expressionErrorMarker;
    try {
      final formatted = formatFunction(value, [pattern]);
      return formatted == null ? '' : formatted.toString();
    } catch (_) {
      return expressionErrorMarker;
    }
  }
}
