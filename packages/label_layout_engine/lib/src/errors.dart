/// Thrown for *structural* problems in a [LabelDocument] that the author
/// must fix — a resolved element with non-positive dimensions, a
/// `styleId`/`layerId` that doesn't exist, a [DateElement]/[TimeElement]
/// missing its `variableName` when `source` is [DateTimeSource.variable].
///
/// Contrast with a broken `{{ }}` expression or an undefined *row*
/// variable: those are per-print-job data problems, not template bugs, so
/// they resolve to a visible error marker in the output instead of
/// throwing — printing 999 correct labels shouldn't abort because one
/// row was missing a field. See `docs/ARCHITECTURE.md` section 9.
class LayoutException implements Exception {
  LayoutException(this.message);

  final String message;

  @override
  String toString() => 'LayoutException: $message';
}
