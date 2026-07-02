import 'package:label_core/label_core.dart';
import 'package:mobx/mobx.dart';

part 'canvas_store.g.dart';

/// A resize handle on the selection's bounding box, or the dedicated
/// rotation handle.
enum ResizeHandle {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  rotation,
}

/// Ephemeral interaction state for `label_canvas` — everything about *how*
/// the user is currently dragging, not *what* is selected ([SelectionStore])
/// or *what the document contains* ([DocumentStore]).
///
/// None of this is undo-able or persisted: it's reset the moment the
/// gesture ends. This also doubles as the live "drag preview" the
/// painter reads while a gesture is in progress — `label_canvas` never
/// dispatches a `Command` per pointer-move frame (that would flood the
/// undo stack), only once on release; until then, the moved/resized/
/// rotated element's on-screen position comes from here instead of
/// `DocumentStore`.
class CanvasStore = CanvasStoreBase with _$CanvasStore;

abstract class CanvasStoreBase with Store {
  @observable
  bool isDragging = false;

  @observable
  ResizeHandle? activeResizeHandle;

  @observable
  ObservableList<double> activeGuidesX = ObservableList<double>();

  @observable
  ObservableList<double> activeGuidesY = ObservableList<double>();

  /// Live mm position of every element being dragged in a move gesture,
  /// keyed by element id. Empty when no move drag is in progress.
  @observable
  ObservableMap<String, Point> dragPreviewPositions =
      ObservableMap<String, Point>();

  @observable
  String? resizingElementId;

  @observable
  Point? resizePreviewPosition;

  @observable
  Size2D? resizePreviewSize;

  @observable
  String? rotatingElementId;

  @observable
  double? rotationPreviewDegrees;

  /// The two opposite corners (mm) of an in-progress marquee/rubber-band
  /// selection rectangle. Both `null` when no marquee is active.
  @observable
  Point? marqueeStart;

  @observable
  Point? marqueeEnd;

  @computed
  bool get hasActiveGuides =>
      activeGuidesX.isNotEmpty || activeGuidesY.isNotEmpty;

  @action
  void beginDrag({ResizeHandle? handle}) {
    isDragging = true;
    activeResizeHandle = handle;
  }

  @action
  void endDrag() {
    isDragging = false;
    activeResizeHandle = null;
    clearGuides();
  }

  @action
  void setGuides({List<double> x = const [], List<double> y = const []}) {
    activeGuidesX
      ..clear()
      ..addAll(x);
    activeGuidesY
      ..clear()
      ..addAll(y);
  }

  @action
  void clearGuides() {
    activeGuidesX.clear();
    activeGuidesY.clear();
  }

  /// Starts a move drag with [startPositions] (one entry per selected
  /// element) as the initial preview.
  @action
  void beginElementDrag(Map<String, Point> startPositions) {
    dragPreviewPositions
      ..clear()
      ..addAll(startPositions);
    beginDrag();
  }

  /// Updates the live preview position of every dragged element.
  @action
  void updateElementDrag(Map<String, Point> livePositions) {
    dragPreviewPositions
      ..clear()
      ..addAll(livePositions);
  }

  @action
  void endElementDrag() {
    dragPreviewPositions.clear();
    endDrag();
  }

  @action
  void beginResize(
    String elementId,
    ResizeHandle handle, {
    required Point position,
    required Size2D size,
  }) {
    resizingElementId = elementId;
    resizePreviewPosition = position;
    resizePreviewSize = size;
    beginDrag(handle: handle);
  }

  @action
  void updateResize({required Point position, required Size2D size}) {
    resizePreviewPosition = position;
    resizePreviewSize = size;
  }

  @action
  void endResize() {
    resizingElementId = null;
    resizePreviewPosition = null;
    resizePreviewSize = null;
    endDrag();
  }

  @action
  void beginRotate(String elementId, {required double rotationDegrees}) {
    rotatingElementId = elementId;
    rotationPreviewDegrees = rotationDegrees;
    beginDrag(handle: ResizeHandle.rotation);
  }

  @action
  void updateRotate(double rotationDegrees) {
    rotationPreviewDegrees = rotationDegrees;
  }

  @action
  void endRotate() {
    rotatingElementId = null;
    rotationPreviewDegrees = null;
    endDrag();
  }

  @action
  void beginMarquee(Point start) {
    marqueeStart = start;
    marqueeEnd = start;
    beginDrag();
  }

  @action
  void updateMarquee(Point current) {
    marqueeEnd = current;
  }

  @action
  void endMarquee() {
    marqueeStart = null;
    marqueeEnd = null;
    endDrag();
  }
}
