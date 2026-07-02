import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [ImageElement]: source and fit.
class ImageSection extends StatelessWidget {
  const ImageSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final ImageElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Imagem',
      children: [
        LabeledTextField(
          label: 'Origem',
          value: element.source,
          onChanged: (value) => onChange(
            (e) => (e as ImageElement).copyWith(source: value),
          ),
        ),
        DropdownButtonFormField<ImageFit>(
          value: element.fit,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Ajuste',
            isDense: true,
          ),
          items: [
            for (final fit in ImageFit.values)
              DropdownMenuItem(value: fit, child: Text(fit.name)),
          ],
          onChanged: (value) {
            if (value != null) {
              onChange((e) => (e as ImageElement).copyWith(fit: value));
            }
          },
        ),
      ],
    );
  }
}
