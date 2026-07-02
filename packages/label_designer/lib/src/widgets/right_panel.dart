import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_preview/label_preview.dart';
import 'package:label_property_panel/label_property_panel.dart';

import '../logic/sample_data.dart';

/// Which view the editor's right-hand panel currently shows.
enum RightPanelTab { properties, preview }

/// The editor's right sidebar: toggles between `label_property_panel`
/// (edit the selection) and `label_preview` (see the document as it would
/// actually print). Both read the same [documentStore], so switching tabs
/// never shows stale data.
///
/// `label_preview` isn't MobX-aware (see its own doc comment) — this is
/// exactly the composition point responsible for observing
/// [documentStore] and passing the current `LabelDocument` value down to
/// it on every change (`docs/ARCHITECTURE.md` section 16).
class RightPanel extends StatelessWidget {
  const RightPanel({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.documentStore,
    required this.selectionStore,
    required this.propertyStore,
  });

  final RightPanelTab tab;
  final ValueChanged<RightPanelTab> onTabChanged;
  final DocumentStore documentStore;
  final SelectionStore selectionStore;
  final PropertyStore propertyStore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<RightPanelTab>(
            segments: const [
              ButtonSegment(
                value: RightPanelTab.properties,
                label: Text('Propriedades'),
                icon: Icon(Icons.tune),
              ),
              ButtonSegment(
                value: RightPanelTab.preview,
                label: Text('Preview'),
                icon: Icon(Icons.visibility_outlined),
              ),
            ],
            selected: {tab},
            onSelectionChanged: (selection) => onTabChanged(selection.first),
          ),
        ),
        Expanded(
          child: switch (tab) {
            RightPanelTab.properties => LabelPropertyPanel(
              documentStore: documentStore,
              selectionStore: selectionStore,
              propertyStore: propertyStore,
            ),
            RightPanelTab.preview => Observer(
              builder: (context) => LabelPreview(
                document: documentStore.document,
                sampleData: buildSampleData(documentStore.variables),
              ),
            ),
          },
        ),
      ],
    );
  }
}
