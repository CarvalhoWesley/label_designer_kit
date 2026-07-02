import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../widgets/labeled_number_field.dart';
import '../widgets/property_panel_section.dart';
import 'common_element_updates.dart';

/// Position, size and rotation — common to every [LabelElement] subtype,
/// always expressed in millimeters/degrees (see `docs/ARCHITECTURE.md`
/// section 8: the canvas/panel never edit dots).
class GeometrySection extends StatelessWidget {
  const GeometrySection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final LabelElement element;

  /// Called with the field's `with...` updater already applied to
  /// [element] and the old/new common-field values, so the caller can
  /// dispatch a single `PropertyStore.changeProperty` per edit.
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    final position = element.position;
    final size = element.size;

    return PropertyPanelSection(
      title: 'Geometria',
      children: [
        Row(
          children: [
            Expanded(
              child: LabeledNumberField(
                label: 'X',
                value: position.x,
                suffixText: 'mm',
                onChanged: (value) => onChange(
                  (e) => withPosition(e, position.copyWith(x: value)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LabeledNumberField(
                label: 'Y',
                value: position.y,
                suffixText: 'mm',
                onChanged: (value) => onChange(
                  (e) => withPosition(e, position.copyWith(y: value)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LabeledNumberField(
                label: 'Largura',
                value: size.width,
                min: 0.1,
                suffixText: 'mm',
                onChanged: (value) => onChange(
                  (e) => withSize(e, size.copyWith(width: value)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LabeledNumberField(
                label: 'Altura',
                value: size.height,
                min: 0.1,
                suffixText: 'mm',
                onChanged: (value) => onChange(
                  (e) => withSize(e, size.copyWith(height: value)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LabeledNumberField(
          label: 'Rotação',
          value: element.rotation,
          suffixText: '°',
          onChanged: (value) => onChange((e) => withRotation(e, value)),
        ),
      ],
    );
  }
}
