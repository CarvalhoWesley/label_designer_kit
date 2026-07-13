/// Ponto de entrada único para um projeto Flutter consumidor: uma
/// dependência (`flutter_label_designer`) em vez de uma por pacote. Ver
/// `docs/INTEGRATION.md` e `docs/ARCHITECTURE.md`, seção 20.
///
/// Reexporta exatamente a superfície pública que a arquitetura já definia
/// como "o que o projeto do usuário toca" — nada mais:
///
/// - `label_core`: `LabelDocument` e todo o modelo de domínio.
/// - `label_designer`: o widget `LabelDesigner` (editor visual completo).
/// - `label_layout_engine`: `LabelLayoutEngine.resolve(document, data)`.
/// - `label_renderer`: o contrato `LabelRenderer`/`RendererOptions` e o
///   `BaseRenderer` Template Method (só relevante se você for escrever um
///   renderer de impressora próprio).
/// - `label_renderer_pdf`, `label_renderer_canvas`, `label_renderer_argox`:
///   os backends de saída prontos (PDF, PNG, PPLA).
/// - `label_renderer_argox_raster`: variante do backend PPLA que rasteriza
///   a etiqueta inteira (via `label_renderer_canvas`) em vez de comandos
///   nativos por elemento — contorna os limites de fonte/forma do PPLA
///   nativo ao custo de um job maior; ver o README do pacote.
/// - `label_serialization`: `LabelDocumentCodec` para persistir `.label`.
///
/// Pacotes internos de composição (`label_canvas`, `label_designer_state`,
/// `label_preview`, `label_property_panel`, `label_widgets`,
/// `label_history`, `label_expression_engine`, `label_barcode`) **não**
/// são reexportados — são detalhe de implementação de `label_designer`,
/// nunca fizeram parte da API pretendida para o consumidor (ver
/// `docs/ARCHITECTURE.md`, seções 3–7).
///
/// `label_print_transport`/`label_print_transport_windows` (envio de bytes
/// já renderizados para uma impressora física) também **não** são
/// reexportados aqui, de propósito — diferente de um `label_renderer_*`
/// (só produz bytes), transporte fala diretamente com o SO/hardware, então
/// só o app que efetivamente imprime declara essas dependências (ver
/// `docs/ARCHITECTURE.md`, seção 20).
///
/// **Uma armadilha conhecida**: `label_core.EdgeInsets` (margens em mm) e
/// `flutter/material.dart`'s `EdgeInsets` têm o mesmo nome. Se seu arquivo
/// importar os dois, use `import 'package:flutter/material.dart' hide
/// EdgeInsets;` — o próprio `label_designer` faz isso internamente.
library;

export 'package:label_core/label_core.dart';
export 'package:label_designer/label_designer.dart';
export 'package:label_layout_engine/label_layout_engine.dart';
export 'package:label_renderer/label_renderer.dart';
export 'package:label_renderer_argox/label_renderer_argox.dart';
export 'package:label_renderer_argox_raster/label_renderer_argox_raster.dart';
// `ImageResolver`/`defaultImageResolver` are intentionally duplicated,
// identical typedefs in label_renderer_canvas and label_renderer_pdf —
// renderer packages are siblings and must not depend on each other (see
// each package's own docs). Both resolve to the same underlying function
// type, so hiding the canvas copy here loses nothing: a lambda passed as
// either renderer's `imageResolver` works regardless of which typedef
// name is in scope, and code that needs the name explicitly can import
// `package:label_renderer_canvas/label_renderer_canvas.dart` directly.
export 'package:label_renderer_canvas/label_renderer_canvas.dart'
    hide ImageResolver, defaultImageResolver;
export 'package:label_renderer_pdf/label_renderer_pdf.dart';
export 'package:label_serialization/label_serialization.dart';
