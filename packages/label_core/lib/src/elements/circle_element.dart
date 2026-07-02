part of 'label_element.dart';

/// A circle, modeled as a bounding box like every other element.
///
/// The canvas is responsible for constraining `size.width == size.height`
/// while the user drags a resize handle; the model itself does not
/// enforce it, keeping this class as simple as [EllipseElement].
class CircleElement extends LabelElement {
  const CircleElement({
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
  });

  final ShapeStyleSpec style;

  @override
  String get typeName => 'circle';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitCircle(this);

  CircleElement copyWith({
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
  }) {
    return CircleElement(
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
    );
  }

  @override
  Map<String, dynamic> toJson() => {..._commonJson(), 'style': style.toJson()};

  static CircleElement fromJson(Map<String, dynamic> json) {
    return CircleElement(
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
    );
  }

  @override
  List<Object?> get props => [...super.props, style];
}
