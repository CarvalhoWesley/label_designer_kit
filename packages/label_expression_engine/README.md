# label_expression_engine

Parser e avaliador desacoplado de expressões — a linguagem por trás de `{{ preco * quantidade }}`, `{{ estoque == 0 ? "SEM ESTOQUE" : "" }}`, `{{ data.format("dd/MM/yyyy") }}`. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 10.

Pacote Dart puro — sem dependência de `label_core`, Flutter ou impressoras. Avalia apenas o corpo da expressão (sem as chaves `{{ }}`); varrer um texto livre em busca de placeholders é responsabilidade do `label_layout_engine`.

## Uso

```dart
const engine = ExpressionEngine();

final result = engine.evaluate('preco * quantidade', {'preco': 3.9, 'quantidade': 2});

switch (result) {
  case ExpressionSuccess(:final value):
    print(value); // 7.8
  case ExpressionFailure(:final message):
    print('Erro: $message');
}
```

`evaluate` nunca lança exceção — todo erro (sintaxe, variável indefinida, tipo incompatível) volta como `ExpressionFailure`, para quem chama decidir o que exibir.

Funções chamáveis como `alvo.nome(args)` (`format`, `currency`) ficam em `defaultExpressionFunctions` e podem ser estendidas ou sobrescritas:

```dart
final engine = ExpressionEngine(functions: {
  ...defaultExpressionFunctions,
  'upper': (target, args) => (target as String).toUpperCase(),
});
```

## Testes

```
dart test
```
