import 'dart:typed_data';

import 'package:label_print_transport/label_print_transport.dart';
import 'package:windows_printer/windows_printer.dart';

/// Sends raw bytes (e.g. PPLA/PPLB from `label_renderer_argox`) straight to
/// a Windows printer's spooler, bypassing Windows' own rendering — the
/// printer receives exactly the bytes it was given. `target` is a Windows
/// printer name; `null` uses the system default printer.
///
/// Wraps `windows_printer`'s `WindowsPrinter.printRawData`. Validated
/// manually against a real Argox printer connected via USB — this backend
/// isn't covered by automated tests, since there's no spooler to talk to
/// in CI (see `label_print_transport_windows`'s test/ for what *is*
/// automated).
class WindowsRawPrintTransport implements PrintTransport {
  const WindowsRawPrintTransport();

  @override
  Future<void> send(Uint8List bytes, {String? target}) async {
    final success = await WindowsPrinter.printRawData(
      printerName: target,
      data: bytes,
      useRawDatatype: true,
    );
    if (!success) {
      throw PrintTransportException(
        'WindowsPrinter.printRawData falhou para a impressora '
        '${target ?? "padrão do sistema"}.',
      );
    }
  }
}
