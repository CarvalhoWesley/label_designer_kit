import 'package:label_expression_engine/label_expression_engine.dart';
import 'package:test/test.dart';

Expr _parse(String source) => Parser(Tokenizer(source).tokenize()).parse();

void main() {
  group('Parser precedence', () {
    test('* binds tighter than +', () {
      final expr = _parse('1 + 2 * 3') as BinaryExpr;
      expect(expr.operatorSymbol, '+');
      expect(expr.left, isA<LiteralExpr>());
      final right = expr.right as BinaryExpr;
      expect(right.operatorSymbol, '*');
    });

    test('comparison binds tighter than equality', () {
      final expr = _parse('a < b == c') as BinaryExpr;
      expect(expr.operatorSymbol, '==');
      expect((expr.left as BinaryExpr).operatorSymbol, '<');
    });

    test('&& binds tighter than ||', () {
      final expr = _parse('a || b && c') as BinaryExpr;
      expect(expr.operatorSymbol, '||');
      expect((expr.right as BinaryExpr).operatorSymbol, '&&');
    });

    test('ternary has the lowest precedence and is right-associative', () {
      final expr = _parse('a ? b : c ? d : e') as ConditionalExpr;
      expect(expr.condition, isA<IdentifierExpr>());
      expect(expr.whenFalse, isA<ConditionalExpr>());
    });

    test('parentheses override default precedence', () {
      final expr = _parse('(1 + 2) * 3') as BinaryExpr;
      expect(expr.operatorSymbol, '*');
      expect((expr.left as BinaryExpr).operatorSymbol, '+');
    });

    test('unary minus binds tighter than binary operators', () {
      final expr = _parse('-a + b') as BinaryExpr;
      expect(expr.left, isA<UnaryExpr>());
    });

    test('left-associative binary operators nest to the left', () {
      final expr = _parse('1 - 2 - 3') as BinaryExpr;
      expect(expr.operatorSymbol, '-');
      expect(expr.left, isA<BinaryExpr>());
      expect(expr.right, isA<LiteralExpr>());
    });
  });

  group('Parser structures', () {
    test('produces PropertyAccessExpr for a dotted path', () {
      final expr = _parse('produto.nome') as PropertyAccessExpr;
      expect((expr.target as IdentifierExpr).name, 'produto');
      expect(expr.property, 'nome');
    });

    test('produces MethodCallExpr with arguments', () {
      final expr = _parse('data.format("dd/MM/yyyy")') as MethodCallExpr;
      expect(expr.methodName, 'format');
      expect(expr.arguments, hasLength(1));
      expect((expr.arguments.single as LiteralExpr).value, 'dd/MM/yyyy');
    });

    test('produces MethodCallExpr with zero arguments', () {
      final expr = _parse('preco.currency()') as MethodCallExpr;
      expect(expr.arguments, isEmpty);
    });

    test('chains property access and method calls', () {
      final expr = _parse('a.b.c()') as MethodCallExpr;
      expect(expr.methodName, 'c');
      expect(expr.target, isA<PropertyAccessExpr>());
    });
  });

  group('Parser errors', () {
    test('throws on trailing tokens after a complete expression', () {
      expect(() => _parse('1 2'), throwsA(isA<ExpressionSyntaxError>()));
    });

    test('throws when a ternary is missing its ":"', () {
      expect(() => _parse('a ? b'), throwsA(isA<ExpressionSyntaxError>()));
    });

    test('throws when a group is missing its closing ")"', () {
      expect(() => _parse('(1 + 2'), throwsA(isA<ExpressionSyntaxError>()));
    });

    test('throws on an empty expression', () {
      expect(() => _parse(''), throwsA(isA<ExpressionSyntaxError>()));
    });
  });
}
