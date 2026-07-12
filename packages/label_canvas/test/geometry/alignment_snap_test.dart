import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/alignment_snap.dart';
import 'package:label_canvas/src/geometry/element_bounds.dart';
import 'package:label_core/label_core.dart';

ElementBounds _bounds(double x, double y, {double w = 10, double h = 10}) =>
    ElementBounds(position: Point(x: x, y: y), size: Size2D(width: w, height: h));

void main() {
  group('snapToElements', () {
    test('snaps left edges when within threshold, on the X axis only', () {
      // moving at x=52 (left edge), other's left edge at x=50 -> diff 2,
      // within a threshold of 5.
      final result = snapToElements(
        moving: _bounds(52, 30),
        others: [_bounds(50, 0)],
        thresholdMm: 5,
      );
      expect(result.adjustedPosition, const Point(x: 50, y: 30)); // y untouched
      expect(result.guidesX, [50]);
      expect(result.guidesY, isEmpty);
    });

    test('snaps center-to-center alignment', () {
      // moving center x = 52+5=57; other center x = 50+5=55 -> diff 2.
      final result = snapToElements(
        moving: _bounds(52, 0),
        others: [_bounds(50, 0)],
        thresholdMm: 5,
      );
      // Closest of (left,left)=2, (center,center)=2, (right,right)=2 —
      // all tie at diff 2; whichever wins, the adjusted left must equal
      // one of the three valid alignments. Left-left is checked first and
      // ties are resolved by "first strictly smaller diff wins", so the
      // first-found (left-left) match stays.
      expect(result.adjustedPosition.x, 50);
    });

    test('snaps top/bottom/center on the Y axis independently of X', () {
      final result = snapToElements(
        moving: _bounds(0, 22),
        others: [_bounds(100, 20)],
        thresholdMm: 5,
      );
      expect(result.guidesX, isEmpty); // x=0 vs x=100, way outside threshold
      expect(result.guidesY, [20]);
      expect(result.adjustedPosition.y, 20);
    });

    test('does nothing outside the threshold', () {
      final result = snapToElements(
        moving: _bounds(0, 0),
        others: [_bounds(100, 100)],
        thresholdMm: 5,
      );
      expect(result.adjustedPosition, const Point(x: 0, y: 0));
      expect(result.guidesX, isEmpty);
      expect(result.guidesY, isEmpty);
    });

    test('picks the closest match among several candidates', () {
      final result = snapToElements(
        moving: _bounds(10, 0),
        others: [_bounds(8, 0), _bounds(11, 100)], // diffs -2 and +1
        thresholdMm: 5,
      );
      expect(result.guidesX, [11]); // the closer match (diff 1) wins
      expect(result.adjustedPosition.x, 11);
    });

    test('an empty others list never snaps', () {
      final result = snapToElements(
        moving: _bounds(0, 0),
        others: const [],
        thresholdMm: 5,
      );
      expect(result.adjustedPosition, const Point(x: 0, y: 0));
      expect(result.guidesX, isEmpty);
      expect(result.guidesY, isEmpty);
    });
  });
}
