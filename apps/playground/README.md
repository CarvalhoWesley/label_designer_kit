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
na hora de salvar/exportar/imprimir (ver `docs/ARCHITECTURE.md`, seção 20):

1. codifica o `LabelDocument` via `label_serialization`;
2. abre um diálogo nativo de "Salvar como" (`file_picker`), sugerindo o
   nome da própria etiqueta como nome de arquivo, e grava o `.label` em
   disco;
3. resolve via `LabelLayoutEngine`, usando os valores de amostra já
   declarados nas variáveis do documento;
4. renderiza o documento resolvido em **dois** backends reais —
   `label_renderer_pdf` (PDF vetorial) e `label_renderer_argox` (comandos
   PPLA) — e mostra o resultado (caminho salvo + tamanho de cada saída)
   num snackbar.

Não envia nada a uma impressora de verdade — isso é responsabilidade do
projeto consumidor, não deste framework.

Rodar (o app só tem suporte à plataforma Windows desktop configurado —
`dart:io`/diálogo nativo de arquivo não funcionam em `flutter run -d chrome`):

```
melos exec --scope=playground -- flutter run -d windows
```
