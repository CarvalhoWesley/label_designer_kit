/// Editor visual (`CustomPainter`): selecionar, mover, redimensionar,
/// girar, zoom/pan, grid/snap. See `docs/ARCHITECTURE.md` section 15.
///
/// Draws a direct, editable representation of the current `LabelDocument`
/// — never `label_layout_engine`, never any `label_renderer_*`.
library;

export 'src/interaction/canvas_controller.dart';
export 'src/label_canvas.dart';
export 'src/painting/label_canvas_painter.dart'
    show CanvasPaintData, LabelCanvasPainter;
