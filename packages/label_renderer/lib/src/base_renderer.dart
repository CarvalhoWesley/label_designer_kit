import 'dart:convert';
import 'dart:typed_data';

import 'package:label_core/label_core.dart';

import 'label_renderer.dart';
import 'renderer_options.dart';

/// Template Method for renderers whose output is a sequence of textual
/// commands (PPLA/PPLB, ZPL II, TSPL, ...) instead of a raster/vector
/// image — see `docs/ARCHITECTURE.md`, section 11.
///
/// The fixed flow — `header` once, `encodeElement` per element sorted by
/// [ResolvedElement.zIndex], `footer` once, then encode the concatenated
/// string to bytes — lives here a single time; each command-based
/// renderer (`label_renderer_argox`, `_zebra`, `_tsc`) only implements the
/// three dialect-specific pieces. `CanvasRenderer` and `PdfRenderer` don't
/// extend this — they paint into a raster/vector canvas, not a command
/// string, so forcing the same shape on them would be an artificial
/// abstraction (see `label_renderer_canvas`'s docs).
abstract class BaseRenderer implements LabelRenderer {
  const BaseRenderer();

  /// Command(s) that configure the printer/label before any element is
  /// emitted — unit, transfer type, label length, darkness/speed,
  /// "enter label formatting mode", etc.
  String header(ResolvedDocument document, RendererOptions options);

  /// The command(s) for a single already-resolved element.
  String encodeElement(
    ResolvedElement element,
    ResolvedDocument document,
    RendererOptions options,
  );

  /// Command(s) that close the label and trigger printing — copy count,
  /// "end job", etc.
  String footer(ResolvedDocument document, RendererOptions options);

  /// Converts the combined `header`/`encodeElement`/`footer` output to
  /// bytes. Defaults to Latin-1, which covers plain ASCII plus the
  /// single-byte control codes (STX, CR, ...) most printer command
  /// languages rely on; override if a dialect needs something else.
  Uint8List encodeBytes(String commands) =>
      Uint8List.fromList(latin1.encode(commands));

  @override
  Future<Uint8List> render(
    ResolvedDocument document,
    RendererOptions options,
  ) async {
    final buffer = StringBuffer(header(document, options));
    final elementsByZIndex = [...document.elements]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final element in elementsByZIndex) {
      buffer.write(encodeElement(element, document, options));
    }
    buffer.write(footer(document, options));
    return encodeBytes(buffer.toString());
  }
}
