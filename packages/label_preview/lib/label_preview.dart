/// Live preview widget for the editor: `LabelDocument` → `LabelLayoutEngine`
/// → `CanvasRenderer` → `Image.memory`. See `docs/ARCHITECTURE.md`
/// section 16.
///
/// Uses the exact same layout/render pipeline as a PNG/JPEG export job, so
/// the preview never diverges from the real print output. Never imports
/// `label_renderer_argox`/`_zebra`/`_tsc`/`_pdf`.
library;

export 'src/label_preview.dart';
