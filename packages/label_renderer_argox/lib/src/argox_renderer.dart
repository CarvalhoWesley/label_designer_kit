import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';

import 'argox_renderer_options.dart';
import 'ppla_fields.dart';

/// PPLA/PPLB control bytes — see `docs/ROADMAP.md`, etapa 16.
const _stx = '\x02';
const _cr = '\r';

/// Converts a [ResolvedDocument] to Argox printer commands (PPLA today,
/// PPLB planned) via [BaseRenderer]'s header/element/footer Template
/// Method.
///
/// PPLA's coordinate system has its origin at the label's **bottom-left**
/// corner with Y increasing upward — the opposite of [ResolvedElement],
/// which (like every other renderer in this framework) uses a top-left
/// origin with Y increasing downward. [_argoxY] is the one place that
/// conversion happens; X needs no adjustment.
///
/// See the package README for which command layouts are cross-validated
/// against multiple independent real-world PPLA implementations versus
/// which are a best-effort approximation still needing validation against
/// actual Argox hardware.
class ArgoxRenderer extends BaseRenderer {
  const ArgoxRenderer();

  @override
  String header(ResolvedDocument document, RendererOptions options) =>
      clearMemoryCommand() + labelFormatHeader(document, options);

  /// `<STX>qA` — clears the printer's RAM image buffer. Split out from
  /// [header] so a raster-mode caller (`label_renderer_argox_raster`) can
  /// send this, then its own `<STX>I` image-download command, then
  /// [labelFormatHeader] — the image download is a system-level command
  /// and must run before `<STX>L` enters label-formatting mode, but after
  /// the memory clear (a clear issued afterward would wipe the just-sent
  /// image). See the Class Series 2 Programmer's Manual, "System-Level
  /// Command Functions" (`<STX>I`) vs. "Generating Label Formats".
  String clearMemoryCommand() => '${_stx}qA$_cr';

  /// Everything [header] sends after [clearMemoryCommand]: transfer type,
  /// label length, enter-label-format, dot size, darkness. Public for the
  /// same raster-mode reuse reason as [clearMemoryCommand].
  ///
  /// [dotMultiplierOverride] replaces [pplaDotMultiplier]'s DPI-based
  /// default for just the `D` (dot size) command — a raster-only job has
  /// no barcode module-width field (the one other place the multiplier
  /// matters) to desync, so `label_renderer_argox_raster` uses this to
  /// request `D11` (full print-head resolution) even on a 203 DPI head
  /// that would otherwise default to `D22`, per the manual: "This command
  /// is used to change the size of a printed dot, hence the print
  /// resolution... D22 is the default value for all 203 DPI printer
  /// models" — a *default*, not the only valid value.
  String labelFormatHeader(
    ResolvedDocument document,
    RendererOptions options, {
    int? dotMultiplierOverride,
  }) {
    final argoxOptions = _optionsOf(options);
    if (argoxOptions.dialect == ArgoxDialect.pplb) {
      throw UnimplementedError(
        'ArgoxDialect.pplb ainda não implementado — use ArgoxDialect.ppla '
        '(docs/ROADMAP.md, etapa 16).',
      );
    }

    final transferType =
        argoxOptions.transferType == ArgoxTransferType.thermalTransfer
        ? '1'
        : '0';
    final lengthHundredthsOfInch = pplaDigits(
      pplaHundredthsOfInch(document.heightDots, document.dpi) +
          pplaMmToHundredthsOfInch(argoxOptions.feedOffsetMm),
      4,
    );
    final dotMultiplier =
        dotMultiplierOverride ?? pplaDotMultiplier(document.dpi);

    return '$_stx'
        'KI7$transferType$_cr' // transfer type
        '$_stx'
        'c$lengthHundredthsOfInch$_cr' // label length
        '$_stx'
        'L$_cr' // enter label formatting mode
        'D$dotMultiplier$dotMultiplier$_cr' // dot size, per print head DPI
        'H${pplaDigits(argoxOptions.darkness, 2)}$_cr'; // darkness/heat
  }

  @override
  String footer(ResolvedDocument document, RendererOptions options) {
    final argoxOptions = _optionsOf(options);
    return 'Q${pplaDigits(argoxOptions.copies, 4)}$_cr' // copies
        'E$_cr'; // end job / print
  }

  @override
  String encodeElement(
    ResolvedElement element,
    ResolvedDocument document,
    RendererOptions options,
  ) {
    final argoxOptions = _optionsOf(options);
    switch (element.payload) {
      case ResolvedTextPayload payload:
        return _encodeText(element, document, payload, argoxOptions);
      case ResolvedBarcodePayload payload:
        return _encodeBarcode(element, document, payload, argoxOptions);
      case ResolvedShapePayload payload:
        return _encodeShape(element, document, payload, argoxOptions);
      case ResolvedQrCodePayload _:
        // PPLA 2D-code support isn't cross-validated against a known byte
        // format yet (see README) — skip rather than emit a guess.
        return '';
      case ResolvedImagePayload _:
        // Requires PPLA's HEX/BMP graphics download subsystem, out of
        // scope for this etapa (see README) — skip rather than emit a
        // guess.
        return '';
    }
  }

