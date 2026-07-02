import 'package:label_core/label_core.dart';
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:test/test.dart';

LabelDocument _documentWith({
  required List<LabelElement> elements,
  List<LabelStyle> styles = const [],
  Dpi dpi = Dpi.dpi203,
}) {
  final now = DateTime.utc(2026, 7, 2);
  return LabelDocument(
    name: 'Teste',
    page: PageConfig(width: 100, height: 50, dpi: dpi),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    styles: styles,
    elements: elements,
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}

void main() {
  const engine = LabelLayoutEngine();

  group('page resolution', () {
    test('converts page width/height/dpi to dots', () {
      final document = _documentWith(elements: const []);
      final resolved = engine.resolve(document, {});

      expect(resolved.dpi, 203);
      expect(resolved.widthDots, Dpi.dpi203.mmToDots(100));
      expect(resolved.heightDots, Dpi.dpi203.mmToDots(50));
    });
  });

  group('basic element resolution (no rotation, no group)', () {
    test('converts position/size from mm to dots', () {
      final document = _documentWith(
        elements: const [
          RectangleElement(
            id: 'el-1',
            name: 'Caixa',
            position: Point(x: 10, y: 5),
            size: Size2D(width: 40, height: 20),
            layerId: 'layer-1',
          ),
        ],
      );

      final resolved = engine.resolve(document, {});
      final element = resolved.elements.single;

      expect(element.xDots, Dpi.dpi203.mmToDots(10));
      expect(element.yDots, Dpi.dpi203.mmToDots(5));
      expect(element.widthDots, Dpi.dpi203.mmToDots(40));
      expect(element.heightDots, Dpi.dpi203.mmToDots(20));
      expect(element.rotationDegrees, 0);
    });

    test('carries zIndex and opacity through unchanged', () {
      final document = _documentWith(
        elements: const [
          RectangleElement(
            id: 'el-1',
            name: 'Caixa',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 10, height: 10),
            layerId: 'layer-1',
            zIndex: 7,
            opacity: 0.5,
          ),
        ],
      );

      final element = engine.resolve(document, {}).elements.single;
      expect(element.zIndex, 7);
      expect(element.opacity, 0.5);
    });

    test('resolves an unrotated element to a rotationDegrees of 0', () {
      final document = _documentWith(
        elements: const [
          CircleElement(
            id: 'el-1',
            name: 'Círculo',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 10, height: 10),
            layerId: 'layer-1',
          ),
        ],
      );
      expect(engine.resolve(document, {}).elements.single.rotationDegrees, 0);
    });

    test(
      'a positive element rotation passes through unchanged at the root',
      () {
        final document = _documentWith(
          elements: const [
            RectangleElement(
              id: 'el-1',
              name: 'Caixa',
              position: Point(x: 0, y: 0),
              size: Size2D(width: 10, height: 10),
              layerId: 'layer-1',
              rotation: 45,
            ),
          ],
        );
        expect(
          engine.resolve(document, {}).elements.single.rotationDegrees,
          45,
        );
      },
    );
  });

  group('text resolution', () {
    test('resolves {{ }} placeholders mixed with literal text', () {
      final document = _documentWith(
        elements: const [
          TextElement(
            id: 'el-1',
            name: 'Nome',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 40, height: 8),
            layerId: 'layer-1',
            content: 'Lote: {{ lote }}',
          ),
        ],
      );
      final payload =
          engine.resolve(document, {'lote': 'A123'}).elements.single.payload
              as ResolvedTextPayload;
      expect(payload.text, 'Lote: A123');
    });

    test(
      'an undefined variable resolves to the #ERROR# marker, not a throw',
      () {
        final document = _documentWith(
          elements: const [
            TextElement(
              id: 'el-1',
              name: 'Nome',
              position: Point(x: 0, y: 0),
              size: Size2D(width: 40, height: 8),
              layerId: 'layer-1',
              content: '{{ inexistente }}',
            ),
          ],
        );
        final payload =
            engine.resolve(document, {}).elements.single.payload
                as ResolvedTextPayload;
        expect(payload.text, '#ERROR#');
      },
    );

    test('resolves a styleId reference over the inline style', () {
      final document = _documentWith(
        styles: const [
          LabelStyle(
            id: 'style-titulo',
            name: 'Título',
            spec: TextStyleSpec(fontSize: 6, bold: true),
          ),
        ],
        elements: const [
          TextElement(
            id: 'el-1',
            name: 'Nome',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 40, height: 8),
            layerId: 'layer-1',
            content: 'x',
            styleId: 'style-titulo',
          ),
        ],
      );
      final payload =
          engine.resolve(document, {}).elements.single.payload
              as ResolvedTextPayload;
      expect(payload.style.fontSizeDots, Dpi.dpi203.mmToDots(6));
      expect(payload.style.bold, true);
    });

    test('falls back to the inline style when styleId is not found', () {
      final document = _documentWith(
        elements: const [
          TextElement(
            id: 'el-1',
            name: 'Nome',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 40, height: 8),
            layerId: 'layer-1',
            content: 'x',
            styleId: 'style-inexistente',
            style: TextStyleSpec(fontSize: 9),
          ),
        ],
      );
      final payload =
          engine.resolve(document, {}).elements.single.payload
              as ResolvedTextPayload;
      expect(payload.style.fontSizeDots, Dpi.dpi203.mmToDots(9));
    });
  });

  group('VariableElement resolution', () {
    test('evaluates the expression and stringifies the result', () {
      final document = _documentWith(
        elements: const [
          VariableElement(
            id: 'el-1',
            name: 'Preço',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 20, height: 8),
            layerId: 'layer-1',
            expression: 'preco.currency()',
          ),
        ],
      );
      final payload =
          engine.resolve(document, {'preco': 10}).elements.single.payload
              as ResolvedTextPayload;
      expect(payload.text, r'R$ 10,00');
    });
  });

  group('DateElement/TimeElement resolution', () {
    test('formats a value read from a declared variable', () {
      final document = _documentWith(
        elements: const [
          DateElement(
            id: 'el-1',
            name: 'Validade',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 20, height: 8),
            layerId: 'layer-1',
            format: 'dd/MM/yyyy',
            source: DateTimeSource.variable,
            variableName: 'validade',
          ),
        ],
      );
      final payload =
          engine
                  .resolve(document, {'validade': DateTime(2026, 12, 31)})
                  .elements
                  .single
                  .payload
              as ResolvedTextPayload;
      expect(payload.text, '31/12/2026');
    });

    test(
      'throws LayoutException when source is variable but variableName is null',
      () {
        final document = _documentWith(
          elements: const [
            TimeElement(
              id: 'el-1',
              name: 'Hora',
              position: Point(x: 0, y: 0),
              size: Size2D(width: 20, height: 8),
              layerId: 'layer-1',
              source: DateTimeSource.variable,
            ),
          ],
        );
        expect(
          () => engine.resolve(document, {}),
          throwsA(isA<LayoutException>()),
        );
      },
    );

    test('a missing row value resolves to the #ERROR# marker', () {
      final document = _documentWith(
        elements: const [
          DateElement(
            id: 'el-1',
            name: 'Validade',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 20, height: 8),
            layerId: 'layer-1',
            source: DateTimeSource.variable,
            variableName: 'validade',
          ),
        ],
      );
      final payload =
          engine.resolve(document, {}).elements.single.payload
              as ResolvedTextPayload;
      expect(payload.text, '#ERROR#');
    });
  });

  group('BarcodeElement/QRCodeElement resolution', () {
    test('resolves a placeholder inside barcode data', () {
      final document = _documentWith(
        elements: const [
          BarcodeElement(
            id: 'el-1',
            name: 'Código',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 40, height: 15),
            layerId: 'layer-1',
            data: '{{ codigo }}',
            symbology: BarcodeSymbology.code128,
            moduleWidth: 0.5,
          ),
        ],
      );
      final payload =
          engine
                  .resolve(document, {'codigo': '789123456'})
                  .elements
                  .single
                  .payload
              as ResolvedBarcodePayload;
      expect(payload.data, '789123456');
      expect(payload.symbology, BarcodeSymbology.code128);
      expect(payload.moduleWidthDots, Dpi.dpi203.mmToDots(0.5));
    });

    test('resolves QRCodeElement data and error correction level', () {
      final document = _documentWith(
        elements: const [
          QRCodeElement(
            id: 'el-1',
            name: 'QR',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 20, height: 20),
            layerId: 'layer-1',
            data: '{{ url }}',
            errorCorrectionLevel: QrErrorCorrectionLevel.high,
          ),
        ],
      );
      final payload =
          engine
                  .resolve(document, {'url': 'https://x.io'})
                  .elements
                  .single
                  .payload
              as ResolvedQrCodePayload;
      expect(payload.data, 'https://x.io');
      expect(payload.errorCorrectionLevel, QrErrorCorrectionLevel.high);
    });
  });

  group('ImageElement resolution', () {
    test('converts crop rectangle from mm to dots', () {
      final document = _documentWith(
        elements: const [
          ImageElement(
            id: 'el-1',
            name: 'Logo',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 20, height: 20),
            layerId: 'layer-1',
            source: 'logo.png',
            cropPosition: Point(x: 1, y: 1),
            cropSize: Size2D(width: 5, height: 5),
          ),
        ],
      );
      final payload =
          engine.resolve(document, {}).elements.single.payload
              as ResolvedImagePayload;
      expect(payload.cropXDots, Dpi.dpi203.mmToDots(1));
      expect(payload.cropWidthDots, Dpi.dpi203.mmToDots(5));
    });

    test('leaves crop fields null when no crop is set', () {
      final document = _documentWith(
        elements: const [
          ImageElement(
            id: 'el-1',
            name: 'Logo',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 20, height: 20),
            layerId: 'layer-1',
            source: 'logo.png',
          ),
        ],
      );
      final payload =
          engine.resolve(document, {}).elements.single.payload
              as ResolvedImagePayload;
      expect(payload.cropXDots, isNull);
    });
  });

  group('shape resolution', () {
    test('RectangleElement resolves cornerRadius to dots', () {
      final document = _documentWith(
        elements: const [
          RectangleElement(
            id: 'el-1',
            name: 'Caixa',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 10, height: 10),
            layerId: 'layer-1',
            cornerRadius: 2,
          ),
        ],
      );
      final payload =
          engine.resolve(document, {}).elements.single.payload
              as ResolvedShapePayload;
      expect(payload.kind, ShapeKind.rectangle);
      expect(payload.cornerRadiusDots, Dpi.dpi203.mmToDots(2));
    });

    test(
      'LineElement folds strokeColor/strokeWidth into a ResolvedShapeStyle',
      () {
        final document = _documentWith(
          elements: const [
            LineElement(
              id: 'el-1',
              name: 'Linha',
              position: Point(x: 0, y: 0),
              size: Size2D(width: 10, height: 0),
              layerId: 'layer-1',
              strokeColor: 0xFFFF0000,
              strokeWidth: 0.8,
            ),
          ],
        );
        final payload =
            engine.resolve(document, {}).elements.single.payload
                as ResolvedShapePayload;
        expect(payload.kind, ShapeKind.line);
        expect(payload.style.strokeColor, 0xFFFF0000);
        expect(payload.style.strokeWidthDots, Dpi.dpi203.mmToDots(0.8));
      },
    );
  });

  group('TableElement', () {
    test(
      'is skipped (produces no ResolvedElement) until rendering is implemented',
      () {
        final document = _documentWith(
          elements: const [
            TableElement(
              id: 'el-1',
              name: 'Itens',
              position: Point(x: 0, y: 0),
              size: Size2D(width: 40, height: 20),
              layerId: 'layer-1',
              columns: [
                TableColumn(header: 'Produto', dataField: 'produto', width: 20),
              ],
            ),
          ],
        );
        expect(engine.resolve(document, {}).elements, isEmpty);
      },
    );
  });

  group('validation', () {
    test(
      'throws LayoutException when a resolved dimension is not positive',
      () {
        final document = _documentWith(
          elements: const [
            RectangleElement(
              id: 'el-1',
              name: 'Caixa',
              position: Point(x: 0, y: 0),
              size: Size2D(width: 0, height: 10),
              layerId: 'layer-1',
            ),
          ],
        );
        expect(
          () => engine.resolve(document, {}),
          throwsA(isA<LayoutException>()),
        );
      },
    );

    test('allows a LineElement with a zero height (a horizontal line)', () {
      final document = _documentWith(
        elements: const [
          LineElement(
            id: 'el-1',
            name: 'Linha',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 10, height: 0),
            layerId: 'layer-1',
          ),
        ],
      );
      expect(() => engine.resolve(document, {}), returnsNormally);
    });

    test('rejects a LineElement with zero length on both axes', () {
      final document = _documentWith(
        elements: const [
          LineElement(
            id: 'el-1',
            name: 'Linha',
            position: Point(x: 0, y: 0),
            size: Size2D(width: 0, height: 0),
            layerId: 'layer-1',
          ),
        ],
      );
      expect(
        () => engine.resolve(document, {}),
        throwsA(isA<LayoutException>()),
      );
    });
  });
}
