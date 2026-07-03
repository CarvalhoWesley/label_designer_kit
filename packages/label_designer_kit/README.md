# label_designer_kit

Pacote guarda-chuva: uma única dependência que reexporta toda a API pública de que um projeto consumidor precisa. Ver [docs/INTEGRATION.md](../../docs/INTEGRATION.md) e [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 20.

## Por quê

A arquitetura deste workspace é modular de propósito (cada pacote com uma responsabilidade única, ver `docs/ARCHITECTURE.md`) — ótimo para manter o código organizado, mas isso significa que, sem este pacote, um projeto consumidor precisaria declarar 6-8 dependências `path:`/`git:` separadas (`label_core`, `label_designer`, `label_layout_engine`, `label_renderer_pdf`, `label_renderer_argox`, `label_serialization`, ...) só para usar o editor e exportar uma etiqueta. `label_designer_kit` existe só para isso: uma dependência, um import.

Isso **não substitui** os pacotes individuais — eles continuam existindo e podem ser usados diretamente por quem quiser controle fino (por exemplo, um app que só precisa do `label_renderer_pdf` sem o editor visual). `label_designer_kit` é uma camada de conveniência por cima, não uma mudança na arquitetura interna.

## O que está incluído

| Pacote | Para quê |
|---|---|
| `label_core` | `LabelDocument` e o modelo de domínio |
| `label_designer` | o widget `LabelDesigner` (editor visual completo) |
| `label_layout_engine` | `LabelLayoutEngine.resolve(document, data)` |
| `label_renderer` | o contrato `LabelRenderer`/`RendererOptions` e `BaseRenderer` (só necessário se você for escrever um renderer próprio) |
| `label_renderer_pdf`, `label_renderer_canvas`, `label_renderer_argox` | os backends de saída prontos: PDF vetorial, PNG raster, comandos PPLA (Argox) |
| `label_serialization` | `LabelDocumentCodec`, para persistir/carregar `.label` |

**Não incluído** (detalhe de implementação de `label_designer`, nunca foi pensado para uso direto pelo consumidor): `label_canvas`, `label_designer_state`, `label_preview`, `label_property_panel`, `label_widgets`, `label_history`, `label_expression_engine`, `label_barcode`.

## Uso

```yaml
# pubspec.yaml do seu projeto
dependencies:
  label_designer_kit:
    path: ../label_designer_workspace/packages/label_designer_kit
```

```dart
import 'package:label_designer_kit/label_designer_kit.dart';

// Editor:
LabelDesigner(document: meuDocumento, onSave: minhaFuncaoDeSalvar)

// Exportar/imprimir:
const layoutEngine = LabelLayoutEngine();
final resolved = layoutEngine.resolve(documento, dados);
final pdfBytes = await const PdfRenderer().render(resolved, const PdfRendererOptions());
final pplaBytes = await const ArgoxRenderer().render(resolved, const ArgoxRendererOptions());
```

## Armadilha conhecida: `EdgeInsets`

`label_core.EdgeInsets` (margens em milímetros) e `flutter/material.dart`'s `EdgeInsets` têm o mesmo nome. Se o seu arquivo importar os dois, esconda um deles:

```dart
import 'package:flutter/material.dart' hide EdgeInsets;
import 'package:label_designer_kit/label_designer_kit.dart';
```

(é o mesmo workaround que `label_designer` já usa internamente — não é algo novo introduzido por este pacote.)

## Testes

```
flutter test
```

`test/label_designer_kit_test.dart` prova que o barrel sozinho — sem nenhum outro import de pacote — já é suficiente para embutir `LabelDesigner` e rodar o pipeline completo (serializar → resolver → renderizar em PDF, PNG e PPLA). Se uma mudança futura em qualquer pacote interno reduzir o que este barrel reexporta, esse teste quebra aqui em vez de silenciosamente quebrar todo consumidor.
