import 'package:flutter/material.dart';

/// A titled group of fields in the property panel (e.g. "Geometria",
/// "Texto", "Preenchimento"). Purely a layout/visual container — sections
/// own no state of their own.
class PropertyPanelSection extends StatelessWidget {
  const PropertyPanelSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: child,
            ),
        ],
      ),
    );
  }
}
