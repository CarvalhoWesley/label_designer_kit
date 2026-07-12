import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/interaction/canvas_controller.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

RectangleElement _rect(
  String id, {
  Point position = const Point.zero(),
  Size2D size = const Size2D(width: 10, height: 10),
  double rotation = 0,
  int zIndex = 0,
  String layerId = 'layer-1',
}) => RectangleElement(
  id: id,
  name: id,
  position: position,
  size: size,
  rotation: rotation,
  zIndex: zIndex,
  layerId: layerId,
);

class _Harness {
  _Harness(List<LabelElement> elements)
    : documentStore = DocumentStore(_documentWith(elements)) {
    historyStore = HistoryStore(documentStore);
    selectionStore = SelectionStore();
    // 1 px per mm, pan (0,0). ViewportStore.snapEnabled defaults to true;
    // most tests below want raw, unsnapped math, so start it off here and
    // opt back in explicitly in the tests that care about snapping.
    viewportStore = ViewportStore()
      ..setZoom(1)
      ..toggleSnap();
    canvasStore = CanvasStore();
    controller = CanvasController(
      documentStore: documentStore,
      selectionStore: selectionStore,
      historyStore: historyStore,
      viewportStore: viewportStore,
      canvasStore: canvasStore,
    );
  }

  static LabelDocument _documentWith(List<LabelElement> elements) =>
      LabelDocument.blank(name: 'Doc').copyWith(elements: elements);

  final DocumentStore documentStore;
  late final HistoryStore historyStore;
  late final SelectionStore selectionStore;
  late final ViewportStore viewportStore;
  late final CanvasStore canvasStore;
  late final CanvasController controller;

  LabelElement element(String id) =>
      documentStore.elements.firstWhere((e) => e.id == id);
}

