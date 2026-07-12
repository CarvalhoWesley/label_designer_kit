import 'dart:typed_data';

/// A monochrome (1 bit per pixel) raster, independent of any file format —
/// [BmpEncoder]-agnostic on purpose so the thresholding step here stays
/// pure Dart (testable without `dart:ui`) and file-format concerns live
/// entirely in `bmp_encoder.dart`.
class MonochromePixels {
  const MonochromePixels({
    required this.widthPx,
    required this.heightPx,
    required this.rows,
  });

  final int widthPx;
  final int heightPx;

  /// Top-down, one entry per scanline (`rows.length == heightPx`).
  /// Each row is packed MSB-first, 1 bit per pixel, 1 = a "dark"/printed
  /// pixel, unpadded (`row.length == (widthPx + 7) ~/ 8`) — row padding to
  /// a byte-alignment boundary is a BMP file-format concern, not this
  /// format-agnostic pixel grid's.
  final List<Uint8List> rows;
}

/// Converts a `dart:ui` `rawRgba` byte buffer (4 bytes/pixel — R,G,B,A,
/// row-major, top-down, unpadded — the layout `ui.Image.toByteData` uses
/// with `ui.ImageByteFormat.rawRgba`) to [MonochromePixels] by thresholding
/// each pixel's luminance.
///
/// No dithering: label content is text/bars/lines — near-solid black on
/// white — where a hard threshold reproduces the source faithfully. A
/// halftone/dither step would only matter for photographic content, which
/// [ResolvedImagePayload] doesn't attempt to support via this path.
///
/// Assumes the source is already fully opaque — [CanvasRenderer] always
/// paints an opaque background rect before any element, so alpha is
/// ignored rather than composited against an assumed backdrop.
MonochromePixels thresholdToMonochrome(
  Uint8List rgba, {
  required int widthPx,
  required int heightPx,
  int threshold = 128,
  bool mirrorHorizontal = false,
}) {
  final rowBytes = (widthPx + 7) ~/ 8;
  final rows = List<Uint8List>.generate(heightPx, (_) => Uint8List(rowBytes));

  for (var y = 0; y < heightPx; y++) {
    final row = rows[y];
    final rowOffset = y * widthPx * 4;
    for (var x = 0; x < widthPx; x++) {
      final pixelOffset = rowOffset + x * 4;
      final r = rgba[pixelOffset];
      final g = rgba[pixelOffset + 1];
      final b = rgba[pixelOffset + 2];
      final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
      if (luminance < threshold) {
        // [mirrorHorizontal] reverses which output column a source pixel
        // lands in (a true left-right mirror of the whole row), not the
        // bit order within a byte — see the package README/[flipped] for
        // why this needs to be independently toggleable.
        final column = mirrorHorizontal ? widthPx - 1 - x : x;
        final byteIndex = column ~/ 8;
        final bitFromMsb = 7 - (column % 8);
        row[byteIndex] |= 1 << bitFromMsb;
      }
    }
  }

  return MonochromePixels(widthPx: widthPx, heightPx: heightPx, rows: rows);
}
