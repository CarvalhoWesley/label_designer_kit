import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';
import 'package:label_widgets/label_widgets.dart';

import '../widgets/labeled_number_field.dart';

/// Editable fields for a [ShapeStyleSpec], shared by [RectangleElement],
/// [EllipseElement] and [CircleElement].
///
/// Purely presentational, mirroring [TextStyleFields]: the caller owns
/// [style] and receives a whole new [ShapeStyleSpec] via [onChanged].
class ShapeStyleFields extends StatelessWidget {
  const ShapeStyleFields({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final ShapeStyleSpec style;
  final ValueChanged<ShapeStyleSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contorno', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        LabelColorPicker(
          color: Color(style.strokeColor),
          onColorChanged: (color) =>
              onChanged(style.copyWith(strokeColor: color.toARGB32())),
        ),
        const SizedBox(height: 8),
        LabeledNumberField(
          label: 'Espessura do contorno',
          value: style.strokeWidth,
          min: 0,
          suffixText: 'mm',
          onChanged: (value) =>
              onChanged(style.copyWith(strokeWidth: value)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Preenchimento',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Switch(
              value: style.fillColor != null,
              onChanged: (enabled) => onChanged(
                ShapeStyleSpec(
                  strokeColor: style.strokeColor,
                  strokeWidth: style.strokeWidth,
                  fillColor: enabled ? 0xFFFFFFFF : null,
                ),
              ),
            ),
          ],
        ),
        if (style.fillColor != null) ...[
          const SizedBox(height: 4),
          LabelColorPicker(
            color: Color(style.fillColor!),
            onColorChanged: (color) =>
                onChanged(style.copyWith(fillColor: color.toARGB32())),
          ),
        ],
      ],
    );
  }
}
