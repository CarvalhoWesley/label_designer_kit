import 'package:flutter/material.dart';

/// A single tappable color square, used both as a preset swatch inside
/// [LabelColorPicker] and standalone (e.g. a "current color" indicator).
class LabelColorSwatch extends StatelessWidget {
  const LabelColorSwatch({
    super.key,
    required this.color,
    this.selected = false,
    this.onTap,
    this.size = 24,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Cor ${color.toARGB32().toRadixString(16)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
        ),
      ),
    );
  }
}
