# label_barcode

Geração de símbolos de código de barras/QR — um padrão de módulos abstrato (retângulos fracionários 0.0–1.0, sem pixels/dots/cor), consumido por `label_renderer_canvas`, `label_renderer_pdf` e qualquer renderer futuro. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 11.

## Decisão de arquitetura

Em vez de reimplementar os algoritmos de codificação (checksum EAN13, tabelas Code128, Reed-Solomon/Galois Field do QR Code) do zero — alto risco de bugs sutis e difícil de verificar sem um leitor real —, este pacote adapta [`package:barcode`](https://pub.dev/packages/barcode) (Apache-2.0, mantido pelo autor do popular `package:pdf`) atrás da nossa própria interface (`BarcodeEncoder`/`QrCodeEncoder`). **Nenhum consumidor deste pacote importa `package:barcode` diretamente** — só `lib/src/package_barcode_adapter.dart` conhece a dependência externa, então trocá-la no futuro não afeta ninguém.

## Uso

```dart
final symbol = linearBarcodeEncoders[BarcodeSymbology.ean13]!.encode('5901234123457');
// symbol.modules: List<SymbolModule>, cada um um retângulo de tinta em frações 0.0-1.0

final qr = qrCodeEncoder.encode('https://...', level: QrErrorCorrectionLevel.medium);
```

Cobre todos os 7 símbolos lineares declarados em `label_core.BarcodeSymbology` (EAN13, EAN8, Code39, Code128, UPC, ITF, Codabar) mais QR Code. PDF417 e DataMatrix já têm encoder pronto (`pdf417BarcodeEncoder`, `dataMatrixBarcodeEncoder`), aguardando apenas um `LabelElement` correspondente em `label_core` para serem usados.

## Testes

```
dart test
```
