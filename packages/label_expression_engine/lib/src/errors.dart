/// Base type for every error the expression engine can produce.
///
/// Never escapes [ExpressionEngine.evaluate] as a thrown exception — it is
/// always caught and turned into an [ExpressionFailure] instead, so
/// callers (ultimately the Layout Engine) decide what to show for a
/// broken expression instead of crashing.
sealed class ExpressionException implements Exception {
  const ExpressionException(this.message, this.position);

  final String message;

  /// Offset into the original source where the problem was detected.
  final int position;

  @override
  String toString() => '$runtimeType at $position: $message';
}

/// The source text could not be tokenized or parsed into an AST.
class ExpressionSyntaxError extends ExpressionException {
  const ExpressionSyntaxError(super.message, super.position);
}

/// The AST was valid but could not be evaluated against the given data
/// (e.g. an undefined variable, a type mismatch, an unknown function).
class ExpressionEvaluationError extends ExpressionException {
  const ExpressionEvaluationError(super.message, super.position);
}
