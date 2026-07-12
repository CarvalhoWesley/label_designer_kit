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
  /// Pixels per millimeter at "100%" (actual/real size) — the reference
  /// most design tools use to approximate physical size on screen without
  /// knowing the monitor's real DPI: a 96 DPI "reference pixel" (the same
  /// assumption CSS uses), i.e. `96 / 25.4` px per mm.
  ///
  /// [zoom] itself stays a plain px/mm density (unrelated to any
  /// percentage), so this is what converts between the two — see
  /// [showActualSize] and the toolbar's zoom percentage display.
  static const double pxPerMmAtActualSize = 96 / 25.4;

  static const double minZoom = pxPerMmAtActualSize * 0.1;
  static const double maxZoom = pxPerMmAtActualSize * 8;

  @observable
  double zoom = pxPerMmAtActualSize;

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
    zoom = pxPerMmAtActualSize;
    pan = const Point.zero();
  }

  /// Zooms and pans so the page (given its size in mm) is centered and
  /// fills [viewportWidthPx]/[viewportHeightPx] with a 10% margin — the
  /// toolbar's explicit "fit to view" action, not what runs automatically
  /// when a document opens (see [showActualSize] for that).
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

  /// Centers the page at [pxPerMmAtActualSize] ("100%", actual/real size)
  /// — called when the canvas first lays out and whenever a different
  /// document is loaded, so opening a label shows it at real-world size
  /// (like BarTender/NiceLabel do) instead of an auto-computed "fit"
  /// zoom that has no relationship to 100% and, for a small label on a
  /// wide viewport, routinely lands near [maxZoom].
  @action
  void showActualSize({
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
    zoom = pxPerMmAtActualSize;
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
