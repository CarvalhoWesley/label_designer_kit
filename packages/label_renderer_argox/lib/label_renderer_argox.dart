/// Renderer que converte um ResolvedDocument em comandos PPLA (e
/// futuramente PPLB) para impressoras Argox, via o Template Method
/// `BaseRenderer` de `label_renderer`. Ver `docs/ARCHITECTURE.md`, seção
/// 11, e `docs/ROADMAP.md`, etapa 16.
library;

export 'src/argox_renderer.dart';
export 'src/argox_renderer_options.dart';
export 'src/ppla_fields.dart';
