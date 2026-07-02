part of 'label_element.dart';

class RectangleElement extends LabelElement {
  const RectangleElement({
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
    this.style = const ShapeStyleSpec(),
    this.cornerRadius = 0,
  });

  final ShapeStyleSpec style;

  /// Corner radius in millimeters. `0` means sharp corners.
  final double cornerRadius;

  @override
  String get typeName => 'rectangle';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitRectangle(this);

  RectangleElement copyWith({
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
    ShapeStyleSpec? style,
    double? cornerRadius,
  }) {
    return RectangleElement(
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
      style: style ?? this.style,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'style': style.toJson(),
    'cornerRadius': cornerRadius,
  };

  static RectangleElement fromJson(Map<String, dynamic> json) {
    return RectangleElement(
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
      style: json['style'] == null
          ? const ShapeStyleSpec()
          : ShapeStyleSpec.fromJson(json['style'] as Map<String, dynamic>),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [...super.props, style, cornerRadius];
}
