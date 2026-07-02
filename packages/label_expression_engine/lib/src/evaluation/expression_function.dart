/// A function callable from an expression as `target.name(args)`, e.g.
/// `preco.currency()` or `data.format("dd/MM/yyyy")`.
///
/// Registered by name in a `Map<String, ExpressionFunction>` (Strategy
/// pattern) so new functions — or app-specific overrides of the built-in
/// ones — never require changing the parser or evaluator.
typedef ExpressionFunction =
    Object? Function(Object? target, List<Object?> arguments);
