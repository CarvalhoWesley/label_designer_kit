import 'dart:ui';

import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

import '../geometry/alignment_snap.dart';
import '../geometry/canvas_transform.dart';
import '../geometry/element_bounds.dart';
import '../geometry/resize_math.dart';
import '../geometry/rotation_math.dart';
import '../geometry/snap.dart';
import 'hit_test.dart';

enum _DragKind { move, resize, rotate, marquee }

/// The gesture state machine behind `label_canvas`: translates raw pointer
/// events (already converted to on-screen pixels by the widget) into
/// store updates.
///
/// Plain Dart, no widget dependency, so every interaction — select, move,
/// resize, rotate, marquee, zoom/pan — is testable by calling its methods
/// directly, without pumping a widget tree. Live feedback during a drag
/// goes through [CanvasStore]'s preview fields; a [Command] is only
/// dispatched once, on release (see that store's doc comment for why).
class CanvasController {
  CanvasController({
    required this.documentStore,
    required this.selectionStore,
    required this.historyStore,
    required this.viewportStore,
    required this.canvasStore,
  });

  final DocumentStore documentStore;
  final SelectionStore selectionStore;
  final HistoryStore historyStore;
  final ViewportStore viewportStore;
  final CanvasStore canvasStore;

  static const double handleHitRadiusPx = 8;
  static const double rotationSnapIncrementDegrees = 15;
  static const double minElementSizeMm = 1;

  /// How close (in screen pixels, independent of zoom) an edge needs to
  /// be to another element's edge before [snapToElements] "magnetically"
  /// aligns to it — same pixel-radius-independent-of-zoom idea as
  /// [handleHitRadiusPx].
  static const double alignmentSnapThresholdPx = 6;

  CanvasTransform get transform =>
      CanvasTransform(zoom: viewportStore.zoom, pan: viewportStore.pan);

  _DragKind? _dragKind;

  // Move
  Point? _moveStartPointerMm;
  Map<String, Point> _moveStartPositions = {};

  // Resize
  String? _resizeElementId;
  ElementBounds? _resizeOriginalBounds;
  ResizeHandle? _resizeHandle;

  // Rotate
  String? _rotateElementId;
  double? _rotateOriginalDegrees;
  Point? _rotateCenter;

  // Marquee
  bool _marqueeAdditive = false;

  LabelElement? _findElement(String id) {
    for (final element in documentStore.elements) {
      if (element.id == id) return element;
    }
    return null;
  }

  /// Call from the widget's pointer-down handler, with [localPositionPx]
  /// already relative to the canvas's own origin. [addToSelection] is
  /// true when shift/ctrl is held.
  void pointerDown(Offset localPositionPx, {bool addToSelection = false}) {
    final pointerMm = transform.pxToMm(localPositionPx);

    final singleId = selectionStore.singleSelectedId;
    if (singleId != null) {
      final element = _findElement(singleId);
      if (element != null) {
        final bounds = ElementBounds.of(element);
        final handle = hitTestHandle(
          bounds: bounds,
          pointerMm: pointerMm,
          hitRadiusMm: transform.lengthToMm(handleHitRadiusPx),
        );
        if (handle == ResizeHandle.rotation) {
          _beginRotate(element, bounds);
          return;
        }
        // Groups don't get resize handles painted (see the README), so a
        // handle hit here is only meaningful for non-group elements.
        if (handle != null && element is! GroupElement) {
          _beginResize(element, bounds, handle);
          return;
        }
      }
    }

    final hitId = hitTestElement(
      elements: documentStore.elements,
      layers: documentStore.layers,
      pointerMm: pointerMm,
    );
    if (hitId != null) {
      final alreadySelected = selectionStore.selectedIds.contains(hitId);
      if (addToSelection) {
        selectionStore.toggle(hitId);
      } else if (!alreadySelected) {
        selectionStore.select(hitId);
      }
      if (selectionStore.selectedIds.contains(hitId)) {
        _beginMove(pointerMm);
      }
      return;
    }

    _beginMarquee(pointerMm, additive: addToSelection);
  }

