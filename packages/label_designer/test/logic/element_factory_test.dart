import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer/src/logic/element_factory.dart';

void main() {
  for (final type in AddableElementType.values) {
    test('createDefaultElement builds a valid ${type.name} element', () {
      final element = createDefaultElement(
        type: type,
        id: 'id-1',
        layerId: 'layer-1',
        position: const Point(x: 2, y: 3),
      );

      expect(element.id, 'id-1');
      expect(element.layerId, 'layer-1');
      expect(element.position, const Point(x: 2, y: 3));
      expect(element.name, addableElementTypeLabel(type));
      expect(element.size.width, greaterThan(0));
      // A LineElement's "size" is a (dx, dy) delta and may legitimately be
      // 0 on one axis (a purely horizontal/vertical line) — see
      // label_layout_engine's hasValidDimensions check.
      if (type != AddableElementType.line) {
        expect(element.size.height, greaterThan(0));
      }
    });
  }

  test('barcode default has non-empty data (so it actually encodes)', () {
    final element =
        createDefaultElement(
              type: AddableElementType.barcode,
              id: 'id-1',
              layerId: 'layer-1',
              position: Point.zero(),
            )
            as BarcodeElement;
    expect(element.data, isNotEmpty);
  });

  test('table default has at least one column', () {
    final element =
        createDefaultElement(
              type: AddableElementType.table,
              id: 'id-1',
              layerId: 'layer-1',
              position: Point.zero(),
            )
            as TableElement;
    expect(element.columns, isNotEmpty);
  });
}
