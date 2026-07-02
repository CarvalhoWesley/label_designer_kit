/// Resolves a `LabelDocument` + data map into a `ResolvedDocument`:
/// expressions, style references, mm -> dots, DPI and rotations
/// (including nested groups). See `docs/ARCHITECTURE.md` section 9.
///
/// Pacote Dart puro — sem dependência de Flutter ou de qualquer renderer.
library;

export 'src/errors.dart';
export 'src/label_layout_engine.dart';
