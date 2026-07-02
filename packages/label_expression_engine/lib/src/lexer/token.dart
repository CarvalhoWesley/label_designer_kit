enum TokenType {
  number,
  string,
  identifier,
  trueKeyword,
  falseKeyword,
  nullKeyword,
  plus,
  minus,
  star,
  slash,
  percent,
  equalEqual,
  notEqual,
  less,
  lessEqual,
  greater,
  greaterEqual,
  andAnd,
  orOr,
  not,
  question,
  colon,
  dot,
  comma,
  leftParen,
  rightParen,
  eof,
}

/// A single lexical token produced by [Tokenizer].
class Token {
  const Token(this.type, this.lexeme, this.position, [this.value]);

  final TokenType type;

  /// The raw source text this token was scanned from.
  final String lexeme;

  /// Offset into the source string where this token starts, used for
  /// error messages.
  final int position;

  /// The parsed literal value for [TokenType.number] and
  /// [TokenType.string] tokens.
  final Object? value;

  @override
  String toString() => 'Token($type, "$lexeme")';
}
