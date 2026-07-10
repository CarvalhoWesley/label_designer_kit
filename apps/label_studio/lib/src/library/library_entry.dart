import 'package:label_designer_kit/label_designer_kit.dart' hide EdgeInsets;

/// One saved template in the local library: a decoded [LabelDocument] paired
/// with the `.label` file it was read from. [id] is the file's basename
/// (without extension) and stays fixed across renames/edits, so
/// [LibraryRepository.save] always overwrites the same file regardless of
/// what the user renames the document to.
class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.document,
    required this.filePath,
  });

  final String id;
  final LabelDocument document;
  final String filePath;
}
