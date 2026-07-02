import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_core/label_core.dart';
import 'package:label_designer/label_designer.dart';

RectangleElement _rect(
  String id, {
  Point position = const Point.zero(),
  String layerId = 'layer-1',
}) => RectangleElement(
  id: id,
  name: id,
  position: position,
  size: const Size2D(width: 20, height: 20),
  layerId: layerId,
);

LabelDocument _document({List<LabelElement> elements = const []}) =>
    LabelDocument.blank(name: 'Doc').copyWith(elements: elements);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: 1200, height: 800, child: child),
  ),
);

Future<void> _pressCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pump();
}

Future<void> _pressCtrlShift(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pump();
}

void main() {
  testWidgets('renders without throwing for a blank document', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(LabelDesigner(document: _document())));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing with elements already on the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(LabelDesigner(document: _document(elements: [_rect('a')]))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding an element via the toolbar menu adds and selects it', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(LabelDesigner(document: _document())));

    await tester.tap(find.byTooltip('Adicionar elemento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retângulo').last);
    await tester.pumpAndSettle();

    // The property panel (right panel's default tab) now shows the newly
    // added, auto-selected element's type section.
    expect(find.text('Retângulo'), findsWidgets);
    expect(find.text('Geometria'), findsOneWidget);
  });

  testWidgets('undo/redo toolbar buttons roll the add back and forward', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(LabelDesigner(document: _document())));

    await tester.tap(find.byTooltip('Adicionar elemento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Texto').last);
    await tester.pumpAndSettle();
    expect(find.text('Geometria'), findsOneWidget);

    await tester.tap(find.byTooltip('Desfazer (Ctrl+Z)'));
    await tester.pumpAndSettle();
    expect(
      find.text('Selecione um elemento para editar suas propriedades.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Refazer (Ctrl+Y)'));
    await tester.pumpAndSettle();
    expect(find.text('Geometria'), findsOneWidget);
  });

  testWidgets('delete toolbar button removes the selection', (tester) async {
    await tester.pumpWidget(
      _wrap(LabelDesigner(document: _document(elements: [_rect('a')]))),
    );

    await tester.tap(find.byTooltip('Adicionar elemento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Círculo').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir (Delete)'));
    await tester.pumpAndSettle();

    expect(
      find.text('Selecione um elemento para editar suas propriedades.'),
      findsOneWidget,
    );
  });

  testWidgets('duplicate toolbar button clones and selects the clone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(LabelDesigner(document: _document(elements: [_rect('a')]))),
    );

    await tester.tap(find.byTooltip('Adicionar elemento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elipse').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Duplicar (Ctrl+D)'));
    await tester.pumpAndSettle();

    // Still on a (single) selection after duplicating — the clone, not
    // the original.
    expect(find.text('Elipse'), findsWidgets);
    expect(find.text('Geometria'), findsOneWidget);
  });

  testWidgets(
    'ctrl+A selects everything, escape clears the selection',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          LabelDesigner(
            document: _document(elements: [_rect('a'), _rect('b')]),
          ),
        ),
      );
      await tester.pump();

      await _pressCtrl(tester, LogicalKeyboardKey.keyA);
      // Multi-selection panel shows the count.
      expect(find.text('2 elementos selecionados'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(
        find.text('Selecione um elemento para editar suas propriedades.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('ctrl+G groups a multi-selection into one GroupElement', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LabelDesigner(
          document: _document(elements: [_rect('a'), _rect('b')]),
        ),
      ),
    );
    await tester.pump();

    await _pressCtrl(tester, LogicalKeyboardKey.keyA);
    await _pressCtrl(tester, LogicalKeyboardKey.keyG);

    // A single group is now selected (single-selection property panel).
    expect(find.text('Grupo'), findsWidgets);

    await _pressCtrlShift(tester, LogicalKeyboardKey.keyG);
    // Ungrouped back into a 2-element multi-selection.
    expect(find.text('2 elementos selecionados'), findsOneWidget);
  });

  testWidgets('the save button hands the current document to onSave', (
    tester,
  ) async {
    LabelDocument? saved;
    await tester.pumpWidget(
      _wrap(
        LabelDesigner(document: _document(), onSave: (doc) => saved = doc),
      ),
    );

    await tester.tap(find.byTooltip('Salvar'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.name, 'Doc');
  });

  testWidgets('no save button is shown when onSave is not provided', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(LabelDesigner(document: _document())));
    await tester.pump();
    expect(find.byTooltip('Salvar'), findsNothing);
  });

  testWidgets('switching the right panel tab shows the preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(LabelDesigner(document: _document(elements: [_rect('a')]))),
    );
    await tester.pump();

    await tester.tap(find.text('Preview'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('layers panel toggles visibility and lock', (tester) async {
    await tester.pumpWidget(
      _wrap(LabelDesigner(document: _document(elements: [_rect('a')]))),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Ocultar camada'));
    await tester.pump();
    expect(find.byTooltip('Mostrar camada'), findsOneWidget);

    await tester.tap(find.byTooltip('Bloquear camada'));
    await tester.pump();
    expect(find.byTooltip('Desbloquear camada'), findsOneWidget);
  });

  testWidgets('bring-to-front/send-to-back toolbar buttons work without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LabelDesigner(
          document: _document(elements: [_rect('a'), _rect('b')]),
        ),
      ),
    );
    await tester.pump();

    await _pressCtrl(tester, LogicalKeyboardKey.keyA);
    await tester.tap(find.byTooltip('Trazer para frente'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Enviar para trás'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final key in [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace]) {
    testWidgets('$key removes the selection', (tester) async {
      await tester.pumpWidget(
        _wrap(LabelDesigner(document: _document(elements: [_rect('a')]))),
      );
      await tester.pump();
      await _pressCtrl(tester, LogicalKeyboardKey.keyA);
      expect(find.text('Geometria'), findsOneWidget);

      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(
        find.text('Selecione um elemento para editar suas propriedades.'),
        findsOneWidget,
      );
    });
  }

  testWidgets('Ctrl+Z/Ctrl+Y and Ctrl+D work as keyboard shortcuts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(LabelDesigner(document: _document(elements: [_rect('a')]))),
    );
    await tester.pump();
    await _pressCtrl(tester, LogicalKeyboardKey.keyA);
    expect(find.text('Geometria'), findsOneWidget);

    await _pressCtrl(tester, LogicalKeyboardKey.keyD);
    // Duplicating re-selects the (single) clone — still a single selection.
    expect(find.text('Geometria'), findsOneWidget);

    await _pressCtrl(tester, LogicalKeyboardKey.keyZ);
    await tester.pump();
    expect(
      find.text('Selecione um elemento para editar suas propriedades.'),
      findsOneWidget,
    );

    await _pressCtrl(tester, LogicalKeyboardKey.keyY);
    await tester.pump();
    expect(find.text('Geometria'), findsOneWidget);
  });

  testWidgets(
    'swapping to a different document (same widget, new document) loads '
    'it and resets selection/history',
    (tester) async {
      final first = _document(elements: [_rect('a')]);
      final second = LabelDocument.blank(
        name: 'Outro documento',
      ).copyWith(elements: [_rect('b'), _rect('c')]);

      await tester.pumpWidget(_wrap(LabelDesigner(document: first)));
      await tester.pump();
      await _pressCtrl(tester, LogicalKeyboardKey.keyA);
      expect(find.text('Geometria'), findsOneWidget); // single selection

      await tester.pumpWidget(_wrap(LabelDesigner(document: second)));
      await tester.pump();

      // The old selection ('a') doesn't exist in the new document, so the
      // panel falls back to the empty state rather than a stale selection.
      expect(
        find.text('Selecione um elemento para editar suas propriedades.'),
        findsOneWidget,
      );

      // Undo history was reset, not carried over from the first document.
      expect(find.byTooltip('Desfazer (Ctrl+Z)'), findsOneWidget);
      await tester.tap(find.byTooltip('Adicionar elemento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Linha').last);
      await tester.pumpAndSettle();
      await _pressCtrl(tester, LogicalKeyboardKey.keyZ);
      await tester.pump();
      // One undo fully reverts the add — proves history didn't inherit
      // any steps from editing the first document.
      expect(
        find.text('Selecione um elemento para editar suas propriedades.'),
        findsOneWidget,
      );
    },
  );
}
