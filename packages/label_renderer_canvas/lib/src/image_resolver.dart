import 'dart:convert';
import 'dart:typed_data';

/// Turns a [ResolvedImagePayload.source] reference into raw image bytes
/// (PNG/JPEG/etc, whatever `dart:ui.instantiateImageCodec` accepts), or
/// `null` if this resolver doesn't know how to fetch that reference.
///
/// `label_renderer_canvas` deliberately does no file or network I/O
/// itself — a `source` might be a file path, a URL, an asset key or a
/// data URI, and only the app knows which apply and how to reach them
/// (file I/O isn't available on Flutter Web at all). [defaultImageResolver]
/// only understands inline `data:` URIs; pass a custom [ImageResolver] via
/// [CanvasRendererOptions] to add file/network/asset support.
typedef ImageResolver = Future<Uint8List?> Function(String source);

/// Decodes `source` if it is a `data:...;base64,...` URI; returns `null`
/// for anything else (file paths, URLs, asset keys).
Future<Uint8List?> defaultImageResolver(String source) async {
  const prefix = 'data:';
  if (!source.startsWith(prefix)) return null;

  final commaIndex = source.indexOf(',');
  if (commaIndex == -1) return null;

  final meta = source.substring(prefix.length, commaIndex);
  if (!meta.contains('base64')) return null;

  try {
    return base64Decode(source.substring(commaIndex + 1));
  } on FormatException {
    return null;
  }
}
