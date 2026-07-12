import 'dart:typed_data';

import 'package:label_renderer_argox_raster/label_renderer_argox_raster.dart';
import 'package:test/test.dart';

/// Builds a `rawRgba`-shaped buffer (4 bytes/pixel, row-major, top-down,
/// unpadded, opaque) from a row-major list of 0xRRGGBB colors.
Uint8List _rgba(int width, int height, List<int> colors) {
  final bytes = Uint8List(width * height * 4);
  for (var i = 0; i < colors.length; i++) {
    final color = colors[i];
    bytes[i * 4] = (color >> 16) & 0xFF;
    bytes[i * 4 + 1] = (color >> 8) & 0xFF;
    bytes[i * 4 + 2] = color & 0xFF;
    bytes[i * 4 + 3] = 0xFF;
  }
  return bytes;
}

void main() {
  group('downsampleRgba', () {
    test('factor 1 returns the source buffer unchanged', () {
      final source = _rgba(2, 2, [0x000000, 0xFFFFFF, 0xFFFFFF, 0x000000]);
      expect(downsampleRgba(source, widthPx: 2, heightPx: 2, factor: 1), same(source));
    });

    test('averages a single 2x2 block into one output pixel', () {
      final source = _rgba(2, 2, [
        0xFF0000, 0x000000, //
        0x000000, 0x000000,
      ]);
      final out = downsampleRgba(source, widthPx: 2, heightPx: 2, factor: 2);
      // (0xFF+0+0+0)/4 = 63 (integer division) for red, 0 for green/blue.
      expect(out, [63, 0, 0, 0xFF]);
    });

    test('output dimensions are widthPx/heightPx floor-divided by factor', () {
      final source = _rgba(4, 4, List.filled(16, 0xFFFFFF));
      final out = downsampleRgba(source, widthPx: 4, heightPx: 4, factor: 2);
      expect(out.length, 2 * 2 * 4); // 2x2 output, 4 bytes/pixel
    });

    test('drops a leftover partial row/column at the edge instead of '
        'averaging it in', () {
      // 3x1 source, factor 2 -> floor(3/2) = 1 output column; the third
      // source pixel (a lone leftover column) must not affect the result.
      final source = _rgba(3, 1, [0x000000, 0x000000, 0xFFFFFF]);
      final out = downsampleRgba(source, widthPx: 3, heightPx: 1, factor: 2);
      expect(out, [0, 0, 0, 0xFF]); // average of the two black pixels only
    });

    test('averages independent 2x2 blocks across a larger grid', () {
      final source = _rgba(4, 2, [
        0xFFFFFF, 0xFFFFFF, 0x000000, 0x000000, //
        0xFFFFFF, 0xFFFFFF, 0x000000, 0x000000,
      ]);
      final out = downsampleRgba(source, widthPx: 4, heightPx: 2, factor: 2);
      expect(out, [
        0xFF, 0xFF, 0xFF, 0xFF, // left block: all white
        0x00, 0x00, 0x00, 0xFF, // right block: all black
      ]);
    });
  });
}
