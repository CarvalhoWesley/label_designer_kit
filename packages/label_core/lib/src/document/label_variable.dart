import 'package:equatable/equatable.dart';

/// The declared type of a [LabelVariable], used by the editor to validate
/// input and offer the right widget when previewing with sample data.
enum VariableType { string, number, date, boolean }

/// Declares a variable that can be referenced as `{{ name }}` in
/// [TextElement.content], [VariableElement.expression], barcodes, etc.
///
/// Declaring variables up front lets the editor offer autocomplete and lets
/// the Layout Engine validate the data map passed in at print time.
class LabelVariable extends Equatable {
  const LabelVariable({
    required this.name,
    this.type = VariableType.string,
    this.defaultValue,
    this.description = '',
  });

  factory LabelVariable.fromJson(Map<String, dynamic> json) {
    return LabelVariable(
      name: json['name'] as String,
      type: VariableType.values.byName(json['type'] as String? ?? 'string'),
      defaultValue: json['defaultValue'],
      description: json['description'] as String? ?? '',
    );
  }

  /// Dotted path used inside `{{ }}`, e.g. `"empresa.nome"`.
  final String name;
  final VariableType type;
  final Object? defaultValue;
  final String description;

  LabelVariable copyWith({
    String? name,
    VariableType? type,
    Object? defaultValue,
    String? description,
  }) {
    return LabelVariable(
      name: name ?? this.name,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    if (defaultValue != null) 'defaultValue': defaultValue,
    'description': description,
  };

  @override
  List<Object?> get props => [name, type, defaultValue, description];
}
