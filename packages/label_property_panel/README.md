# label_property_panel

Painel de propriedades do editor: edição reativa dos campos do(s)
elemento(s) selecionado(s) no canvas.

Estados:

- **Sem seleção**: mensagem vazia.
- **Um elemento selecionado**: seção comum (nome, camada, posição, tamanho,
  rotação, opacidade, visível, bloqueado) + seção específica do tipo
  (`TextElement`, `BarcodeElement`, `RectangleElement`, ...), despachada via
  `LabelElementVisitor`.
- **Múltiplos elementos selecionados**: apenas os campos que fazem sentido
  aplicar a todos de uma vez (visível, bloqueado, opacidade), como um único
  passo de undo (`PropertyStore.changeProperties`).

Toda edição passa por `PropertyStore` (de `label_designer_state`), que
despacha `ChangePropertyCommand`s através de `HistoryStore` — nenhuma
edição aqui muta `LabelDocument` diretamente. Este pacote nunca calcula
layout nem importa `label_layout_engine`/`label_renderer_*`.

Ver `docs/ARCHITECTURE.md`, seções 7 e 14.
