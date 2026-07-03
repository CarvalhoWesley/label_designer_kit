/// Reactive property panel for the editor, wired to `label_designer_state`.
/// See `docs/ARCHITECTURE.md` section 7.
///
/// Edits the selected element(s)' fields; never calculates layout, never
/// imports `label_layout_engine` nor any `label_renderer_*`.
library;

export 'src/label_property_panel.dart';
export 'src/widgets/labeled_number_field.dart';
export 'src/widgets/labeled_text_field.dart';
export 'src/widgets/property_panel_section.dart';
