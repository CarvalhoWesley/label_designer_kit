# label_designer

Composição do editor visual completo — o pacote que o projeto do usuário
importa para embutir "o editor de etiquetas" numa tela (ver
`docs/ARCHITECTURE.md`, seção 20).

```dart
LabelDesigner(
  document: meuLabelDocument,
  onSave: (doc) => salvarNoMeuBanco(doc),
)
```

`LabelDesigner` possui internamente todas as stores de
`label_designer_state` (`DocumentStore`, `HistoryStore`, `SelectionStore`,
`ViewportStore`, `CanvasStore`, `PropertyStore`, `LayerStore`), construídas
a partir de `document` na inicialização, e compõe:

- **Toolbar**: desfazer/refazer, adicionar elemento (12 tipos), agrupar/
  desagrupar, trazer para frente/enviar para trás, excluir, duplicar,
  zoom, grade/snap/réguas, salvar.
- **Painel de camadas**: lista de `LabelLayer`s (visibilidade, bloqueio,
  reordenar, camada ativa para novos elementos).
- **Canvas** (`label_canvas`): editor visual central.
- **Painel direito**: alterna entre propriedades (`label_property_panel`)
  e preview ao vivo (`label_preview`).
- **Atalhos de teclado**: Ctrl+Z/Y (desfazer/refazer), Delete/Backspace
  (excluir seleção), Ctrl+D (duplicar), Ctrl+G/Ctrl+Shift+G (agrupar/
  desagrupar), Ctrl+A (selecionar tudo), Escape (limpar seleção).

Não sabe salvar em disco nem imprimir — `onSave` entrega o `LabelDocument`
atual para o app do usuário decidir o que fazer com ele. Nunca importa
nenhum `label_renderer_*` de impressora.
