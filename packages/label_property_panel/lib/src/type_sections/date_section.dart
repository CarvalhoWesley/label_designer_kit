import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../style/text_style_fields.dart';
import '../widgets/property_panel_section.dart';
import 'date_time_source_fields.dart';

/// Type-specific fields for [DateElement].
class DateSection extends StatelessWidget {
  const DateSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final DateElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Data',
      children: [
        DateTimeSourceFields(
          format: element.format,
          source: element.source,
          variableName: element.variableName,
          onFormatChanged: (value) => onChange(
            (e) => (e as DateElement).copyWith(format: value),
          ),
          onSourceChanged: (value) => onChange(
            (e) => (e as DateElement).copyWith(source: value),
          ),
          onVariableNameChanged: (value) => onChange(
            (e) => (e as DateElement).copyWith(variableName: value),
          ),
        ),
        TextStyleFields(
          style: element.style,
          onChanged: (value) => onChange(
            (e) => (e as DateElement).copyWith(style: value),
          ),
        ),
      ],
    );
  }
}
