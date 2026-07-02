import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../style/shape_style_fields.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [EllipseElement]: stroke/fill only (geometry
/// is fully described by the common position/size).
class EllipseSection extends StatelessWidget {
  const EllipseSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final EllipseElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Elipse',
      children: [
        ShapeStyleFields(
          style: element.style,
          onChanged: (value) => onChange(
            (e) => (e as EllipseElement).copyWith(style: value),
          ),
        ),
      ],
    );
  }
}
