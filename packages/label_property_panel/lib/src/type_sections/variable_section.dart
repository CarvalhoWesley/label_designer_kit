import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../style/text_style_fields.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';
import 'style_id_dropdown.dart';

/// Type-specific fields for [VariableElement]: the bound expression and
/// typography.
class VariableSection extends StatelessWidget {
  const VariableSection({
    super.key,
    required this.element,
    required this.styles,
    required this.onChange,
  });

  final VariableElement element;
  final List<LabelStyle> styles;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Variável',
      children: [
        LabeledTextField(
          label: 'Expressão',
          value: element.expression,
          onChanged: (value) => onChange(
            (e) => (e as VariableElement).copyWith(expression: value),
          ),
        ),
        StyleIdDropdown(
          styleId: element.styleId,
          styles: styles,
          onChanged: (value) => onChange(
            (e) => (e as VariableElement).copyWith(styleId: value),
          ),
        ),
        TextStyleFields(
          style: element.style,
          onChanged: (value) => onChange(
            (e) => (e as VariableElement).copyWith(style: value),
          ),
        ),
      ],
    );
  }
}
