import 'dart:typed_data';

import 'monochrome_bitmap.dart';

/// Encodes [MonochromePixels] as a standard, minimal 1-bit-per-pixel
/// Windows BMP file (`BITMAPFILEHEADER` + `BITMAPINFOHEADER` + a 2-color
/// palette + row-padded pixel data) — the file format the Datamax Class
/// Series 2 Programmer's Manual documents for PPLA's `<STX>I`
/// image-download command's `b`/`B` format designators ("the native
/// format for storing downloaded ... BMP images is RLE-2", i.e. the
/// printer itself parses a standard BMP; this doesn't need to emit any
/// Argox/Datamax-specific pixel format).
///
/// **`biHeight` is always written positive.** A negative `biHeight` (the
/// spec-standard way to mark a BMP top-down, which an earlier version of
/// this function used, paired with the manual's `B`/"flipped" designator)
/// is confirmed on real Argox hardware to hang the printer outright — it
/// stops responding and needs a power cycle. This printer's BMP parser
/// apparently can't handle it at all, so this function never emits one and
/// callers should never send the `B` designator either; only `b`.
///
/// [reverseRowOrder] instead controls row order directly, independent of
/// any header flag: `true` (default) writes a spec-standard bottom-up
/// arrangement (last scanline of [pixels] written first) — the original,
/// always-safe default. `false` writes [pixels] in its own top-down order,
/// unreversed — same row order the abandoned negative-`biHeight` path used
/// to produce, minus the part that hangs the printer. Which one this
/// printer's raster scan direction actually wants still needs a real print
/// test (see the package README); flip this if the label prints upside
/// down.
///
/// Pixel bits are written **inverted** relative to
/// [thresholdToMonochrome]'s "1 = dark/printed pixel" convention — a
/// written `0` is a dark/printed pixel, `1` is light — and the palette is
/// index 0 = black, index 1 = white to match. Confirmed on real Argox
/// hardware: sending bits in the "natural" sense (1 = dark) with a
/// `white, black` palette printed with colors fully inverted (black
/// background, white content), meaning this printer's `<STX>I` BMP parser
/// doesn't read the embedded palette at all and instead assumes a fixed
/// `0 = black, 1 = white` convention — so the palette bytes here mostly
/// document intent for a spec-reading tool inspecting the file, not
/// something this printer actually consults.
///
/// This is plain BMP spec (modulo that one inversion, which is a real
/// hardware finding, not a spec requirement) — fully unit-testable,
/// unlike the rest of this renderer's PPLA framing (see the package
/// README for what still needs a real print test).
Uint8List encodeMonochromeBmp(
  MonochromePixels pixels, {
  bool reverseRowOrder = true,
}) {
  const fileHeaderSize = 14;
  const infoHeaderSize = 40;
  const paletteSize = 2 * 4; // 2 colors, 4 bytes (B,G,R,0) each
  const pixelDataOffset = fileHeaderSize + infoHeaderSize + paletteSize;

  final rowBytesPadded = ((pixels.widthPx + 31) ~/ 32) * 4;
  final pixelDataSize = rowBytesPadded * pixels.heightPx;
  final fileSize = pixelDataOffset + pixelDataSize;

  final bytes = Uint8List(fileSize);
  final data = ByteData.sublistView(bytes);

  // BITMAPFILEHEADER
  bytes[0] = 0x42; // 'B'
  bytes[1] = 0x4D; // 'M'
  data.setUint32(2, fileSize, Endian.little);
  data.setUint32(6, 0, Endian.little); // reserved
  data.setUint32(10, pixelDataOffset, Endian.little);

  // BITMAPINFOHEADER
  data.setUint32(14, infoHeaderSize, Endian.little);
  data.setInt32(18, pixels.widthPx, Endian.little);
  // Always positive — see this function's doc comment on why a negative
  // biHeight is never emitted.
  data.setInt32(22, pixels.heightPx, Endian.little);
  data.setUint16(26, 1, Endian.little); // planes
  data.setUint16(28, 1, Endian.little); // bit count (1bpp)
  data.setUint32(30, 0, Endian.little); // compression: BI_RGB
  data.setUint32(34, pixelDataSize, Endian.little);
  data.setInt32(38, 0, Endian.little); // x pixels/meter
  data.setInt32(42, 0, Endian.little); // y pixels/meter
  data.setUint32(46, 2, Endian.little); // colors used
  data.setUint32(50, 2, Endian.little); // important colors

  // Palette: index 0 = black, index 1 = white — inverted from the more
  // "obvious" white/black order to match the inverted bits below.
  var offset = 54;
  bytes.setRange(offset, offset + 4, [0x00, 0x00, 0x00, 0x00]);
  offset += 4;
  bytes.setRange(offset, offset + 4, [0xFF, 0xFF, 0xFF, 0x00]);
  offset += 4;

  // Pixel data, each row padded with zero bytes to a 4-byte boundary.
  // reverseRowOrder: last scanline of `pixels.rows` (already top-down)
  // written first. Otherwise: `pixels.rows` written in its own order,
  // unreversed. Every source byte is bitwise-inverted on the way out — see
  // the real-hardware finding in this function's doc comment.
  final unpaddedRowBytes = (pixels.widthPx + 7) ~/ 8;
  for (var y = 0; y < pixels.heightPx; y++) {
    final sourceRow = reverseRowOrder
        ? pixels.rows[pixels.heightPx - 1 - y]
        : pixels.rows[y];
    final rowOffset = pixelDataOffset + y * rowBytesPadded;
    for (var i = 0; i < unpaddedRowBytes; i++) {
      bytes[rowOffset + i] = sourceRow[i] ^ 0xFF;
    }
    // Remaining bytes in the padded row are already zero (Uint8List
    // default-initializes to 0) — outside the declared width, so never
    // actually read as pixels by a spec-compliant BMP reader.
  }

  return bytes;
}
