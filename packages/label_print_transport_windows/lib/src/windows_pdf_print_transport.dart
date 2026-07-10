import 'dart:typed_data';

import 'package:label_print_transport/label_print_transport.dart';
import 'package:windows_printer/windows_printer.dart';

/// Sends PDF bytes (e.g. from `label_renderer_pdf`) to a Windows printer
/// through the system's own driver/rendering pipeline — works with any
/// installed printer, not just direct-command thermal printers. `target`
/// is a Windows printer name; `null` uses the system default printer.
///
/// Unlike [PrintTransport.send]'s single-copy contract, Windows' PDF print
/// path natively supports multiple copies per call, so [copies] is a
/// constructor setting rather than a `send()` parameter — separate from
/// `WindowsRawPrintTransport`, whose raw byte stream (e.g. PPLA) already
/// encodes its own copy count.
///
/// Wraps `windows_printer`'s `WindowsPrinter.printPdf`. Validated manually
/// against a real printer — see `WindowsRawPrintTransport`'s doc comment
/// for why this isn't covered by automated tests.
class WindowsPdfPrintTransport implements PrintTransport {
  const WindowsPdfPrintTransport({this.copies = 1})
    : assert(copies >= 1, 'copies must be at least 1');

  final int copies;

  @override
  Future<void> send(Uint8List bytes, {String? target}) async {
    final success = await WindowsPrinter.printPdf(
      printerName: target,
      data: bytes,
      copies: copies,
    );
    if (!success) {
      throw PrintTransportException(
        'WindowsPrinter.printPdf falhou para a impressora '
        '${target ?? "padrão do sistema"}.',
      );
    }
  }
}
