import 'package:flutter/material.dart';

/// An icon-only toolbar button with a tooltip and an optional "selected"
/// (toggled-on) visual state — the building block for `label_designer`'s
/// toolbar and `label_property_panel`'s alignment/style toggles.
class LabelToolbarButton extends StatelessWidget {
  const LabelToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.iconSize = 20,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null;

    final Color foreground;
    final Color background;
    if (!enabled) {
      foreground = colors.onSurface.withValues(alpha: 0.38);
      background = Colors.transparent;
    } else if (selected) {
      foreground = colors.onPrimaryContainer;
      background = colors.primaryContainer;
    } else {
      foreground = colors.onSurfaceVariant;
      background = Colors.transparent;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: iconSize, color: foreground),
          ),
        ),
      ),
    );
  }
}
