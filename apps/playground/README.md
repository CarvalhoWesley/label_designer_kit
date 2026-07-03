# playground

Sandbox interno do workspace — **não é um entregável**. O projeto do
usuário nunca importa este app; ele existe só para rodar `LabelDesigner`
de ponta a ponta durante o desenvolvimento (ver `docs/ARCHITECTURE.md`,
seção 4, e `docs/ROADMAP.md`, etapas 14 e 17).

Abre `LabelDesigner` com um documento de exemplo (borda, texto com
`{{ produto }}`, código de barras rotacionado) já preenchendo as
variáveis declaradas com valores de amostra, então grade/preview/painel
de propriedades mostram algo útil imediatamente.

"Salvar" exercita o pipeline completo que um projeto consumidor rodaria
na hora de exportar/imprimir (ver `docs/ARCHITECTURE.md`, seção 20):

1. codifica o `LabelDocument` via `label_serialization` (JSON no console);
2. resolve via `LabelLayoutEngine`, usando os valores de amostra já
   declarados nas variáveis do documento;
3. renderiza o documento resolvido em **dois** backends reais —
   `label_renderer_pdf` (PDF vetorial) e `label_renderer_argox` (comandos
   PPLA) — e mostra o tamanho de cada saída num snackbar.

Não grava em disco nem envia nada a uma impressora de verdade — isso é
responsabilidade do projeto consumidor, não deste framework.

Rodar:

```
melos exec --scope=playground -- flutter run -d chrome
```
