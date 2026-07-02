part of 'label_element.dart';

/// A single column definition for [TableElement].
class TableColumn extends Equatable {
  const TableColumn({
    required this.header,
    required this.dataField,
    required this.width,
  });

  factory TableColumn.fromJson(Map<String, dynamic> json) {
    return TableColumn(
      header: json['header'] as String,
      dataField: json['dataField'] as String,
      width: (json['width'] as num).toDouble(),
    );
  }

  final String header;

  /// Path into the row data map, e.g. `"produto.nome"`.
  final String dataField;

  /// Column width in millimeters.
  final double width;

  Map<String, dynamic> toJson() => {
    'header': header,
    'dataField': dataField,
    'width': width,
  };

  @override
  List<Object?> get props => [header, dataField, width];
}

/// A tabular element bound to a list of rows in the print data (e.g. order
/// line items). Modeled now so the JSON schema and the sealed
/// [LabelElement] hierarchy are stable; layout/rendering support is
/// implemented in a later roadmap step.
class TableElement extends LabelElement {
  const TableElement({
    required super.id,
    required super.name,
    required super.position,
    required super.size,
    super.rotation,
    super.visible,
    super.locked,
    super.opacity,
    required super.layerId,
    super.zIndex,
    super.transform,
    required this.columns,
    this.dataField = '',
    this.rowHeight = 5,
    this.headerStyle = const TextStyleSpec(bold: true),
    this.cellStyle = const TextStyleSpec(),
  });

  final List<TableColumn> columns;

  /// Path into the print data pointing at the list of rows, e.g. `"itens"`.
  final String dataField;

  /// Row height in millimeters.
  final double rowHeight;
  final TextStyleSpec headerStyle;
  final TextStyleSpec cellStyle;

  @override
  String get typeName => 'table';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitTable(this);

  TableElement copyWith({
    String? id,
    String? name,
    Point? position,
    Size2D? size,
    double? rotation,
    bool? visible,
    bool? locked,
    double? opacity,
    String? layerId,
    int? zIndex,
    ElementTransform? transform,
    List<TableColumn>? columns,
    String? dataField,
    double? rowHeight,
    TextStyleSpec? headerStyle,
    TextStyleSpec? cellStyle,
  }) {
    return TableElement(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      layerId: layerId ?? this.layerId,
      zIndex: zIndex ?? this.zIndex,
      transform: transform ?? this.transform,
      columns: columns ?? this.columns,
      dataField: dataField ?? this.dataField,
      rowHeight: rowHeight ?? this.rowHeight,
      headerStyle: headerStyle ?? this.headerStyle,
      cellStyle: cellStyle ?? this.cellStyle,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'columns': columns.map((column) => column.toJson()).toList(),
    'dataField': dataField,
    'rowHeight': rowHeight,
    'headerStyle': headerStyle.toJson(),
    'cellStyle': cellStyle.toJson(),
  };

  static TableElement fromJson(Map<String, dynamic> json) {
    return TableElement(
      id: json['id'] as String,
      name: json['name'] as String,
      position: Point.fromJson(json['position'] as Map<String, dynamic>),
      size: Size2D.fromJson(json['size'] as Map<String, dynamic>),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      layerId: json['layerId'] as String,
      zIndex: json['zIndex'] as int? ?? 0,
      transform: json['transform'] == null
          ? const ElementTransform.identity()
          : ElementTransform.fromJson(
              json['transform'] as Map<String, dynamic>,
            ),
      columns: (json['columns'] as List<dynamic>)
          .map((column) => TableColumn.fromJson(column as Map<String, dynamic>))
          .toList(),
      dataField: json['dataField'] as String? ?? '',
      rowHeight: (json['rowHeight'] as num?)?.toDouble() ?? 5,
      headerStyle: json['headerStyle'] == null
          ? const TextStyleSpec(bold: true)
          : TextStyleSpec.fromJson(json['headerStyle'] as Map<String, dynamic>),
      cellStyle: json['cellStyle'] == null
          ? const TextStyleSpec()
          : TextStyleSpec.fromJson(json['cellStyle'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    columns,
    dataField,
    rowHeight,
    headerStyle,
    cellStyle,
  ];
}
