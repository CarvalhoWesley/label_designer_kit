import 'expression_function.dart';

/// Built-in functions available to every expression unless overridden.
///
/// Pass a custom map to `ExpressionEngine` (optionally spreading these in)
/// to add app-specific functions or replace `format`/`currency` with a
/// locale-aware implementation (e.g. backed by `package:intl`) without
/// touching the parser or evaluator.
const Map<String, ExpressionFunction> defaultExpressionFunctions = {
  'format': _format,
  'currency': _currency,
};

Object? _format(Object? target, List<Object?> arguments) {
  if (target == null) return null;
  final DateTime date;
  if (target is DateTime) {
    date = target;
  } else if (target is String) {
    date = DateTime.parse(target);
  } else {
    throw FormatException(
      'format() espera um DateTime ou uma String ISO-8601, recebeu ${target.runtimeType}',
    );
  }
  final pattern = arguments.isNotEmpty ? arguments[0] as String : 'dd/MM/yyyy';
  return _formatDate(date, pattern);
}

Object? _currency(Object? target, List<Object?> arguments) {
  if (target == null) return null;
  if (target is! num) {
    throw FormatException(
      'currency() espera um número, recebeu ${target.runtimeType}',
    );
  }
  final symbol = arguments.isNotEmpty ? arguments[0] as String : r'R$';
  return _formatCurrency(target, symbol: symbol);
}

/// Formats [date] according to a small subset of the common `dd/MM/yyyy`
/// style tokens (`yyyy`, `yy`, `MM`, `M`, `dd`, `d`, `HH`, `H`, `mm`, `m`,
/// `ss`, `s`). Any other character passes through unchanged, so
/// separators like `/`, `-` and `:` work without extra handling.
///
/// Text wrapped in single quotes is always emitted literally — needed for
/// words that collide with a token, e.g. `"dd 'de' MMMM"` in Portuguese
/// (a bare `d` would otherwise be read as the day-of-month token). `''`
/// inside a pattern means a literal single quote.
String _formatDate(DateTime date, String pattern) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < pattern.length) {
    final char = pattern[i];
    if (char == "'") {
      i++;
      if (i < pattern.length && pattern[i] == "'") {
        buffer.write("'");
        i++;
        continue;
      }
      final closingQuote = pattern.indexOf("'", i);
      final literalEnd = closingQuote == -1 ? pattern.length : closingQuote;
      buffer.write(pattern.substring(i, literalEnd));
      i = literalEnd + 1;
      continue;
    }

    var runLength = 1;
    while (i + runLength < pattern.length && pattern[i + runLength] == char) {
      runLength++;
    }
    final token = char * runLength;
    buffer.write(_dateToken(token, date) ?? token);
    i += runLength;
  }
  return buffer.toString();
}

String? _dateToken(String token, DateTime date) {
  switch (token) {
    case 'yyyy':
      return date.year.toString().padLeft(4, '0');
    case 'yy':
      return (date.year % 100).toString().padLeft(2, '0');
    case 'MM':
      return date.month.toString().padLeft(2, '0');
    case 'M':
      return date.month.toString();
    case 'dd':
      return date.day.toString().padLeft(2, '0');
    case 'd':
      return date.day.toString();
    case 'HH':
      return date.hour.toString().padLeft(2, '0');
    case 'H':
      return date.hour.toString();
    case 'mm':
      return date.minute.toString().padLeft(2, '0');
    case 'm':
      return date.minute.toString();
    case 'ss':
      return date.second.toString().padLeft(2, '0');
    case 's':
      return date.second.toString();
    default:
      return null;
  }
}

/// Formats [value] as `"R$ 1.234,56"` — thousands separated by `.`,
/// decimals separated by `,`, matching pt-BR conventions.
String _formatCurrency(num value, {required String symbol}) {
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final dotIndex = fixed.indexOf('.');
  final integerPart = fixed.substring(0, dotIndex);
  final decimalPart = fixed.substring(dotIndex + 1);
  final grouped = _groupThousands(integerPart);
  final sign = isNegative ? '-' : '';
  return '$symbol $sign$grouped,$decimalPart';
}

String _groupThousands(String digits) {
  final reversedGroups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    reversedGroups.add(digits.substring(start, end));
  }
  return reversedGroups.reversed.join('.');
}
