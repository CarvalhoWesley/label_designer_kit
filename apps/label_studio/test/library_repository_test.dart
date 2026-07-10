import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_designer_kit/label_designer_kit.dart' hide EdgeInsets;
import 'package:label_studio/src/library/library_repository.dart';

void main() {
  late Directory tempDir;
  late LibraryRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('label_studio_test_');
    repository = LibraryRepository(directory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('list() is empty for a fresh library', () async {
    expect(await repository.list(), isEmpty);
  });

  test('create() saves a blank document with a thumbnail', () async {
    final entry = await repository.create(name: 'Minha etiqueta');

    expect(entry.document.name, 'Minha etiqueta');
    expect(entry.document.metadata.thumbnailBase64, isNotNull);
    expect(await File(entry.filePath).exists(), isTrue);

    final entries = await repository.list();
    expect(entries, hasLength(1));
    expect(entries.single.id, entry.id);
  });

  test('save() overwrites the same file across renames', () async {
    final entry = await repository.create(name: 'Original');
    final renamed = entry.document.copyWith(name: 'Renomeada');

    final saved = await repository.save(id: entry.id, document: renamed);

    expect(saved.filePath, entry.filePath);
    final entries = await repository.list();
    expect(entries, hasLength(1));
    expect(entries.single.document.name, 'Renomeada');
  });

  test('duplicate() creates a second file with a distinct id', () async {
    final original = await repository.create(name: 'Original');

    final copy = await repository.duplicate(original);

    expect(copy.id, isNot(original.id));
    expect(copy.document.name, 'Original (cópia)');
    final entries = await repository.list();
    expect(entries, hasLength(2));
  });

  test('delete() removes the file and drops it from list()', () async {
    final entry = await repository.create();

    await repository.delete(entry);

    expect(await repository.list(), isEmpty);
    expect(await File(entry.filePath).exists(), isFalse);
  });

  test('list() skips files that fail to decode', () async {
    await File('${tempDir.path}/corrupted.label').writeAsString('not json');
    final entry = await repository.create(name: 'Válida');

    final entries = await repository.list();

    expect(entries, hasLength(1));
    expect(entries.single.id, entry.id);
  });

  test('list() sorts most recently updated first', () async {
    final older = await repository.create(name: 'Mais antiga');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final newer = await repository.create(name: 'Mais nova');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.save(
      id: older.id,
      document: older.document.copyWith(name: 'Mais antiga (editada)'),
    );

    final entries = await repository.list();

    expect(entries.first.id, older.id);
    expect(entries.last.id, newer.id);
  });

  test('saved file round-trips through LabelDocumentCodec', () async {
    final entry = await repository.create(name: 'Round trip');
    final raw = await File(entry.filePath).readAsString();

    final decoded = const LabelDocumentCodec().decode(raw);

    expect(decoded.name, 'Round trip');
    expect(jsonDecode(raw), isA<Map<String, dynamic>>());
  });
}
