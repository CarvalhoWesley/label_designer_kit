import 'dart:convert';
import 'dart:typed_data';

/// Turns a [ResolvedImagePayload.source] reference into raw image bytes, or
/// `null` if this resolver doesn't know how to fetch that reference.
///
/// Mirrors `label_renderer_canvas`'s `ImageResolver` typedef exactly, but is
/// declared separately here: renderer packages are siblings and must not
/// depend on one another (only on `label_renderer`/`label_core`), so the
/// small typedef + default implementation is duplicated rather than shared.
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
