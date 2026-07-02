import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';
import 'package:test/test.dart';

void main() {
  test('beginDrag sets isDragging and the active handle', () {
    final store = CanvasStore();
    store.beginDrag(handle: ResizeHandle.bottomRight);
    expect(store.isDragging, isTrue);
    expect(store.activeResizeHandle, ResizeHandle.bottomRight);
  });

  test('endDrag resets dragging, handle and guides', () {
    final store = CanvasStore();
    store.beginDrag(handle: ResizeHandle.rotation);
    store.setGuides(x: [10, 20], y: [5]);

    store.endDrag();

    expect(store.isDragging, isFalse);
    expect(store.activeResizeHandle, isNull);
    expect(store.hasActiveGuides, isFalse);
  });

  test('setGuides/clearGuides toggle hasActiveGuides', () {
    final store = CanvasStore();
    expect(store.hasActiveGuides, isFalse);
    store.setGuides(x: [15]);
    expect(store.hasActiveGuides, isTrue);
    store.clearGuides();
    expect(store.hasActiveGuides, isFalse);
  });

  group('element drag preview', () {
    test('begin/update/end manage dragPreviewPositions and isDragging', () {
      final store = CanvasStore();
      store.beginElementDrag({'a': const Point.zero()});

      expect(store.isDragging, isTrue);
      expect(store.dragPreviewPositions, {'a': const Point.zero()});

      store.updateElementDrag({'a': const Point(x: 5, y: 5)});
      expect(store.dragPreviewPositions, {'a': const Point(x: 5, y: 5)});

      store.endElementDrag();
      expect(store.isDragging, isFalse);
      expect(store.dragPreviewPositions, isEmpty);
    });
  });

  group('resize preview', () {
    test('begin/update/end manage the resize preview and active handle', () {
      final store = CanvasStore();
      store.beginResize(
        'a',
        ResizeHandle.bottomRight,
        position: const Point.zero(),
        size: const Size2D(width: 10, height: 10),
      );

      expect(store.resizingElementId, 'a');
      expect(store.activeResizeHandle, ResizeHandle.bottomRight);
      expect(store.resizePreviewSize, const Size2D(width: 10, height: 10));

      store.updateResize(
        position: const Point(x: 1, y: 1),
        size: const Size2D(width: 15, height: 12),
      );
      expect(store.resizePreviewSize, const Size2D(width: 15, height: 12));

      store.endResize();
      expect(store.resizingElementId, isNull);
      expect(store.resizePreviewPosition, isNull);
      expect(store.resizePreviewSize, isNull);
      expect(store.isDragging, isFalse);
    });
  });

  group('rotate preview', () {
    test('begin/update/end manage the rotation preview', () {
      final store = CanvasStore();
      store.beginRotate('a', rotationDegrees: 0);

      expect(store.rotatingElementId, 'a');
      expect(store.activeResizeHandle, ResizeHandle.rotation);
      expect(store.rotationPreviewDegrees, 0);

      store.updateRotate(45);
      expect(store.rotationPreviewDegrees, 45);

      store.endRotate();
      expect(store.rotatingElementId, isNull);
      expect(store.rotationPreviewDegrees, isNull);
      expect(store.isDragging, isFalse);
    });
  });

  group('marquee selection', () {
    test('begin/update/end manage the marquee rectangle and isDragging', () {
      final store = CanvasStore();
      store.beginMarquee(const Point.zero());

      expect(store.isDragging, isTrue);
      expect(store.marqueeStart, const Point.zero());
      expect(store.marqueeEnd, const Point.zero());

      store.updateMarquee(const Point(x: 10, y: 10));
      expect(store.marqueeEnd, const Point(x: 10, y: 10));
      expect(store.marqueeStart, const Point.zero());

      store.endMarquee();
      expect(store.marqueeStart, isNull);
      expect(store.marqueeEnd, isNull);
      expect(store.isDragging, isFalse);
    });
  });
}
