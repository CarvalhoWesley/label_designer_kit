/// Thrown by a [PrintTransport] backend when the underlying OS/driver call
/// reports failure (e.g. Windows' spooler API returning `false`) — surfaced
/// as an exception rather than silently swallowed, since [PrintTransport]
/// callers otherwise have no way to know a job never reached the printer.
class PrintTransportException implements Exception {
  const PrintTransportException(this.message);

  final String message;

  @override
  String toString() => 'PrintTransportException: $message';
}
