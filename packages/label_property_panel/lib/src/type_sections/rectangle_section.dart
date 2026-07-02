import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../style/shape_style_fields.dart';
import '../widgets/labeled_number_field.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [RectangleElement]: stroke/fill and corner
/// radius.
class RectangleSection extends StatelessWidget {
  const RectangleSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final RectangleElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Retângulo',
      children: [
        ShapeStyleFields(
          style: element.style,
          onChanged: (value) => onChange(
            (e) => (e as RectangleElement).copyWith(style: value),
          ),
        ),
        LabeledNumberField(
          label: 'Raio do canto',
          value: element.cornerRadius,
          min: 0,
          suffixText: 'mm',
          onChanged: (value) => onChange(
            (e) => (e as RectangleElement).copyWith(cornerRadius: value),
          ),
        ),
      ],
    );
  }
}
