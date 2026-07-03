/// Field-formatting helpers for PPLA, factored out of the encoder because
/// they're pure functions with their own well-defined edge cases (rounding,
/// clamping, table lookups) — easier to unit test in isolation than as
/// private methods mixed into command-building code.
///
/// Every mapping here (orientation codes, ASD font sizes, barcode type
/// letters, the `0-9,A-O` scale alphabet) was cross-checked against three
/// independent, real-world PPLA implementations rather than derived from a
/// single source — see `label_renderer_argox`'s README for the references
/// and what still needs validation against actual Argox hardware.
library;

import 'package:label_core/label_core.dart';

/// Zero-pads [value] to [width] digits, e.g. `pplaDigits(7, 4) == '0007'`.
/// PPLA fixed-width fields never carry a sign, so negative input (which
/// shouldn't occur — [ResolvedElement] geometry is always non-negative) is
/// clamped to zero rather than emitting a `-` that would corrupt the fixed
/// column layout.
String pplaDigits(int value, int width) =>
    value.clamp(0, 1 << 31).toString().padLeft(width, '0');

/// PPLA only supports four fixed orientations (no arbitrary rotation);
/// [rotationDegrees] is snapped to the nearest multiple of 90° and mapped
/// to the printer's own (non-sequential) code: `1`=0°, `4`=90°, `3`=180°,
/// `2`=270°.
String pplaOrientationCode(double rotationDegrees) {
  final normalized = ((rotationDegrees % 360) + 360) % 360;
  final steps = (normalized / 90).round() % 4;
  const codes = ['1', '4', '3', '2'];
  return codes[steps];
}

/// Encodes a magnification factor (`0`-`24`) as the single character PPLA
/// uses for h/v text scale and barcode bar widths: `0`-`9` then `A`-`O`.
String pplaScaleCode(int scale) {
  final clamped = scale.clamp(0, 24);
  if (clamped < 10) return clamped.toString();
  return String.fromCharCode('A'.codeUnitAt(0) + (clamped - 10));
}

/// Point sizes of the seven built-in "ASD smooth" font sizes, in the same
/// order as their subtype codes (`000`-`006`).
const List<int> pplaAsdFontSizesPt = [4, 6, 8, 10, 12, 14, 16];

/// Picks the ASD smooth font subtype (`000`-`006`) whose point size is
/// closest to [fontSizeDots] converted to points at [dpi].
///
/// PPLA has no arbitrary-size text — only a fixed ladder of ASD sizes (plus
/// unrelated fixed-size bitmap fonts) — so an exact match is not always
/// possible; this rounds to the nearest available size rather than
/// rejecting the element.
String pplaAsdFontSubtype(int fontSizeDots, int dpi) {
  final pointSize = fontSizeDots * 72 / dpi;
  var closestIndex = 0;
  var closestDiff = (pointSize - pplaAsdFontSizesPt[0]).abs();
  for (var i = 1; i < pplaAsdFontSizesPt.length; i++) {
    final diff = (pointSize - pplaAsdFontSizesPt[i]).abs();
    if (diff < closestDiff) {
      closestDiff = diff;
      closestIndex = i;
    }
  }
  return pplaDigits(closestIndex, 3);
}

/// One PPLA type letter per [BarcodeSymbology] `label_barcode` can encode.
/// Uppercase shows the human-readable text under the bars; lowercase
/// suppresses it — see [pplaBarcodeTypeCode].
const Map<BarcodeSymbology, String> pplaBarcodeTypeLetters = {
  BarcodeSymbology.code39: 'A',
  BarcodeSymbology.upc: 'B',
  BarcodeSymbology.itf: 'D',
  BarcodeSymbology.code128: 'E',
  BarcodeSymbology.ean13: 'F',
  BarcodeSymbology.ean8: 'G',
  BarcodeSymbology.codabar: 'I',
};

/// The PPLA type letter for [symbology], or `null` if PPLA has no known
/// mapping for it (e.g. [BarcodeSymbology.codabar] variants outside the
/// table above) — callers should fall back to a placeholder rather than
/// emit an invalid command.
String? pplaBarcodeTypeCode(
  BarcodeSymbology symbology, {
  required bool humanReadable,
}) {
  final letter = pplaBarcodeTypeLetters[symbology];
  if (letter == null) return null;
  return humanReadable ? letter : letter.toLowerCase();
}
