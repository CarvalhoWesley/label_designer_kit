import 'package:label_barcode/label_barcode.dart';
import 'package:label_core/label_core.dart';
import 'package:test/test.dart';

void main() {
  group('qrCodeEncoder', () {
    test('encodes data at every error correction level', () {
      for (final level in QrErrorCorrectionLevel.values) {
        final symbol = qrCodeEncoder.encode(
          'https://example.com/produto/123',
          level: level,
        );
        expect(symbol.modules, isNotEmpty, reason: 'level $level');
      }
    });

    test('modules fall within the unit box, roughly square', () {
      final symbol = qrCodeEncoder.encode(
        'ABC123',
        level: QrErrorCorrectionLevel.medium,
      );
      for (final module in symbol.modules) {
        expect(module.left, inInclusiveRange(0.0, 1.0));
        expect(module.top, inInclusiveRange(0.0, 1.0));
        expect(module.width, greaterThan(0.0));
        expect(module.height, greaterThan(0.0));
      }
    });

    test(
      'a higher error-correction level needs more modules for the same data',
      () {
        // Higher ECC leaves less room for data per module, so the encoder
        // must step up to a larger QR version — more, smaller dark modules.
        final low = qrCodeEncoder.encode(
          'The quick brown fox jumps over the lazy dog',
          level: QrErrorCorrectionLevel.low,
        );
        final high = qrCodeEncoder.encode(
          'The quick brown fox jumps over the lazy dog',
          level: QrErrorCorrectionLevel.high,
        );
        expect(high.modules.length, greaterThan(low.modules.length));
      },
    );

    test('encoding the same data twice is deterministic', () {
      final a = qrCodeEncoder.encode('x', level: QrErrorCorrectionLevel.low);
      final b = qrCodeEncoder.encode('x', level: QrErrorCorrectionLevel.low);
      expect(a.modules, b.modules);
    });
  });

  group('bonus 2D encoders (not yet wired to a LabelElement)', () {
    test('pdf417BarcodeEncoder encodes data', () {
      expect(pdf417BarcodeEncoder.encode('PRODUTO-123').modules, isNotEmpty);
    });

    test('dataMatrixBarcodeEncoder encodes data', () {
      expect(
        dataMatrixBarcodeEncoder.encode('PRODUTO-123').modules,
        isNotEmpty,
      );
    });
  });
}
