/// The parsed representation of an expression, produced by `Parser` and
/// walked by `Evaluator`.
///
/// `sealed` so the evaluator's `switch` over [Expr] is checked exhaustively
/// by the compiler when a new node type is added.
sealed class Expr {
  const Expr();
}

/// A literal number, string, boolean or `null`.
class LiteralExpr extends Expr {
  const LiteralExpr(this.value);
  final Object? value;

  @override
  String toString() => 'Literal($value)';
}

/// A bare variable reference, e.g. `preco` in `preco * quantidade`.
class IdentifierExpr extends Expr {
  const IdentifierExpr(this.name);
  final String name;

  @override
  String toString() => 'Identifier($name)';
}

/// `target.property`, e.g. `produto.nome`.
class PropertyAccessExpr extends Expr {
  const PropertyAccessExpr(this.target, this.property);
  final Expr target;
  final String property;

  @override
  String toString() => 'PropertyAccess($target.$property)';
}

/// `target.methodName(arguments)`, e.g. `preco.currency()` or
/// `data.format("dd/MM/yyyy")`.
class MethodCallExpr extends Expr {
  const MethodCallExpr(this.target, this.methodName, this.arguments);
  final Expr target;
  final String methodName;
  final List<Expr> arguments;

  @override
  String toString() => 'MethodCall($target.$methodName($arguments))';
}

/// A prefix unary operator: `-value` or `!condition`.
class UnaryExpr extends Expr {
  const UnaryExpr(this.operatorSymbol, this.operand);
  final String operatorSymbol;
  final Expr operand;

  @override
  String toString() => 'Unary($operatorSymbol$operand)';
}

/// A binary operator: arithmetic, comparison, equality or logical.
class BinaryExpr extends Expr {
  const BinaryExpr(this.operatorSymbol, this.left, this.right);
  final String operatorSymbol;
  final Expr left;
  final Expr right;

  @override
  String toString() => 'Binary($left $operatorSymbol $right)';
}

/// `condition ? whenTrue : whenFalse`.
class ConditionalExpr extends Expr {
  const ConditionalExpr(this.condition, this.whenTrue, this.whenFalse);
  final Expr condition;
  final Expr whenTrue;
  final Expr whenFalse;

  @override
  String toString() => 'Conditional($condition ? $whenTrue : $whenFalse)';
}
