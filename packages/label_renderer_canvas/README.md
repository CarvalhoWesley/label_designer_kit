# label_renderer_canvas

Renderiza um `ResolvedDocument` em PNG usando `dart:ui` — tipografia real (TTF, negrito/itálico, Google Fonts) em vez de uma fonte bitmap. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seções 11 e 16.

**Único pacote Flutter deste workspace até agora** (todos os anteriores são Dart puro) — necessário porque renderizar tipografia de verdade exige o motor do Flutter; não há biblioteca Dart pura com qualidade equivalente para TTF/negrito/itálico. Testado com `flutter test`, não `dart test`.

Também é o motor por trás do preview do editor (`label_preview`, etapa futura): o preview chama exatamente este mesmo renderer, garantindo que o que o usuário vê durante a edição nunca diverge do resultado real de exportação/impressão.

## Uso

```dart
const layoutEngine = LabelLayoutEngine();
const renderer = CanvasRenderer();

final resolved = layoutEngine.resolve(document, dados);
final pngBytes = await renderer.render(resolved, const CanvasRendererOptions(pixelRatio: 2));
```

- `CanvasRendererOptions.imageResolver` resolve `ImageElement.source` para bytes — por padrão só entende `data:` URIs base64; passe um resolver customizado para carregar de arquivo/rede (I/O é responsabilidade do app, mantém o pacote utilizável em Flutter Web).
- Falhas de codificação de código de barras/QR ou imagens não resolvíveis viram um placeholder visual (caixa cinza com borda vermelha) em vez de lançar exceção — consistente com a filosofia "um campo com problema não derruba a etiqueta inteira".

## Testes

```
flutter test
```
