# label_history

Command Pattern e undo/redo sobre `LabelDocument`. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 13.

Pacote Dart puro: não conhece MobX nem UI. Cada `Command` é uma função pura `LabelDocument -> LabelDocument` — `execute`/`undo` produzem uma nova versão do documento via `copyWith`, nunca mutam o documento nem nenhum elemento em lugar.

## Uso

```dart
final history = HistoryManager(document);

history.execute(MoveCommand(elementId: 'el-1', from: oldPosition, to: newPosition));
history.undo(); // volta para oldPosition
history.redo(); // aplica newPosition de novo

history.canUndo; // bool
history.canRedo; // bool
history.document; // LabelDocument atual
```

Comandos disponíveis: `MoveCommand`, `ResizeCommand`, `RotateCommand`, `ChangePropertyCommand<T>`, `AddCommand`, `DeleteCommand` (construído via `DeleteCommand.capture(document, elementId)`, que registra onde o elemento estava para o `undo` restaurá-lo no mesmo lugar — inclusive dentro de um `GroupElement`).

`ChangePropertyCommand<T>` cobre qualquer propriedade específica de um subtipo de `LabelElement` (ex.: `TextElement.content`) via uma closure `apply` fornecida pelo chamador, já que cada subtipo tem seu próprio `copyWith`:

```dart
history.execute(ChangePropertyCommand<String>(
  elementId: 'el-1',
  oldValue: 'Antes',
  newValue: 'Depois',
  apply: (element, value) => (element as TextElement).copyWith(content: value),
));
```

## Testes

```
dart test
```
