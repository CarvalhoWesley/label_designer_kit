import 'package:label_expression_engine/label_expression_engine.dart';
import 'package:test/test.dart';

Object? _valueOf(ExpressionResult result) => switch (result) {
  ExpressionSuccess(:final value) => value,
  ExpressionFailure(:final message) => throw StateError(
    'Expected success, got failure: $message',
  ),
};

String _failureOf(ExpressionResult result) => switch (result) {
  ExpressionSuccess(:final value) => throw StateError(
    'Expected failure, got success: $value',
  ),
  ExpressionFailure(:final message) => message,
};

void main() {
  const engine = ExpressionEngine();

  group('examples from docs/ARCHITECTURE.md section 10', () {
    test('{{ preco }}', () {
      final result = engine.evaluate('preco', {'preco': 3.9});
      expect(_valueOf(result), 3.9);
    });

    test('{{ preco * quantidade }}', () {
      final result = engine.evaluate('preco * quantidade', {
        'preco': 3.9,
        'quantidade': 2,
      });
      expect(_valueOf(result), closeTo(7.8, 1e-9));
    });

    test('{{ estoque == 0 ? "SEM ESTOQUE" : "" }} when out of stock', () {
      final result = engine.evaluate('estoque == 0 ? "SEM ESTOQUE" : ""', {
        'estoque': 0,
      });
      expect(_valueOf(result), 'SEM ESTOQUE');
    });

    test('{{ estoque == 0 ? "SEM ESTOQUE" : "" }} when in stock', () {
      final result = engine.evaluate('estoque == 0 ? "SEM ESTOQUE" : ""', {
        'estoque': 15,
      });
      expect(_valueOf(result), '');
    });

    test('{{ data.format("dd/MM/yyyy") }}', () {
      final result = engine.evaluate('data.format("dd/MM/yyyy")', {
        'data': DateTime(2026, 7, 2),
      });
      expect(_valueOf(result), '02/07/2026');
    });

    test('{{ preco.currency() }}', () {
      final result = engine.evaluate('preco.currency()', {'preco': 1234.5});
      expect(_valueOf(result), r'R$ 1.234,50');
    });

    test('{{ produto.nome }}', () {
      final result = engine.evaluate('produto.nome', {
        'produto': {'nome': 'Parafuso M6'},
      });
      expect(_valueOf(result), 'Parafuso M6');
    });
  });

  group('undefined variables and safe navigation', () {
    test('an undeclared top-level variable is a failure', () {
      final result = engine.evaluate('precoo', {'preco': 1});
      expect(_failureOf(result), contains('precoo'));
    });

    test('property access on a null target returns null, not a failure', () {
      final result = engine.evaluate('cliente.endereco', {'cliente': null});
      expect(_valueOf(result), isNull);
    });

    test('a missing key in a present map resolves to null', () {
      final result = engine.evaluate('produto.apelido', {
        'produto': {'nome': 'Parafuso'},
      });
      expect(_valueOf(result), isNull);
    });
  });

  group('type errors surface as ExpressionFailure, not exceptions', () {
    test('arithmetic on non-numbers fails gracefully', () {
      final result = engine.evaluate('preco + 1', {'preco': 'abc'});
      expect(result, isA<ExpressionFailure>());
    });

    test('&& on non-booleans fails gracefully', () {
      final result = engine.evaluate('a && b', {'a': 1, 'b': true});
      expect(result, isA<ExpressionFailure>());
    });

    test('a syntax error fails gracefully instead of throwing', () {
      expect(() => engine.evaluate('1 +', {}), returnsNormally);
      expect(engine.evaluate('1 +', {}), isA<ExpressionFailure>());
    });

    test('calling an unregistered function fails gracefully', () {
      final result = engine.evaluate('preco.discount(10)', {'preco': 100});
      expect(_failureOf(result), contains('discount'));
    });
  });

  group('logical short-circuiting', () {
    test('&& does not evaluate the right side when the left is false', () {
      final result = engine.evaluate('falso && indefinida', {'falso': false});
      expect(_valueOf(result), false);
    });

    test('|| does not evaluate the right side when the left is true', () {
      final result = engine.evaluate('verdadeiro || indefinida', {
        'verdadeiro': true,
      });
      expect(_valueOf(result), true);
    });
  });

  group('custom functions (Strategy pattern)', () {
    test('a custom function map can add new functions', () {
      final custom = ExpressionEngine(
        functions: {
          ...defaultExpressionFunctions,
          'upper': (target, args) => (target as String).toUpperCase(),
        },
      );
      final result = custom.evaluate('nome.upper()', {'nome': 'parafuso'});
      expect(_valueOf(result), 'PARAFUSO');
    });

    test('a custom function map can override a built-in function', () {
      final custom = ExpressionEngine(
        functions: {
          ...defaultExpressionFunctions,
          'currency': (target, args) => 'USD ${target.toString()}',
        },
      );
      final result = custom.evaluate('preco.currency()', {'preco': 10});
      expect(_valueOf(result), 'USD 10');
    });
  });

  group('literals', () {
    test('booleans and null literals evaluate to themselves', () {
      expect(_valueOf(engine.evaluate('true', {})), true);
      expect(_valueOf(engine.evaluate('false', {})), false);
      expect(_valueOf(engine.evaluate('null', {})), isNull);
    });

    test('numeric equality treats 1 and 1.0 as equal, like Dart num', () {
      expect(_valueOf(engine.evaluate('1 == 1.0', {})), true);
    });
  });
}
