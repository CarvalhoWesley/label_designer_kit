import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_argox/label_renderer_argox.dart';
import 'package:label_renderer_canvas/label_renderer_canvas.dart';

import 'argox_raster_renderer_options.dart';
import 'bmp_encoder.dart';
import 'monochrome_bitmap.dart';
import 'rgba_downsample.dart';

const _stx = '\x02';
const _cr = '\r';

/// Renders a [ResolvedDocument] to PPLA bytes the same way
/// [label_renderer_argox]'s `ArgoxRenderer` does for the job-level
/// framing (clear memory, label length, darkness, copies), but instead of
/// one native PPLA command per element, rasterizes the *entire* label via
/// [CanvasRenderer] (real typography, filled shapes, QR codes — see that
/// package) and sends the result as a single monochrome image, via PPLA's
/// `<STX>I` image-download command plus a "5: Images" placement record.
///
/// This exists because PPLA's native text/shape commands have real,
/// unavoidable limits (a fixed internal font ladder, no fill, no true
/// ellipse, no QR) — see `label_renderer_argox`'s README. Rasterizing
/// sidesteps all of that at the cost of a bigger job (an image instead of
/// compact commands) and losing the printer's own crisp native font
/// rendering. Both renderers stay available side by side; this doesn't
/// replace `ArgoxRenderer`.
///
/// See this package's README for exactly which parts of the PPLA image
/// protocol below are sourced from the Datamax Class Series 2
/// Programmer's Manual versus still needing validation against real
/// Argox hardware.
class ArgoxRasterRenderer implements LabelRenderer {
  const ArgoxRasterRenderer();

  @override
  Future<Uint8List> render(
    ResolvedDocument document,
    RendererOptions options,
  ) async {
    final raster = options is ArgoxRasterRendererOptions
        ? options
        : const ArgoxRasterRendererOptions();

    // A raster-only job has no barcode module-width field (the one other
    // place pplaDotMultiplier matters) for D11 to desync — see
    // ArgoxRasterRendererOptions.fullResolution — so this can safely
    // override the D command's DPI-based default independently of what a
    // mixed native-command job would need.
    final dotMultiplier = raster.fullResolution
        ? 1
        : pplaDotMultiplier(document.dpi);

    final bmpBytes = await _rasterizeToMonochromeBmp(
      document,
      raster,
      dotMultiplier,
    );

    const argoxRenderer = ArgoxRenderer();
    // Always 'b' — 'B' ("flipped") is the designator tied to a negative
    // biHeight, confirmed to hang real hardware (see encodeMonochromeBmp).
    // Row order is controlled purely by ArgoxRasterRendererOptions.
    // reverseRowOrder, in the BMP bytes themselves, never via this field.
    const format = 'b';

    final builder = BytesBuilder(copy: false);
    builder.add(latin1.encode(argoxRenderer.clearMemoryCommand()));
    // <STX>I{bank}{format}{name}<CR> — data type field (`b` in the
    // manual's own field-letter scheme, unrelated to our `format`
    // variable) is omitted, meaning raw 8-bit binary follows directly;
    // see this package's README for why no terminator is needed after a
    // BMP payload (unlike the unrelated 7-bit-ASCII image format, BMP is
    // self-describing via its own header).
    builder.add(
      latin1.encode(
        '$_stx' 'I${raster.memoryBank}$format${raster.imageName}$_cr',
      ),
    );
    builder.add(bmpBytes);
    builder.add(
      latin1.encode(
        argoxRenderer.labelFormatHeader(
          document,
          raster.base,
          dotMultiplierOverride: dotMultiplier,
        ),
      ),
    );
    // 1Ycd000ffffgggg<name><CR> — rotation 1 (fixed for images), width/
    // height multiplier 1 (no scaling: already rasterized at the exact
    // target dot grid), row/column 0000/0000 (the image *is* the whole
    // label, so it sits at the label's own origin).
    builder.add(latin1.encode('1Y11000' '0000' '0000${raster.imageName}$_cr'));
    builder.add(latin1.encode(argoxRenderer.footer(document, raster.base)));

    return builder.toBytes();
  }

  Future<Uint8List> _rasterizeToMonochromeBmp(
    ResolvedDocument document,
    ArgoxRasterRendererOptions raster,
    int dotMultiplier,
  ) async {
    // A native text/barcode/shape command's position and size are already
    // in hundredths of an inch (an absolute physical unit unaffected by
    // the dot-size command's doubling), but a downloaded image's pixels
    // map 1:1 to PPLA "addressable dots" — on a 203 DPI head at the D22
    // default, each of those addresses covers a physical 2x2 block. The
    // final image must have exactly one pixel per addressable dot —
    // otherwise the label prints at `dotMultiplier`x too large, confirmed
    // on real hardware — but nothing stops rendering at a finer resolution
    // and averaging back down to that grid (see [downsampleRgba]) for
    // better anti-aliased edges, or shrinking `dotMultiplier` itself via
    // [ArgoxRasterRendererOptions.fullResolution] for genuinely more
    // addressable dots — neither changes the physical size printed.
    // `raster.supersample` picks the anti-aliasing multiple.
    final supersample = raster.supersample;
    final pixelRatio = supersample / dotMultiplier;

    const canvasRenderer = CanvasRenderer();
    final image = await canvasRenderer.renderToImage(
      document,
      CanvasRendererOptions(pixelRatio: pixelRatio),
    );
    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        throw StateError('Falha ao rasterizar o ResolvedDocument.');
      }
      final rgba = byteData.buffer.asUint8List();
      final downsampled = supersample > 1
          ? downsampleRgba(
              rgba,
              widthPx: image.width,
              heightPx: image.height,
              factor: supersample,
            )
          : rgba;
      final monochrome = thresholdToMonochrome(
        downsampled,
        widthPx: image.width ~/ supersample,
        heightPx: image.height ~/ supersample,
        threshold: raster.threshold,
        mirrorHorizontal: raster.mirrorHorizontal,
      );
      return encodeMonochromeBmp(
        monochrome,
        reverseRowOrder: raster.reverseRowOrder,
      );
    } finally {
      image.dispose();
    }
  }
}
