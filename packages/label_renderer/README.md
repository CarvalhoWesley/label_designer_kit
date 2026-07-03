# label_renderer

Contrato `LabelRenderer`/`RendererOptions` implementado por cada backend de saída (`label_renderer_canvas`, `label_renderer_pdf`, `label_renderer_argox`, ...), mais `BaseRenderer`, o Template Method reutilizado pelos renderers de comando textual. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 11.

Pacote Dart puro — nenhum renderer concreto de backend específico mora aqui. Um renderer recebe sempre um `ResolvedDocument` já pronto e nunca recalcula layout.

```dart
class MeuRenderer implements LabelRenderer {
  @override
  Future<Uint8List> render(ResolvedDocument document, RendererOptions options) async {
    // ...
  }
}
```

## BaseRenderer

Renderers cuja saída é uma sequência de comandos textuais (PPLA/PPLB, ZPL II, TSPL, ...) em vez de uma imagem raster/vetorial podem estender `BaseRenderer` em vez de implementar `LabelRenderer` diretamente — ele já resolve o fluxo fixo `header` → elementos (ordenados por `zIndex`) → `footer` → bytes, deixando só as três partes específicas do dialeto para a subclasse:

```dart
class MeuRenderer extends BaseRenderer {
  const MeuRenderer();

  @override
  String header(ResolvedDocument document, RendererOptions options) => '...';

  @override
  String encodeElement(ResolvedElement element, ResolvedDocument document, RendererOptions options) => '...';

  @override
  String footer(ResolvedDocument document, RendererOptions options) => '...';
}
```

`CanvasRenderer` e `PdfRenderer` **não** estendem `BaseRenderer` — pintam em um canvas raster/vetorial, não concatenam uma string de comandos, então forçar a mesma forma neles seria uma abstração artificial (ver a nota da Etapa 6 no `docs/ARCHITECTURE.md`).

## Testes

```
dart test
```
