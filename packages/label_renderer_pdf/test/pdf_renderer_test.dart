import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_pdf/label_renderer_pdf.dart';
import 'package:test/test.dart';

const _textStyle = ResolvedTextStyle(
  fontFamily: 'Roboto',
  fontSizeDots: 12,
  bold: false,
  italic: false,
  underline: false,
  color: 0xFF000000,
  alignment: TextAlignment.left,
);

/// A `package:pdf` document is a tree of plain-text objects (`/MediaBox`,
/// `/Type /Page`, ...) with only the individual stream *bodies* optionally
/// deflate-compressed — so, unlike a rasterized PNG, we can't decode pixel
/// colors to assert on the visual result (there's no PDF rasterizer in
/// pure Dart). These tests instead check the document's structure directly
/// and that every payload type renders without throwing; actual visual
/// correctness for this etapa is validated manually by opening a sample
/// PDF (see docs/ROADMAP.md, etapa 15).
const _pdfMagic = [0x25, 0x50, 0x44, 0x46];

void _expectValidPdf(Uint8List bytes) {
  expect(bytes.sublist(0, 4), _pdfMagic);
  final text = latin1.decode(bytes, allowInvalid: true);
  expect(text, contains('%%EOF'));
}

({double width, double height}) _mediaBoxSize(Uint8List bytes) {
  final text = latin1.decode(bytes, allowInvalid: true);
  final match = RegExp(
    r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]',
  ).firstMatch(text);
  if (match == null) {
    fail('no /MediaBox found in the generated PDF');
  }
  return (
    width: double.parse(match.group(1)!),
    height: double.parse(match.group(2)!),
  );
}

String _tinySolidColorPngDataUri(int argb) {
  final image = img.Image(width: 4, height: 4);
  img.fill(
    image,
    color: img.ColorRgba8(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
      (argb >> 24) & 0xFF,
    ),
  );
  final base64Png = base64Encode(img.encodePng(image));
  return 'data:image/png;base64,$base64Png';
}

