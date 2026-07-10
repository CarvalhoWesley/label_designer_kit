import 'print_transport.dart';

/// Lists printers/ports a [PrintTransport] backend could send to.
///
/// Kept separate from `PrintTransport` because discovery is inherently
/// backend-shaped — a Windows spooler lists printer names, a serial
/// backend would enumerate COM ports, a network backend has no
/// enumeration at all — so not every [PrintTransport] implementation needs
/// to implement this too.
abstract interface class PrinterDiscovery {
  /// Returns the identifiers ([PrintTransport.send]'s `target`) available
  /// right now.
  Future<List<String>> listAvailable();
}
