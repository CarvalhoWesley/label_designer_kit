import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

void main() {
  group('rulerTicks', () {
    test('generates ticks snapped to a multiple of intervalMm', () {
      final ticks = rulerTicks(startMm: 0, endMm: 5, intervalMm: 1);
      expect(ticks, [0, 1, 2, 3, 4, 5]);
    });

    test('excludes a snapped tick that falls before startMm', () {
      // Multiples of 2 in [2.3, 5] are {4} — 2 is snapped-to but off-range,
      // 6 is past endMm.
      final ticks = rulerTicks(startMm: 2.3, endMm: 5, intervalMm: 2);
      expect(ticks, [4]);
    });

    test('handles a negative startMm (panned past the origin)', () {
      final ticks = rulerTicks(startMm: -3, endMm: 2, intervalMm: 1);
      expect(ticks, [-3, -2, -1, 0, 1, 2]);
    });

    test('returns an empty list when endMm is before startMm', () {
      expect(rulerTicks(startMm: 5, endMm: 0, intervalMm: 1), isEmpty);
    });

    test('respects a non-integer intervalMm', () {
      final ticks = rulerTicks(startMm: 0, endMm: 1, intervalMm: 0.5);
      expect(ticks, [0, 0.5, 1]);
    });
  });

  group('isMajorTick', () {
    test('true for exact multiples of majorIntervalMm', () {
      expect(isMajorTick(0, 10), isTrue);
      expect(isMajorTick(10, 10), isTrue);
      expect(isMajorTick(20, 10), isTrue);
    });

    test('false for values between multiples', () {
      expect(isMajorTick(1, 10), isFalse);
      expect(isMajorTick(9, 10), isFalse);
    });

    test('true for negative exact multiples', () {
      expect(isMajorTick(-10, 10), isTrue);
    });

    test('tolerates floating-point drift from repeated addition', () {
      // Simulates rulerTicks() accumulating error over many + steps.
      var mm = 0.0;
      for (var i = 0; i < 100; i++) {
        mm += 0.1;
      }
      expect(isMajorTick(mm, 10), isTrue);
    });
  });
}
