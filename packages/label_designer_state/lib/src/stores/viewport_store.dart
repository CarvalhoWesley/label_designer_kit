import 'dart:math' as math;

import 'package:label_core/label_core.dart';
import 'package:mobx/mobx.dart';

part 'viewport_store.g.dart';

/// Zoom, pan, grid, snap and ruler state for `label_canvas`.
///
/// Deliberately not routed through [HistoryStore]: the viewport is a
/// property of the *editing session*, not of the [LabelDocument] itself —
/// undoing a zoom/pan change would be surprising to a user (most design
/// tools don't do it either).
class ViewportStore = ViewportStoreBase with _$ViewportStore;

abstract class ViewportStoreBase with Store {
  static const double minZoom = 0.1;
  static const double maxZoom = 8;

  @observable
  double zoom = 1;

  @observable
  Point pan = const Point.zero();

  @observable
  bool showGrid = true;

  @observable
  double gridSizeMm = 1;

  @observable
  bool snapEnabled = true;

  @observable
  bool showRulers = true;

  @action
  void setZoom(double value) => zoom = value.clamp(minZoom, maxZoom);

  @action
  void zoomBy(double factor) => setZoom(zoom * factor);

  @action
  void setPan(Point value) => pan = value;

  @action
  void panBy(double dx, double dy) => pan = pan.translate(dx, dy);

  @action
  void resetView() {
    zoom = 1;
    pan = const Point.zero();
  }

  /// Zooms and pans so the page (given its size in mm) is centered and
  /// fills [viewportWidthPx]/[viewportHeightPx] with a 10% margin — called
  /// when the canvas first lays out and whenever a different document is
  /// loaded, so a small label doesn't appear tiny in a corner of a large
  /// viewport at the default `zoom = 1` (1mm = 1px).
  @action
  void fitToPage({
    required double pageWidthMm,
    required double pageHeightMm,
    required double viewportWidthPx,
    required double viewportHeightPx,
  }) {
    if (pageWidthMm <= 0 ||
        pageHeightMm <= 0 ||
        viewportWidthPx <= 0 ||
        viewportHeightPx <= 0) {
      return;
    }
    final fitZoom =
        0.9 *
        math.min(viewportWidthPx / pageWidthMm, viewportHeightPx / pageHeightMm);
    zoom = fitZoom.clamp(minZoom, maxZoom);
    pan = Point(
      x: (viewportWidthPx - pageWidthMm * zoom) / 2,
      y: (viewportHeightPx - pageHeightMm * zoom) / 2,
    );
  }

  @action
  void toggleGrid() => showGrid = !showGrid;

  @action
  void toggleSnap() => snapEnabled = !snapEnabled;

  @action
  void toggleRulers() => showRulers = !showRulers;

  @action
  void setGridSize(double mm) => gridSizeMm = mm.clamp(0.5, 100);

  /// Converts a length in millimeters to on-screen pixels at the current
  /// [zoom]. Panning is a separate translation, applied by the painter.
  double mmToPixels(double mm) => mm * zoom;

  /// Converts a length in on-screen pixels back to millimeters at the
  /// current [zoom].
  double pixelsToMm(double pixels) => pixels / zoom;
}
