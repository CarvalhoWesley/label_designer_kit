import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_designer_state/label_designer_state.dart';

import 'common/general_section.dart';
import 'common/geometry_section.dart';
import 'type_sections/type_section_visitor.dart';
import 'widgets/empty_selection_view.dart';
import 'widgets/multi_selection_view.dart';

/// The editor's property panel: reactive editing of the selected
/// element(s)' fields, wired to `label_designer_state`'s stores (see
/// `docs/ARCHITECTURE.md` sections 7 and 14).
///
/// Every field edit is dispatched through [propertyStore], which routes
/// it through [HistoryStore] — this widget never mutates a
/// [LabelDocument] directly, so every edit is undo-able by construction.
/// Never imports `label_layout_engine` nor any `label_renderer_*`.
class LabelPropertyPanel extends StatelessWidget {
  const LabelPropertyPanel({
    super.key,
    required this.documentStore,
    required this.selectionStore,
    required this.propertyStore,
  });

  final DocumentStore documentStore;
  final SelectionStore selectionStore;
  final PropertyStore propertyStore;

  void _changeElement(LabelElement element, LabelElement Function(LabelElement) apply) {
    final newElement = apply(element);
    if (newElement == element) return;
    propertyStore.changeProperty<LabelElement>(
      elementId: element.id,
      oldValue: element,
      newValue: newElement,
      apply: (_, value) => value,
    );
  }

  Widget _buildSingleSelection(BuildContext context, LabelElement element) {
    void onChange(LabelElement Function(LabelElement) apply) =>
        _changeElement(element, apply);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GeneralSection(
            element: element,
            layers: documentStore.layers,
            onChange: onChange,
          ),
          const Divider(),
          GeometrySection(element: element, onChange: onChange),
          const Divider(),
          element.accept(
            TypeSectionVisitor(
              styles: documentStore.styles,
              onChange: onChange,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final elements = propertyStore.selectedElements;
        if (elements.isEmpty) return const EmptySelectionView();
        final single = propertyStore.singleSelectedElement;
        if (single != null) return _buildSingleSelection(context, single);
        return MultiSelectionView(
          elements: elements,
          propertyStore: propertyStore,
        );
      },
    );
  }
}
