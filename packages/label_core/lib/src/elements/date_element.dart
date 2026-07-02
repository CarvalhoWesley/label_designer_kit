part of 'label_element.dart';

/// Where a [DateElement] or [TimeElement] gets its value from.
enum DateTimeSource {
  /// Uses the moment the label is rendered/printed.
  now,

  /// Reads [DateElement.variableName]/[TimeElement.variableName] from the
  /// data passed to the Layout Engine.
  variable,
}

/// A date, formatted with [format] (e.g. `"dd/MM/yyyy"`).
class DateElement extends LabelElement {
  const DateElement({
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
    this.format = 'dd/MM/yyyy',
    this.source = DateTimeSource.now,
    this.variableName,
    this.style = const TextStyleSpec(),
  });

  final String format;
  final DateTimeSource source;

  /// Required when [source] is [DateTimeSource.variable].
  final String? variableName;
  final TextStyleSpec style;

  @override
  String get typeName => 'date';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitDate(this);

  DateElement copyWith({
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
    String? format,
    DateTimeSource? source,
    String? variableName,
    TextStyleSpec? style,
  }) {
    return DateElement(
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
      format: format ?? this.format,
      source: source ?? this.source,
      variableName: variableName ?? this.variableName,
      style: style ?? this.style,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'format': format,
    'source': source.name,
    if (variableName != null) 'variableName': variableName,
    'style': style.toJson(),
  };

  static DateElement fromJson(Map<String, dynamic> json) {
    return DateElement(
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
      format: json['format'] as String? ?? 'dd/MM/yyyy',
      source: DateTimeSource.values.byName(json['source'] as String? ?? 'now'),
      variableName: json['variableName'] as String?,
      style: json['style'] == null
          ? const TextStyleSpec()
          : TextStyleSpec.fromJson(json['style'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    format,
    source,
    variableName,
    style,
  ];
}
