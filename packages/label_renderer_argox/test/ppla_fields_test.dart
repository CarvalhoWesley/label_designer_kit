import 'package:label_core/label_core.dart';
import 'package:label_renderer_argox/label_renderer_argox.dart';
import 'package:test/test.dart';

/// These expected values are copied verbatim from three independent,
/// real-world PPLA implementations (a Python driver tested against a real
/// Argox R-400 plus printer, a Node.js builder with byte-exact unit
/// tests, and an actively maintained TypeScript package) — see the
/// package README for links. All three agree on every value asserted
/// here.
void main() {
  group('pplaOrientationCode', () {
    test('maps the four fixed orientations to their non-sequential codes', () {
      expect(pplaOrientationCode(0), '1');
      expect(pplaOrientationCode(90), '4');
      expect(pplaOrientationCode(180), '3');
      expect(pplaOrientationCode(270), '2');
    });

    test(
      'snaps an arbitrary angle to the nearest of the four orientations',
      () {
        expect(pplaOrientationCode(10), '1');
        expect(pplaOrientationCode(80), '4');
        expect(pplaOrientationCode(100), '4');
        expect(pplaOrientationCode(200), '3');
        expect(pplaOrientationCode(350), '1');
      },
    );

    test('wraps negative angles the same way as their positive equivalent', () {
      expect(pplaOrientationCode(-90), pplaOrientationCode(270));
    });
  });

  group('pplaScaleCode', () {
    test('encodes 0-9 as themselves', () {
      for (var i = 0; i <= 9; i++) {
        expect(pplaScaleCode(i), '$i');
      }
    });

    test('encodes 10-24 as A-O', () {
      expect(pplaScaleCode(10), 'A');
      expect(pplaScaleCode(15), 'F');
      expect(pplaScaleCode(24), 'O');
    });

    test('clamps out-of-range values instead of throwing', () {
      expect(pplaScaleCode(-1), '0');
      expect(pplaScaleCode(99), 'O');
    });
  });

  group('pplaDigits', () {
    test('zero-pads to the requested width', () {
      expect(pplaDigits(7, 4), '0007');
      expect(pplaDigits(150, 4), '0150');
      expect(pplaDigits(1, 2), '01');
    });

    test('clamps negative input to zero instead of emitting a sign', () {
      expect(pplaDigits(-5, 4), '0000');
    });
  });

  group('pplaBarcodeTypeCode', () {
    test(
      'uppercase shows the human-readable text, lowercase suppresses it',
      () {
        expect(
          pplaBarcodeTypeCode(BarcodeSymbology.ean13, humanReadable: true),
          'F',
        );
        expect(
          pplaBarcodeTypeCode(BarcodeSymbology.ean13, humanReadable: false),
          'f',
        );
      },
    );

    test('covers every BarcodeSymbology label_barcode can encode', () {
      const expected = {
        BarcodeSymbology.code39: 'A',
        BarcodeSymbology.upc: 'B',
        BarcodeSymbology.itf: 'D',
        BarcodeSymbology.code128: 'E',
        BarcodeSymbology.ean13: 'F',
        BarcodeSymbology.ean8: 'G',
        BarcodeSymbology.codabar: 'I',
      };
      for (final entry in expected.entries) {
        expect(
          pplaBarcodeTypeCode(entry.key, humanReadable: true),
          entry.value,
        );
      }
    });
  });

  group('pplaAsdFontSubtype', () {
    test('picks the exact subtype when the point size matches exactly', () {
      // 12pt at 203dpi is 12 * 203 / 72 = 33.83 dots; round-tripping a
      // dot count derived from an exact point size must land on that
      // size's subtype.
      final dots = (12 * 203 / 72).round();
      expect(pplaAsdFontSubtype(dots, 203), '004'); // sizes[4] == 12pt
    });

    test(
      'rounds to the nearest of the fixed ASD sizes (4,6,8,10,12,14,16pt)',
      () {
        expect(pplaAsdFontSubtype((4 * 203 / 72).round(), 203), '000');
        expect(pplaAsdFontSubtype((6 * 203 / 72).round(), 203), '001');
        expect(pplaAsdFontSubtype((16 * 203 / 72).round(), 203), '006');
        // Halfway-ish between 8 and 10 should land on whichever is closer.
        final between = ((8 + 10) / 2 * 203 / 72).round();
        final subtype = pplaAsdFontSubtype(between, 203);
        expect(['002', '003'], contains(subtype));
      },
    );
  });
}