  void pointerMove(Offset localPositionPx) {
    final pointerMm = transform.pxToMm(localPositionPx);
    switch (_dragKind) {
      case _DragKind.move:
        _updateMove(pointerMm);
      case _DragKind.resize:
        _updateResize(pointerMm);
      case _DragKind.rotate:
        _updateRotate(pointerMm);
      case _DragKind.marquee:
        _updateMarquee(pointerMm);
      case null:
        break;
    }
  }

  void pointerUp(Offset localPositionPx) {
    switch (_dragKind) {
      case _DragKind.move:
        _endMove();
      case _DragKind.resize:
        _endResize();
      case _DragKind.rotate:
        _endRotate();
      case _DragKind.marquee:
        _endMarquee(transform.pxToMm(localPositionPx));
      case null:
        break;
    }
    _dragKind = null;
  }

  /// Cancels whatever drag is in progress without committing a `Command` —
  /// e.g. on `onPointerCancel` or when focus is lost mid-gesture.
  void pointerCancel() {
    switch (_dragKind) {
      case _DragKind.move:
        canvasStore.endElementDrag();
      case _DragKind.resize:
        canvasStore.endResize();
      case _DragKind.rotate:
        canvasStore.endRotate();
      case _DragKind.marquee:
        canvasStore.endMarquee();
      case null:
        break;
    }
    _dragKind = null;
  }

  // --- move ---------------------------------------------------------

  void _beginMove(Point pointerMm) {
    _dragKind = _DragKind.move;
    _moveStartPointerMm = pointerMm;
    _moveStartPositions = {
      for (final id in selectionStore.selectedIds)
        if (_findElement(id) case final element?) id: element.position,
    };
    canvasStore.beginElementDrag(_moveStartPositions);
  }

  void _updateMove(Point pointerMm) {
    final start = _moveStartPointerMm;
    if (start == null || _moveStartPositions.isEmpty) return;
    var dx = pointerMm.x - start.x;
    var dy = pointerMm.y - start.y;

    if (viewportStore.snapEnabled) {
      // Snap the anchor (first) element, then apply the same corrected
      // delta to the rest, preserving their relative offsets. Alignment
      // to other elements' edges (smart guides) takes priority over grid
      // snapping, independently per axis — falls back to the grid on
      // whichever axis didn't get a close-enough alignment match.
      final anchorEntry = _moveStartPositions.entries.first;
      final anchorStart = anchorEntry.value;
      final proposed = Point(x: anchorStart.x + dx, y: anchorStart.y + dy);
      final gridSnapped = snapPoint(proposed, viewportStore.gridSizeMm);

      final anchorElement = _findElement(anchorEntry.key);
      AlignmentSnapResult? alignment;
      if (anchorElement != null) {
        alignment = snapToElements(
          moving: ElementBounds(
            position: proposed,
            size: anchorElement.size,
            rotationDegrees: anchorElement.rotation,
          ),
          others: [
            for (final element in documentStore.elements)
              if (!_moveStartPositions.containsKey(element.id))
                ElementBounds.of(element),
          ],
          thresholdMm: transform.lengthToMm(alignmentSnapThresholdPx),
        );
      }

      final snapped = Point(
        x: alignment != null && alignment.guidesX.isNotEmpty
            ? alignment.adjustedPosition.x
            : gridSnapped.x,
        y: alignment != null && alignment.guidesY.isNotEmpty
            ? alignment.adjustedPosition.y
            : gridSnapped.y,
      );
      canvasStore.setGuides(
        x: alignment?.guidesX ?? const [],
        y: alignment?.guidesY ?? const [],
      );

      dx = snapped.x - anchorStart.x;
      dy = snapped.y - anchorStart.y;
    } else {
      canvasStore.clearGuides();
    }

    canvasStore.updateElementDrag({
      for (final entry in _moveStartPositions.entries)
        entry.key: Point(x: entry.value.x + dx, y: entry.value.y + dy),
    });
  }

  void _endMove() {
    final live = Map<String, Point>.of(canvasStore.dragPreviewPositions);
    final changed = live.entries.any(
      (entry) => entry.value != _moveStartPositions[entry.key],
    );
    if (changed) {
      historyStore.moveElements(from: _moveStartPositions, to: live);
    }
    canvasStore.endElementDrag();
    _moveStartPositions = {};
    _moveStartPointerMm = null;
  }

  // --- resize ---------------------------------------------------------

