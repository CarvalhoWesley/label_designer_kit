import 'package:flutter/rendering.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

import '../geometry/canvas_transform.dart';
import '../geometry/element_bounds.dart';
import '../geometry/placement.dart';
import 'element_painter.dart';

/// Everything [LabelCanvasPainter] needs, as a plain snapshot — the
/// `label_canvas` widget reads this out of the MobX stores inside an
/// `Observer` build and hands it down, so the painter itself has no store
/// dependency and is trivially constructible in tests.
class CanvasPaintData {
  const CanvasPaintData({
    required this.page,
    required this.elements,
    required this.layers,
    required this.transform,
    required this.selectedIds,
    this.dragPreviewPositions = const {},
    this.resizingElementId,
    this.resizePreviewPosition,
    this.resizePreviewSize,
    this.rotatingElementId,
    this.rotationPreviewDegrees,
    this.showGrid = false,
    this.gridSizeMm = 5,
    this.guidesX = const [],
    this.guidesY = const [],
    this.marqueeStart,
    this.marqueeEnd,
  });

  final PageConfig page;
  final List<LabelElement> elements;
  final List<LabelLayer> layers;
  final CanvasTransform transform;
  final Set<String> selectedIds;

  final Map<String, Point> dragPreviewPositions;
  final String? resizingElementId;
  final Point? resizePreviewPosition;
  final Size2D? resizePreviewSize;
  final String? rotatingElementId;
  final double? rotationPreviewDegrees;

  final bool showGrid;
  final double gridSizeMm;
  final List<double> guidesX;
  final List<double> guidesY;

  final Point? marqueeStart;
  final Point? marqueeEnd;
}

/// Draws the page, grid, every element, the current selection's outline +
/// handles, snap guides and an in-progress marquee rectangle — the direct,
/// editable rendering `label_canvas` owns (never `label_layout_engine` /
/// `label_renderer_*`; see `docs/ARCHITECTURE.md` section 15).
class LabelCanvasPainter extends CustomPainter {
  LabelCanvasPainter(this.data);

  final CanvasPaintData data;

  static const double handleSizePx = 8;
  static const double rotationHandleOffsetMm = 8;

  @override
  void paint(Canvas canvas, Size size) {
    _paintPageBackground(canvas);
    if (data.showGrid) _paintGrid(canvas, size);
    _paintElements(canvas);
    _paintSelection(canvas);
    _paintGuides(canvas, size);
    _paintMarquee(canvas);
  }

