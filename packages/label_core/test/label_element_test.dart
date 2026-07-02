import 'package:label_core/label_core.dart';
import 'package:test/test.dart';

/// Records which `visitXxx` method was invoked, proving [LabelElement.accept]
/// dispatches to the correct one (Visitor pattern double-dispatch).
class _RecordingVisitor implements LabelElementVisitor<String> {
  @override
  String visitText(TextElement element) => 'text';
  @override
  String visitBarcode(BarcodeElement element) => 'barcode';
  @override
  String visitQrCode(QRCodeElement element) => 'qrcode';
  @override
  String visitImage(ImageElement element) => 'image';
  @override
  String visitRectangle(RectangleElement element) => 'rectangle';
  @override
  String visitEllipse(EllipseElement element) => 'ellipse';
  @override
  String visitCircle(CircleElement element) => 'circle';
  @override
  String visitLine(LineElement element) => 'line';
  @override
  String visitVariable(VariableElement element) => 'variable';
  @override
  String visitDate(DateElement element) => 'date';
  @override
  String visitTime(TimeElement element) => 'time';
  @override
  String visitTable(TableElement element) => 'table';
  @override
  String visitGroup(GroupElement element) => 'group';
}

const _position = Point(x: 5, y: 5);
const _size = Size2D(width: 40, height: 10);

void main() {
  final visitor = _RecordingVisitor();

  group('each LabelElement subtype', () {
    final elements = <String, LabelElement>{
      'text': const TextElement(
        id: 'el-1',
        name: 'Título',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        content: '{{ produto }}',
      ),
      'barcode': const BarcodeElement(
        id: 'el-2',
        name: 'Código',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        data: '{{ codigo }}',
        symbology: BarcodeSymbology.code128,
      ),
      'qrcode': const QRCodeElement(
        id: 'el-3',
        name: 'QR',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        data: '{{ url }}',
      ),
      'image': const ImageElement(
        id: 'el-4',
        name: 'Logo',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        source: 'assets/logo.png',
      ),
      'rectangle': const RectangleElement(
        id: 'el-5',
        name: 'Caixa',
        position: _position,
        size: _size,
        layerId: 'layer-1',
      ),
      'ellipse': const EllipseElement(
        id: 'el-6',
        name: 'Elipse',
        position: _position,
        size: _size,
        layerId: 'layer-1',
      ),
      'circle': const CircleElement(
        id: 'el-7',
        name: 'Círculo',
        position: _position,
        size: _size,
        layerId: 'layer-1',
      ),
      'line': const LineElement(
        id: 'el-8',
        name: 'Linha',
        position: _position,
        size: _size,
        layerId: 'layer-1',
      ),
      'variable': const VariableElement(
        id: 'el-9',
        name: 'Preço',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        expression: 'preco.currency()',
      ),
      'date': const DateElement(
        id: 'el-10',
        name: 'Data',
        position: _position,
        size: _size,
        layerId: 'layer-1',
      ),
      'time': const TimeElement(
        id: 'el-11',
        name: 'Hora',
        position: _position,
        size: _size,
        layerId: 'layer-1',
      ),
      'table': const TableElement(
        id: 'el-12',
        name: 'Itens',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        columns: [
          TableColumn(header: 'Produto', dataField: 'produto', width: 20),
        ],
      ),
      'group': const GroupElement(
        id: 'el-13',
        name: 'Grupo',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        children: [
          TextElement(
            id: 'child-1',
            name: 'Filho',
            position: _position,
            size: _size,
            layerId: 'layer-1',
            content: 'texto',
          ),
        ],
      ),
    };

    elements.forEach((typeName, element) {
      test('$typeName: typeName getter matches the JSON discriminator', () {
        expect(element.typeName, typeName == 'qrcode' ? 'qrcode' : typeName);
      });

      test('$typeName: accept() dispatches to the matching visit method', () {
        expect(element.accept(visitor), typeName);
      });

      test('$typeName: round-trips through toJson/fromJson', () {
        final decoded = LabelElement.fromJson(element.toJson());
        expect(decoded, element);
        expect(decoded.runtimeType, element.runtimeType);
      });
    });
  });

  group('copyWith', () {
    test('TextElement.copyWith overrides only the given fields', () {
      const original = TextElement(
        id: 'el-1',
        name: 'Título',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        content: '{{ produto }}',
      );
      final updated = original.copyWith(content: '{{ nome }}');

      expect(updated.content, '{{ nome }}');
      expect(updated.id, original.id);
      expect(updated.position, original.position);
      expect(updated, isNot(original));
    });

    test('GroupElement.copyWith can replace children', () {
      const child = TextElement(
        id: 'child-1',
        name: 'Filho',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        content: 'texto',
      );
      const group = GroupElement(
        id: 'el-13',
        name: 'Grupo',
        position: _position,
        size: _size,
        layerId: 'layer-1',
        children: [child],
      );

      final ungrouped = group.copyWith(children: []);
      expect(ungrouped.children, isEmpty);
      expect(group.children, [child]);
    });
  });

  group('LineElement', () {
    test('endPoint is derived from position + size', () {
      const line = LineElement(
        id: 'el-8',
        name: 'Linha',
        position: Point(x: 5, y: 5),
        size: Size2D(width: 20, height: 10),
        layerId: 'layer-1',
      );
      expect(line.endPoint, const Point(x: 25, y: 15));
    });
  });

  group('LabelElement.fromJson', () {
    test('throws for an unknown discriminator', () {
      expect(
        () => LabelElement.fromJson({'type': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}
