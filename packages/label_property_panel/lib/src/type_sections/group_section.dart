import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../widgets/property_panel_section.dart';

/// Type-specific fields for [GroupElement]: just a read-only summary.
/// Editing a group's own properties (position, size, rotation, ...) cascades
/// to its children at edit time in `label_canvas`, not here — this panel
/// only edits the group's own [LabelElement] fields via [GeometrySection]/
/// [GeneralSection], same as any other element.
class GroupSection extends StatelessWidget {
  const GroupSection({super.key, required this.element});

  final GroupElement element;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Grupo',
      children: [
        Text('${element.children.length} elemento(s) agrupado(s)'),
      ],
    );
  }
}
