import 'package:label_core/label_core.dart';
import 'package:test/test.dart';

void main() {
  group('ResolvedPayload subtypes', () {
    test('ResolvedTextPayload has value equality', () {
      const a = ResolvedTextPayload(text: 'Parafuso', style: TextStyleSpec());
      const b = ResolvedTextPayload(text: 'Parafuso', style: TextStyleSpec());
      const c = ResolvedTextPayload(text: 'Outro', style: TextStyleSpec());
      expect(a, b);
      expect(a, isNot(c));
    });

    test('ResolvedBarcodePayload carries symbology and module width', () {
      const payload = ResolvedBarcodePayload(
        data: '789123456',
        symbology: BarcodeSymbology.code128,
        showText: true,
        moduleWidthDots: 3,
      );
      expect(payload.symbology, BarcodeSymbology.code128);
      expect(payload.moduleWidthDots, 3);
    });

    test('ResolvedShapePayload defaults cornerRadiusDots to 0', () {
      const payload = ResolvedShapePayload(
        kind: ShapeKind.ellipse,
        style: ShapeStyleSpec(),
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
            payload: ResolvedTextPayload(
              text: 'Parafuso',
              style: TextStyleSpec(),
            ),
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
          style: ShapeStyleSpec(),
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
          style: ShapeStyleSpec(),
        ),
      );
      expect(elementA, elementB);
    });
  });
}
