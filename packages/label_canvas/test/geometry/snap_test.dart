import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas/src/geometry/snap.dart';
import 'package:label_core/label_core.dart';

void main() {
  group('snapValue', () {
    test('rounds to the nearest multiple of gridSizeMm', () {
      expect(snapValue(11, 5), 10);
      expect(snapValue(13, 5), 15);
      expect(snapValue(12.5, 5), 15); // .round() rounds half-up
    });

    test('leaves an exact multiple unchanged', () {
      expect(snapValue(20, 5), 20);
    });

    test('handles negative values', () {
      expect(snapValue(-11, 5), -10);
    });

    test('is a no-op when gridSizeMm is zero or negative', () {
      expect(snapValue(11.3, 0), 11.3);
      expect(snapValue(11.3, -5), 11.3);
    });
  });

  group('snapPoint', () {
    test('snaps both axes independently', () {
      expect(
        snapPoint(const Point(x: 11, y: 13), 5),
        const Point(x: 10, y: 15),
      );
    });
  });
}
