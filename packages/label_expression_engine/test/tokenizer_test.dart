import 'package:label_expression_engine/label_expression_engine.dart';
import 'package:test/test.dart';

List<TokenType> _types(String source) =>
    Tokenizer(source).tokenize().map((token) => token.type).toList();

void main() {
  group('Tokenizer', () {
    test('tokenizes a bare identifier', () {
      expect(_types('preco'), [TokenType.identifier, TokenType.eof]);
    });

    test('tokenizes an integer literal', () {
      final tokens = Tokenizer('42').tokenize();
      expect(tokens[0].type, TokenType.number);
      expect(tokens[0].value, 42);
    });

    test('tokenizes a decimal literal', () {
      final tokens = Tokenizer('3.5').tokenize();
      expect(tokens[0].value, 3.5);
    });

    test('tokenizes a double-quoted string, unescaping \\"', () {
      final tokens = Tokenizer(r'"SEM \"ESTOQUE\""').tokenize();
      expect(tokens[0].type, TokenType.string);
      expect(tokens[0].value, 'SEM "ESTOQUE"');
    });

    test('tokenizes true/false/null as keywords, not identifiers', () {
      expect(_types('true'), [TokenType.trueKeyword, TokenType.eof]);
      expect(_types('false'), [TokenType.falseKeyword, TokenType.eof]);
      expect(_types('null'), [TokenType.nullKeyword, TokenType.eof]);
    });

    test('tokenizes every operator', () {
      const source = '+ - * / % == != < <= > >= && || ! ? : . , ( )';
      expect(_types(source), [
        TokenType.plus,
        TokenType.minus,
        TokenType.star,
        TokenType.slash,
        TokenType.percent,
        TokenType.equalEqual,
        TokenType.notEqual,
        TokenType.less,
        TokenType.lessEqual,
        TokenType.greater,
        TokenType.greaterEqual,
        TokenType.andAnd,
        TokenType.orOr,
        TokenType.not,
        TokenType.question,
        TokenType.colon,
        TokenType.dot,
        TokenType.comma,
        TokenType.leftParen,
        TokenType.rightParen,
        TokenType.eof,
      ]);
    });

    test('ignores surrounding and internal whitespace', () {
      expect(_types('  preco   *   quantidade  '), [
        TokenType.identifier,
        TokenType.star,
        TokenType.identifier,
        TokenType.eof,
      ]);
    });

    test('produces a dotted path as identifier, dot, identifier tokens', () {
      expect(_types('produto.nome'), [
        TokenType.identifier,
        TokenType.dot,
        TokenType.identifier,
        TokenType.eof,
      ]);
    });

    test('throws ExpressionSyntaxError for an unexpected character', () {
      expect(
        () => Tokenizer('preco @ 1').tokenize(),
        throwsA(isA<ExpressionSyntaxError>()),
      );
    });

    test('throws ExpressionSyntaxError for an unterminated string', () {
      expect(
        () => Tokenizer('"sem fim').tokenize(),
        throwsA(isA<ExpressionSyntaxError>()),
      );
    });

    test('throws ExpressionSyntaxError for a lone "&"', () {
      expect(
        () => Tokenizer('a & b').tokenize(),
        throwsA(isA<ExpressionSyntaxError>()),
      );
    });
  });
}
