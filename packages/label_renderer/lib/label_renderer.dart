/// O contrato `LabelRenderer`/`RendererOptions` implementado por cada
/// backend de saída, mais `BaseRenderer`, o Template Method reutilizado
/// pelos renderers de comando textual (`label_renderer_argox`, `_zebra`,
/// `_tsc`). Ver `docs/ARCHITECTURE.md` seção 11.
///
/// Pacote Dart puro — nenhum renderer concreto de backend específico mora
/// aqui, só o contrato e o esqueleto compartilhado.
library;

export 'src/base_renderer.dart';
export 'src/label_renderer.dart';
export 'src/renderer_options.dart';
