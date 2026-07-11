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

/// Point sizes of the internal ASD smooth font (font type `9`) available at
/// 203 DPI via the `Ann` size-selector code, per the Datamax Class Series 2
/// Programmer's Manual, Table C-6 ("Internal Bitmapped (Smooth Font) 9 Size
/// Chart"). 4pt and 72pt only exist at 300 DPI and above — see
/// [pplaAsdFontSizesPt300Plus] — so a 203 DPI head's usable range starts at
/// 6pt.
const List<int> pplaAsdFontSizesPt = [6, 8, 10, 12, 14, 18, 24, 30, 36, 48];

/// Same as [pplaAsdFontSizesPt] but for 300/400/600 DPI heads, which also
/// support 4pt and 72pt per Table C-6.
const List<int> pplaAsdFontSizesPt300Plus = [
  4,
  6,
  8,
  10,
  12,
  14,
  18,
  24,
  30,
  36,
  48,
  72,
];

/// Picks the ASD smooth font size code (`0nn`, e.g. `004` for 12pt) whose
/// point size is closest to [fontSizeDots] converted to points at [dpi].
///
/// PPLA has no arbitrary-size text — only a fixed ladder of ASD sizes (plus
/// unrelated fixed-size bitmap fonts) — so an exact match is not always
/// possible; this rounds to the nearest available size rather than
/// rejecting the element.
///
/// This previously returned a hand-picked `000`-`006` numeric code for 7
/// assumed sizes (4/6/8/10/12/14/16pt) — none of that matched Table C-6: the
/// real `0nn` numeric codes only cover `001`-`010` (6pt-48pt), `000` is
/// reserved for 300 DPI+ only (4pt), and there is no 16pt size at all.
/// Sending an out-of-spec code like `000` to a 203 DPI printer made it fall
/// back to a much larger default font — confirmed on real Argox hardware
/// printing text far bigger than configured, even after the row/column unit
/// fix. This was then switched to the `Ann` alpha form (`A12` for 12pt),
/// which the manual documents as DPI-independent — but that alpha form
/// turned out to not be recognized on at least one real Argox model (OS-214
/// plus), reproducing the exact same "falls back to an oversized default
/// font" symptom the `000`-`006` table caused. Back to the numeric form,
/// this time with the table Table C-6 actually documents: index within
/// [pplaAsdFontSizesPt]/[pplaAsdFontSizesPt300Plus] plus one at <300 DPI
/// (`001`-`010`), or the bare index at >=300 DPI (`000`-`011`, since `000`
/// covers the 300-DPI-only 4pt size there).
String pplaAsdFontSubtype(int fontSizeDots, int dpi) {
  final pointSize = fontSizeDots * 72 / dpi;
  final sizes = dpi >= 300 ? pplaAsdFontSizesPt300Plus : pplaAsdFontSizesPt;
  var closestIndex = 0;
  var closestDiff = (pointSize - sizes[0]).abs();
  for (var i = 1; i < sizes.length; i++) {
    final diff = (pointSize - sizes[i]).abs();
    if (diff < closestDiff) {
      closestDiff = diff;
      closestIndex = i;
    }
  }
  final code = dpi >= 300 ? closestIndex : closestIndex + 1;
  return code.toString().padLeft(3, '0');
}

/// PPLA's `D` command (dot width/height multiplier) — a per-model default
/// documented in the Datamax Class Series 2 Programmer's Manual (PPLA's
/// base language, per `docs/ROADMAP.md` etapa 16): `D11` (1x1, no
/// doubling) for 300/400/600 DPI print heads, `D22` (2x2) for 203 DPI print
/// heads. Getting this wrong desyncs the physical size of a printed dot
/// from the mm→dots math the rest of this renderer assumes, so every
/// coordinate/size ends up scaled incorrectly on real hardware — this was
/// found after the first real-hardware print test came out uniformly
/// oversized on a 203 DPI Argox printer (the renderer previously
/// hardcoded `D11` regardless of DPI).
String pplaDotSizeCommand(int dpi) => dpi == 203 ? 'D22' : 'D11';

/// Converts [dots] (at [dpi] dots/inch) to hundredths of an inch — the
/// unit PPLA actually uses for every row/column position field and every
/// line/box dimension field, confirmed against the Datamax Class Series 2
/// Programmer's Manual: "ffff: Row Position ... Field data is interpreted
/// in hundredths of an inch", "Lines and Boxes ... all measurements are
/// interpreted as inches/100", and "The eee height field represents the
/// bar code (symbol) height. The valid range (001 to 999) translates to
/// bar heights ranging from .01 inch ... to 9.99 inches." This renderer
/// originally embedded raw dot counts in these fields instead, which
/// prints ~2x too large on real 203 DPI hardware (a dot is about twice as
/// fine as a hundredth of an inch at that resolution) — found via a real
/// print test, not from the spec alone.
///
/// Not used for bar code wide/narrow bar width (`c`/`d` fields) — those
/// are explicitly documented as dots, unlike everything else here.
int pplaHundredthsOfInch(int dots, int dpi) => (dots * 100 / dpi).round();

/// Converts [mm] straight to hundredths of an inch, for values (like a
/// manual calibration offset) that start out in millimeters rather than
/// document dots — skips the dots round-trip [pplaHundredthsOfInch] does,
/// avoiding an extra rounding step.
int pplaMmToHundredthsOfInch(double mm) => (mm * 100 / 25.4).round();

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
