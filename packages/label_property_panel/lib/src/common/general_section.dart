import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';
import 'package:label_widgets/label_widgets.dart';

import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';
import 'common_element_updates.dart';

/// Name, layer, opacity, visibility and lock — the remaining fields every
/// [LabelElement] subtype shares, besides geometry (see [GeometrySection]).
class GeneralSection extends StatelessWidget {
  const GeneralSection({
    super.key,
    required this.element,
    required this.layers,
    required this.onChange,
  });

  final LabelElement element;
  final List<LabelLayer> layers;

  /// Called with the field's `with...` updater already applied to
  /// [element], so the caller can dispatch a single
  /// `PropertyStore.changeProperty` per edit.
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Geral',
      children: [
        LabeledTextField(
          label: 'Nome',
          value: element.name,
          onChanged: (value) => onChange((e) => withName(e, value)),
        ),
        DropdownButtonFormField<String>(
          value: element.layerId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Camada', isDense: true),
          items: [
            for (final layer in layers)
              DropdownMenuItem(value: layer.id, child: Text(layer.name)),
          ],
          onChanged: (value) {
            if (value != null) onChange((e) => withLayerId(e, value));
          },
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Opacidade',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text('${(element.opacity * 100).round()}%'),
          ],
        ),
        Slider(
          value: element.opacity,
          onChanged: (value) => onChange((e) => withOpacity(e, value)),
        ),
        Row(
          children: [
            LabelToolbarButton(
              icon: element.visible ? LabelIcons.visible : LabelIcons.hidden,
              tooltip: element.visible ? 'Visível' : 'Oculto',
              selected: element.visible,
              onPressed: () =>
                  onChange((e) => withVisible(e, !element.visible)),
            ),
            LabelToolbarButton(
              icon: element.locked ? LabelIcons.lock : LabelIcons.unlock,
              tooltip: element.locked ? 'Bloqueado' : 'Desbloqueado',
              selected: element.locked,
              onPressed: () =>
                  onChange((e) => withLocked(e, !element.locked)),
            ),
          ],
        ),
      ],
    );
  }
}
