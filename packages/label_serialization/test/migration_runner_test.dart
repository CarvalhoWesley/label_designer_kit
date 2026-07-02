import 'package:label_serialization/label_serialization.dart';
import 'package:test/test.dart';

/// Synthetic migration used only to exercise [MigrationRunner] — it does
/// not correspond to any real `.label` schema change.
class _RenameFieldMigration extends LabelDocumentMigration {
  const _RenameFieldMigration();

  @override
  int get fromVersion => 1;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> json) {
    final next = Map<String, dynamic>.from(json)..remove('oldName');
    next['name'] = json['oldName'];
    next['version'] = 2;
    return next;
  }
}

class _AddFieldMigration extends LabelDocumentMigration {
  const _AddFieldMigration();

  @override
  int get fromVersion => 2;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> json) {
    return {...json, 'version': 3, 'newField': 'default'};
  }
}

class _BuggyMigration extends LabelDocumentMigration {
  const _BuggyMigration();

  @override
  int get fromVersion => 1;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> json) {
    // Forgets to bump the version — the runner must catch this.
    return {...json};
  }
}

void main() {
  group('MigrationRunner', () {
    test('returns the input unchanged when already at targetVersion', () {
      const runner = MigrationRunner([]);
      final json = {'version': 3, 'name': 'x'};
      expect(runner.run(json, targetVersion: 3), json);
    });

    test('applies a single migration to reach targetVersion', () {
      const runner = MigrationRunner([_RenameFieldMigration()]);
      final result = runner.run({
        'version': 1,
        'oldName': 'Etiqueta',
      }, targetVersion: 2);

      expect(result['version'], 2);
      expect(result['name'], 'Etiqueta');
      expect(result.containsKey('oldName'), isFalse);
    });

    test('chains multiple migrations across several versions', () {
      const runner = MigrationRunner([
        _RenameFieldMigration(),
        _AddFieldMigration(),
      ]);
      final result = runner.run({
        'version': 1,
        'oldName': 'Etiqueta',
      }, targetVersion: 3);

      expect(result['version'], 3);
      expect(result['name'], 'Etiqueta');
      expect(result['newField'], 'default');
    });

    test('throws MissingMigrationException when a step is not registered', () {
      const runner = MigrationRunner([_RenameFieldMigration()]);
      expect(
        () => runner.run({'version': 1}, targetVersion: 3),
        throwsA(isA<MissingMigrationException>()),
      );
    });

    test(
      'throws UnsupportedSchemaVersionException when the document is newer than target',
      () {
        const runner = MigrationRunner([]);
        expect(
          () => runner.run({'version': 5}, targetVersion: 3),
          throwsA(isA<UnsupportedSchemaVersionException>()),
        );
      },
    );

    test('throws StateError when a migration does not advance the version', () {
      const runner = MigrationRunner([_BuggyMigration()]);
      expect(
        () => runner.run({'version': 1}, targetVersion: 2),
        throwsStateError,
      );
    });

    test('defaults an absent "version" field to 1', () {
      const runner = MigrationRunner([_RenameFieldMigration()]);
      final result = runner.run({'oldName': 'Sem versão'}, targetVersion: 2);
      expect(result['version'], 2);
    });
  });
}
