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
  group('thresholdToMonochrome', () {
    test('an all-white row packs to an all-zero byte', () {
      final pixels = thresholdToMonochrome(
        _rgba(8, 1, List.filled(8, 0xFFFFFF)),
        widthPx: 8,
        heightPx: 1,
      );
      expect(pixels.rows, [
        [0x00],
      ]);
    });

    test('an all-black row packs to an all-one byte', () {
      final pixels = thresholdToMonochrome(
        _rgba(8, 1, List.filled(8, 0x000000)),
        widthPx: 8,
        heightPx: 1,
      );
      expect(pixels.rows, [
        [0xFF],
      ]);
    });

    test('packs bits MSB-first (leftmost pixel is the high bit)', () {
      final pixels = thresholdToMonochrome(
        _rgba(8, 1, [
          0x000000, 0xFFFFFF, 0x000000, 0xFFFFFF, //
          0x000000, 0xFFFFFF, 0x000000, 0xFFFFFF,
        ]),
        widthPx: 8,
        heightPx: 1,
      );
      expect(pixels.rows, [
        [0xAA], // 1010 1010
      ]);
    });

    test('a width not a multiple of 8 still rounds up to one byte, '
        'MSB-aligned', () {
      final pixels = thresholdToMonochrome(
        _rgba(3, 1, [0x000000, 0xFFFFFF, 0xFFFFFF]),
        widthPx: 3,
        heightPx: 1,
      );
      expect(pixels.rows, [
        [0x80], // 1000 0000 — only the leftmost of 3 pixels is dark
      ]);
    });

    test('rows are top-down and independently packed', () {
      final pixels = thresholdToMonochrome(
        _rgba(8, 2, [
          ...List.filled(8, 0x000000), // row 0: all dark
          ...List.filled(8, 0xFFFFFF), // row 1: all light
        ]),
        widthPx: 8,
        heightPx: 2,
      );
      expect(pixels.rows, [
        [0xFF],
        [0x00],
      ]);
    });

    test('thresholds at exact luminance boundary: 128 is light, 127 is '
        'dark, under the default threshold of 128', () {
      final pixels = thresholdToMonochrome(
        _rgba(2, 1, [0x808080, 0x7F7F7F]),
        widthPx: 2,
        heightPx: 1,
      );
      expect(pixels.rows, [
        [0x40], // 0100 0000 — only the second (127-luminance) pixel is dark
      ]);
    });

    test('a custom threshold shifts the dark/light boundary', () {
      final pixels = thresholdToMonochrome(
        _rgba(1, 1, [0x646464]), // luminance 100
        widthPx: 1,
        heightPx: 1,
        threshold: 90,
      );
      expect(pixels.rows, [
        [0x00], // 100 is not < 90 -> light
      ]);
    });

    test('mirrorHorizontal reverses which column a dark source pixel '
        'lands in', () {
      final pixels = thresholdToMonochrome(
        _rgba(8, 1, [
          0x000000, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF, //
          0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF,
        ]),
        widthPx: 8,
        heightPx: 1,
        mirrorHorizontal: true,
      );
      expect(pixels.rows, [
        [0x01], // 0000 0001 — leftmost source pixel lands in the last column
      ]);
    });

    test('mirrorHorizontal on a width not a multiple of 8 mirrors against '
        'the true image width, not the padded byte width', () {
      final pixels = thresholdToMonochrome(
        _rgba(3, 1, [0x000000, 0xFFFFFF, 0xFFFFFF]),
        widthPx: 3,
        heightPx: 1,
        mirrorHorizontal: true,
      );
      expect(pixels.rows, [
        [0x20], // 0010 0000 — leftmost of 3 source pixels lands in column 2
      ]);
    });
  });
}
