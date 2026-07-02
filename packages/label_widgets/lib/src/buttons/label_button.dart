import 'package:flutter/material.dart';

/// Visual weight of a [LabelButton].
enum LabelButtonVariant { primary, secondary, danger }

/// A text (optionally icon-prefixed) button in one of three visual
/// weights, for dialogs and panels (as opposed to [LabelToolbarButton],
/// which is icon-only and lives in toolbars).
class LabelButton extends StatelessWidget {
  const LabelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LabelButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final LabelButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final content = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(label),
            ],
          );

    return switch (variant) {
      LabelButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        child: content,
      ),
      LabelButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        child: content,
      ),
      LabelButtonVariant.danger => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: onPressed,
        child: content,
      ),
    };
  }
}
