import 'package:equatable/equatable.dart';

/// A named, orderable layer. Elements reference a layer via
/// `LabelElement.layerId`.
class LabelLayer extends Equatable {
  const LabelLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    required this.order,
  });

  factory LabelLayer.fromJson(Map<String, dynamic> json) {
    return LabelLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      order: json['order'] as int,
    );
  }

  final String id;
  final String name;
  final bool visible;
  final bool locked;

  /// Lower values are painted first (further back).
  final int order;

  LabelLayer copyWith({
    String? id,
    String? name,
    bool? visible,
    bool? locked,
    int? order,
  }) {
    return LabelLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'visible': visible,
    'locked': locked,
    'order': order,
  };

  @override
  List<Object?> get props => [id, name, visible, locked, order];
}
