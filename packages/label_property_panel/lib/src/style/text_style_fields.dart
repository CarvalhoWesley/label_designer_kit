import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';
import 'package:label_widgets/label_widgets.dart';

import '../widgets/labeled_number_field.dart';
import '../widgets/labeled_text_field.dart';

/// Editable fields for a [TextStyleSpec], shared by every text-like
/// element ([TextElement], [VariableElement], [DateElement],
/// [TimeElement]).
///
/// Purely presentational: the caller owns [style] and receives a whole new
/// [TextStyleSpec] via [onChanged] on every edit — it decides how to fold
/// that back into the concrete element's `copyWith`.
class TextStyleFields extends StatelessWidget {
  const TextStyleFields({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final TextStyleSpec style;
  final ValueChanged<TextStyleSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          label: 'Fonte',
          value: style.fontFamily,
          onChanged: (value) => onChanged(style.copyWith(fontFamily: value)),
        ),
        const SizedBox(height: 8),
        LabeledNumberField(
          label: 'Tamanho da fonte',
          value: style.fontSize,
          min: 0.1,
          suffixText: 'mm',
          onChanged: (value) => onChanged(style.copyWith(fontSize: value)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            LabelToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Negrito',
              selected: style.bold,
              onPressed: () => onChanged(style.copyWith(bold: !style.bold)),
            ),
            LabelToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Itálico',
              selected: style.italic,
              onPressed: () =>
                  onChanged(style.copyWith(italic: !style.italic)),
            ),
            LabelToolbarButton(
              icon: Icons.format_underline,
              tooltip: 'Sublinhado',
              selected: style.underline,
              onPressed: () =>
                  onChanged(style.copyWith(underline: !style.underline)),
            ),
            const SizedBox(width: 8),
            LabelToolbarButton(
              icon: Icons.format_align_left,
              tooltip: 'Esquerda',
              selected: style.alignment == TextAlignment.left,
              onPressed: () => onChanged(
                style.copyWith(alignment: TextAlignment.left),
              ),
            ),
            LabelToolbarButton(
              icon: Icons.format_align_center,
              tooltip: 'Centro',
              selected: style.alignment == TextAlignment.center,
              onPressed: () => onChanged(
                style.copyWith(alignment: TextAlignment.center),
              ),
            ),
            LabelToolbarButton(
              icon: Icons.format_align_right,
              tooltip: 'Direita',
              selected: style.alignment == TextAlignment.right,
              onPressed: () => onChanged(
                style.copyWith(alignment: TextAlignment.right),
              ),
            ),
            LabelToolbarButton(
              icon: Icons.format_align_justify,
              tooltip: 'Justificado',
              selected: style.alignment == TextAlignment.justify,
              onPressed: () => onChanged(
                style.copyWith(alignment: TextAlignment.justify),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Cor do texto', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        LabelColorPicker(
          color: Color(style.color),
          onColorChanged: (color) =>
              onChanged(style.copyWith(color: color.toARGB32())),
        ),
      ],
    );
  }
}
