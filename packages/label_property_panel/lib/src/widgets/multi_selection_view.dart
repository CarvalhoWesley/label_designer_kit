import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_widgets/label_widgets.dart';

import '../common/common_element_updates.dart';
import '../widgets/property_panel_section.dart';

/// Shown in [LabelPropertyPanel] when more than one element is selected.
///
/// Position/size/rotation aren't editable here — each selected element has
/// its own, and there's no single sensible "apply to all" semantics for
/// them (unlike a drag, which moves each by the same delta). Only the
/// fields where "set the same value on every selected element" is
/// unambiguous — visibility, lock, opacity — are exposed, applied as one
/// undo step via [PropertyStore.changeProperties].
class MultiSelectionView extends StatelessWidget {
  const MultiSelectionView({
    super.key,
    required this.elements,
    required this.propertyStore,
  });

  final List<LabelElement> elements;
  final PropertyStore propertyStore;

  void _setAllVisible(bool visible) => propertyStore.changeProperties<bool>(
    oldValues: {for (final e in elements) e.id: e.visible},
    newValues: {for (final e in elements) e.id: visible},
    apply: withVisible,
  );

  void _setAllLocked(bool locked) => propertyStore.changeProperties<bool>(
    oldValues: {for (final e in elements) e.id: e.locked},
    newValues: {for (final e in elements) e.id: locked},
    apply: withLocked,
  );

  void _setAllOpacity(double opacity) =>
      propertyStore.changeProperties<double>(
        oldValues: {for (final e in elements) e.id: e.opacity},
        newValues: {for (final e in elements) e.id: opacity},
        apply: withOpacity,
      );

  @override
  Widget build(BuildContext context) {
    final allVisible = elements.every((e) => e.visible);
    final allLocked = elements.every((e) => e.locked);
    final averageOpacity =
        elements.map((e) => e.opacity).reduce((a, b) => a + b) /
        elements.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: PropertyPanelSection(
        title: '${elements.length} elementos selecionados',
        children: [
          Row(
            children: [
              LabelToolbarButton(
                icon: allVisible ? LabelIcons.visible : LabelIcons.hidden,
                tooltip: allVisible ? 'Ocultar todos' : 'Mostrar todos',
                selected: allVisible,
                onPressed: () => _setAllVisible(!allVisible),
              ),
              LabelToolbarButton(
                icon: allLocked ? LabelIcons.lock : LabelIcons.unlock,
                tooltip: allLocked ? 'Desbloquear todos' : 'Bloquear todos',
                selected: allLocked,
                onPressed: () => _setAllLocked(!allLocked),
              ),
            ],
          ),
          Text(
            'Opacidade (${(averageOpacity * 100).round()}%)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(value: averageOpacity, onChanged: _setAllOpacity),
        ],
      ),
    );
  }
}
