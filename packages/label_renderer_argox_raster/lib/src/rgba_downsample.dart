import 'dart:typed_data';

/// Shrinks a `rawRgba` buffer (4 bytes/pixel, row-major, top-down,
/// unpadded) by an integer [factor], averaging each `factor`x`factor`
/// block of source pixels into one output pixel (a box filter).
///
/// This is what makes [ArgoxRasterRendererOptions.supersample] actually
/// improve quality: [CanvasRenderer] is asked to render at `factor` times
/// the final addressable-dot resolution (see
/// `ArgoxRasterRenderer._rasterizeToMonochromeBmp`), and the averaging
/// here turns that extra detail into smoother per-dot gray levels before
/// [thresholdToMonochrome] makes its binary call — proper anti-aliasing,
/// as opposed to point-sampling a render that was already produced at the
/// final (low) resolution. The final image's pixel dimensions — and so
/// the physical size printed, since a raster image's pixels map 1:1 to
/// addressable dots — are unaffected by [factor]; only how each of those
/// pixels' color was decided changes.
///
/// Output dimensions are `widthPx ~/ factor` and `heightPx ~/ factor`
/// (floor division). Any leftover partial row/column at the source's edge
/// is dropped rather than averaged in — harmless in practice since the
/// caller always renders at an exact multiple of the target size.
///
/// Alpha is ignored (never read back) — same assumption
/// [thresholdToMonochrome] makes: the source is always fully opaque
/// ([CanvasRenderer] paints an opaque background before any element).
Uint8List downsampleRgba(
  Uint8List rgba, {
  required int widthPx,
  required int heightPx,
  required int factor,
}) {
  if (factor <= 1) return rgba;

  final outWidth = widthPx ~/ factor;
  final outHeight = heightPx ~/ factor;
  final out = Uint8List(outWidth * outHeight * 4);
  final blockPixels = factor * factor;

  for (var oy = 0; oy < outHeight; oy++) {
    for (var ox = 0; ox < outWidth; ox++) {
      var rSum = 0;
      var gSum = 0;
      var bSum = 0;
      for (var dy = 0; dy < factor; dy++) {
        final sy = oy * factor + dy;
        final rowOffset = sy * widthPx * 4;
        for (var dx = 0; dx < factor; dx++) {
          final offset = rowOffset + (ox * factor + dx) * 4;
          rSum += rgba[offset];
          gSum += rgba[offset + 1];
          bSum += rgba[offset + 2];
        }
      }
      final outOffset = (oy * outWidth + ox) * 4;
      out[outOffset] = rSum ~/ blockPixels;
      out[outOffset + 1] = gSum ~/ blockPixels;
      out[outOffset + 2] = bSum ~/ blockPixels;
      out[outOffset + 3] = 0xFF;
    }
  }

  return out;
}
