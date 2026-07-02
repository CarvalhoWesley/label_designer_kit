/// Thrown when decoding a `.label` document whose `version` is newer than
/// this package knows how to read (the app should upgrade its dependency
/// on `label_serialization` instead of guessing at the newer schema).
class UnsupportedSchemaVersionException implements Exception {
  UnsupportedSchemaVersionException({
    required this.version,
    required this.maxSupportedVersion,
  });

  final int version;
  final int maxSupportedVersion;

  @override
  String toString() =>
      'UnsupportedSchemaVersionException: documento na versão $version, '
      'mas este pacote só sabe ler até a versão $maxSupportedVersion. '
      'Atualize a dependência label_serialization.';
}

/// Thrown when the migration chain has no [LabelDocumentMigration]
/// registered for a version encountered while upgrading an old document.
class MissingMigrationException implements Exception {
  MissingMigrationException(this.fromVersion);

  final int fromVersion;

  @override
  String toString() =>
      'MissingMigrationException: nenhuma migração registrada a partir da '
      'versão $fromVersion.';
}
