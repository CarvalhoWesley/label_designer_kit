import 'dart:convert';
import 'dart:io';

import 'package:label_designer_kit/label_designer_kit.dart' hide EdgeInsets;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'library_entry.dart';

/// Persists the local library of `.label` templates as one file per
/// document under [directory], keyed by [LibraryEntry.id]. There is no
/// separate index file: the directory listing *is* the library, so it can
/// never drift out of sync with what's actually on disk (see
/// `docs/ARCHITECTURE.md` section 20 — the app owns all real file I/O).
///
/// Every save also renders a small PNG thumbnail via the same
/// `LabelLayoutEngine` + `CanvasRenderer` pipeline used for the live
/// preview, and stores it in [DocumentMetadata.thumbnailBase64] — exactly
/// the field `label_core` already reserves for this purpose.
class LibraryRepository {
  const LibraryRepository({
    required this.directory,
    this.codec = const LabelDocumentCodec(),
  });

  /// Opens the library under the OS-managed app-support directory (e.g.
  /// `%APPDATA%/label_studio/labels` on Windows), creating it on first run.
  static Future<LibraryRepository> open() async {
    final supportDir = await getApplicationSupportDirectory();
    final labelsDir = Directory('${supportDir.path}/labels');
    if (!await labelsDir.exists()) {
      await labelsDir.create(recursive: true);
    }
    return LibraryRepository(directory: labelsDir);
  }

  final Directory directory;
  final LabelDocumentCodec codec;

  String _pathFor(String id) => '${directory.path}/$id.label';

  static String _idFromPath(String path) {
    final base = path.split(RegExp(r'[\\/]')).last;
    return base.substring(0, base.length - '.label'.length);
  }

  /// Lists every saved template, most recently updated first. Files that
  /// fail to decode (corrupted, foreign format) are skipped rather than
  /// failing the whole listing.
  Future<List<LibraryEntry>> list() async {
    if (!await directory.exists()) return [];
    final entries = <LibraryEntry>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.label')) continue;
      try {
        final document = codec.decode(await entity.readAsString());
        entries.add(
          LibraryEntry(
            id: _idFromPath(entity.path),
            document: document,
            filePath: entity.path,
          ),
        );
      } on FormatException {
        continue;
      }
    }
    entries.sort(
      (a, b) => b.document.metadata.updatedAt.compareTo(
        a.document.metadata.updatedAt,
      ),
    );
    return entries;
  }

  /// Creates and saves a brand-new blank template.
  Future<LibraryEntry> create({String name = 'Nova etiqueta'}) {
    return save(
      id: const Uuid().v4(),
      document: LabelDocument.blank(name: name),
    );
  }

  /// Encodes [document] (stamping a fresh thumbnail and `updatedAt`) and
  /// writes it to the file identified by [id], creating it if new.
  Future<LibraryEntry> save({
    required String id,
    required LabelDocument document,
  }) async {
    final withThumbnail = await _stampThumbnail(document);
    final file = File(_pathFor(id));
    await file.writeAsString(codec.encode(withThumbnail));
    return LibraryEntry(id: id, document: withThumbnail, filePath: file.path);
  }

  /// Saves a copy of [entry] under a new id, named "{original name} (cópia)".
  Future<LibraryEntry> duplicate(LibraryEntry entry) {
    final source = entry.document;
    final copy = source.copyWith(
      name: '${source.name} (cópia)',
      metadata: source.metadata.copyWith(createdAt: DateTime.now()),
    );
    return save(id: const Uuid().v4(), document: copy);
  }

  Future<void> delete(LibraryEntry entry) async {
    final file = File(entry.filePath);
    if (await file.exists()) await file.delete();
  }

  /// Renders [document] with its variables' sample values through the
  /// canvas backend, scaled down to a card-sized thumbnail, and stores the
  /// PNG as base64 on the document's metadata. Falls back to no thumbnail
  /// (keeping the rest of the save intact) if the document can't currently
  /// be resolved — e.g. a mid-edit state with an invalid element size.
  Future<LabelDocument> _stampThumbnail(LabelDocument document) async {
    final now = DateTime.now();
    try {
      final data = {
        for (final variable in document.variables)
          variable.name: variable.defaultValue,
      };
      const layoutEngine = LabelLayoutEngine();
      final resolved = layoutEngine.resolve(document, data);
      final widthDots = document.page.dpi.mmToDots(document.page.width);
      final pixelRatio = widthDots <= 0
          ? 1.0
          : (240 / widthDots).clamp(0.1, 4.0);
      const renderer = CanvasRenderer();
      final png = await renderer.render(
        resolved,
        CanvasRendererOptions(pixelRatio: pixelRatio),
      );
      return document.copyWith(
        metadata: document.metadata.copyWith(
          thumbnailBase64: base64Encode(png),
          updatedAt: now,
        ),
      );
    } catch (_) {
      return document.copyWith(
        metadata: document.metadata.copyWith(updatedAt: now),
      );
    }
  }
}
