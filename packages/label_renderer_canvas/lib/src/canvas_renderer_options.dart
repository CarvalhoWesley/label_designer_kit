import 'package:label_renderer/label_renderer.dart';

import 'image_resolver.dart';

/// Settings specific to [CanvasRenderer].
class CanvasRendererOptions extends RendererOptions {
  const CanvasRendererOptions({
    this.backgroundColor = 0xFFFFFFFF,
    this.pixelRatio = 1.0,
    this.imageResolver = defaultImageResolver,
  });

  /// ARGB fill color painted behind every element. Defaults to opaque
  /// white.
  final int backgroundColor;

  /// Supersampling factor: the output PNG is
  /// `document.widthDots * pixelRatio` pixels wide, so `2.0` renders at
  /// double resolution for crisper zoomed-in previews.
  final double pixelRatio;

  /// Resolves an [ResolvedImagePayload.source] reference to bytes. See
  /// [ImageResolver].
  final ImageResolver imageResolver;
}
