import 'package:label_core/label_core.dart';
import 'package:test/test.dart';

void main() {
  group('Point', () {
    test('round-trips through JSON', () {
      const point = Point(x: 10.5, y: -3.25);
      expect(Point.fromJson(point.toJson()), point);
    });

    test('translate returns a new offset point', () {
      const point = Point(x: 1, y: 1);
      expect(point.translate(2, 3), const Point(x: 3, y: 4));
    });

    test('equality is value-based', () {
      expect(const Point(x: 1, y: 2), const Point(x: 1, y: 2));
    });
  });

  group('Size2D', () {
    test('round-trips through JSON', () {
      const size = Size2D(width: 40, height: 8);
      expect(Size2D.fromJson(size.toJson()), size);
    });
  });

  group('EdgeInsets', () {
    test('all() sets every side to the same value', () {
      const insets = EdgeInsets.all(2);
      expect(insets, const EdgeInsets(top: 2, right: 2, bottom: 2, left: 2));
    });

    test('round-trips through JSON', () {
      const insets = EdgeInsets(top: 1, right: 2, bottom: 3, left: 4);
      expect(EdgeInsets.fromJson(insets.toJson()), insets);
    });
  });

  group('Unit', () {
    test('converts mm to cm and back', () {
      expect(Unit.cm.fromMm(25), 2.5);
      expect(Unit.cm.toMm(2.5), 25);
    });

    test('converts mm to inch and back', () {
      expect(Unit.inch.fromMm(25.4), closeTo(1, 1e-9));
      expect(Unit.inch.toMm(1), closeTo(25.4, 1e-9));
    });

    test('mm is the identity conversion', () {
      expect(Unit.mm.fromMm(12), 12);
      expect(Unit.mm.toMm(12), 12);
    });
  });

  group('Dpi', () {
    test('dotsPerMm matches dots-per-inch / 25.4', () {
      expect(Dpi.dpi203.dotsPerMm, closeTo(203 / 25.4, 1e-9));
    });

    test('mmToDots rounds to the nearest dot', () {
      // 203 dpi => ~7.99 dots/mm; 10mm => ~79.9 dots, rounds to 80.
      expect(Dpi.dpi203.mmToDots(10), 80);
    });

    test('dotsToMm is the inverse of mmToDots at whole-dot boundaries', () {
      final dots = Dpi.dpi300.mmToDots(50);
      expect(Dpi.dpi300.dotsToMm(dots), closeTo(50, 0.1));
    });

    test('fromValue resolves known DPI values', () {
      expect(Dpi.fromValue(300), Dpi.dpi300);
    });

    test('fromValue throws for unsupported DPI', () {
      expect(() => Dpi.fromValue(150), throwsArgumentError);
    });
  });
}
