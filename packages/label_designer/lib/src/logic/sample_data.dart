import 'package:label_core/label_core.dart';

/// Builds a placeholder data map for `label_preview` from a document's
/// declared [LabelVariable]s: [LabelVariable.defaultValue] when present,
/// otherwise a type-appropriate empty value — so `{{ produto }}` renders
/// as something (an empty string, `0`, ...) instead of the literal string
/// `"null"` while the user hasn't supplied real print data yet.
Map<String, dynamic> buildSampleData(List<LabelVariable> variables) => {
  for (final variable in variables)
    variable.name: variable.defaultValue ?? _emptyValueFor(variable.type),
};

Object _emptyValueFor(VariableType type) => switch (type) {
  VariableType.string => '',
  VariableType.number => 0,
  VariableType.boolean => false,
  VariableType.date => DateTime.now(),
};
