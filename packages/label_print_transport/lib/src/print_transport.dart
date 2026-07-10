import 'dart:typed_data';

/// Sends already-rendered bytes (PPLA, ZPL, PDF, ...) to a physical
/// printer, over whatever channel a concrete backend implements — USB via
/// an OS spooler, a raw TCP socket, serial, Bluetooth.
///
/// This is the **only** contract the rest of the framework depends on for
/// print transport. It deliberately knows nothing about `LabelDocument`,
/// `ResolvedDocument` or any `label_renderer_*` — it only moves bytes. See
/// `docs/ARCHITECTURE.md` and `docs/ROADMAP.md` etapa 20 for why this is a
/// separate package from `label_designer_kit`'s domain packages, consumed
/// only by the app doing the actual printing.
///
/// `send()` is deliberately stateless — no `connect()`/`disconnect()` — a
/// backend that needs a persistent connection (serial, a long-lived TCP
/// socket) can manage that internally on each call without requiring a
/// change to this interface.
abstract interface class PrintTransport {
  /// Sends [bytes] to the printer. [target] identifies which printer/port
  /// to use in a way specific to the backend (e.g. a Windows printer name,
  /// a host:port pair, a serial device path); `null` means "the backend's
  /// default".
  Future<void> send(Uint8List bytes, {String? target});
}
