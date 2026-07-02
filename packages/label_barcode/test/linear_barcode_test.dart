import 'package:label_barcode/label_barcode.dart';
import 'package:label_core/label_core.dart';
import 'package:test/test.dart';

void main() {
  group('linearBarcodeEncoders registry', () {
    test('has one encoder per BarcodeSymbology value', () {
      for (final symbology in BarcodeSymbology.values) {
        expect(
          linearBarcodeEncoders.containsKey(symbology),
          isTrue,
          reason: '$symbology has no registered encoder',
        );
      }
    });
  });

  group('module extraction', () {
    test('EAN13 modules are non-empty and fall within the unit box', () {
      // 5901234123457 is a well-known valid EAN-13 (correct check digit
      // 7, verified by hand against the GS1 checksum algorithm).
      final symbol = linearBarcodeEncoders[BarcodeSymbology.ean13]!.encode(
        '5901234123457',
      );

      expect(symbol.modules, isNotEmpty);
      for (final module in symbol.modules) {
        expect(module.left, inInclusiveRange(0.0, 1.0));
        expect(module.width, greaterThan(0.0));
        expect(module.left + module.width, lessThanOrEqualTo(1.0001));
        // A 1D symbol's bars span the full height.
        expect(module.top, 0.0);
        expect(module.height, 1.0);
      }
    });

    test('encoding the same data twice is deterministic', () {
      final encoder = linearBarcodeEncoders[BarcodeSymbology.code128]!;
      final a = encoder.encode('PROD-12345');
      final b = encoder.encode('PROD-12345');
      expect(a.modules, b.modules);
    });

    test('different data produces different modules', () {
      final encoder = linearBarcodeEncoders[BarcodeSymbology.code128]!;
      final a = encoder.encode('AAAA');
      final b = encoder.encode('ZZZZ');
      expect(a.modules, isNot(b.modules));
    });
  });

  group('EAN13 checksum validation (delegated to package:barcode)', () {
    test('accepts a code with a correct check digit', () {
      expect(
        () => linearBarcodeEncoders[BarcodeSymbology.ean13]!.encode(
          '5901234123457',
        ),
        returnsNormally,
      );
    });

    test('rejects a code with an incorrect check digit', () {
      expect(
        () => linearBarcodeEncoders[BarcodeSymbology.ean13]!.encode(
          '5901234123458',
        ),
        throwsA(isA<BarcodeEncodingException>()),
      );
    });

    test('rejects a code of the wrong length', () {
      expect(
        () => linearBarcodeEncoders[BarcodeSymbology.ean13]!.encode('12345'),
        throwsA(isA<BarcodeEncodingException>()),
      );
    });
  });

  group('other linear symbologies encode representative data', () {
    test('EAN8', () {
      // 73513537 is a commonly cited valid EAN-8 (check digit 7).
      expect(
        linearBarcodeEncoders[BarcodeSymbology.ean8]!
            .encode('73513537')
            .modules,
        isNotEmpty,
      );
    });

    test('Code39', () {
      expect(
        linearBarcodeEncoders[BarcodeSymbology.code39]!
            .encode('PRODUTO-1')
            .modules,
        isNotEmpty,
      );
    });

    test('UPC-A', () {
      // 036000291452 is the well-known Wrigley's gum UPC-A reference code.
      expect(
        linearBarcodeEncoders[BarcodeSymbology.upc]!
            .encode('036000291452')
            .modules,
        isNotEmpty,
      );
    });

    test('ITF (Interleaved 2 of 5) requires an even number of digits', () {
      expect(
        linearBarcodeEncoders[BarcodeSymbology.itf]!.encode('12345678').modules,
        isNotEmpty,
      );
    });

    test('Codabar', () {
      // Start/stop letters (A-D) are supplied via the encoder's own
      // configuration, not embedded in the data string by default.
      expect(
        linearBarcodeEncoders[BarcodeSymbology.codabar]!
            .encode('12345-6789')
            .modules,
        isNotEmpty,
      );
    });
  });
}
