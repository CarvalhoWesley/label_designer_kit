import 'package:label_renderer/label_renderer.dart';

import 'image_resolver.dart';
import 'pdf_font_resolver.dart';

/// Settings specific to [PdfRenderer].
class PdfRendererOptions extends RendererOptions {
  const PdfRendererOptions({
    this.imageResolver = defaultImageResolver,
    this.fontResolver = defaultPdfFontResolver,
  });

  /// Resolves a [ResolvedImagePayload.source] reference to bytes. See
  /// [ImageResolver].
  final ImageResolver imageResolver;

  /// Resolves a [ResolvedTextStyle.fontFamily] to an embeddable font. See
  /// [PdfFontResolver].
  final PdfFontResolver fontResolver;
}
