# label_designer_state

Stores MobX que orquestram documento, seleção, histórico, camadas e viewport do editor. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 14.

Pacote Dart puro: nenhum widget, nenhuma dependência de Flutter. Cada store é testável com `mobx` + `test` isoladamente.

## Stores

| Store | Responsabilidade |
|---|---|
| `DocumentStore` | Fonte da verdade do `LabelDocument` atual (`document`, `elements`, `layers`, `styles`, `variables`) |
| `HistoryStore` | Fachada reativa sobre `HistoryManager` (`execute`/`undo`/`redo`, `canUndo`/`canRedo`, `loadDocument`, `loadFromJson`/`encodeToJson`) |
| `SelectionStore` | Ids selecionados, seleção múltipla (`select`, `toggle`, `selectAll`, `clear`) |
| `PropertyStore` | Deriva `selectedElements`/`singleSelectedElement` a partir de `DocumentStore` + `SelectionStore`; despacha `ChangePropertyCommand` via `changeProperty<T>` |
| `LayerStore` | Ordem, visibilidade e lock de camadas, undo-áveis via `ChangeDocumentCommand` |
| `ViewportStore` | Zoom, pan, grid, snap, réguas — estado de sessão, **não** passa por `HistoryStore` |
| `CanvasStore` | Estado efêmero de interação (drag em andamento, handle de resize ativo, guides ativas) |

## Uso

```dart
final documentStore = DocumentStore(LabelDocument.blank());
final historyStore = HistoryStore(documentStore);
final selectionStore = SelectionStore();
final propertyStore = PropertyStore(documentStore, selectionStore, historyStore);
final layerStore = LayerStore(documentStore, historyStore);

historyStore.execute(AddCommand(element: someElement));
selectionStore.select(someElement.id);
propertyStore.changeProperty<String>(
  elementId: someElement.id,
  oldValue: 'Antes',
  newValue: 'Depois',
  apply: (element, value) => (element as TextElement).copyWith(content: value),
);

historyStore.undo();
```

Toda edição (elementos e camadas) passa por `HistoryStore`, então é undo-ável por construção — ver seção 15 da arquitetura.

## Codegen

Os stores usam `part 'x_store.g.dart'` (mobx_codegen). Depois de editar um store:

```
dart run build_runner build --delete-conflicting-outputs
```

## Testes

```
dart test
```
