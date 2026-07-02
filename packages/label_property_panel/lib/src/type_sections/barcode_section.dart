import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../widgets/labeled_number_field.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [BarcodeElement]: data, symbology and bar
/// geometry.
class BarcodeSection extends StatelessWidget {
  const BarcodeSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final BarcodeElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Código de barras',
      children: [
        LabeledTextField(
          label: 'Dados',
          value: element.data,
          onChanged: (value) => onChange(
            (e) => (e as BarcodeElement).copyWith(data: value),
          ),
        ),
        DropdownButtonFormField<BarcodeSymbology>(
          value: element.symbology,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Simbologia',
            isDense: true,
          ),
          items: [
            for (final symbology in BarcodeSymbology.values)
              DropdownMenuItem(
                value: symbology,
                child: Text(symbology.name),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChange(
                (e) => (e as BarcodeElement).copyWith(symbology: value),
              );
            }
          },
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Mostrar texto',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Switch(
              value: element.showText,
              onChanged: (value) => onChange(
                (e) => (e as BarcodeElement).copyWith(showText: value),
              ),
            ),
          ],
        ),
        LabeledNumberField(
          label: 'Largura do módulo',
          value: element.moduleWidth,
          min: 0.05,
          suffixText: 'mm',
          onChanged: (value) => onChange(
            (e) => (e as BarcodeElement).copyWith(moduleWidth: value),
          ),
        ),
      ],
    );
  }
}
