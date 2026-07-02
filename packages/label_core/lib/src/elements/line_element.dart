part of 'label_element.dart';

/// A straight line from [LabelElement.position] to [endPoint].
///
/// Reuses the common `position`/`size` contract instead of a bespoke
/// start/end pair: `position` is the start point and `size` is interpreted
/// as the (dx, dy) delta to the end point, so a line behaves like every
/// other element under drag/resize/rotate in the canvas.
class LineElement extends LabelElement {
  const LineElement({
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
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 0.3,
  });

  final int strokeColor;

  /// Line thickness in millimeters.
  final double strokeWidth;

  /// The line's end point, derived from `position + size`.
  Point get endPoint =>
      Point(x: position.x + size.width, y: position.y + size.height);

  @override
  String get typeName => 'line';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitLine(this);

  LineElement copyWith({
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
    int? strokeColor,
    double? strokeWidth,
  }) {
    return LineElement(
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
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
  };

  static LineElement fromJson(Map<String, dynamic> json) {
    return LineElement(
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
      strokeColor: json['strokeColor'] as int? ?? 0xFF000000,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.3,
    );
  }

  @override
  List<Object?> get props => [...super.props, strokeColor, strokeWidth];
}
