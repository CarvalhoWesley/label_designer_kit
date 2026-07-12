import 'dart:typed_data';

import 'package:label_renderer_argox_raster/label_renderer_argox_raster.dart';
import 'package:test/test.dart';

void main() {
  group('encodeMonochromeBmp', () {
    // 3x2 pixel grid: top row has only the leftmost pixel dark (0x80 —
    // matches thresholdToMonochrome's MSB-first packing for a width not a
    // multiple of 8), bottom row is all light.
    final pixels = MonochromePixels(
      widthPx: 3,
      heightPx: 2,
      rows: [
        Uint8List.fromList([0x80]),
        Uint8List.fromList([0x00]),
      ],
    );
    final bmp = encodeMonochromeBmp(pixels);
    final data = ByteData.sublistView(bmp);

    test('starts with the BM magic bytes', () {
      expect(bmp[0], 0x42); // 'B'
      expect(bmp[1], 0x4D); // 'M'
    });

    test('file size and pixel-data offset account for a 3-wide row '
        'padded to a 4-byte boundary', () {
      // header(14) + info(40) + palette(8) = 62 byte offset to pixel data;
      // 1 unpadded byte/row rounds up to 4 padded bytes/row * 2 rows = 8;
      // total file size 62 + 8 = 70.
      expect(data.getUint32(2, Endian.little), 70); // bfSize
      expect(data.getUint32(10, Endian.little), 62); // bfOffBits
    });

    test('info header declares 1bpp, uncompressed, bottom-up dimensions', () {
      expect(data.getUint32(14, Endian.little), 40); // biSize
      expect(data.getInt32(18, Endian.little), 3); // biWidth
      expect(data.getInt32(22, Endian.little), 2); // biHeight (positive)
      expect(data.getUint16(26, Endian.little), 1); // biPlanes
      expect(data.getUint16(28, Endian.little), 1); // biBitCount
      expect(data.getUint32(30, Endian.little), 0); // biCompression: BI_RGB
      expect(data.getUint32(34, Endian.little), 8); // biSizeImage
      expect(data.getUint32(46, Endian.little), 2); // biClrUsed
      expect(data.getUint32(50, Endian.little), 2); // biClrImportant
    });

    test('palette is index 0 = black, index 1 = white', () {
      expect(bmp.sublist(54, 58), [0x00, 0x00, 0x00, 0x00]);
      expect(bmp.sublist(58, 62), [0xFF, 0xFF, 0xFF, 0x00]);
    });

    test('pixel data is written bottom-up, bit-inverted, with 4-byte row '
        'padding', () {
      // First row written is the SOURCE's last row (all-light -> 0x00),
      // inverted to 0xFF; second is the source's first row (0x80),
      // inverted to 0x7F — both padded to 4 bytes.
      expect(bmp.sublist(62, 66), [0xFF, 0x00, 0x00, 0x00]);
      expect(bmp.sublist(66, 70), [0x7F, 0x00, 0x00, 0x00]);
    });

    test('total length matches the declared file size', () {
      expect(bmp.length, 70);
    });
  });

  test('a width that is already a multiple of 32 pixels needs no padding '
      '(bytes still bit-inverted)', () {
    final pixels = MonochromePixels(
      widthPx: 32,
      heightPx: 1,
      rows: [Uint8List.fromList([0xFF, 0x00, 0xFF, 0x00])],
    );
    final bmp = encodeMonochromeBmp(pixels);
    final data = ByteData.sublistView(bmp);
    expect(data.getUint32(34, Endian.little), 4); // biSizeImage: no padding
    expect(bmp.sublist(62, 66), [0x00, 0xFF, 0x00, 0xFF]);
  });

  group('encodeMonochromeBmp(reverseRowOrder: false)', () {
    // Same 3x2 grid as the main group above: top row 0x80, bottom row 0x00.
    final pixels = MonochromePixels(
      widthPx: 3,
      heightPx: 2,
      rows: [
        Uint8List.fromList([0x80]),
        Uint8List.fromList([0x00]),
      ],
    );
    final bmp = encodeMonochromeBmp(pixels, reverseRowOrder: false);
    final data = ByteData.sublistView(bmp);

    test('still declares a positive biHeight, same as the default — a '
        'negative biHeight is never emitted (confirmed to hang real Argox '
        'hardware, see encodeMonochromeBmp)', () {
      expect(data.getInt32(22, Endian.little), 2);
    });

    test('writes pixel rows in their original top-down order, unreversed '
        '(still bit-inverted)', () {
      // Unlike the default (reverseRowOrder: true), row 0 written is
      // `pixels.rows[0]` (0x80, inverted to 0x7F) directly, not the last
      // source row.
      expect(bmp.sublist(62, 66), [0x7F, 0x00, 0x00, 0x00]);
      expect(bmp.sublist(66, 70), [0xFF, 0x00, 0x00, 0x00]);
    });

    test('every other header field is unaffected by reverseRowOrder', () {
      expect(data.getUint32(2, Endian.little), 70); // bfSize
      expect(data.getInt32(18, Endian.little), 3); // biWidth
      expect(data.getUint16(28, Endian.little), 1); // biBitCount
    });
  });
}
