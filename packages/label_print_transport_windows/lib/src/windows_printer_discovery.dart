import 'package:label_print_transport/label_print_transport.dart';
import 'package:windows_printer/windows_printer.dart';

/// Lists printer names known to the Windows spooler — the `target` values
/// that `WindowsRawPrintTransport`/`WindowsPdfPrintTransport` accept.
///
/// Wraps `windows_printer`'s `WindowsPrinter.getAvailablePrinters`.
class WindowsPrinterDiscovery implements PrinterDiscovery {
  const WindowsPrinterDiscovery();

  @override
  Future<List<String>> listAvailable() => WindowsPrinter.getAvailablePrinters();
}