  void _beginResize(
    LabelElement element,
    ElementBounds bounds,
    ResizeHandle handle,
  ) {
    _dragKind = _DragKind.resize;
    _resizeElementId = element.id;
    _resizeOriginalBounds = bounds;
    _resizeHandle = handle;
    canvasStore.beginResize(
      element.id,
      handle,
      position: bounds.position,
      size: bounds.size,
    );
  }

  void _updateResize(Point pointerMm) {
    final original = _resizeOriginalBounds;
    final handle = _resizeHandle;
    final elementId = _resizeElementId;
    if (original == null || handle == null || elementId == null) return;

    var result = resizeFromHandle(
      original: original,
      handle: handle,
      pointerMm: pointerMm,
      minSizeMm: minElementSizeMm,
    );

    if (viewportStore.snapEnabled) {
      result = ResizeResult(
        position: snapPoint(result.position, viewportStore.gridSizeMm),
        size: Size2D(
          width: snapValue(
            result.size.width,
            viewportStore.gridSizeMm,
          ).clamp(minElementSizeMm, double.infinity),
          height: snapValue(
            result.size.height,
            viewportStore.gridSizeMm,
          ).clamp(minElementSizeMm, double.infinity),
        ),
      );
    }

    if (_findElement(elementId) is CircleElement) {
      // CircleElement must stay square — label_core deliberately leaves
      // this to the canvas (see that class's doc comment).
      result = ResizeResult(
        position: result.position,
        size: Size2D(width: result.size.width, height: result.size.width),
      );
    }

    canvasStore.updateResize(position: result.position, size: result.size);
  }

  void _endResize() {
    final id = _resizeElementId;
    final original = _resizeOriginalBounds;
    final position = canvasStore.resizePreviewPosition;
    final size = canvasStore.resizePreviewSize;
    if (id != null && original != null && position != null && size != null) {
      historyStore.resizeElementBounds(
        elementId: id,
        fromPosition: original.position,
        toPosition: position,
        fromSize: original.size,
        toSize: size,
      );
    }
    canvasStore.endResize();
    _resizeElementId = null;
    _resizeOriginalBounds = null;
    _resizeHandle = null;
  }

  // --- rotate ---------------------------------------------------------

  void _beginRotate(LabelElement element, ElementBounds bounds) {
    _dragKind = _DragKind.rotate;
    _rotateElementId = element.id;
    _rotateOriginalDegrees = element.rotation;
    _rotateCenter = bounds.center;
    canvasStore.beginRotate(element.id, rotationDegrees: element.rotation);
  }

  void _updateRotate(Point pointerMm) {
    final center = _rotateCenter;
    if (center == null) return;
    final degrees = rotationAngleForPointer(
      center,
      pointerMm,
      snapIncrementDegrees: viewportStore.snapEnabled
          ? rotationSnapIncrementDegrees
          : null,
    );
    canvasStore.updateRotate(degrees);
  }

  void _endRotate() {
    final id = _rotateElementId;
    final from = _rotateOriginalDegrees;
    final to = canvasStore.rotationPreviewDegrees;
    if (id != null && from != null && to != null && from != to) {
      historyStore.rotateElement(elementId: id, from: from, to: to);
    }
    canvasStore.endRotate();
    _rotateElementId = null;
    _rotateOriginalDegrees = null;
    _rotateCenter = null;
  }

  // --- marquee ---------------------------------------------------------

  void _beginMarquee(Point pointerMm, {required bool additive}) {
    _dragKind = _DragKind.marquee;
    _marqueeAdditive = additive;
    if (!additive) selectionStore.clear();
    canvasStore.beginMarquee(pointerMm);
  }

  void _updateMarquee(Point pointerMm) {
    canvasStore.updateMarquee(pointerMm);
  }

  void _endMarquee(Point pointerMm) {
    final start = canvasStore.marqueeStart;
    if (start != null) {
      final hits = elementsInMarquee(
        elements: documentStore.elements,
        layers: documentStore.layers,
        corner1: start,
        corner2: pointerMm,
      );
      if (_marqueeAdditive) {
        selectionStore.selectAll({...selectionStore.selectedIds, ...hits});
      } else {
        selectionStore.selectAll(hits);
      }
    }
    canvasStore.endMarquee();
  }
}
