/// Rasteriza um `ResolvedDocument` inteiro via `label_renderer_canvas` e
/// envia como imagem monocromática para uma impressora Argox via o comando
/// de download de imagem do PPLA — ver `argox_raster_renderer.dart` e o
/// README deste pacote.
library;

export 'src/argox_raster_renderer.dart';
export 'src/argox_raster_renderer_options.dart';
export 'src/bmp_encoder.dart';
export 'src/monochrome_bitmap.dart';
export 'src/rgba_downsample.dart';