void main() {
  const renderer = PdfRenderer();

  group('page and options', () {
    test('produces a valid PDF with no elements', () async {
      const document = ResolvedDocument(
        widthDots: 20,
        heightDots: 20,
        dpi: 203,
        elements: [],
      );
      final bytes = await renderer.render(document, const PdfRendererOptions());
      _expectValidPdf(bytes);
    });

    test(
      'falls back to default PdfRendererOptions when given a plain RendererOptions',
      () async {
        const document = ResolvedDocument(
          widthDots: 10,
          heightDots: 10,
          dpi: 203,
          elements: [],
        );
        await expectLater(
          renderer.render(document, const RendererOptions()),
          completes,
        );
      },
    );

    test(
      'page size in points matches widthDots/heightDots at the document dpi',
      () async {
        const document = ResolvedDocument(
          widthDots: 812,
          heightDots: 406,
          dpi: 203,
          elements: [],
        );
        final bytes = await renderer.render(
          document,
          const PdfRendererOptions(),
        );
        final size = _mediaBoxSize(bytes);
        expect(size.width, closeTo(812 * 72 / 203, 0.01));
        expect(size.height, closeTo(406 * 72 / 203, 0.01));
      },
    );
  });

  group('shapes', () {
    for (final kind in ShapeKind.values) {
      test('$kind renders without throwing', () async {
        final document = ResolvedDocument(
          widthDots: 40,
          heightDots: 40,
          dpi: 203,
          elements: [
            ResolvedElement(
              id: 'el-1',
              xDots: 5,
              yDots: 5,
              widthDots: 20,
              heightDots: 20,
              rotationDegrees: 0,
              zIndex: 0,
              opacity: 1,
              payload: ResolvedShapePayload(
                kind: kind,
                style: const ResolvedShapeStyle(
                  strokeColor: 0xFF000000,
                  strokeWidthDots: 2,
                  fillColor: 0xFF00FF00,
                ),
                cornerRadiusDots: kind == ShapeKind.rectangle ? 4 : 0,
              ),
            ),
          ],
        );
        final bytes = await renderer.render(
          document,
          const PdfRendererOptions(),
        );
        _expectValidPdf(bytes);
      });
    }
  });

  group('text', () {
    test('renders without throwing', () async {
      const document = ResolvedDocument(
        widthDots: 100,
        heightDots: 40,
        dpi: 203,
        elements: [
          ResolvedElement(
            id: 'el-1',
            xDots: 0,
            yDots: 0,
            widthDots: 100,
            heightDots: 40,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedTextPayload(
              text: 'Etiqueta Ação',
              style: _textStyle,
            ),
          ),
        ],
      );
      final bytes = await renderer.render(document, const PdfRendererOptions());
      _expectValidPdf(bytes);
    });

    test(
      'a custom fontResolver is used instead of the base-14 fallback',
      () async {
        const document = ResolvedDocument(
          widthDots: 100,
          heightDots: 40,
          dpi: 203,
          elements: [
            ResolvedElement(
              id: 'el-1',
              xDots: 0,
              yDots: 0,
              widthDots: 100,
              heightDots: 40,
              rotationDegrees: 0,
              zIndex: 0,
              opacity: 1,
              payload: ResolvedTextPayload(text: 'ABC', style: _textStyle),
            ),
          ],
        );
        var wasCalled = false;
        await renderer.render(
          document,
          PdfRendererOptions(
            fontResolver: (family, {required bool bold, required bool italic}) {
              wasCalled = true;
              return null;
            },
          ),
        );
        expect(wasCalled, isTrue);
      },
    );
  });

  group('barcode', () {
    test('a valid EAN13 renders without throwing', () async {
      const document = ResolvedDocument(
        widthDots: 120,
        heightDots: 40,
        dpi: 203,
        elements: [
          ResolvedElement(
            id: 'el-1',
            xDots: 0,
            yDots: 0,
            widthDots: 120,
            heightDots: 40,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedBarcodePayload(
              data: '5901234123457',
              symbology: BarcodeSymbology.ean13,
              showText: true,
              moduleWidthDots: 2,
              textSizeDots: 0,
            ),
          ),
        ],
      );
      final bytes = await renderer.render(document, const PdfRendererOptions());
      _expectValidPdf(bytes);
    });

    test(
      'invalid barcode data renders a placeholder instead of throwing',
      () async {
        const document = ResolvedDocument(
          widthDots: 60,
          heightDots: 30,
          dpi: 203,
          elements: [
            ResolvedElement(
              id: 'el-1',
              xDots: 0,
              yDots: 0,
              widthDots: 60,
              heightDots: 30,
              rotationDegrees: 0,
              zIndex: 0,
              opacity: 1,
              payload: ResolvedBarcodePayload(
                data: 'not-a-valid-ean13',
                symbology: BarcodeSymbology.ean13,
                showText: false,
                moduleWidthDots: 2,
                textSizeDots: 0,
              ),
            ),
          ],
        );
        await expectLater(
          renderer.render(document, const PdfRendererOptions()),
          completes,
        );
      },
    );
  });

  group('QR Code', () {
    test('renders without throwing', () async {
      const document = ResolvedDocument(
        widthDots: 60,
        heightDots: 60,
        dpi: 203,
        elements: [
          ResolvedElement(
            id: 'el-1',
            xDots: 0,
            yDots: 0,
            widthDots: 60,
            heightDots: 60,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedQrCodePayload(
              data: 'https://example.com',
              errorCorrectionLevel: QrErrorCorrectionLevel.medium,
            ),
          ),
        ],
      );
      final bytes = await renderer.render(document, const PdfRendererOptions());
      _expectValidPdf(bytes);
    });
  });

  group('image', () {
    test('embeds a decoded data: URI image without throwing', () async {
      final dataUri = _tinySolidColorPngDataUri(0xFFFF00FF);
      final document = ResolvedDocument(
        widthDots: 20,
        heightDots: 20,
        dpi: 203,
        elements: [
          ResolvedElement(
            id: 'el-1',
            xDots: 0,
            yDots: 0,
            widthDots: 20,
            heightDots: 20,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedImagePayload(source: dataUri, fit: ImageFit.fill),
          ),
        ],
      );
      final bytes = await renderer.render(document, const PdfRendererOptions());
      _expectValidPdf(bytes);
    });

    test('a cropped image renders without throwing', () async {
      final dataUri = _tinySolidColorPngDataUri(0xFF00FFFF);
      final document = ResolvedDocument(
        widthDots: 20,
        heightDots: 20,
        dpi: 203,
        elements: [
          ResolvedElement(
            id: 'el-1',
            xDots: 0,
            yDots: 0,
            widthDots: 20,
            heightDots: 20,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedImagePayload(
              source: dataUri,
              fit: ImageFit.contain,
              cropXDots: 1,
              cropYDots: 1,
              cropWidthDots: 2,
              cropHeightDots: 2,
            ),
          ),
        ],
      );
      final bytes = await renderer.render(document, const PdfRendererOptions());
      _expectValidPdf(bytes);
    });

    test(
      'an unresolvable source renders a placeholder instead of throwing',
      () async {
        const document = ResolvedDocument(
          widthDots: 20,
          heightDots: 20,
          dpi: 203,
          elements: [
            ResolvedElement(
              id: 'el-1',
              xDots: 0,
              yDots: 0,
              widthDots: 20,
              heightDots: 20,
              rotationDegrees: 0,
              zIndex: 0,
              opacity: 1,
              payload: ResolvedImagePayload(
                source: 'file:///nao/existe.png',
                fit: ImageFit.contain,
              ),
            ),
          ],
        );
        await expectLater(
          renderer.render(document, const PdfRendererOptions()),
          completes,
        );
      },
    );
  });

  group('rotation and opacity', () {
    test(
      'a rotated, semi-transparent element renders without throwing',
      () async {
        const document = ResolvedDocument(
          widthDots: 40,
          heightDots: 40,
          dpi: 203,
          elements: [
            ResolvedElement(
              id: 'el-1',
              xDots: 10,
              yDots: 10,
              widthDots: 20,
              heightDots: 20,
              rotationDegrees: 45,
              zIndex: 0,
              opacity: 0.5,
              payload: ResolvedShapePayload(
                kind: ShapeKind.rectangle,
                style: ResolvedShapeStyle(
                  strokeColor: 0xFF000000,
                  strokeWidthDots: 0,
                  fillColor: 0xFF00FF00,
                ),
              ),
            ),
          ],
        );
        final bytes = await renderer.render(
          document,
          const PdfRendererOptions(),
        );
        _expectValidPdf(bytes);
      },
    );
  });
}
