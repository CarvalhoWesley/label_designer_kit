import 'dart:typed_data';

import 'package:label_core/label_core.dart';

import 'renderer_options.dart';

/// Converts an already-resolved [ResolvedDocument] into bytes: PPLA/PPLB,
/// ZPL II, TSPL, a PDF, a PNG — whatever the implementing backend targets.
///
/// This is the **only** contract the rest of the framework depends on for
/// output. Implementations receive layout that has already been fully
/// resolved by the Layout Engine (variables, expressions, styles, mm→dots,
/// rotations) and must not recompute any of it — see
/// `docs/ARCHITECTURE.md` sections 1–2 and 11 for why that boundary is
/// non-negotiable.
abstract interface class LabelRenderer {
  Future<Uint8List> render(ResolvedDocument document, RendererOptions options);
}
