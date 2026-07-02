part of 'label_element.dart';

/// Text bound to a single variable or expression (e.g. `produto.nome` or
/// `preco.currency()`), as opposed to [TextElement] which mixes free text
/// with placeholders.
///
/// Kept as its own type so the property panel and canvas can offer a
/// variable picker (dropdown) instead of a free-text field, without having
/// to parse `{{ }}` templates back out of arbitrary text.
class VariableElement extends LabelElement {
  const VariableElement({
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
    required this.expression,
    this.styleId,
    this.style = const TextStyleSpec(),
  });

  /// The expression body, without the surrounding `{{ }}`, e.g.
  /// `"preco * quantidade"`.
  final String expression;
  final String? styleId;
  final TextStyleSpec style;

  @override
  String get typeName => 'variable';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitVariable(this);

  VariableElement copyWith({
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
    String? expression,
    String? styleId,
    TextStyleSpec? style,
  }) {
    return VariableElement(
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
      expression: expression ?? this.expression,
      styleId: styleId ?? this.styleId,
      style: style ?? this.style,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'expression': expression,
    if (styleId != null) 'styleId': styleId,
    'style': style.toJson(),
  };

  static VariableElement fromJson(Map<String, dynamic> json) {
    return VariableElement(
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
      expression: json['expression'] as String,
      styleId: json['styleId'] as String?,
      style: json['style'] == null
          ? const TextStyleSpec()
          : TextStyleSpec.fromJson(json['style'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [...super.props, expression, styleId, style];
}
