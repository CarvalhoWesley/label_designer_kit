import 'package:label_expression_engine/label_expression_engine.dart';
import 'package:test/test.dart';

void main() {
  group('format()', () {
    test('accepts a DateTime target', () {
      final result = defaultExpressionFunctions['format']!(
        DateTime(2026, 7, 2, 14, 5, 9),
        ['dd/MM/yyyy HH:mm:ss'],
      );
      expect(result, '02/07/2026 14:05:09');
    });

    test('accepts an ISO-8601 String target', () {
      final result = defaultExpressionFunctions['format']!(
        '2026-07-02T00:00:00.000',
        ['yyyy-MM-dd'],
      );
      expect(result, '2026-07-02');
    });

    test('defaults to dd/MM/yyyy when no pattern is given', () {
      final result = defaultExpressionFunctions['format']!(
        DateTime(2026, 1, 5),
        [],
      );
      expect(result, '05/01/2026');
    });

    test('passes non-token characters through literally', () {
      final result = defaultExpressionFunctions['format']!(
        DateTime(2026, 7, 2),
        ['dd-MM-yyyy'],
      );
      expect(result, '02-07-2026');
    });

    test(
      'quoted text is emitted literally, even if it collides with a token',
      () {
        final result = defaultExpressionFunctions['format']!(
          DateTime(2026, 7, 2),
          ["dd 'de' MM 'de' yyyy"],
        );
        expect(result, '02 de 07 de 2026');
      },
    );

    test('returns null for a null target', () {
      expect(defaultExpressionFunctions['format']!(null, []), isNull);
    });

    test('throws FormatException for an unsupported target type', () {
      expect(
        () => defaultExpressionFunctions['format']!(42, []),
        throwsFormatException,
      );
    });
  });

  group('currency()', () {
    test('formats with thousands and decimal separators (pt-BR)', () {
      expect(
        defaultExpressionFunctions['currency']!(1234.5, []),
        r'R$ 1.234,50',
      );
    });

    test('formats values under 1000 without a thousands separator', () {
      expect(defaultExpressionFunctions['currency']!(9.9, []), r'R$ 9,90');
    });

    test('formats negative values with a leading "-"', () {
      expect(defaultExpressionFunctions['currency']!(-42, []), r'R$ -42,00');
    });

    test('formats millions with multiple grouping separators', () {
      expect(
        defaultExpressionFunctions['currency']!(1234567.89, []),
        r'R$ 1.234.567,89',
      );
    });

    test('accepts a custom symbol argument', () {
      expect(
        defaultExpressionFunctions['currency']!(10, ['US\$']),
        r'US$ 10,00',
      );
    });

    test('returns null for a null target', () {
      expect(defaultExpressionFunctions['currency']!(null, []), isNull);
    });

    test('throws FormatException for a non-numeric target', () {
      expect(
        () => defaultExpressionFunctions['currency']!('abc', []),
        throwsFormatException,
      );
    });
  });
}
