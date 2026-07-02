part of 'label_element.dart';

/// Free-form text, potentially containing `{{ expression }}` placeholders
/// resolved by the Layout Engine at print/preview time.
class TextElement extends LabelElement {
  const TextElement({
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
    required this.content,
    this.styleId,
    this.style = const TextStyleSpec(),
  });

  /// Raw content, e.g. `"{{ produto }}"` or `"Lote: {{ lote }}"`.
  final String content;

  /// Optional reference to a named [LabelStyle]. When set, [style] fields
  /// act as local overrides on top of the referenced style.
  final String? styleId;
  final TextStyleSpec style;

  @override
  String get typeName => 'text';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitText(this);

  TextElement copyWith({
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
    String? content,
    String? styleId,
    TextStyleSpec? style,
  }) {
    return TextElement(
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
      content: content ?? this.content,
      styleId: styleId ?? this.styleId,
      style: style ?? this.style,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'content': content,
    if (styleId != null) 'styleId': styleId,
    'style': style.toJson(),
  };

  static TextElement fromJson(Map<String, dynamic> json) {
    return TextElement(
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
      content: json['content'] as String,
      styleId: json['styleId'] as String?,
      style: json['style'] == null
          ? const TextStyleSpec()
          : TextStyleSpec.fromJson(json['style'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [...super.props, content, styleId, style];
}
