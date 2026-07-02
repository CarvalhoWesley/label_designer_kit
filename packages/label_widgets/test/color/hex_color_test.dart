import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

void main() {
  group('colorToHex', () {
    test('formats RGB without alpha by default', () {
      expect(colorToHex(const Color(0xFFFF0000)), '#FF0000');
    });

    test('includes alpha when requested', () {
      expect(
        colorToHex(const Color(0x80FF0000), includeAlpha: true),
        '#80FF0000',
      );
    });
  });

  group('colorFromHex', () {
    test('parses a 6-digit hex as fully opaque', () {
      expect(
        colorFromHex('00FF00')?.toARGB32(),
        const Color(0xFF00FF00).toARGB32(),
      );
    });

    test('parses a leading-# 6-digit hex', () {
      expect(
        colorFromHex('#00FF00')?.toARGB32(),
        const Color(0xFF00FF00).toARGB32(),
      );
    });

    test('parses an 8-digit hex including alpha', () {
      expect(
        colorFromHex('8000FF00')?.toARGB32(),
        const Color(0x8000FF00).toARGB32(),
      );
    });

    test('returns null for an invalid length', () {
      expect(colorFromHex('FFF'), isNull);
      expect(colorFromHex(''), isNull);
    });

    test('returns null for non-hex characters', () {
      expect(colorFromHex('GGGGGG'), isNull);
    });

    test('round-trips through colorToHex', () {
      const color = Color(0xFF3366CC);
      expect(colorFromHex(colorToHex(color))?.toARGB32(), color.toARGB32());
    });
  });
}
