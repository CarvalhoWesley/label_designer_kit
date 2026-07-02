/// Thrown when [data] cannot be encoded for a given symbology — wrong
/// length, an unsupported character, an invalid checksum digit, etc.
///
/// Wraps whatever the underlying encoding implementation reports so
/// callers never need to depend on (or catch) a third-party exception
/// type directly.
class BarcodeEncodingException implements Exception {
  BarcodeEncodingException(this.message);

  final String message;

  @override
  String toString() => 'BarcodeEncodingException: $message';
}
