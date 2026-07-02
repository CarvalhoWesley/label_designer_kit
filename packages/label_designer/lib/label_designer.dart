/// Composition of the full visual editor — toolbar, layers panel, canvas,
/// properties/preview panel and keyboard shortcuts. See
/// `docs/ARCHITECTURE.md` sections 7 and 20.
///
/// This is the package a consuming Flutter project imports to embed
/// `LabelDesigner` in a screen. Doesn't save to disk or print; never
/// imports any `label_renderer_*` for a physical printer.
library;

export 'src/label_designer.dart';
export 'src/widgets/right_panel.dart' show RightPanelTab;
