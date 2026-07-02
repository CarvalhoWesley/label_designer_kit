# playground

Sandbox interno do workspace — **não é um entregável**. O projeto do
usuário nunca importa este app; ele existe só para rodar `LabelDesigner`
de ponta a ponta durante o desenvolvimento (ver `docs/ARCHITECTURE.md`,
seção 4, e `docs/ROADMAP.md`, etapa 14).

Abre `LabelDesigner` com um documento de exemplo (borda, texto com
`{{ produto }}`, variável com `.currency()`, código de barras) já
preenchendo as variáveis declaradas com valores de amostra, então
grade/preview/painel de propriedades mostram algo útil imediatamente.
"Salvar" codifica o documento via `label_serialization` e imprime o JSON
no console — não grava em disco nem exercita nenhum
`label_renderer_argox`/`_zebra`/`_tsc`/`_pdf` (esses ainda não existem;
ver etapa 16).

Rodar:

```
melos exec --scope=playground -- flutter run -d chrome
```
