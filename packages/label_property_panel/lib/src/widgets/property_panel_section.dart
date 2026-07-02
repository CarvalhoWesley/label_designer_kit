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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: child,
            ),
        ],
      ),
    );
  }
}
