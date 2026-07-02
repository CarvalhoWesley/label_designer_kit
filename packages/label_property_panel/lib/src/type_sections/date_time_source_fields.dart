import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../widgets/labeled_text_field.dart';

/// Format string, source (now/variable) and variable name — shared by
/// [DateElement] and [TimeElement], which only differ in their default
/// format and don't otherwise need distinct UI.
class DateTimeSourceFields extends StatelessWidget {
  const DateTimeSourceFields({
    super.key,
    required this.format,
    required this.source,
    required this.variableName,
    required this.onFormatChanged,
    required this.onSourceChanged,
    required this.onVariableNameChanged,
  });

  final String format;
  final DateTimeSource source;
  final String? variableName;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<DateTimeSource> onSourceChanged;
  final ValueChanged<String> onVariableNameChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Formato',
          value: format,
          onChanged: onFormatChanged,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DateTimeSource>(
          value: source,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Origem',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(
              value: DateTimeSource.now,
              child: Text('Momento da impressão'),
            ),
            DropdownMenuItem(
              value: DateTimeSource.variable,
              child: Text('Variável dos dados'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onSourceChanged(value);
          },
        ),
        if (source == DateTimeSource.variable) ...[
          const SizedBox(height: 8),
          LabeledTextField(
            label: 'Nome da variável',
            value: variableName ?? '',
            onChanged: onVariableNameChanged,
          ),
        ],
      ],
    );
  }
}
