/// The outcome of [ExpressionEngine.evaluate].
///
/// `sealed` so callers must handle both cases (typically via `switch`).
/// Deciding what a failure *means* for the final label — an empty string,
/// a placeholder like `#ERROR#`, or aborting the print job — is up to the
/// caller (the Layout Engine), never this package.
sealed class ExpressionResult {
  const ExpressionResult();
}

class ExpressionSuccess extends ExpressionResult {
  const ExpressionSuccess(this.value);

  final Object? value;

  @override
  String toString() => 'ExpressionSuccess($value)';
}

class ExpressionFailure extends ExpressionResult {
  const ExpressionFailure(this.message);

  final String message;

  @override
  String toString() => 'ExpressionFailure($message)';
}
