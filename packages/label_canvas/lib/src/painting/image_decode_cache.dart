import 'dart:convert';
import 'dart:ui' as ui;

/// Decodes and caches `data:` URI images referenced by
/// [ImageElement.source] so `label_canvas`'s editable rendering can show a
/// real preview instead of a placeholder for self-contained images — this
/// is still zero file/network I/O (the bytes are already inline in the
/// document), so it doesn't cross the "editor never resolves external
/// assets" line documented on [ElementPainter]. A file path, URL or asset
/// key still falls back to the placeholder, since only the app knows how
/// to fetch those.
///
/// Owned by `_LabelCanvasState` (survives across repaints, unlike
/// [ElementPainter], which is rebuilt every frame); [onImageReady] is
/// called once a decode finishes so the caller can trigger a repaint.
class ImageDecodeCache {
  ImageDecodeCache({required this.onImageReady});

  final void Function() onImageReady;
  final Map<String, ui.Image> _decoded = {};
  final Set<String> _inFlight = {};

  /// Returns the cached, already-decoded image for `data:` [source], or
  /// `null` if it isn't a `data:` URI, hasn't finished decoding yet, or
  /// failed to decode. Kicks off decoding as a side effect on cache miss.
  ui.Image? get(String source) {
    if (!source.startsWith('data:')) return null;
    final cached = _decoded[source];
    if (cached != null) return cached;
    if (!_inFlight.contains(source)) _decode(source);
    return null;
  }

  Future<void> _decode(String source) async {
    _inFlight.add(source);
    try {
      final commaIndex = source.indexOf(',');
      if (commaIndex == -1) return;
      final meta = source.substring('data:'.length, commaIndex);
      if (!meta.contains('base64')) return;
      final bytes = base64Decode(source.substring(commaIndex + 1));
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _decoded[source] = frame.image;
      onImageReady();
    } catch (_) {
      // Leave undecoded — get() keeps returning null so the placeholder
      // stays visible instead of throwing mid-paint.
    } finally {
      _inFlight.remove(source);
    }
  }

  void dispose() {
    for (final image in _decoded.values) {
      image.dispose();
    }
    _decoded.clear();
  }
}
