import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:test/test.dart';

void main() {
  test('setZoom clamps to [minZoom, maxZoom]', () {
    final store = ViewportStore();
    store.setZoom(100);
    expect(store.zoom, ViewportStoreBase.maxZoom);
    store.setZoom(-5);
    expect(store.zoom, ViewportStoreBase.minZoom);
  });

  test('zoomBy multiplies the current zoom', () {
    final store = ViewportStore()..setZoom(2);
    store.zoomBy(1.5);
    expect(store.zoom, 3);
  });

  test('panBy accumulates translation', () {
    final store = ViewportStore();
    store.panBy(5, 5);
    store.panBy(-2, 3);
    expect(store.pan, const Point(x: 3, y: 8));
  });

  test('resetView restores actual-size zoom and zero pan', () {
    final store = ViewportStore()
      ..setZoom(4)
      ..panBy(10, 10);
    store.resetView();
    expect(store.zoom, ViewportStoreBase.pxPerMmAtActualSize);
    expect(store.pan, const Point.zero());
  });

  test('a freshly-constructed store defaults to actual size (100%)', () {
    final store = ViewportStore();
    expect(store.zoom, ViewportStoreBase.pxPerMmAtActualSize);
  });

  test('showActualSize sets zoom to pxPerMmAtActualSize and centers the '
      'page in the viewport', () {
    final store = ViewportStore()..setZoom(999);
    store.showActualSize(
      pageWidthMm: 100,
      pageHeightMm: 50,
      viewportWidthPx: 1000,
      viewportHeightPx: 500,
    );
    expect(store.zoom, ViewportStoreBase.pxPerMmAtActualSize);
    final expectedWidthPx = 100 * ViewportStoreBase.pxPerMmAtActualSize;
    final expectedHeightPx = 50 * ViewportStoreBase.pxPerMmAtActualSize;
    expect(store.pan.x, (1000 - expectedWidthPx) / 2);
    expect(store.pan.y, (500 - expectedHeightPx) / 2);
  });

  test('showActualSize is a no-op for degenerate page/viewport sizes', () {
    final store = ViewportStore()..setZoom(4);
    store.showActualSize(
      pageWidthMm: 0,
      pageHeightMm: 50,
      viewportWidthPx: 1000,
      viewportHeightPx: 500,
    );
    expect(store.zoom, 4);
  });

  test('toggles flip their respective booleans', () {
    final store = ViewportStore();
    final initialGrid = store.showGrid;
    store.toggleGrid();
    expect(store.showGrid, !initialGrid);
    final initialSnap = store.snapEnabled;
    store.toggleSnap();
    expect(store.snapEnabled, !initialSnap);
  });

  test('mmToPixels/pixelsToMm are inverse at the current zoom', () {
    final store = ViewportStore()..setZoom(2);
    expect(store.mmToPixels(10), 20);
    expect(store.pixelsToMm(20), 10);
  });
}
