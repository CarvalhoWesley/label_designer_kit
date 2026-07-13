import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_label_designer/flutter_label_designer.dart' hide EdgeInsets;

/// Builds one input per declared [LabelVariable] on a document, seeded with
/// its `defaultValue`, and reports the whole data map back on every change
/// — used by the export and print dialogs to resolve `{{ }}` placeholders
/// with values other than the document's own defaults before rendering.
class SampleDataForm extends StatefulWidget {
  const SampleDataForm({
    super.key,
    required this.variables,
    required this.onChanged,
  });

  final List<LabelVariable> variables;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<SampleDataForm> createState() => _SampleDataFormState();
}

class _SampleDataFormState extends State<SampleDataForm> {
  final Map<String, Object?> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final variable in widget.variables) {
      _values[variable.name] = variable.defaultValue;
      if (variable.type != VariableType.boolean) {
        _controllers[variable.name] = TextEditingController(
          text: variable.defaultValue?.toString() ?? '',
        );
      }
    }
    scheduleMicrotask(() => widget.onChanged(Map.of(_values)));
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _update(String name, Object? value) {
    _values[name] = value;
    widget.onChanged(Map.of(_values));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variables.isEmpty) {
      return const Text('Esta etiqueta não declara variáveis.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [for (final variable in widget.variables) _fieldFor(variable)],
    );
  }

  Widget _fieldFor(LabelVariable variable) {
    final helperText = variable.description.isEmpty
        ? null
        : variable.description;
    switch (variable.type) {
      case VariableType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(variable.name),
          subtitle: helperText == null ? null : Text(helperText),
          value: _values[variable.name] == true,
          onChanged: (value) => setState(() => _update(variable.name, value)),
        );
      case VariableType.number:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: _controllers[variable.name],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: variable.name,
              helperText: helperText,
            ),
            onChanged: (text) => _update(variable.name, num.tryParse(text)),
          ),
        );
      case VariableType.string:
      case VariableType.date:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: _controllers[variable.name],
            decoration: InputDecoration(
              labelText: variable.name,
              helperText: helperText,
            ),
            onChanged: (text) => _update(variable.name, text),
          ),
        );
    }
  }
}
