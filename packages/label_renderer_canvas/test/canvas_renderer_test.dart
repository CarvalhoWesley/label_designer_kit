import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' as painting;
import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_canvas/label_renderer_canvas.dart';

const _textStyle = ResolvedTextStyle(
  fontFamily: 'Roboto',
  fontSizeDots: 12,
  bold: false,
  italic: false,
  underline: false,
  color: 0xFF000000,
  alignment: TextAlignment.left,
);

Future<ui.Image> _decode(Uint8List pngBytes) async {
  final codec = await ui.instantiateImageCodec(pngBytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<int> _argbAt(ui.Image image, int x, int y) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  final r = byteData!.getUint8(offset);
  final g = byteData.getUint8(offset + 1);
  final b = byteData.getUint8(offset + 2);
  final a = byteData.getUint8(offset + 3);
  return (a << 24) | (r << 16) | (g << 8) | b;
}

/// Encodes a tiny solid-color PNG in-memory, for use as a `data:` URI in
/// [ResolvedImagePayload] tests — avoids depending on any file on disk.
Future<String> _tinySolidColorPngDataUri(int argb) async {
  final recorder = ui.PictureRecorder();
  final canvas = painting.Canvas(recorder);
  canvas.drawRect(
    const painting.Rect.fromLTWH(0, 0, 4, 4),
    painting.Paint()..color = painting.Color(argb),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(4, 4);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final base64Png = base64Encode(byteData!.buffer.asUint8List());
  return 'data:image/png;base64,$base64Png';
}

Future<bool> _hasAnyNonBackgroundPixel(
  ui.Image image,
  int x0,
  int y0,
  int x1,
  int y1,
  int backgroundArgb,
) async {
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      if (await _argbAt(image, x, y) != backgroundArgb) return true;
    }
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const renderer = CanvasRenderer();

  group('page and options', () {
    test(
      'fills the background with backgroundColor when there are no elements',
      () async {
        const document = ResolvedDocument(
          widthDots: 20,
          heightDots: 20,
          dpi: 203,
          elements: [],
        );
        final bytes = await renderer.render(
          document,
          const CanvasRendererOptions(backgroundColor: 0xFF3366CC),
        );
        final image = await _decode(bytes);
        expect(image.width, 20);
        expect(image.height, 20);
        expect(await _argbAt(image, 10, 10), 0xFF3366CC);
      },
    );

    test(
      'falls back to default CanvasRendererOptions when given a plain RendererOptions',
      () async {
        const document = ResolvedDocument(
          widthDots: 10,
          heightDots: 10,
          dpi: 203,
          elements: [],
        );
        final bytes = await renderer.render(document, const RendererOptions());
        final image = await _decode(bytes);
        expect(await _argbAt(image, 5, 5), 0xFFFFFFFF);
      },
    );

    test('pixelRatio scales the output image size', () async {
      const document = ResolvedDocument(
        widthDots: 10,
        heightDots: 10,
        dpi: 203,
        elements: [],
      );
      final bytes = await renderer.render(
        document,
        const CanvasRendererOptions(pixelRatio: 2.0),
      );
      final image = await _decode(bytes);
      expect(image.width, 20);
      expect(image.height, 20);
    });
  });

  group('shapes', () {
    test(
      'paints a filled rectangle at its resolved position, leaving the rest as background',
      () async {
        const document = ResolvedDocument(
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
          const CanvasRendererOptions(),
        );
        final image = await _decode(bytes);
        expect(await _argbAt(image, 15, 15), 0xFF00FF00);
        expect(await _argbAt(image, 1, 1), 0xFFFFFFFF);
      },
    );

    test('paints elements in zIndex order, higher on top', () async {
      const document = ResolvedDocument(
        widthDots: 20,
        heightDots: 20,
        dpi: 203,
        elements: [
          ResolvedElement(
            id: 'back',
            xDots: 0,
            yDots: 0,
            widthDots: 20,
            heightDots: 20,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedShapePayload(
              kind: ShapeKind.rectangle,
              style: ResolvedShapeStyle(
                strokeColor: 0xFF000000,
                strokeWidthDots: 0,
                fillColor: 0xFFFF0000,
              ),
            ),
          ),
          ResolvedElement(
            id: 'front',
            xDots: 0,
            yDots: 0,
            widthDots: 20,
            heightDots: 20,
            rotationDegrees: 0,
            zIndex: 1,
            opacity: 1,
            payload: ResolvedShapePayload(
              kind: ShapeKind.rectangle,
              style: ResolvedShapeStyle(
                strokeColor: 0xFF000000,
                strokeWidthDots: 0,
                fillColor: 0xFF0000FF,
              ),
            ),
          ),
        ],
      );
      final bytes = await renderer.render(
        document,
        const CanvasRendererOptions(),
      );
      final image = await _decode(bytes);
      expect(await _argbAt(image, 10, 10), 0xFF0000FF);
    });

    test('a rounded rectangle leaves its corners as background', () async {
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
            payload: ResolvedShapePayload(
              kind: ShapeKind.rectangle,
              style: ResolvedShapeStyle(
                strokeColor: 0xFF000000,
                strokeWidthDots: 0,
                fillColor: 0xFF00FF00,
              ),
              cornerRadiusDots: 8,
            ),
          ),
        ],
      );
      final bytes = await renderer.render(
        document,
        const CanvasRendererOptions(),
      );
      final image = await _decode(bytes);
      expect(await _argbAt(image, 0, 0), 0xFFFFFFFF);
      expect(await _argbAt(image, 10, 10), 0xFF00FF00);
    });

    test('opacity blends the element color with the background', () async {
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
            opacity: 0.5,
            payload: ResolvedShapePayload(
              kind: ShapeKind.rectangle,
              style: ResolvedShapeStyle(
                strokeColor: 0xFF000000,
                strokeWidthDots: 0,
                fillColor: 0xFF000000,
              ),
            ),
          ),
        ],
      );
      final bytes = await renderer.render(
        document,
        const CanvasRendererOptions(backgroundColor: 0xFFFFFFFF),
      );
      final image = await _decode(bytes);
      final argb = await _argbAt(image, 10, 10);
      final red = (argb >> 16) & 0xFF;
      // Black at 50% opacity over white should land roughly mid-gray —
      // neither pure white (255) nor pure black (0).
      expect(red, inInclusiveRange(80, 180));
    });
  });

  group('text', () {
    test(
      'renders text without throwing and paints some ink inside its box',
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
        final bytes = await renderer.render(
          document,
          const CanvasRendererOptions(),
        );
        final image = await _decode(bytes);
        expect(
          await _hasAnyNonBackgroundPixel(image, 0, 0, 100, 40, 0xFFFFFFFF),
          isTrue,
        );
      },
    );
  });

  group('barcode', () {
    test('a valid EAN13 paints ink inside its box', () async {
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
              showText: false,
              moduleWidthDots: 2,
            ),
          ),
        ],
      );
      final bytes = await renderer.render(
        document,
        const CanvasRendererOptions(),
      );
      final image = await _decode(bytes);
      expect(
        await _hasAnyNonBackgroundPixel(image, 0, 0, 120, 40, 0xFFFFFFFF),
        isTrue,
      );
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
              ),
            ),
          ],
        );

        await expectLater(
          renderer.render(document, const CanvasRendererOptions()),
          completes,
        );
      },
    );
  });

  group('QR Code', () {
    test('paints ink inside its box', () async {
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
      final bytes = await renderer.render(
        document,
        const CanvasRendererOptions(),
      );
      final image = await _decode(bytes);
      expect(
        await _hasAnyNonBackgroundPixel(image, 0, 0, 60, 60, 0xFFFFFFFF),
        isTrue,
      );
    });
  });

  group('image', () {
    test('paints a decoded data: URI image', () async {
      final dataUri = await _tinySolidColorPngDataUri(0xFFFF00FF);
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
      final bytes = await renderer.render(
        document,
        const CanvasRendererOptions(),
      );
      final image = await _decode(bytes);
      expect(await _argbAt(image, 10, 10), 0xFFFF00FF);
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
          renderer.render(document, const CanvasRendererOptions()),
          completes,
        );
      },
    );
  });

  group('rotation', () {
    test(
      'rotating an element does not throw and keeps the output size correct',
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
              opacity: 1,
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
          const CanvasRendererOptions(),
        );
        final image = await _decode(bytes);
        expect(image.width, 40);
        expect(image.height, 40);
        // The element's own center should still be painted regardless of
        // rotation (rotating around the center leaves the center fixed).
        expect(await _argbAt(image, 20, 20), 0xFF00FF00);
      },
    );
  });
}
