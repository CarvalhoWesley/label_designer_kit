import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';
import 'package:label_widgets/label_widgets.dart';

import '../widgets/labeled_number_field.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [LineElement]: stroke color/width. [LineElement]
/// has no [ShapeStyleSpec] (it has no fill), so this doesn't reuse
/// [ShapeStyleFields].
class LineSection extends StatelessWidget {
  const LineSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final LineElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Linha',
      children: [
        Text('Cor', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        LabelColorPicker(
          color: Color(element.strokeColor),
          onColorChanged: (color) => onChange(
            (e) => (e as LineElement).copyWith(strokeColor: color.toARGB32()),
          ),
        ),
        const SizedBox(height: 8),
        LabeledNumberField(
          label: 'Espessura',
          value: element.strokeWidth,
          min: 0,
          suffixText: 'mm',
          onChanged: (value) => onChange(
            (e) => (e as LineElement).copyWith(strokeWidth: value),
          ),
        ),
      ],
    );
  }
}
