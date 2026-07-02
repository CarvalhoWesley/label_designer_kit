import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../style/text_style_fields.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';
import 'style_id_dropdown.dart';

/// Type-specific fields for [TextElement]: content and typography.
class TextSection extends StatelessWidget {
  const TextSection({
    super.key,
    required this.element,
    required this.styles,
    required this.onChange,
  });

  final TextElement element;
  final List<LabelStyle> styles;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Texto',
      children: [
        LabeledTextField(
          label: 'Conteúdo',
          value: element.content,
          maxLines: 3,
          onChanged: (value) => onChange(
            (e) => (e as TextElement).copyWith(content: value),
          ),
        ),
        StyleIdDropdown(
          styleId: element.styleId,
          styles: styles,
          onChanged: (value) => onChange(
            (e) => (e as TextElement).copyWith(styleId: value),
          ),
        ),
        TextStyleFields(
          style: element.style,
          onChanged: (value) => onChange(
            (e) => (e as TextElement).copyWith(style: value),
          ),
        ),
      ],
    );
  }
}
