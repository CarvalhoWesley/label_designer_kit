import '../ast/expr.dart';
import '../errors.dart';
import 'default_functions.dart';
import 'expression_function.dart';

/// Walks an [Expr] tree and produces a value against a data context.
///
/// Null handling: an undeclared top-level identifier (e.g. a typo'd
/// variable name) throws [ExpressionEvaluationError], since that is almost
/// always a template bug. Accessing a property on a `null` target instead
/// returns `null` (safe navigation), since optional nested fields are a
/// normal, expected shape for row data — e.g. `cliente.endereco.numero`
/// when `endereco` is legitimately absent for a given row.
class Evaluator {
  const Evaluator({this.functions = defaultExpressionFunctions});

  final Map<String, ExpressionFunction> functions;

  Object? evaluate(Expr expr, Map<String, dynamic> data) {
    return switch (expr) {
      LiteralExpr(:final value) => value,
      IdentifierExpr(:final name) => _lookupIdentifier(name, data),
      PropertyAccessExpr(:final target, :final property) => _propertyAccess(
        target,
        property,
        data,
      ),
      MethodCallExpr(:final target, :final methodName, :final arguments) =>
        _methodCall(target, methodName, arguments, data),
      UnaryExpr(:final operatorSymbol, :final operand) => _unary(
        operatorSymbol,
        operand,
        data,
      ),
      BinaryExpr(:final operatorSymbol, :final left, :final right) => _binary(
        operatorSymbol,
        left,
        right,
        data,
      ),
      ConditionalExpr(:final condition, :final whenTrue, :final whenFalse) =>
        _conditional(condition, whenTrue, whenFalse, data),
    };
  }

  Object? _lookupIdentifier(String name, Map<String, dynamic> data) {
    if (!data.containsKey(name)) {
      throw ExpressionEvaluationError('Variável "$name" não definida', 0);
    }
    return data[name];
  }

  Object? _propertyAccess(
    Expr targetExpr,
    String property,
    Map<String, dynamic> data,
  ) {
    final target = evaluate(targetExpr, data);
    if (target == null) return null;
    if (target is! Map) {
      throw ExpressionEvaluationError(
        'Não é possível acessar a propriedade "$property" em um valor do '
        'tipo ${target.runtimeType}',
        0,
      );
    }
    return target[property];
  }

  Object? _methodCall(
    Expr targetExpr,
    String methodName,
    List<Expr> argumentExprs,
    Map<String, dynamic> data,
  ) {
    final target = evaluate(targetExpr, data);
    final function = functions[methodName];
    if (function == null) {
      throw ExpressionEvaluationError('Função "$methodName" não registrada', 0);
    }
    final arguments = argumentExprs
        .map((argument) => evaluate(argument, data))
        .toList();
    try {
      return function(target, arguments);
    } on ExpressionException {
      rethrow;
    } catch (error) {
      throw ExpressionEvaluationError(
        'Erro ao chamar "$methodName()": $error',
        0,
      );
    }
  }

  Object? _unary(
    String operatorSymbol,
    Expr operandExpr,
    Map<String, dynamic> data,
  ) {
    final operand = evaluate(operandExpr, data);
    switch (operatorSymbol) {
      case '-':
        if (operand is num) return -operand;
        throw ExpressionEvaluationError(
          'Operador unário "-" espera um número, recebeu ${operand.runtimeType}',
          0,
        );
      case '!':
        if (operand is bool) return !operand;
        throw ExpressionEvaluationError(
          'Operador unário "!" espera um booleano, recebeu ${operand.runtimeType}',
          0,
        );
      default:
        throw ExpressionEvaluationError(
          'Operador unário desconhecido "$operatorSymbol"',
          0,
        );
    }
  }

  Object? _binary(
    String operatorSymbol,
    Expr leftExpr,
    Expr rightExpr,
    Map<String, dynamic> data,
  ) {
    switch (operatorSymbol) {
      case '&&':
        final left = _requireBool(evaluate(leftExpr, data), '&&');
        if (!left) return false;
        return _requireBool(evaluate(rightExpr, data), '&&');
      case '||':
        final left = _requireBool(evaluate(leftExpr, data), '||');
        if (left) return true;
        return _requireBool(evaluate(rightExpr, data), '||');
      case '==':
        return evaluate(leftExpr, data) == evaluate(rightExpr, data);
      case '!=':
        return evaluate(leftExpr, data) != evaluate(rightExpr, data);
    }

    final left = evaluate(leftExpr, data);
    final right = evaluate(rightExpr, data);

    switch (operatorSymbol) {
      case '+':
        return _requireNum(left, '+') + _requireNum(right, '+');
      case '-':
        return _requireNum(left, '-') - _requireNum(right, '-');
      case '*':
        return _requireNum(left, '*') * _requireNum(right, '*');
      case '/':
        return _requireNum(left, '/') / _requireNum(right, '/');
      case '%':
        return _requireNum(left, '%') % _requireNum(right, '%');
      case '<':
        return _requireNum(left, '<') < _requireNum(right, '<');
      case '<=':
        return _requireNum(left, '<=') <= _requireNum(right, '<=');
      case '>':
        return _requireNum(left, '>') > _requireNum(right, '>');
      case '>=':
        return _requireNum(left, '>=') >= _requireNum(right, '>=');
      default:
        throw ExpressionEvaluationError(
          'Operador desconhecido "$operatorSymbol"',
          0,
        );
    }
  }

  Object? _conditional(
    Expr conditionExpr,
    Expr whenTrueExpr,
    Expr whenFalseExpr,
    Map<String, dynamic> data,
  ) {
    final condition = _requireBool(evaluate(conditionExpr, data), '?:');
    return condition
        ? evaluate(whenTrueExpr, data)
        : evaluate(whenFalseExpr, data);
  }

  num _requireNum(Object? value, String operatorSymbol) {
    if (value is num) return value;
    throw ExpressionEvaluationError(
      'Operador "$operatorSymbol" espera números, recebeu ${value.runtimeType}',
      0,
    );
  }

  bool _requireBool(Object? value, String operatorSymbol) {
    if (value is bool) return value;
    throw ExpressionEvaluationError(
      'Operador "$operatorSymbol" espera booleanos, recebeu ${value.runtimeType}',
      0,
    );
  }
}
