# label_renderer

Contrato `LabelRenderer`/`RendererOptions` implementado por cada backend de saída (`label_renderer_canvas`, `label_renderer_pdf`, `label_renderer_argox`, ...). Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 11.

Pacote Dart puro — só a interface, nenhuma implementação concreta. Um renderer recebe sempre um `ResolvedDocument` já pronto e nunca recalcula layout.

```dart
class MeuRenderer implements LabelRenderer {
  @override
  Future<Uint8List> render(ResolvedDocument document, RendererOptions options) async {
    // ...
  }
}
```

## Testes

```
dart test
```