  ArgoxRendererOptions _optionsOf(RendererOptions options) =>
      options is ArgoxRendererOptions ? options : const ArgoxRendererOptions();

  /// PPLA Y is measured from the *bottom* of the label to the *bottom* of
  /// the element's box — the mirror image of [ResolvedElement.yDots],
  /// which is the *top* of the box measured from the label's top.
  int _argoxY(ResolvedElement element, ResolvedDocument document) =>
      document.heightDots - element.yDots - element.heightDots;

  String _encodeText(
    ResolvedElement element,
    ResolvedDocument document,
    ResolvedTextPayload payload,
    ArgoxRendererOptions argoxOptions,
  ) {
    final style = payload.style;
    final orientation = pplaOrientationCode(element.rotationDegrees);
    const fontType = '9'; // ASD smooth font — the only PPLA font family
    // that scales to arbitrary-ish sizes; see README for the bold/italic
    // and built-in bitmap font gaps this simplification leaves open.
    const hScale = '1';
    const vScale = '1';
    final fontSubtype = pplaAsdFontSubtype(style.fontSizeDots, document.dpi);
    final y = pplaDigits(
      pplaHundredthsOfInch(_argoxY(element, document), document.dpi) +
          pplaMmToHundredthsOfInch(argoxOptions.offsetYMm),
      4,
    );
    final x = pplaDigits(
      pplaHundredthsOfInch(element.xDots, document.dpi) +
          pplaMmToHundredthsOfInch(argoxOptions.offsetXMm),
      4,
    );

    return '$orientation$fontType$hScale$vScale$fontSubtype$y$x${payload.text}$_cr';
  }

  String _encodeBarcode(
    ResolvedElement element,
    ResolvedDocument document,
    ResolvedBarcodePayload payload,
    ArgoxRendererOptions argoxOptions,
  ) {
    final typeCode = pplaBarcodeTypeCode(
      payload.symbology,
      humanReadable: payload.showText,
    );
    if (typeCode == null) return ''; // unsupported symbology — skip.

    final orientation = pplaOrientationCode(element.rotationDegrees);
    // Bar width (c/d fields) is the one dimension PPLA keeps in dots —
    // everything else below is hundredths of an inch.
    final barWidth = pplaScaleCode(payload.moduleWidthDots);
    final height = pplaDigits(
      pplaHundredthsOfInch(element.heightDots, document.dpi),
      3,
    );
    final y = pplaDigits(
      pplaHundredthsOfInch(_argoxY(element, document), document.dpi) +
          pplaMmToHundredthsOfInch(argoxOptions.offsetYMm),
      4,
    );
    final x = pplaDigits(
      pplaHundredthsOfInch(element.xDots, document.dpi) +
          pplaMmToHundredthsOfInch(argoxOptions.offsetXMm),
      4,
    );

    return '$orientation$typeCode$barWidth$barWidth$height$y$x${payload.data}$_cr';
  }

  String _encodeShape(
    ResolvedElement element,
    ResolvedDocument document,
    ResolvedShapePayload payload,
    ArgoxRendererOptions argoxOptions,
  ) {
    final orientation = pplaOrientationCode(element.rotationDegrees);
    final y = pplaDigits(
      pplaHundredthsOfInch(_argoxY(element, document), document.dpi) +
          pplaMmToHundredthsOfInch(argoxOptions.offsetYMm),
      4,
    );
    final x = pplaDigits(
      pplaHundredthsOfInch(element.xDots, document.dpi) +
          pplaMmToHundredthsOfInch(argoxOptions.offsetXMm),
      4,
    );
    final width = pplaDigits(
      pplaHundredthsOfInch(element.widthDots, document.dpi),
      4,
    );
    final height = pplaDigits(
      pplaHundredthsOfInch(element.heightDots, document.dpi),
      4,
    );

    switch (payload.kind) {
      case ShapeKind.line:
        // PPLA's line primitive is axis-aligned (a straight horizontal or
        // vertical stroke sized by width/height), unlike our diagonal
        // ShapeKind.line — see README.
        return '${orientation}X11000$y${x}l$width$height$_cr';
      case ShapeKind.rectangle:
      case ShapeKind.ellipse:
      case ShapeKind.circle:
        // PPLA's box primitive is an outline only (no solid fill) and has
        // no curve — ellipse/circle render as their bounding box, and
        // ResolvedShapeStyle.fillColor has no PPLA equivalent. Both are
        // documented gaps, not silent data loss.
        final thicknessHundredths = pplaHundredthsOfInch(
          payload.style.strokeWidthDots,
          document.dpi,
        ).clamp(1, 999);
        final thickness = pplaDigits(thicknessHundredths, 4);
        return '${orientation}X11000$y${x}b$width$height$thickness$thickness$_cr';
    }
  }
}
