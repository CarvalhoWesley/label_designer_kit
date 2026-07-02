/// Parser desacoplado de expressões (`{{ preco * quantidade }}`,
/// `{{ estoque == 0 ? "SEM ESTOQUE" : "" }}`, `{{ data.format("dd/MM/yyyy") }}`).
///
/// Pacote Dart puro — sem dependência de `label_core`, Flutter ou
/// impressoras. Ver `docs/ARCHITECTURE.md` seção 10.
library;

export 'src/ast/expr.dart';
export 'src/errors.dart';
export 'src/evaluation/default_functions.dart';
export 'src/evaluation/evaluator.dart';
export 'src/evaluation/expression_function.dart';
export 'src/expression_engine.dart';
export 'src/expression_result.dart';
export 'src/lexer/token.dart';
export 'src/lexer/tokenizer.dart';
export 'src/parsing/parser.dart';
