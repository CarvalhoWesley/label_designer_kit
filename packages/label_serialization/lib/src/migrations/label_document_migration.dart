/// One step in the `.label` schema's Chain of Responsibility.
///
/// Each migration upgrades a raw JSON map from exactly [fromVersion] to
/// `fromVersion + 1` and must write the new version number into the
/// returned map's `version` field. [MigrationRunner] chains these together
/// so `LabelDocumentCodec` never has a cascade of `if (version == ...)`
/// checks — supporting an old file is just registering one more migration.
abstract class LabelDocumentMigration {
  const LabelDocumentMigration();

  /// The schema version this migration accepts as input.
  int get fromVersion;

  /// Returns a new map upgraded to `fromVersion + 1`. Must not mutate
  /// [json] in place, since the runner may need the original for error
  /// reporting.
  Map<String, dynamic> migrate(Map<String, dynamic> json);
}
