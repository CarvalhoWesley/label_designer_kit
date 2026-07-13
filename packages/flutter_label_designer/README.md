# flutter_label_designer

[![pub package](https://img.shields.io/pub/v/flutter_label_designer.svg)](https://pub.dev/packages/flutter_label_designer)

Editor visual de etiquetas para Flutter, com motor de layout, serialização e renderers prontos (PDF, PNG, PPLA/Argox) — tudo atrás de uma única dependência.

## Features

- **`LabelDesigner`** — widget de editor visual completo (canvas, camadas, painel de propriedades).
- **`LabelLayoutEngine`** — resolve variáveis, expressões e unidades de um `LabelDocument` para um DPI alvo.
- **Renderers prontos**:
  - `PdfRenderer` — saída PDF vetorial.
  - `CanvasRenderer` — saída PNG/raster (preview e export).
  - `ArgoxRenderer` — comandos PPLA para impressoras Argox.
  - `ArgoxRasterRenderer` — variante do backend PPLA que rasteriza a etiqueta inteira em vez de emitir comandos nativos por elemento, contornando limites de fonte/forma do PPLA nativo ao custo de um job maior.
- **`LabelDocumentCodec`** — serializa/desserializa documentos `.label` (JSON).
- **`LabelRenderer`/`RendererOptions`/`BaseRenderer`** — contrato Template Method para quem quiser escrever um renderer de impressora próprio.

Este é um pacote guarda-chuva: reexporta a API pública de um conjunto de pacotes internos por trás de uma única dependência, para não obrigar o projeto consumidor a declarar 6-8 dependências separadas. Os pacotes individuais continuam existindo para quem quiser controle fino (por exemplo, um serviço headless que só precisa de um renderer, sem o editor visual).

## Getting started

Requer Flutter `>=3.32.0` e Dart SDK `^3.8.1`.

```yaml
dependencies:
  flutter_label_designer: ^1.0.0
```

ou

```
flutter pub add flutter_label_designer
```

## Usage

### Embutir o editor

`LabelDesigner` é um widget comum — não gerencia navegação nem faz I/O. Recebe um `LabelDocument` e devolve o documento editado via `onSave`; persistir em disco/banco é responsabilidade da tela que o embute.

```dart
import 'package:flutter/material.dart' hide EdgeInsets; // ver "armadilha conhecida" abaixo
import 'package:flutter_label_designer/flutter_label_designer.dart';

class MinhaTelaDeEdicao extends StatelessWidget {
  const MinhaTelaDeEdicao({super.key, required this.documento});

  final LabelDocument documento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LabelDesigner(
        document: documento,
        onSave: (documentoEditado) {
          meuRepositorio.salvar(documentoEditado);
        },
      ),
    );
  }
}
```

### Resolver e renderizar (exportar/imprimir)

`LabelDocument` não sabe nada sobre impressoras ou pixels: `LabelLayoutEngine` resolve variáveis/expressões/unidades para o DPI alvo, e um renderer converte o layout resolvido em bytes de saída. Nenhum renderer recalcula layout — todos recebem o mesmo `ResolvedDocument`.

```dart
import 'package:flutter_label_designer/flutter_label_designer.dart';

const layoutEngine = LabelLayoutEngine();
final resolved = layoutEngine.resolve(documento, {
  'produto': 'Parafuso Sextavado M6',
  'preco': 3.9,
  'codigo': 'PROD-000123',
});

// PDF (conferência visual, e-mail, arquivo):
final pdfBytes = await const PdfRenderer().render(resolved, const PdfRendererOptions());

// PNG (preview):
final pngBytes = await const CanvasRenderer().render(resolved, const CanvasRendererOptions());

// PPLA (impressora Argox):
final pplaBytes = await const ArgoxRenderer().render(
  resolved,
  const ArgoxRendererOptions(darkness: 12, copies: 1),
);
```

Este pacote entrega apenas bytes já codificados — o transporte até a saída física (arquivo, e-mail, socket TCP na porta 9100, USB, Bluetooth) é responsabilidade do projeto consumidor.

### Armadilha conhecida: `EdgeInsets`

`LabelDocument`'s `EdgeInsets` (margens em milímetros) e `flutter/material.dart`'s `EdgeInsets` têm o mesmo nome. Se o seu arquivo importar os dois, esconda um deles:

```dart
import 'package:flutter/material.dart' hide EdgeInsets;
import 'package:flutter_label_designer/flutter_label_designer.dart';
```

## Additional information

`test/flutter_label_designer_test.dart` prova que o barrel sozinho — sem nenhum outro import de pacote — é suficiente para embutir `LabelDesigner` e rodar o pipeline completo (serializar → resolver → renderizar em PDF, PNG e PPLA). Rode com:

```
flutter test
```
