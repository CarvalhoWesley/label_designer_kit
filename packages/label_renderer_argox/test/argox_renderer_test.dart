import 'dart:convert';

import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_argox/label_renderer_argox.dart';
import 'package:test/test.dart';

const _textStyle = ResolvedTextStyle(
  fontFamily: 'Roboto',
  fontSizeDots: 34, // ~12pt at 203dpi -> ASD size code '004'
  bold: false,
  italic: false,
  underline: false,
  color: 0xFF000000,
  alignment: TextAlignment.left,
);

ResolvedDocument _documentWith(
  ResolvedElement element, {
  int heightDots = 100,
}) => ResolvedDocument(
  widthDots: 200,
  heightDots: heightDots,
  dpi: 203,
  elements: [element],
);

Future<String> _render(
  ResolvedDocument document, [
  RendererOptions options = const ArgoxRendererOptions(),
]) async {
  const renderer = ArgoxRenderer();
  final bytes = await renderer.render(document, options);
  return latin1.decode(bytes);
}

/// Builds the expected command string from its individual fields instead
/// of a single hand-typed literal — a fixed-width digit string like
/// `191100400750010ABC` is very easy to mistype/miscount by hand, and a
/// wrong-by-one-zero literal would silently assert the wrong thing.
String _expectedTextCommand({
  required String orientation,
  required String fontType,
  required String hScale,
  required String vScale,
  required String fontSubtype,
  required String y,
  required String x,
  required String text,
}) => '$orientation$fontType$hScale$vScale$fontSubtype$y$x$text\r';

String _expectedBarcodeCommand({
  required String orientation,
  required String type,
  required String wideBar,
  required String narrowBar,
  required String height,
  required String y,
  required String x,
  required String data,
}) => '$orientation$type$wideBar$narrowBar$height$y$x$data\r';

String _expectedBoxCommand({
  required String orientation,
  required String y,
  required String x,
  required String width,
  required String height,
  required String thickness,
}) => '${orientation}X11000$y${x}b$width$height$thickness$thickness\r';

String _expectedLineCommand({
  required String orientation,
  required String y,
  required String x,
  required String width,
  required String height,
}) => '${orientation}X11000$y${x}l$width$height\r';

