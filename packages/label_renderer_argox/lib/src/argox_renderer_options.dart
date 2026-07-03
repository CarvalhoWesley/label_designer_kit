import 'package:label_renderer/label_renderer.dart';

/// Which Argox command language to emit. See `docs/ROADMAP.md`, etapa 16.
enum ArgoxDialect {
  /// Printer Programming Language A — Datamax-compatible, mostly
  /// resolution-independent. Implemented.
  ppla,

  /// Printer Programming Language B — Eltron/EPL2-compatible,
  /// resolution-dependent. Not implemented yet; [ArgoxRenderer.render]
  /// throws [UnimplementedError] for this dialect.
  pplb,
}

/// `direct-thermal` needs no ribbon; `thermal-transfer` prints through a
/// ribbon and produces more durable labels.
enum ArgoxTransferType { directThermal, thermalTransfer }

/// Settings specific to [ArgoxRenderer].
class ArgoxRendererOptions extends RendererOptions {
  const ArgoxRendererOptions({
    this.dialect = ArgoxDialect.ppla,
    this.darkness = 10,
    this.copies = 1,
    this.transferType = ArgoxTransferType.directThermal,
  }) : assert(darkness >= 2 && darkness <= 20, 'darkness (heat) is 2-20'),
       assert(copies >= 1 && copies <= 9999, 'copies is 1-9999');

  final ArgoxDialect dialect;

  /// Heat/darkness value, `H02`-`H20` in PPLA. Higher prints darker.
  final int darkness;

  /// Number of copies to print, `Q0001`-`Q9999` in PPLA.
  final int copies;

  final ArgoxTransferType transferType;
}
