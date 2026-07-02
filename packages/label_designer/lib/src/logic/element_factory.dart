import 'package:label_core/label_core.dart';

/// Every [LabelElement] subtype the toolbar can add directly.
/// `GroupElement` is deliberately excluded — a group is only ever created
/// by grouping an existing selection (see `grouping.dart`), never blank.
enum AddableElementType {
  text,
  barcode,
  qrCode,
  image,
  rectangle,
  ellipse,
  circle,
  line,
  variable,
  date,
  time,
  table,
}

/// A human-readable label for [type], used for the toolbar tooltip and as
/// the new element's default [LabelElement.name].
String addableElementTypeLabel(AddableElementType type) => switch (type) {
  AddableElementType.text => 'Texto',
  AddableElementType.barcode => 'Código de barras',
  AddableElementType.qrCode => 'QR Code',
  AddableElementType.image => 'Imagem',
  AddableElementType.rectangle => 'Retângulo',
  AddableElementType.ellipse => 'Elipse',
  AddableElementType.circle => 'Círculo',
  AddableElementType.line => 'Linha',
  AddableElementType.variable => 'Variável',
  AddableElementType.date => 'Data',
  AddableElementType.time => 'Hora',
  AddableElementType.table => 'Tabela',
};

/// Builds a new [LabelElement] of [type] with sensible default content/
/// size, placed at [position] on [layerId] with the given [id].
///
/// The result is meant to be dropped onto the canvas as-is and then
/// edited via `label_property_panel` — defaults exist only so a freshly
/// added element renders as something visible rather than empty/invalid
/// (e.g. a barcode needs non-empty `data` to encode at all).
LabelElement createDefaultElement({
  required AddableElementType type,
  required String id,
  required String layerId,
  required Point position,
}) {
  final name = addableElementTypeLabel(type);
  return switch (type) {
    AddableElementType.text => TextElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 30, height: 10),
      layerId: layerId,
      content: 'Texto',
    ),
    AddableElementType.barcode => BarcodeElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 40, height: 15),
      layerId: layerId,
      data: '123456789012',
      symbology: BarcodeSymbology.code128,
    ),
    AddableElementType.qrCode => QRCodeElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 20),
      layerId: layerId,
      data: 'https://',
    ),
    AddableElementType.image => ImageElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 20),
      layerId: layerId,
      source: '',
    ),
    AddableElementType.rectangle => RectangleElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 20),
      layerId: layerId,
    ),
    AddableElementType.ellipse => EllipseElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 20),
      layerId: layerId,
    ),
    AddableElementType.circle => CircleElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 20),
      layerId: layerId,
    ),
    AddableElementType.line => LineElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 0),
      layerId: layerId,
    ),
    AddableElementType.variable => VariableElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 30, height: 10),
      layerId: layerId,
      expression: 'variavel',
    ),
    AddableElementType.date => DateElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 6),
      layerId: layerId,
    ),
    AddableElementType.time => TimeElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 20, height: 6),
      layerId: layerId,
    ),
    AddableElementType.table => TableElement(
      id: id,
      name: name,
      position: position,
      size: const Size2D(width: 50, height: 20),
      layerId: layerId,
      columns: const [
        TableColumn(header: 'Coluna', dataField: 'campo', width: 25),
      ],
      dataField: 'itens',
    ),
  };
}
