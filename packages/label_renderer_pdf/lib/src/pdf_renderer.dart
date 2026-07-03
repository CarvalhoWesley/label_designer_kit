import 'dart:typed_data';

import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'element_encoder.dart';
import 'pdf_renderer_options.dart';

/// Renders a [ResolvedDocument] to vectorial PDF bytes using `package:pdf`
/// — real embedded fonts and vector paths, no rasterization, unlike
/// `label_renderer_canvas`.
///
/// `package:pdf` brings its own font engine and drawing primitives in pure
/// Dart (no `dart:ui`), so — unlike `label_renderer_canvas` — this package
/// needs no Flutter dependency and is tested with `dart test`. See
/// `docs/ARCHITECTURE.md` section 11 and `docs/ROADMAP.md` etapa 15.
class PdfRenderer implements LabelRenderer {
  const PdfRenderer();

  @override
  Future<Uint8List> render(
    ResolvedDocument document,
    RendererOptions options,
  ) async {
    final pdfOptions = options is PdfRendererOptions
        ? options
        : const PdfRendererOptions();
    final scale = 72.0 / document.dpi;
    final widthPt = document.widthDots * scale;
    final heightPt = document.heightDots * scale;

    final encoder = ElementEncoder(
      scale: scale,
      imageResolver: pdfOptions.imageResolver,
      fontResolver: pdfOptions.fontResolver,
    );

    final elementsByZIndex = [...document.elements]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final widgets = <pw.Widget>[
      for (final element in elementsByZIndex) await encoder.encode(element),
    ];

    final pdfDocument = pw.Document();
    pdfDocument.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(widthPt, heightPt),
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Stack(children: widgets),
      ),
    );

    return pdfDocument.save();
  }
}
