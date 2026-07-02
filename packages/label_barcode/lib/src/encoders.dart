import 'package:label_core/label_core.dart';

import 'symbol.dart';

/// Encodes string data into a [BarcodeSymbol] for one symbology.
///
/// One [BarcodeEncoder] exists per [BarcodeSymbology] value, looked up via
/// [linearBarcodeEncoders] — a new symbology registers another
/// implementation there without touching any existing one (Strategy
/// pattern).
abstract interface class BarcodeEncoder {
  BarcodeSymbol encode(String data);
}

/// Encodes string data into a QR Code [BarcodeSymbol]. Separate from
/// [BarcodeEncoder] because QR Code takes an error-correction level that
/// no other symbology in this package needs.
abstract interface class QrCodeEncoder {
  BarcodeSymbol encode(String data, {required QrErrorCorrectionLevel level});
}
