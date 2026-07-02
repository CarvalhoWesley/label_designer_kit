import 'package:flutter/widgets.dart';

/// Formats [color] as `#RRGGBB` (or `#AARRGGBB` when [includeAlpha] is
/// `true`). Uses [Color.toARGB32] rather than the deprecated `.value`
/// getter.
String colorToHex(Color color, {bool includeAlpha = false}) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return includeAlpha ? '#$argb' : '#${argb.substring(2)}';
}

/// Parses a `#RGB`/`#RRGGBB`/`#AARRGGBB` (with or without the leading `#`)
/// string into a [Color], or `null` if [value] isn't a valid hex color.
/// A 6-digit value is treated as fully opaque.
Color? colorFromHex(String value) {
  final cleaned = value.trim().replaceFirst('#', '');
  final normalized = switch (cleaned.length) {
    6 => 'FF$cleaned',
    8 => cleaned,
    _ => null,
  };
  if (normalized == null) return null;
  final parsed = int.tryParse(normalized, radix: 16);
  return parsed == null ? null : Color(parsed);
}
