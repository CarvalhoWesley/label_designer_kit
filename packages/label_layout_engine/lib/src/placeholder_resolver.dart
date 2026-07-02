import 'package:label_expression_engine/label_expression_engine.dart';

final RegExp _placeholderPattern = RegExp(r'\{\{(.*?)\}\}');

/// Marker substituted for a placeholder whose expression failed to
/// evaluate against the current row's data (undefined variable, type
/// error, syntax error). Kept visible on purpose — a silently blank field
/// is much harder to notice on a printed label than `#ERROR#`.
const String expressionErrorMarker = '#ERROR#';

/// Scans [template] for `{{ expression }}` placeholders, evaluates each
/// one against [data] and substitutes the result, leaving surrounding
/// literal text untouched.
///
/// This is the one place in the framework that understands the `{{ }}`
/// delimiters themselves — [ExpressionEngine] only ever sees the bare
/// expression body inside them. Used for [TextElement.content],
/// [BarcodeElement.data], [QRCodeElement.data] and [ImageElement.source],
/// all of which may mix literal text with placeholders (e.g.
/// `"Lote: {{ lote }}"`).
String resolvePlaceholders(
  String template,
  Map<String, dynamic> data,
  ExpressionEngine expressionEngine,
) {
  if (!template.contains('{{')) return template;

  return template.replaceAllMapped(_placeholderPattern, (match) {
    final expressionSource = match.group(1)!.trim();
    final result = expressionEngine.evaluate(expressionSource, data);
    return switch (result) {
      ExpressionSuccess(:final value) => _stringify(value),
      ExpressionFailure() => expressionErrorMarker,
    };
  });
}

String _stringify(Object? value) => value == null ? '' : value.toString();
