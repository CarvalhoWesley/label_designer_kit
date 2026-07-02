/// Millimeter positions of every ruler tick between [startMm] and [endMm]
/// (inclusive), spaced [intervalMm] apart and snapped to a multiple of
/// [intervalMm] — so ticks always land on round numbers regardless of
/// where the visible range starts (e.g. after panning).
///
/// Pure geometry, no Flutter dependency, so it's unit-testable without a
/// widget pump.
List<double> rulerTicks({
  required double startMm,
  required double endMm,
  required double intervalMm,
}) {
  assert(intervalMm > 0, 'intervalMm must be positive');
  if (endMm < startMm) return const [];

  final first = (startMm / intervalMm).floor() * intervalMm;
  final ticks = <double>[];
  for (var mm = first; mm <= endMm; mm += intervalMm) {
    if (mm >= startMm) ticks.add(mm);
  }
  return ticks;
}

/// Whether [mm] falls on a "major" tick — a multiple of [majorIntervalMm]
/// — used to decide which ticks get a numeric label and a longer mark.
/// Tolerant of floating-point drift from repeated addition in
/// [rulerTicks].
bool isMajorTick(double mm, double majorIntervalMm) {
  const epsilon = 1e-6;
  final remainder = mm % majorIntervalMm;
  return remainder < epsilon || (majorIntervalMm - remainder) < epsilon;
}
