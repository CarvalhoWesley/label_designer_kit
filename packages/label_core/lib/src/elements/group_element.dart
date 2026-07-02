part of 'label_element.dart';

/// A composite of other elements (GoF Composite pattern), created by the
/// canvas' "group" action.
///
/// Children positions are relative to the group's own [position]. Moving,
/// resizing or rotating a group cascades to its children at render/edit
/// time; this class only stores the structure.
class GroupElement extends LabelElement {
  const GroupElement({
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
    required this.children,
  });

  final List<LabelElement> children;

  @override
  String get typeName => 'group';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitGroup(this);

  GroupElement copyWith({
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
    List<LabelElement>? children,
  }) {
    return GroupElement(
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
      children: children ?? this.children,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'children': children.map((child) => child.toJson()).toList(),
  };

  static GroupElement fromJson(Map<String, dynamic> json) {
    return GroupElement(
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
      children: (json['children'] as List<dynamic>)
          .map((child) => LabelElement.fromJson(child as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [...super.props, children];
}
