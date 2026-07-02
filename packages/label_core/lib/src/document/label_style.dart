import 'package:equatable/equatable.dart';

import '../elements/text_style_spec.dart';

/// A named, reusable [TextStyleSpec], referenced by id from
/// `TextElement.styleId`, `VariableElement.styleId`, etc.
///
/// Centralizing typography here means updating one [LabelStyle] updates
/// every element that references it, instead of editing each element.
class LabelStyle extends Equatable {
  const LabelStyle({required this.id, required this.name, required this.spec});

  factory LabelStyle.fromJson(Map<String, dynamic> json) {
    return LabelStyle(
      id: json['id'] as String,
      name: json['name'] as String,
      spec: TextStyleSpec.fromJson(json['spec'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String name;
  final TextStyleSpec spec;

  LabelStyle copyWith({String? id, String? name, TextStyleSpec? spec}) {
    return LabelStyle(
      id: id ?? this.id,
      name: name ?? this.name,
      spec: spec ?? this.spec,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'spec': spec.toJson(),
  };

  @override
  List<Object?> get props => [id, name, spec];
}
