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

  group('pplaDotMultiplier', () {
    test('is 2 for 203 DPI print heads', () {
      expect(pplaDotMultiplier(203), 2);
    });

    test('is 1 for 300/400/600 DPI print heads', () {
      expect(pplaDotMultiplier(300), 1);
      expect(pplaDotMultiplier(400), 1);
      expect(pplaDotMultiplier(600), 1);
    });
  });

  group('pplaDotSizeCommand', () {
    test('is D22 for 203 DPI print heads', () {
      expect(pplaDotSizeCommand(203), 'D22');
    });

    test('is D11 for 300/400/600 DPI print heads', () {
      expect(pplaDotSizeCommand(300), 'D11');
      expect(pplaDotSizeCommand(400), 'D11');
      expect(pplaDotSizeCommand(600), 'D11');
    });
  });

  group('pplaHundredthsOfInch', () {
    test('converts dots at 203dpi to hundredths of an inch', () {
      // 203 dots at 203dpi is exactly 1.00 inch == 100 hundredths.
      expect(pplaHundredthsOfInch(203, 203), 100);
    });

    test('rounds to the nearest hundredth of an inch', () {
      expect(pplaHundredthsOfInch(75, 203), 37); // 36.945... -> 37
      expect(pplaHundredthsOfInch(10, 203), 5); // 4.926... -> 5
    });

    test('is independent of pplaDotSizeCommand — always dots/dpi*100', () {
      expect(pplaHundredthsOfInch(300, 300), 100);
      expect(pplaHundredthsOfInch(0, 203), 0);
    });
  });

  group('pplaAsdFontSubtype', () {
    test('picks the exact size code when the point size matches exactly', () {
      // 12pt at 203dpi is 12 * 203 / 72 = 33.83 dots; round-tripping a
      // dot count derived from an exact point size must land on that
      // size's code. 12pt is index 3 in pplaAsdFontSizesPt, so at <300 DPI
      // the numeric code is index+1 = 004.
      final dots = (12 * 203 / 72).round();
      expect(pplaAsdFontSubtype(dots, 203), '004');
    });

    test('rounds to the nearest of the fixed ASD sizes at 203 DPI '
        '(6,8,10,12,14,18,24,30,36,48pt — no 4pt/72pt below 300 DPI)', () {
      // Below the smallest available size (6pt), it clamps to 6pt (index 0,
      // code 001) rather than emitting the 300-DPI-only 4pt code (000).
      expect(pplaAsdFontSubtype((4 * 203 / 72).round(), 203), '001');
      expect(pplaAsdFontSubtype((6 * 203 / 72).round(), 203), '001');
      expect(pplaAsdFontSubtype((18 * 203 / 72).round(), 203), '006');
      expect(pplaAsdFontSubtype((48 * 203 / 72).round(), 203), '010');
      // Halfway-ish between 8 and 10 should land on whichever is closer.
      final between = ((8 + 10) / 2 * 203 / 72).round();
      final subtype = pplaAsdFontSubtype(between, 203);
      expect(['002', '003'], contains(subtype));
    });

    test('unlocks 4pt and 72pt only at 300 DPI and above', () {
      // At >=300 DPI the code is the bare index (0-based) since 000 is a
      // valid code there (4pt), unlike at <300 DPI where 000 is reserved.
      expect(pplaAsdFontSubtype((4 * 300 / 72).round(), 300), '000');
      expect(pplaAsdFontSubtype((72 * 300 / 72).round(), 300), '011');
    });
  });
}
