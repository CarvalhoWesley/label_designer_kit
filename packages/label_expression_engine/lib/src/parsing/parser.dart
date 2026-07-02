import '../ast/expr.dart';
import '../errors.dart';
import '../lexer/token.dart';

/// Recursive-descent parser producing an [Expr] tree from the tokens
/// scanned by `Tokenizer`.
///
/// Precedence, lowest to highest: ternary, `||`, `&&`, `==`/`!=`,
/// `<`/`<=`/`>`/`>=`, `+`/`-`, `*`/`/`/`%`, unary `-`/`!`, postfix
/// (`.property`, `.method(args)`), primary.
class Parser {
  Parser(this._tokens);

  final List<Token> _tokens;
  int _position = 0;

  /// Parses the entire token stream as a single expression. Throws
  /// [ExpressionSyntaxError] if trailing tokens remain after a complete
  /// expression (e.g. `1 2`).
  Expr parse() {
    final expr = _conditional();
    if (!_isAtEnd) {
      throw ExpressionSyntaxError(
        'Token inesperado "${_peek().lexeme}" após o fim da expressão',
        _peek().position,
      );
    }
    return expr;
  }

  Expr _conditional() {
    final condition = _or();
    if (_match(TokenType.question)) {
      final whenTrue = _conditional();
      _consume(TokenType.colon, 'Esperado ":" no operador ternário');
      final whenFalse = _conditional();
      return ConditionalExpr(condition, whenTrue, whenFalse);
    }
    return condition;
  }

  Expr _or() => _leftAssociativeBinary(_and, {TokenType.orOr: '||'});

  Expr _and() => _leftAssociativeBinary(_equality, {TokenType.andAnd: '&&'});

  Expr _equality() => _leftAssociativeBinary(_comparison, {
    TokenType.equalEqual: '==',
    TokenType.notEqual: '!=',
  });

  Expr _comparison() => _leftAssociativeBinary(_additive, {
    TokenType.less: '<',
    TokenType.lessEqual: '<=',
    TokenType.greater: '>',
    TokenType.greaterEqual: '>=',
  });

  Expr _additive() => _leftAssociativeBinary(_multiplicative, {
    TokenType.plus: '+',
    TokenType.minus: '-',
  });

  Expr _multiplicative() => _leftAssociativeBinary(_unary, {
    TokenType.star: '*',
    TokenType.slash: '/',
    TokenType.percent: '%',
  });

  Expr _leftAssociativeBinary(
    Expr Function() operand,
    Map<TokenType, String> operators,
  ) {
    var expr = operand();
    while (true) {
      final match = operators.entries
          .where((entry) => _check(entry.key))
          .firstOrNull;
      if (match == null) return expr;
      _advance();
      final right = operand();
      expr = BinaryExpr(match.value, expr, right);
    }
  }

  Expr _unary() {
    if (_match(TokenType.minus)) return UnaryExpr('-', _unary());
    if (_match(TokenType.not)) return UnaryExpr('!', _unary());
    return _postfix();
  }

  Expr _postfix() {
    var expr = _primary();
    while (true) {
      if (_match(TokenType.dot)) {
        final name = _consume(
          TokenType.identifier,
          'Esperado um nome de propriedade após "."',
        ).lexeme;
        if (_match(TokenType.leftParen)) {
          final arguments = _arguments();
          expr = MethodCallExpr(expr, name, arguments);
        } else {
          expr = PropertyAccessExpr(expr, name);
        }
      } else {
        return expr;
      }
    }
  }

  List<Expr> _arguments() {
    final arguments = <Expr>[];
    if (!_check(TokenType.rightParen)) {
      do {
        arguments.add(_conditional());
      } while (_match(TokenType.comma));
    }
    _consume(TokenType.rightParen, 'Esperado ")" após os argumentos');
    return arguments;
  }

  Expr _primary() {
    final token = _peek();
    switch (token.type) {
      case TokenType.number:
        _advance();
        return LiteralExpr(token.value);
      case TokenType.string:
        _advance();
        return LiteralExpr(token.value);
      case TokenType.trueKeyword:
        _advance();
        return const LiteralExpr(true);
      case TokenType.falseKeyword:
        _advance();
        return const LiteralExpr(false);
      case TokenType.nullKeyword:
        _advance();
        return const LiteralExpr(null);
      case TokenType.identifier:
        _advance();
        return IdentifierExpr(token.lexeme);
      case TokenType.leftParen:
        _advance();
        final expr = _conditional();
        _consume(TokenType.rightParen, 'Esperado ")" para fechar o grupo');
        return expr;
      default:
        throw ExpressionSyntaxError(
          'Token inesperado "${token.lexeme}"',
          token.position,
        );
    }
  }

  bool _match(TokenType type) {
    if (!_check(type)) return false;
    _advance();
    return true;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw ExpressionSyntaxError(message, _peek().position);
  }

  bool _check(TokenType type) => _peek().type == type;

  Token _advance() => _tokens[_position++];

  Token _peek() => _tokens[_position];

  bool get _isAtEnd => _peek().type == TokenType.eof;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
