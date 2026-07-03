/// Renderer que converte um ResolvedDocument em PDF vetorial usando
/// package:pdf — texto real, formas e código de barras/QR como paths, não
/// bitmap. Ver `docs/ARCHITECTURE.md`, seção 11, e `docs/ROADMAP.md`,
/// etapa 15.
library;

export 'src/image_resolver.dart';
export 'src/pdf_font_resolver.dart';
export 'src/pdf_renderer.dart';
export 'src/pdf_renderer_options.dart';
