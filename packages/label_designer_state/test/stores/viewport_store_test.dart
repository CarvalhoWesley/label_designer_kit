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

  test('resetView restores default zoom and pan', () {
    final store = ViewportStore()
      ..setZoom(4)
      ..panBy(10, 10);
    store.resetView();
    expect(store.zoom, 1);
    expect(store.pan, const Point.zero());
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
