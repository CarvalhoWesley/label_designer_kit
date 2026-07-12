import 'package:label_core/label_core.dart';
import 'package:test/test.dart';

const _textStyle = ResolvedTextStyle(
  fontFamily: 'Roboto',
  fontSizeDots: 20,
  bold: false,
  italic: false,
  underline: false,
  color: 0xFF000000,
  alignment: TextAlignment.left,
);

const _shapeStyle = ResolvedShapeStyle(
  strokeColor: 0xFF000000,
  strokeWidthDots: 2,
);

void main() {
  group('ResolvedPayload subtypes', () {
    test('ResolvedTextPayload has value equality', () {
      const a = ResolvedTextPayload(text: 'Parafuso', style: _textStyle);
      const b = ResolvedTextPayload(text: 'Parafuso', style: _textStyle);
      const c = ResolvedTextPayload(text: 'Outro', style: _textStyle);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('ResolvedBarcodePayload carries symbology and module width', () {
      const payload = ResolvedBarcodePayload(
        data: '789123456',
        symbology: BarcodeSymbology.code128,
        showText: true,
        moduleWidthDots: 3,
        textSizeDots: 0,
      );
      expect(payload.symbology, BarcodeSymbology.code128);
      expect(payload.moduleWidthDots, 3);
    });

    test('ResolvedTextStyle carries fontSize already converted to dots', () {
      const style = ResolvedTextStyle(
        fontFamily: 'Roboto',
        fontSizeDots: 32,
        bold: true,
        italic: false,
        underline: false,
        color: 0xFF000000,
        alignment: TextAlignment.center,
      );
      expect(style.fontSizeDots, isA<int>());
      expect(style.fontSizeDots, 32);
    });

    test('ResolvedShapePayload defaults cornerRadiusDots to 0', () {
      const payload = ResolvedShapePayload(
        kind: ShapeKind.ellipse,
        style: _shapeStyle,
      );
      expect(payload.cornerRadiusDots, 0);
    });
  });

  group('ResolvedDocument', () {
    test('holds resolved elements with dot geometry', () {
      const document = ResolvedDocument(
        widthDots: 800,
        heightDots: 400,
        dpi: 203,
        elements: [
          ResolvedElement(
            id: 'el-1',
            xDots: 10,
            yDots: 10,
            widthDots: 100,
            heightDots: 40,
            rotationDegrees: 0,
            zIndex: 0,
            opacity: 1,
            payload: ResolvedTextPayload(text: 'Parafuso', style: _textStyle),
          ),
        ],
      );

      expect(document.elements, hasLength(1));
      expect(document.elements.single.payload, isA<ResolvedTextPayload>());
    });

    test('has value equality across nested payloads', () {
      const elementA = ResolvedElement(
        id: 'el-1',
        xDots: 0,
        yDots: 0,
        widthDots: 10,
        heightDots: 10,
        rotationDegrees: 0,
        zIndex: 0,
        opacity: 1,
        payload: ResolvedShapePayload(
          kind: ShapeKind.rectangle,
          style: _shapeStyle,
        ),
      );
      const elementB = ResolvedElement(
        id: 'el-1',
        xDots: 0,
        yDots: 0,
        widthDots: 10,
        heightDots: 10,
        rotationDegrees: 0,
        zIndex: 0,
        opacity: 1,
        payload: ResolvedShapePayload(
          kind: ShapeKind.rectangle,
          style: _shapeStyle,
        ),
      );
      expect(elementA, elementB);
    });
  });
}
