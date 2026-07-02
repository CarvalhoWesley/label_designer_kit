import '../errors.dart';
import 'label_document_migration.dart';

/// Applies a chain of [LabelDocumentMigration]s to bring a raw `.label`
/// JSON map from whatever version it declares up to [targetVersion].
class MigrationRunner {
  const MigrationRunner(this.migrations);

  final List<LabelDocumentMigration> migrations;

  Map<String, dynamic> run(
    Map<String, dynamic> json, {
    required int targetVersion,
  }) {
    var current = json;
    var version = current['version'] as int? ?? 1;

    if (version > targetVersion) {
      throw UnsupportedSchemaVersionException(
        version: version,
        maxSupportedVersion: targetVersion,
      );
    }

    while (version < targetVersion) {
      final migration = migrations
          .where((candidate) => candidate.fromVersion == version)
          .firstOrNull;
      if (migration == null) {
        throw MissingMigrationException(version);
      }

      current = migration.migrate(current);
      final nextVersion = current['version'] as int?;
      if (nextVersion == null || nextVersion <= version) {
        throw StateError(
          'A migração a partir da versão $version precisa gravar um '
          '"version" maior no JSON retornado.',
        );
      }
      version = nextVersion;
    }

    return current;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
