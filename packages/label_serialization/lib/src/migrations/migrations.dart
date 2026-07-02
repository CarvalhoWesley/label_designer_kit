import 'label_document_migration.dart';

/// Every migration this package knows about, ordered by [fromVersion].
///
/// Currently empty because `label_core`'s schema is at its first version
/// (see `labelDocumentSchemaVersion`). When a v2 schema is introduced, add
/// a `Migration1To2` implementing [LabelDocumentMigration] here — no other
/// call site needs to change.
const List<LabelDocumentMigration> defaultMigrations = [];
