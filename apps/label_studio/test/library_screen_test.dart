import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_studio/src/library/library_repository.dart';
import 'package:label_studio/src/library/library_screen.dart';

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

  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('shows an empty state and a way to create the first label', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(LibraryScreen(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma etiqueta ainda.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Nova etiqueta'), findsOneWidget);
  });

  testWidgets('lists saved templates as cards', (tester) async {
    await repository.create(name: 'Etiqueta A');
    await repository.create(name: 'Etiqueta B');

    await tester.pumpWidget(wrap(LibraryScreen(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Etiqueta A'), findsOneWidget);
    expect(find.text('Etiqueta B'), findsOneWidget);
  });

  testWidgets('duplicating a card adds a second entry to the grid', (
    tester,
  ) async {
    await repository.create(name: 'Original');
    await tester.pumpWidget(wrap(LibraryScreen(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Original (cópia)'), findsOneWidget);
  });

  testWidgets('deleting a card asks for confirmation then removes it', (
    tester,
  ) async {
    await repository.create(name: 'Descartável');
    await tester.pumpWidget(wrap(LibraryScreen(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir etiqueta'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Descartável'), findsNothing);
    expect(find.text('Nenhuma etiqueta ainda.'), findsOneWidget);
  });
}
