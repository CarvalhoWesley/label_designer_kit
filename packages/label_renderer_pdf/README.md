# label_renderer_pdf

Renderiza um `ResolvedDocument` em PDF vetorial usando [`package:pdf`](https://pub.dev/packages/pdf) — texto com fonte real, formas e código de barras/QR como paths, nunca bitmap. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 11, e [docs/ROADMAP.md](../../docs/ROADMAP.md), etapa 15.

**Dart puro**, ao contrário de `label_renderer_canvas`: `package:pdf` embute suas próprias fontes e primitivas de desenho, sem depender do motor do Flutter (`dart:ui`). Testado com `dart test`, não `flutter test`.

## Decisões de arquitetura

- **Widgets, não `PdfGraphics` cru.** O renderer é construído sobre `package:pdf/widgets.dart` (`pw.Positioned`/`pw.Transform.rotate`/`pw.Text`/...), não sobre a API de baixo nível. PDF é nativamente Y-up com origem no canto inferior esquerdo; a camada de widgets já converte isso para um modelo "distância do topo" + "ângulo positivo gira no sentido horário", igual ao que `dart:ui` oferece de graça no `label_renderer_canvas`. Fazer essa conversão à mão com `PdfGraphics` exigiria espelhar manualmente glifos/imagens para compensar a reflexão de uma matriz de flip vertical — a camada de widgets evita essa classe inteira de bugs. Único ajuste necessário: negar `ResolvedElement.rotationDegrees` uma vez (`angle: -rotationDegrees * pi/180`) ao entrar em `pw.Transform.rotate`, para manter a mesma direção visual de rotação do `CanvasRenderer`.
- **Código de barras/QR reaproveitam `label_barcode`**, exatamente como o `CanvasRenderer` — os `SymbolModule` (retângulos fracionários) são desenhados como retângulos vetoriais via `pw.CustomPaint`, nunca rasterizados. Mantém a regra do `label_barcode` de que só o próprio adapter conhece `package:barcode`.
- **Fontes**: `package:pdf` não resolve fontes de sistema como o Flutter — cada fonte embutida precisa dos bytes de uma TTF. `PdfFontResolver` (`fontFamily -> pw.Font?`) segue o mesmo padrão do `ImageResolver`: por padrão (`defaultPdfFontResolver`) sempre retorna `null`, e o renderer cai para uma das 14 fontes base do PDF (Helvetica, escolhida por `bold`/`italic`) — funciona sem nenhuma configuração extra, mas só cobre Latin-1/WinAnsi (cobre acentuação do PT-BR; não cobre CJK/emoji). Passe um `PdfFontResolver` customizado via `PdfRendererOptions` para embutir TTFs reais.
- **Imagens**: crop (`ResolvedImagePayload.cropXDots` etc.) é aplicado decodificando/recortando via `package:image` antes de embutir — `package:pdf` sozinho não recorta.
- **Falhas** (símbolo não codificável, imagem não resolvível) viram um placeholder visual (caixa cinza com borda vermelha), nunca uma exceção — mesma filosofia do `CanvasRenderer`.

## Uso

```dart
const layoutEngine = LabelLayoutEngine();
const renderer = PdfRenderer();

final resolved = layoutEngine.resolve(document, dados);
final pdfBytes = await renderer.render(resolved, const PdfRendererOptions());
```

## Testes

```
dart test
```

Diferente do `label_renderer_canvas` (que decodifica o PNG gerado e inspeciona pixels), um PDF não tem um rasterizador Dart puro disponível para os testes decodificarem — os testes aqui verificam a estrutura do documento (`%PDF`/`%%EOF`/`/MediaBox`) e que cada tipo de payload renderiza sem lançar exceção. A validação visual desta etapa (texto, rotação, código de barras) foi feita abrindo manualmente um PDF de exemplo gerado pelo pipeline completo, fora da suíte de testes.

Também note: diferente da saída PNG do `CanvasRenderer` (bit-a-bit determinística para a mesma entrada), `package:pdf` embute um `/ID` aleatório por arquivo por design — dois `render()` do mesmo documento produzem PDFs válidos e visualmente idênticos, mas não byte-a-byte iguais.