void main() {
  group('header and footer', () {
    test('wraps the label in STX-L / D.. / H.. and Q../E', () async {
      const document = ResolvedDocument(
        widthDots: 200,
        heightDots: 100,
        dpi: 203,
        elements: [],
      );
      final output = await _render(document);

      expect(output, contains('\x02L\r'));
      // D22, not D11 — see pplaDotSizeCommand: 203 DPI print heads default
      // to D22 per the Datamax Class Series 2 Programmer's Manual.
      expect(output, contains('D22\r'));
      expect(output, contains('H10\r')); // default darkness
      expect(output, endsWith('Q0001\rE\r')); // default copies
    });

    test('encodes D11 (not D22) for a 300 DPI document', () async {
      const document = ResolvedDocument(
        widthDots: 200,
        heightDots: 100,
        dpi: 300,
        elements: [],
      );
      final output = await _render(document);
      expect(output, contains('D11\r'));
    });

    test(
      'labelFormatHeader honors dotMultiplierOverride instead of the '
      "document's own DPI-based default",
      () {
        const document = ResolvedDocument(
          widthDots: 200,
          heightDots: 100,
          dpi: 203, // would normally default to D22
          elements: [],
        );
        const renderer = ArgoxRenderer();
        final withOverride = renderer.labelFormatHeader(
          document,
          const ArgoxRendererOptions(),
          dotMultiplierOverride: 1,
        );
        expect(withOverride, contains('D11\r'));

        final withoutOverride = renderer.labelFormatHeader(
          document,
          const ArgoxRendererOptions(),
        );
        expect(withoutOverride, contains('D22\r'));
      },
    );

    test('encodes darkness and copies from ArgoxRendererOptions', () async {
      const document = ResolvedDocument(
        widthDots: 200,
        heightDots: 100,
        dpi: 203,
        elements: [],
      );
      final output = await _render(
        document,
        const ArgoxRendererOptions(darkness: 18, copies: 5),
      );

      expect(output, contains('H18\r'));
      expect(output, endsWith('Q0005\rE\r'));
    });

    test('encodes the label length in hundredths of an inch', () async {
      // 203 dots at 203dpi == 1.00 inch == 0100 hundredths.
      const document = ResolvedDocument(
        widthDots: 200,
        heightDots: 203,
        dpi: 203,
        elements: [],
      );
      final output = await _render(document);
      expect(output, contains('\x02c0100\r'));
    });

    test('throws UnimplementedError for the pplb dialect', () {
      const document = ResolvedDocument(
        widthDots: 200,
        heightDots: 100,
        dpi: 203,
        elements: [],
      );
      const renderer = ArgoxRenderer();
      expect(
        () => renderer.render(
          document,
          const ArgoxRendererOptions(dialect: ArgoxDialect.pplb),
        ),
        throwsUnimplementedError,
      );
    });
  });

  group('text', () {
    test(
      "flips Y to PPLA's bottom-left origin and pads x/y to 4 digits",
      () async {
        const element = ResolvedElement(
          id: 'el-1',
          xDots: 10,
          yDots: 5,
          widthDots: 50,
          heightDots: 20,
          rotationDegrees: 0,
          zIndex: 0,
          opacity: 1,
          payload: ResolvedTextPayload(text: 'ABC', style: _textStyle),
        );
        // document height 100, element top=5 height=20 -> PPLA y (bottom of
        // box, measured from the label's bottom) = 100 - 5 - 20 = 75 dots,
        // converted to hundredths of an inch at 203dpi: round(75*100/203)
        // = 37. x: round(10*100/203) = 5.
        final output = await _render(_documentWith(element));

        expect(
          output,
          contains(
            _expectedTextCommand(
              orientation: '1',
              fontType: '9',
              hScale: '1',
              vScale: '1',
              fontSubtype: '004',
              y: '0037',
              x: '0005',
              text: 'ABC',
            ),
          ),
        );
      },
    );

    test(
      'rounds rotationDegrees to the nearest fixed PPLA orientation',
      () async {
        const element = ResolvedElement(
          id: 'el-1',
          xDots: 0,
          yDots: 0,
          widthDots: 50,
          heightDots: 20,
          rotationDegrees: 100,
          zIndex: 0,
          opacity: 1,
          payload: ResolvedTextPayload(text: 'X', style: _textStyle),
        );
        final output = await _render(_documentWith(element));

        // 100 degrees snaps to 90 -> orientation code '4'; y (dots) =
        // 100-0-20=80, converted: round(80*100/203) = 39.
        expect(
          output,
          contains(
            _expectedTextCommand(
              orientation: '4',
              fontType: '9',
              hScale: '1',
              vScale: '1',
              fontSubtype: '004',
              y: '0039',
              x: '0000',
              text: 'X',
            ),
          ),
        );
      },
    );
  });

  group('barcode', () {
    test(
      'encodes rotation, type letter, bar widths, height, y, x and data',
      () async {
        const element = ResolvedElement(
          id: 'el-1',
          xDots: 10,
          yDots: 0,
          widthDots: 100,
          heightDots: 40,
          rotationDegrees: 0,
          zIndex: 0,
          opacity: 1,
          payload: ResolvedBarcodePayload(
            data: '123456',
            symbology: BarcodeSymbology.code128,
            showText: true,
            moduleWidthDots: 2,
            textSizeDots: 0,
          ),
        );
        final output = await _render(_documentWith(element, heightDots: 40));

        // y (bottom of box, dots) = 40 - 0 - 40 = 0. x: round(10*100/203)
        // = 5. height: round(40*100/203) = 20 -- hundredths of an inch,
        // not dots (bar width stays in dots, see [_encodeBarcode]).
        expect(
          output,
          contains(
            _expectedBarcodeCommand(
              orientation: '1',
              type: 'E', // code-128, showText: true -> uppercase (readable)
              wideBar: '2',
              narrowBar: '2',
              height: '020',
              y: '0000',
              x: '0005',
              data: '123456',
            ),
          ),
        );
      },
    );

    test(
      'showText false selects the lowercase (non-readable) type letter',
      () async {
        const element = ResolvedElement(
          id: 'el-1',
          xDots: 0,
          yDots: 0,
          widthDots: 100,
          heightDots: 40,
          rotationDegrees: 0,
          zIndex: 0,
          opacity: 1,
          payload: ResolvedBarcodePayload(
            data: '123456',
            symbology: BarcodeSymbology.code128,
            showText: false,
            moduleWidthDots: 2,
            textSizeDots: 0,
          ),
        );
        final output = await _render(_documentWith(element, heightDots: 40));
        // height in hundredths of an inch: round(40*100/203) = 20.
        expect(output, contains('1e22020'));
      },
    );

    test('every declared BarcodeSymbology has a known PPLA type letter', () {
      for (final symbology in BarcodeSymbology.values) {
        expect(
          pplaBarcodeTypeCode(symbology, humanReadable: true),
          isNotNull,
          reason: '$symbology should map to a PPLA type letter',
        );
      }
    });
  });

  group('shapes', () {
    test(
      'a rectangle becomes a box command with matching width/height',
      () async {
        const element = ResolvedElement(
          id: 'el-1',
          xDots: 5,
          yDots: 5,
          widthDots: 40,
          heightDots: 20,
          rotationDegrees: 0,
          zIndex: 0,
          opacity: 1,
          payload: ResolvedShapePayload(
            kind: ShapeKind.rectangle,
            style: ResolvedShapeStyle(
              strokeColor: 0xFF000000,
              strokeWidthDots: 2,
            ),
          ),
        );
        // document height 100 (default), y (dots, bottom) = 100-5-20=75 ->
        // round(75*100/203) = 37. x: round(5*100/203) = 2. width:
        // round(40*100/203) = 20. height: round(20*100/203) = 10.
        // thickness: round(2*100/203) = 1.
        final output = await _render(_documentWith(element));

        expect(
          output,
          contains(
            _expectedBoxCommand(
              orientation: '1',
              y: '0037',
              x: '0002',
              width: '0020',
              height: '0010',
              thickness: '0001',
            ),
          ),
        );
      },
    );

    test(
      'ellipse and circle fall back to their bounding box (no curve primitive in PPLA)',
      () async {
        for (final kind in [ShapeKind.ellipse, ShapeKind.circle]) {
          final element = ResolvedElement(
            id: 'el-1',
            xDots: 0,
            yDots: 0,
            widthDots: 30,
            heightDots: 30,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedShapePayload(
              kind: kind,
              style: const ResolvedShapeStyle(
                strokeColor: 0xFF000000,
                strokeWidthDots: 1,
              ),
            ),
          );
          final output = await _render(_documentWith(element));
          expect(output, contains('X11000'));
          expect(output, contains('b'));
        }
      },
    );

    test('a line becomes an axis-aligned line command', () async {
      const element = ResolvedElement(
        id: 'el-1',
        xDots: 0,
        yDots: 0,
        widthDots: 60,
        heightDots: 0,
        rotationDegrees: 0,
        zIndex: 0,
        opacity: 1,
        payload: ResolvedShapePayload(
          kind: ShapeKind.line,
          style: ResolvedShapeStyle(
            strokeColor: 0xFF000000,
            strokeWidthDots: 1,
          ),
        ),
      );
      // document height 100 (default), y (dots, bottom) = 100-0-0=100 ->
      // round(100*100/203) = 49. width: round(60*100/203) = 30.
      final output = await _render(_documentWith(element));

      expect(
        output,
        contains(
          _expectedLineCommand(
            orientation: '1',
            y: '0049',
            x: '0000',
            width: '0030',
            height: '0000',
          ),
        ),
      );
    });
  });

  group('unsupported payloads', () {
    test(
      'QR Code is skipped rather than emitting an unvalidated guess',
      () async {
        const element = ResolvedElement(
          id: 'el-1',
          xDots: 0,
          yDots: 0,
          widthDots: 40,
          heightDots: 40,
          rotationDegrees: 0,
          zIndex: 0,
          opacity: 1,
          payload: ResolvedQrCodePayload(
            data: 'https://example.com',
            errorCorrectionLevel: QrErrorCorrectionLevel.medium,
          ),
        );
        final output = await _render(_documentWith(element));

        // Header ends with H../CR immediately followed by the footer's Q..
        // -- nothing was emitted in between for the unsupported payload.
        expect(RegExp(r'H\d\d\rQ\d{4}\r').hasMatch(output), isTrue);
      },
    );

    test(
      'images are skipped rather than emitting an unvalidated guess',
      () async {
        const element = ResolvedElement(
          id: 'el-1',
          xDots: 0,
          yDots: 0,
          widthDots: 40,
          heightDots: 40,
          rotationDegrees: 0,
          zIndex: 0,
          opacity: 1,
          payload: ResolvedImagePayload(
            source: 'data:...',
            fit: ImageFit.contain,
          ),
        );
        final output = await _render(_documentWith(element));

        expect(RegExp(r'H\d\d\rQ\d{4}\r').hasMatch(output), isTrue);
      },
    );
  });
}
