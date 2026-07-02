import 'dart:convert';

import 'package:label_core/label_core.dart';

import 'migrations/label_document_migration.dart';
import 'migrations/migration_runner.dart';
import 'migrations/migrations.dart';

/// Converts between `.label` JSON (as a [String] or already-decoded
/// [Map]) and [LabelDocument], migrating older schema versions on the way
/// in.
///
/// This codec does not touch the filesystem or network — reading/writing
/// the `.label` file's bytes is the consuming app's responsibility (see
/// `docs/ARCHITECTURE.md` section 20), which keeps this package usable
/// from Flutter Web as well as Desktop/Mobile.
class LabelDocumentCodec {
  const LabelDocumentCodec({this.migrations = defaultMigrations});

  final List<LabelDocumentMigration> migrations;

  /// Serializes [document] to a `.label` JSON string.
  String encode(LabelDocument document) => jsonEncode(document.toJson());

  /// Serializes [document] to a JSON-compatible map, for callers that want
  /// to embed it in a larger payload instead of a standalone string.
  Map<String, dynamic> encodeToMap(LabelDocument document) => document.toJson();

  /// Parses a `.label` JSON string into a [LabelDocument], applying any
  /// migrations needed to reach [labelDocumentSchemaVersion].
  LabelDocument decode(String source) {
    return decodeMap(jsonDecode(source) as Map<String, dynamic>);
  }

  /// Same as [decode], but starting from an already-decoded JSON map.
  LabelDocument decodeMap(Map<String, dynamic> json) {
    final migrated = MigrationRunner(
      migrations,
    ).run(json, targetVersion: labelDocumentSchemaVersion);
    return LabelDocument.fromJson(migrated);
  }
}