void main() {
  group('click to select', () {
    test('clicking an element selects it', () {
      final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
      h.controller.pointerDown(const Offset(5, 5));
      h.controller.pointerUp(const Offset(5, 5));
      expect(h.selectionStore.selectedIds, {'a'});
    });

    test('clicking empty space clears the selection', () {
      final h = _Harness([_rect('a')]);
      h.selectionStore.select('a');
      h.controller.pointerDown(const Offset(500, 500));
      h.controller.pointerUp(const Offset(500, 500));
      expect(h.selectionStore.selectedIds, isEmpty);
    });

    test('shift-clicking an unselected element adds it to the selection', () {
      final h = _Harness([
        _rect('a', position: const Point(x: 0, y: 0)),
        _rect('b', position: const Point(x: 100, y: 100)),
      ]);
      h.selectionStore.select('a');
      h.controller.pointerDown(const Offset(105, 105), addToSelection: true);
      h.controller.pointerUp(const Offset(105, 105));
      expect(h.selectionStore.selectedIds, {'a', 'b'});
    });

    test('shift-clicking an already-selected element removes it', () {
      // A larger box than the other tests: at zoom=1 with an 8px/8mm
      // handle hit-radius, a small (e.g. 10x10) box makes its own center
      // ambiguous with its resize handles. 40x40 keeps the center (20,20)
      // a clean 20mm from the nearest handle.
      final h = _Harness([
        _rect('a', size: const Size2D(width: 40, height: 40)),
      ]);
      h.selectionStore.select('a');
      h.controller.pointerDown(const Offset(20, 20), addToSelection: true);
      h.controller.pointerUp(const Offset(20, 20));
      expect(h.selectionStore.selectedIds, isEmpty);
    });

    test(
      'clicking an unselected element while another is selected replaces the selection',
      () {
        final h = _Harness([
          _rect('a', position: const Point(x: 0, y: 0)),
          _rect('b', position: const Point(x: 100, y: 100)),
        ]);
        h.selectionStore.select('a');
        h.controller.pointerDown(const Offset(105, 105));
        h.controller.pointerUp(const Offset(105, 105));
        expect(h.selectionStore.selectedIds, {'b'});
      },
    );

    test(
      'clicking an element already part of a multi-selection keeps the whole selection',
      () {
        final h = _Harness([
          _rect('a', position: const Point(x: 0, y: 0)),
          _rect('b', position: const Point(x: 100, y: 100)),
        ]);
        h.selectionStore.selectAll(['a', 'b']);
        h.controller.pointerDown(const Offset(5, 5));
        h.controller.pointerUp(const Offset(5, 5));
        expect(h.selectionStore.selectedIds, {'a', 'b'});
      },
    );
  });

  group('move', () {
    test(
      'dragging a selected element moves it and dispatches one undo step',
      () {
        final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
        h.controller.pointerDown(const Offset(5, 5));
        h.controller.pointerMove(const Offset(15, 15));
        h.controller.pointerUp(const Offset(15, 15));

        expect(h.element('a').position, const Point(x: 10, y: 10));
        expect(h.historyStore.canUndo, isTrue);

        h.historyStore.undo();
        expect(h.element('a').position, const Point.zero());
      },
    );

    test('live preview is visible during the drag, before pointerUp', () {
      final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
      h.controller.pointerDown(const Offset(5, 5));
      h.controller.pointerMove(const Offset(15, 15));

      expect(
        h.canvasStore.dragPreviewPositions['a'],
        const Point(x: 10, y: 10),
      );
      // The committed document hasn't changed yet.
      expect(h.element('a').position, const Point.zero());

      h.controller.pointerUp(const Offset(15, 15));
      expect(h.canvasStore.dragPreviewPositions, isEmpty);
    });

    test('a click with no movement does not dispatch a command', () {
      final h = _Harness([_rect('a')]);
      h.controller.pointerDown(const Offset(5, 5));
      h.controller.pointerUp(const Offset(5, 5));
      expect(h.historyStore.canUndo, isFalse);
    });

    test('snapEnabled rounds the moved position to the grid', () {
      final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
      h.viewportStore
        ..setGridSize(5)
        ..toggleSnap(); // harness starts snap off; this turns it back on
      h.controller.pointerDown(const Offset(5, 5));
      h.controller.pointerMove(
        const Offset(12, 13),
      ); // raw delta (7,8) -> (7,8)
      h.controller.pointerUp(const Offset(12, 13));

      // (0+7, 0+8) = (7,8), snapped to nearest 5 -> (5,10)
      expect(h.element('a').position, const Point(x: 5, y: 10));
    });

    test(
      'snapEnabled aligns to another element\'s edge (smart guides) before '
      'falling back to the grid',
      () {
        final h = _Harness([
          _rect('a', position: const Point(x: 0, y: 0)),
          _rect('b', position: const Point(x: 50, y: 0)),
        ]);
        // A grid this coarse would snap to (0,0) if grid snapping ran
        // instead of alignment — a strong signal alignment actually took
        // priority, not just a coincidental result.
        h.viewportStore
          ..setGridSize(1000)
          ..toggleSnap();
        h.controller.pointerDown(const Offset(5, 5));
        // Raw delta (48,0) -> proposed left edge at x=48, 2mm short of
        // b's left edge (50) — within the 6px/mm alignment threshold.
        h.controller.pointerMove(const Offset(53, 5));

        expect(
          h.canvasStore.dragPreviewPositions['a'],
          const Point(x: 50, y: 0),
        );
        expect(h.canvasStore.activeGuidesX, contains(50));

        h.controller.pointerUp(const Offset(53, 5));
        expect(h.element('a').position, const Point(x: 50, y: 0));
        // Guides are cleared once the drag ends.
        expect(h.canvasStore.hasActiveGuides, isFalse);
      },
    );

    test(
      'dragging one of several selected elements moves all of them as one undo step',
      () {
        final h = _Harness([
          _rect('a', position: const Point(x: 0, y: 0)),
          _rect('b', position: const Point(x: 100, y: 100)),
        ]);
        h.selectionStore.selectAll(['a', 'b']);
        h.controller.pointerDown(const Offset(5, 5));
        h.controller.pointerMove(const Offset(15, 15));
        h.controller.pointerUp(const Offset(15, 15));

        expect(h.element('a').position, const Point(x: 10, y: 10));
        expect(h.element('b').position, const Point(x: 110, y: 110));

        h.historyStore.undo();
        expect(h.element('a').position, const Point.zero());
        expect(h.element('b').position, const Point(x: 100, y: 100));
        expect(h.historyStore.canUndo, isFalse); // exactly one undo step
      },
    );

    test('locked elements cannot be selected or dragged', () {
      final h = _Harness([_rect('a').copyWith(locked: true)]);
      h.controller.pointerDown(const Offset(5, 5));
      h.controller.pointerUp(const Offset(5, 5));
      expect(h.selectionStore.selectedIds, isEmpty);
    });
  });

  group('marquee selection', () {
    test('dragging over empty space selects intersecting elements', () {
      final h = _Harness([
        _rect(
          'a',
          position: const Point(x: 2, y: 2),
          size: const Size2D(width: 4, height: 4),
        ),
        _rect('b', position: const Point(x: 200, y: 200)),
      ]);
      h.controller.pointerDown(const Offset(0, 0));
      h.controller.pointerMove(const Offset(20, 20));
      h.controller.pointerUp(const Offset(20, 20));
      expect(h.selectionStore.selectedIds, {'a'});
    });

    test('shift-dragging a marquee adds to the existing selection', () {
      final h = _Harness([
        _rect(
          'a',
          position: const Point(x: 2, y: 2),
          size: const Size2D(width: 4, height: 4),
        ),
        _rect('other', position: const Point(x: 500, y: 500)),
      ]);
      h.selectionStore.select('other');
      h.controller.pointerDown(const Offset(0, 0), addToSelection: true);
      h.controller.pointerMove(const Offset(20, 20));
      h.controller.pointerUp(const Offset(20, 20));
      expect(h.selectionStore.selectedIds, {'other', 'a'});
    });

    test('an empty marquee (no elements underneath) clears the selection', () {
      final h = _Harness([_rect('a', position: const Point(x: 500, y: 500))]);
      h.selectionStore.select('a');
      h.controller.pointerDown(const Offset(0, 0));
      h.controller.pointerMove(const Offset(20, 20));
      h.controller.pointerUp(const Offset(20, 20));
      expect(h.selectionStore.selectedIds, isEmpty);
    });
  });

  group('resize', () {
    test(
      'dragging the bottomRight handle of a selected element resizes it as one undo step',
      () {
        final h = _Harness([
          _rect(
            'a',
            position: const Point(x: 0, y: 0),
            size: const Size2D(width: 10, height: 10),
          ),
        ]);
        h.selectionStore.select('a');

        // bottomRight handle sits at (10,10)px given zoom=1, pan=0.
        h.controller.pointerDown(const Offset(10, 10));
        h.controller.pointerMove(const Offset(20, 15));
        h.controller.pointerUp(const Offset(20, 15));

        expect(h.element('a').position, const Point.zero());
        expect(h.element('a').size, const Size2D(width: 20, height: 15));
        expect(h.historyStore.canUndo, isTrue);

        h.historyStore.undo();
        expect(h.element('a').size, const Size2D(width: 10, height: 10));
      },
    );

    test(
      'dragging the topLeft handle resizes and repositions as one undo step',
      () {
        final h = _Harness([
          _rect(
            'a',
            position: const Point(x: 0, y: 0),
            size: const Size2D(width: 10, height: 10),
          ),
        ]);
        h.selectionStore.select('a');

        h.controller.pointerDown(const Offset(0, 0));
        h.controller.pointerMove(const Offset(3, 4));
        h.controller.pointerUp(const Offset(3, 4));

        expect(h.element('a').position, const Point(x: 3, y: 4));
        expect(h.element('a').size, const Size2D(width: 7, height: 6));
        expect(h.historyStore.canUndo, isTrue);

        h.historyStore.undo();
        expect(h.element('a').position, const Point.zero());
        expect(h.element('a').size, const Size2D(width: 10, height: 10));
        expect(h.historyStore.canUndo, isFalse); // one combined undo step
      },
    );

    test(
      'resizing does not affect elements outside the current single selection',
      () {
        final h = _Harness([
          _rect(
            'a',
            position: const Point(x: 0, y: 0),
            size: const Size2D(width: 10, height: 10),
          ),
          _rect('b', position: const Point(x: 100, y: 100)),
        ]);
        h.selectionStore.select('a');
        h.controller.pointerDown(const Offset(10, 10));
        h.controller.pointerMove(const Offset(30, 30));
        h.controller.pointerUp(const Offset(30, 30));
        expect(h.element('b').position, const Point(x: 100, y: 100));
      },
    );

    test('a CircleElement stays square while resizing', () {
      const circle = CircleElement(
        id: 'c',
        name: 'c',
        position: Point.zero(),
        size: Size2D(width: 10, height: 10),
        layerId: 'layer-1',
      );
      final h = _Harness([circle]);
      h.selectionStore.select('c');

      h.controller.pointerDown(const Offset(10, 10)); // bottomRight
      h.controller.pointerMove(const Offset(30, 16)); // asymmetric drag
      h.controller.pointerUp(const Offset(30, 16));

      final size = h.element('c').size;
      expect(size.width, size.height);
    });
  });

  group('rotate', () {
    test(
      'dragging the rotation handle rotates the element as one undo step',
      () {
        final h = _Harness([
          _rect(
            'a',
            position: const Point(x: -5, y: -5),
            size: const Size2D(width: 10, height: 10),
          ),
        ]);
        h.selectionStore.select('a');

        // Rotation handle floats above the top edge (default offset 8mm),
        // at local (0, -5-8) = (0,-13), absolute since center is (0,0).
        h.controller.pointerDown(const Offset(0, -13));
        // Drag it to the right of center -> 90 degrees.
        h.controller.pointerMove(const Offset(50, 0));
        h.controller.pointerUp(const Offset(50, 0));

        expect(h.element('a').rotation, 90);
        expect(h.historyStore.canUndo, isTrue);

        h.historyStore.undo();
        expect(h.element('a').rotation, 0);
      },
    );
  });

  group('pointerCancel', () {
    test(
      'cancelling a move drag discards the preview without dispatching a command',
      () {
        final h = _Harness([_rect('a', position: const Point(x: 0, y: 0))]);
        h.controller.pointerDown(const Offset(5, 5));
        h.controller.pointerMove(const Offset(50, 50));
        h.controller.pointerCancel();

        expect(h.canvasStore.dragPreviewPositions, isEmpty);
        expect(h.element('a').position, const Point.zero());
        expect(h.historyStore.canUndo, isFalse);
      },
    );
  });
}
