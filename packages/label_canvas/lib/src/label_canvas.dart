import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:label_widgets/label_widgets.dart';

import 'geometry/canvas_transform.dart';
import 'interaction/canvas_controller.dart';
import 'painting/label_canvas_painter.dart';

/// The editor's visual canvas: page, grid, elements, selection handles and
/// rulers, wired to `label_designer_state`'s stores. Draws a direct,
/// editable representation of the model — never `label_layout_engine`,
/// never any `label_renderer_*` (see `docs/ARCHITECTURE.md` section 15).
///
/// Every gesture — select, move, resize, rotate, marquee, zoom, pan —
/// goes through a [CanvasController], so the interaction logic itself is
/// unit-tested independently of this widget (see
/// `test/interaction/canvas_controller_test.dart`).
class LabelCanvas extends StatefulWidget {
  const LabelCanvas({
    super.key,
    required this.documentStore,
    required this.selectionStore,
    required this.historyStore,
    required this.viewportStore,
    required this.canvasStore,
    this.showRulers = true,
    this.rulerThickness = 20,
  });

  final DocumentStore documentStore;
  final SelectionStore selectionStore;
  final HistoryStore historyStore;
  final ViewportStore viewportStore;
  final CanvasStore canvasStore;
  final bool showRulers;
  final double rulerThickness;

  @override
  State<LabelCanvas> createState() => _LabelCanvasState();
}

class _LabelCanvasState extends State<LabelCanvas> {
  late final CanvasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CanvasController(
      documentStore: widget.documentStore,
      selectionStore: widget.selectionStore,
      historyStore: widget.historyStore,
      viewportStore: widget.viewportStore,
      canvasStore: widget.canvasStore,
    );
  }

  bool get _addToSelectionKeyPressed =>
      HardwareKeyboard.instance.isShiftPressed ||
      HardwareKeyboard.instance.isControlPressed;

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final viewport = widget.viewportStore;
    final zoomKeyPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (zoomKeyPressed) {
      final before = CanvasTransform(
        zoom: viewport.zoom,
        pan: viewport.pan,
      ).pxToMm(event.localPosition);
      viewport.zoomBy(event.scrollDelta.dy > 0 ? 0.9 : 1.1);
      final zoom = viewport.zoom;
      viewport.setPan(
        Point(
          x: event.localPosition.dx - before.x * zoom,
          y: event.localPosition.dy - before.y * zoom,
        ),
      );
    } else if (HardwareKeyboard.instance.isShiftPressed) {
      viewport.panBy(-event.scrollDelta.dy, 0);
    } else {
      viewport.panBy(-event.scrollDelta.dx, -event.scrollDelta.dy);
    }
  }

  Widget _buildSurface() {
    return Observer(
      builder: (context) {
        final page = widget.documentStore.document.page;
        final data = CanvasPaintData(
          page: page,
          elements: widget.documentStore.elements,
          layers: widget.documentStore.layers,
          transform: _controller.transform,
          selectedIds: widget.selectionStore.selectedIds,
          dragPreviewPositions: Map.of(widget.canvasStore.dragPreviewPositions),
          resizingElementId: widget.canvasStore.resizingElementId,
          resizePreviewPosition: widget.canvasStore.resizePreviewPosition,
          resizePreviewSize: widget.canvasStore.resizePreviewSize,
          rotatingElementId: widget.canvasStore.rotatingElementId,
          rotationPreviewDegrees: widget.canvasStore.rotationPreviewDegrees,
          showGrid: widget.viewportStore.showGrid,
          gridSizeMm: widget.viewportStore.gridSizeMm,
          guidesX: List.of(widget.canvasStore.activeGuidesX),
          guidesY: List.of(widget.canvasStore.activeGuidesY),
          marqueeStart: widget.canvasStore.marqueeStart,
          marqueeEnd: widget.canvasStore.marqueeEnd,
        );

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _controller.pointerDown(
            event.localPosition,
            addToSelection: _addToSelectionKeyPressed,
          ),
          onPointerMove: (event) =>
              _controller.pointerMove(event.localPosition),
          onPointerUp: (event) => _controller.pointerUp(event.localPosition),
          onPointerCancel: (_) => _controller.pointerCancel(),
          onPointerSignal: _handlePointerSignal,
          child: SizedBox.expand(
            child: CustomPaint(painter: LabelCanvasPainter(data)),
          ),
        );
      },
    );
  }

  Widget _buildRulers(Widget surface) {
    if (!widget.showRulers) return surface;
    return Observer(
      builder: (context) {
        final zoom = widget.viewportStore.zoom;
        final pan = widget.viewportStore.pan;
        return Column(
          children: [
            SizedBox(
              height: widget.rulerThickness,
              child: Row(
                children: [
                  SizedBox(
                    width: widget.rulerThickness,
                    height: widget.rulerThickness,
                  ),
                  Expanded(
                    child: LabelRuler(
                      axis: RulerAxis.horizontal,
                      pixelsPerMm: zoom,
                      originOffset: pan.x,
                      thickness: widget.rulerThickness,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  LabelRuler(
                    axis: RulerAxis.vertical,
                    pixelsPerMm: zoom,
                    originOffset: pan.y,
                    thickness: widget.rulerThickness,
                  ),
                  Expanded(child: surface),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => _buildRulers(_buildSurface());
}
