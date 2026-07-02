import 'package:flutter/material.dart';

import 'hex_color.dart';
import 'label_color_swatch.dart';

/// A grid of preset color swatches plus a hex text field for a custom
/// value — used by `label_property_panel` to edit fill/stroke/text colors.
///
/// Purely presentational: [color] and [onColorChanged] are the only state,
/// supplied and owned by the caller (no `LabelDocument`/store knowledge).
class LabelColorPicker extends StatefulWidget {
  const LabelColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.presets = defaultPresets,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final List<Color> presets;

  static const List<Color> defaultPresets = [
    Color(0xFF000000),
    Color(0xFF424242),
    Color(0xFF9E9E9E),
    Color(0xFFFFFFFF),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF3F51B5),
    Color(0xFF9C27B0),
    Color(0xFF795548),
  ];

  @override
  State<LabelColorPicker> createState() => _LabelColorPickerState();
}

class _LabelColorPickerState extends State<LabelColorPicker> {
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: colorToHex(widget.color));
  }

  @override
  void didUpdateWidget(covariant LabelColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color.toARGB32() != widget.color.toARGB32()) {
      _hexController.text = colorToHex(widget.color);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _submitHex(String value) {
    final parsed = colorFromHex(value);
    if (parsed != null) {
      widget.onColorChanged(parsed);
    } else {
      // Invalid input: snap the field back to the last valid color instead
      // of leaving unparsable text in place.
      _hexController.text = colorToHex(widget.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in widget.presets)
              LabelColorSwatch(
                color: preset,
                selected: preset.toARGB32() == widget.color.toARGB32(),
                onTap: () => widget.onColorChanged(preset),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hexController,
          decoration: const InputDecoration(labelText: 'Hex', isDense: true),
          onSubmitted: _submitHex,
          onTapOutside: (_) => _submitHex(_hexController.text),
        ),
      ],
    );
  }
}
