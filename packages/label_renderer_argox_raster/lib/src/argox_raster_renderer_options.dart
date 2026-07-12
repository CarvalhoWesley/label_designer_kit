import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_argox/label_renderer_argox.dart';

/// Settings specific to [ArgoxRasterRenderer].
///
/// Wraps [ArgoxRendererOptions] instead of duplicating its fields —
/// darkness/copies/transferType/offsets/feedOffsetMm all still apply the
/// same way to a rasterized job as to a native-command one; only how the
/// label's *content* gets to the printer differs.
class ArgoxRasterRendererOptions extends RendererOptions {
  const ArgoxRasterRendererOptions({
    this.base = const ArgoxRendererOptions(),
    this.memoryBank = 'D',
    this.imageName = 'LBL',
    this.threshold = 128,
    this.reverseRowOrder = false,
    this.mirrorHorizontal = true,
    this.supersample = 4,
    this.fullResolution = true,
  }) : assert(
         imageName.length <= 16,
         'imageName is at most 16 characters (PPLA <STX>I name field)',
       ),
       assert(supersample >= 1, 'supersample must be at least 1');

  final ArgoxRendererOptions base;

  /// PPLA `<STX>I` memory module bank select (a single letter). The
  /// Datamax Class Series 2 Programmer's Manual's own `<STX>I` example
  /// uses `D` — not confirmed against this specific Argox model, see the
  /// package README for what still needs a real print test.
  final String memoryBank;

  /// Name the rasterized label image is downloaded and referenced under
  /// (PPLA `<STX>I`'s name field, max 16 chars). Reused every print job —
  /// nothing is meant to persist across jobs, each one re-uploads a fresh
  /// image under the same name.
  final String imageName;

  /// Luminance threshold (0-255) below which a pixel is considered
  /// "dark"/printed — see [thresholdToMonochrome].
  final int threshold;

  /// Controls the printed row order — see [encodeMonochromeBmp]'s
  /// `reverseRowOrder` parameter, which this maps straight through to.
  ///
  /// This used to be a `flipped` switch that also sent a negative
  /// `biHeight` (the manual's `B`/"flipped" designator) — **that hung real
  /// Argox hardware outright** (printer stops responding, needs a power
  /// cycle). This field no longer has any way to trigger that: row order
  /// is now controlled purely by which bytes get written where, with
  /// `biHeight` always positive and the designator always `b`. Default
  /// `false` (natural/unreversed row order) — the direction a real
  /// hardware test was pointing at right before the old `flipped` switch's
  /// crash cut that test short; still needs a real print to confirm. Flip
  /// this (safely — no crash risk either way now) if the label prints
  /// upside down.
  final bool reverseRowOrder;

  /// Mirrors every row left-right before packing — independent of
  /// [reverseRowOrder] (which only reorders whole rows vertically).
  /// Confirmed necessary on real Argox hardware: a raster print came out
  /// upside down *and* mirrored left-right at the same time (equivalent to
  /// a 180° rotation). Confirmed on real hardware: `true` (the default) is
  /// what fixed the left-right mirroring — see
  /// `label_renderer_argox_raster`'s README.
  final bool mirrorHorizontal;

  /// How many times finer a resolution to render the label at before
  /// averaging down to the final addressable-dot grid (see
  /// [downsampleRgba]) — proper anti-aliasing instead of point-sampling a
  /// render already produced at the final (low) resolution. Purely a
  /// rendering-quality knob: it never changes the final image's pixel
  /// dimensions, so it can't affect the physical size printed (unlike
  /// [pplaDotMultiplier], which the final resolution is still pinned to).
  /// Higher costs more render time for a fixed-size label — 4 is a
  /// reasonable default for label-sized images. `1` disables it (the
  /// original point-sampled behavior).
  final int supersample;

  /// Whether to send the rasterized image at the print head's full native
  /// resolution (PPLA `D11`, one addressable dot per physical dot) instead
  /// of [pplaDotMultiplier]'s DPI-based default (`D22` on a 203 DPI head —
  /// one addressable dot per 2x2 physical block, i.e. half the linear
  /// resolution). The Datamax Class Series 2 Programmer's Manual's `D`
  /// command section is explicit that `D22` is only 203 DPI's *default*,
  /// not its only valid setting ("This command is used to change the size
  /// of a printed dot, hence the print resolution... D22 is the default
  /// value for all 203 DPI printer models") — and a raster-only job has no
  /// barcode module-width field (the one other place the multiplier
  /// matters) for `D11` to desync, unlike a native-command job. Doubles
  /// the addressable pixel grid the image is sent at (real detail, not
  /// just [supersample]'s anti-aliasing) — still unconfirmed against real
  /// hardware, see the package README.
  final bool fullResolution;
}
