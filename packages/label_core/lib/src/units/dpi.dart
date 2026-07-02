/// Printer resolutions supported by the Layout Engine.
///
/// Values are dots per inch. Conversion between millimeters and dots is the
/// only place where a "dot" concept is allowed to exist outside a renderer.
enum Dpi {
  dpi203(203),
  dpi300(300),
  dpi600(600);

  const Dpi(this.value);

  /// Dots per inch.
  final int value;

  /// Dots per millimeter (1 inch = 25.4 mm).
  double get dotsPerMm => value / 25.4;

  /// Converts a millimeter measurement to the nearest whole dot.
  int mmToDots(double mm) => (mm * dotsPerMm).round();

  /// Converts a dot measurement back to millimeters.
  double dotsToMm(int dots) => dots / dotsPerMm;

  static Dpi fromValue(int value) {
    return Dpi.values.firstWhere(
      (dpi) => dpi.value == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Unsupported DPI'),
    );
  }
}
