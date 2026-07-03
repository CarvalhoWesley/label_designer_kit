import 'package:pdf/widgets.dart' as pw;

/// Resolves a [ResolvedTextStyle.fontFamily] to an embeddable [pw.Font], or
/// `null` if this resolver doesn't have a font for that family.
///
/// Unlike `dart:ui` (used by `label_renderer_canvas`), `package:pdf` cannot
/// resolve system/asset fonts on its own — every embedded font needs actual
/// TTF bytes handed to it via `pw.Font.ttf(...)`. [defaultPdfFontResolver]
/// always returns `null`, so [PdfRenderer] falls back to one of the PDF
/// base-14 fonts (Helvetica, picked by [bold]/[italic]); pass a custom
/// [PdfFontResolver] via [PdfRendererOptions] to embed real TTFs.
typedef PdfFontResolver =
    pw.Font? Function(
      String fontFamily, {
      required bool bold,
      required bool italic,
    });

pw.Font? defaultPdfFontResolver(
  String fontFamily, {
  required bool bold,
  required bool italic,
}) => null;
