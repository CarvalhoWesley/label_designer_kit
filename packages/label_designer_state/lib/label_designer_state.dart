/// MobX stores that orchestrate the document, selection, history, layers
/// and viewport of the editor. See `docs/ARCHITECTURE.md` section 14.
///
/// Pure Dart — no widgets. Each store is a plain MobX `Store`, testable
/// with `package:mobx` + `package:test` alone; `label_canvas` and
/// `label_property_panel` wrap them in `Observer()` to react to changes.
library;

export 'src/stores/canvas_store.dart';
export 'src/stores/document_store.dart';
export 'src/stores/history_store.dart';
export 'src/stores/layer_store.dart';
export 'src/stores/property_store.dart';
export 'src/stores/selection_store.dart';
export 'src/stores/viewport_store.dart';
