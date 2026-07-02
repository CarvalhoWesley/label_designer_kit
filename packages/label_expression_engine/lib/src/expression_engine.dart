import 'errors.dart';
import 'evaluation/default_functions.dart';
import 'evaluation/evaluator.dart';
import 'evaluation/expression_function.dart';
import 'expression_result.dart';
import 'lexer/tokenizer.dart';
import 'parsing/parser.dart';

/// Public entry point of the expression engine: tokenizes, parses and
/// evaluates a single expression body (the part inside `{{ }}`, without
/// the braces themselves — scanning literal text for placeholders is the
/// Layout Engine's job, since it also decides how to handle failures).
///
/// Never throws: every failure, from a syntax error to an undefined
/// variable, comes back as an [ExpressionFailure].
class ExpressionEngine {
  const ExpressionEngine({this.functions = defaultExpressionFunctions});

  /// Functions callable as `target.name(args)`, e.g. `format`/`currency`.
  /// Pass a custom map (optionally spreading [defaultExpressionFunctions])
  /// to add or override functions without touching this package.
  final Map<String, ExpressionFunction> functions;

  ExpressionResult evaluate(String source, Map<String, dynamic> data) {
    try {
      final tokens = Tokenizer(source).tokenize();
      final ast = Parser(tokens).parse();
      final value = Evaluator(functions: functions).evaluate(ast, data);
      return ExpressionSuccess(value);
    } on ExpressionException catch (error) {
      return ExpressionFailure(error.message);
    } on FormatException catch (error) {
      // Thrown by num.parse on malformed numeric literals.
      return ExpressionFailure(error.message);
    }
  }
}
