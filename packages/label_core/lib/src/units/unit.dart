/// Linear units supported by the editor for display purposes.
///
/// Canonical storage inside [LabelDocument] is always millimeters — this
/// enum only affects how a value is *displayed* (e.g. a ruler in inches).
enum Unit {
  mm,
  cm,
  inch;

  /// Converts a value expressed in this unit to millimeters.
  double toMm(double value) {
    switch (this) {
      case Unit.mm:
        return value;
      case Unit.cm:
        return value * 10;
      case Unit.inch:
        return value * 25.4;
    }
  }

  /// Converts a value expressed in millimeters to this unit.
  double fromMm(double mm) {
    switch (this) {
      case Unit.mm:
        return mm;
      case Unit.cm:
        return mm / 10;
      case Unit.inch:
        return mm / 25.4;
    }
  }
}
