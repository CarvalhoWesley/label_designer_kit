import 'package:barcode/barcode.dart' as pkg;
import 'package:label_core/label_core.dart';

import 'encoders.dart';
import 'errors.dart';
import 'symbol.dart';

/// Adapts a `package:barcode` [pkg.Barcode] to our own [BarcodeEncoder].
///
/// This is the **only** file in `label_barcode` that imports
/// `package:barcode` — every other file, and every consumer of this
/// package, only ever sees [BarcodeEncoder]/[BarcodeSymbol]. Swapping the
/// underlying implementation (e.g. for a hand-written encoder) later only
/// touches this file.
class PackageBarcodeEncoder implements BarcodeEncoder {
  const PackageBarcodeEncoder(this._barcode);

  final pkg.Barcode _barcode;

  @override
  BarcodeSymbol encode(String data) => _encodeWith(_barcode, data);
}

class PackageBarcodeQrEncoder implements QrCodeEncoder {
  const PackageBarcodeQrEncoder();

  @override
  BarcodeSymbol encode(String data, {required QrErrorCorrectionLevel level}) {
    final barcode = pkg.Barcode.qrCode(
      errorCorrectLevel: pkg.BarcodeQRCorrectionLevel.values[level.index],
    );
    return _encodeWith(barcode, data);
  }
}

/// Requests a unit (1x1) box from `package:barcode`'s public [pkg.Barcode.make]
/// so every returned bar/module's `left`/`top`/`width`/`height` already
/// comes out as a 0.0–1.0 fraction — no separate module-counting or
/// pixel-to-fraction conversion needed.
BarcodeSymbol _encodeWith(pkg.Barcode barcode, String data) {
  try {
    barcode.verify(data);
  } on pkg.BarcodeException catch (error) {
    throw BarcodeEncodingException(error.message);
  }

  final modules = <SymbolModule>[
    for (final element in barcode.make(data, width: 1, height: 1))
      if (element is pkg.BarcodeBar && element.black)
        SymbolModule(
          left: element.left,
          top: element.top,
          width: element.width,
          height: element.height,
        ),
  ];
  return BarcodeSymbol(modules: modules);
}

/// One [BarcodeEncoder] per [BarcodeSymbology] declared in `label_core`.
final Map<BarcodeSymbology, BarcodeEncoder> linearBarcodeEncoders = {
  BarcodeSymbology.ean13: PackageBarcodeEncoder(pkg.Barcode.ean13()),
  BarcodeSymbology.ean8: PackageBarcodeEncoder(pkg.Barcode.ean8()),
  BarcodeSymbology.code39: PackageBarcodeEncoder(pkg.Barcode.code39()),
  BarcodeSymbology.code128: PackageBarcodeEncoder(pkg.Barcode.code128()),
  BarcodeSymbology.upc: PackageBarcodeEncoder(pkg.Barcode.upcA()),
  BarcodeSymbology.itf: PackageBarcodeEncoder(pkg.Barcode.itf()),
  BarcodeSymbology.codabar: PackageBarcodeEncoder(pkg.Barcode.codabar()),
};

/// The QR Code encoder used by `QRCodeElement`.
const QrCodeEncoder qrCodeEncoder = PackageBarcodeQrEncoder();

/// Available for future 2D `LabelElement` types (see
/// `docs/ROADMAP.md`) — not wired to any element yet, since `label_core`
/// currently only models QR Code among 2D symbologies.
final BarcodeEncoder pdf417BarcodeEncoder = PackageBarcodeEncoder(
  pkg.Barcode.pdf417(),
);
final BarcodeEncoder dataMatrixBarcodeEncoder = PackageBarcodeEncoder(
  pkg.Barcode.dataMatrix(),
);