  void _paintPageBackground(Canvas canvas) {
    final topLeft = data.transform.mmToPx(const Point.zero());
    final bottomRight = data.transform.mmToPx(
      Point(x: data.page.width, y: data.page.height),
    );
    final rect = Rect.fromPoints(topLeft, bottomRight);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFBDBDBD)
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    if (data.gridSizeMm <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 1;
    final topLeftMm = data.transform.pxToMm(Offset.zero);
    final bottomRightMm = data.transform.pxToMm(
      Offset(size.width, size.height),
    );

    var x = (topLeftMm.x / data.gridSizeMm).floor() * data.gridSizeMm;
    while (x <= bottomRightMm.x) {
      final px = data.transform.mmToPx(Point(x: x, y: 0)).dx;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), paint);
      x += data.gridSizeMm;
    }
    var y = (topLeftMm.y / data.gridSizeMm).floor() * data.gridSizeMm;
    while (y <= bottomRightMm.y) {
      final py = data.transform.mmToPx(Point(x: 0, y: y)).dy;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
      y += data.gridSizeMm;
    }
  }

  void _paintElements(Canvas canvas) {
    // A resizing element's position also moves (the opposite edge stays
    // fixed on screen), so it needs an entry in the same position-override
    // map a move drag uses — merge them.
    final positionOverrides = {
      ...data.dragPreviewPositions,
      if (data.resizingElementId != null && data.resizePreviewPosition != null)
        data.resizingElementId!: data.resizePreviewPosition!,
    };
    final placed = paintOrder(
      data.elements,
      data.layers,
      positionOverrides: positionOverrides,
      sizeOverrides:
          data.resizingElementId == null || data.resizePreviewSize == null
          ? const {}
          : {data.resizingElementId!: data.resizePreviewSize!},
      rotationOverrides:
          data.rotatingElementId == null || data.rotationPreviewDegrees == null
          ? const {}
          : {data.rotatingElementId!: data.rotationPreviewDegrees!},
    );

    for (final entry in placed) {
      entry.element.accept(
        ElementPainter(
          canvas: canvas,
          transform: data.transform,
          placement: entry.placement,
        ),
      );
    }
  }

  void _paintSelection(Canvas canvas) {
    if (data.selectedIds.isEmpty) return;
    final singleId = data.selectedIds.length == 1
        ? data.selectedIds.single
        : null;

    for (final id in data.selectedIds) {
      final element = _findTopLevel(id);
      if (element == null) continue;
      final bounds = _effectiveBounds(element);

      final path = Path()
        ..addPolygon(bounds.corners.map(data.transform.mmToPx).toList(), true);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF2196F3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      if (singleId == id && element is! GroupElement) {
        _paintHandles(canvas, bounds);
      } else if (singleId == id) {
        // Groups support move/rotate but not per-edge resize (their
        // children don't scale with the group's box) — see the package
        // README for why resize handles are intentionally omitted here.
        _paintHandle(
          canvas,
          bounds.handlePosition(
            ResizeHandle.rotation,
            rotationHandleOffsetMm: rotationHandleOffsetMm,
          ),
        );
      }
    }
  }

  void _paintHandles(Canvas canvas, ElementBounds bounds) {
    for (final handle in ResizeHandle.values) {
      _paintHandle(
        canvas,
        bounds.handlePosition(
          handle,
          rotationHandleOffsetMm: rotationHandleOffsetMm,
        ),
      );
    }
  }

  void _paintHandle(Canvas canvas, Point mm) {
    final center = data.transform.mmToPx(mm);
    canvas.drawCircle(
      center,
      handleSizePx / 2,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawCircle(
      center,
      handleSizePx / 2,
      Paint()
        ..color = const Color(0xFF2196F3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintGuides(Canvas canvas, Size size) {
    if (data.guidesX.isEmpty && data.guidesY.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFFE91E63)
      ..strokeWidth = 1;
    for (final x in data.guidesX) {
      final px = data.transform.mmToPx(Point(x: x, y: 0)).dx;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), paint);
    }
    for (final y in data.guidesY) {
      final py = data.transform.mmToPx(Point(x: 0, y: y)).dy;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
    }
  }

  void _paintMarquee(Canvas canvas) {
    final start = data.marqueeStart;
    final end = data.marqueeEnd;
    if (start == null || end == null) return;
    final rect = Rect.fromPoints(
      data.transform.mmToPx(start),
      data.transform.mmToPx(end),
    );
    canvas.drawRect(rect, Paint()..color = const Color(0x1F2196F3));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF2196F3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  LabelElement? _findTopLevel(String id) {
    for (final element in data.elements) {
      if (element.id == id) return element;
    }
    return null;
  }

  ElementBounds _effectiveBounds(LabelElement element) {
    final position =
        data.dragPreviewPositions[element.id] ??
        (element.id == data.resizingElementId
            ? data.resizePreviewPosition
            : null) ??
        element.position;
    final size = element.id == data.resizingElementId
        ? (data.resizePreviewSize ?? element.size)
        : element.size;
    final rotation = element.id == data.rotatingElementId
        ? (data.rotationPreviewDegrees ?? element.rotation)
        : element.rotation;
    return ElementBounds(
      position: position,
      size: size,
      rotationDegrees: rotation,
    );
  }

  @override
  bool shouldRepaint(covariant LabelCanvasPainter oldDelegate) => true;
}
