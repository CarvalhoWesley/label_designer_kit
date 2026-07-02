/// Codec between the `.label` JSON format and [LabelDocument], with a
/// versioned migration pipeline (Chain of Responsibility) for backward
/// compatibility. See `docs/ARCHITECTURE.md` section 12.
library;

export 'src/errors.dart';
export 'src/label_document_codec.dart';
export 'src/migrations/label_document_migration.dart';
export 'src/migrations/migration_runner.dart';
export 'src/migrations/migrations.dart';
