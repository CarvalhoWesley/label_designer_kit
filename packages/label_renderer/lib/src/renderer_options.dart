/// Base type for renderer-specific settings (e.g. `darkness`/`speed` for a
/// thermal printer, `backgroundColor`/`pixelRatio` for a raster export).
///
/// Deliberately empty: [ResolvedDocument] already carries every piece of
/// layout the renderers need, so [RendererOptions] only exists to be
/// subclassed per backend — see `docs/ARCHITECTURE.md` section 11. A
/// renderer that needs no options at all can just use the base class.
class RendererOptions {
  const RendererOptions();
}
