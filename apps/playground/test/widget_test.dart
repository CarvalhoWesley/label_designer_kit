import 'package:flutter_test/flutter_test.dart';
import 'package:label_designer_kit/label_designer_kit.dart';
import 'package:playground/main.dart';

void main() {
  testWidgets('the playground boots and shows the label designer', (
    tester,
  ) async {
    await tester.pumpWidget(const PlaygroundApp());
    await tester.pump();

    expect(find.byType(LabelDesigner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nothing is selected on load, so the property panel starts '
      'in its empty state', (tester) async {
    await tester.pumpWidget(const PlaygroundApp());
    await tester.pump();

    expect(
      find.text('Selecione um elemento para editar suas propriedades.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'tapping Salvar runs the full serialize -> resolve -> render pipeline '
    '(docs/ROADMAP.md etapa 17) and reports every leg in a snackbar',
    (tester) async {
      // `FilePicker.platform` drives a real native dialog with no
      // test-harness mock, so this fakes the user cancelling the save
      // dialog — the rest of the pipeline (resolve, PDF, PPLA, snackbar)
      // runs for real either way.
      await tester.pumpWidget(
        PlaygroundApp(saveFilePicker: ({required suggestedFileName}) async => null),
      );
      await tester.pump();

      // The PDF/PPLA renders do real (if small) async work — runAsync lets
      // that finish for real instead of the widget test's fake time.
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Salvar'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('JSON:'), findsOneWidget);
      expect(find.textContaining('PDF:'), findsOneWidget);
      expect(find.textContaining('PPLA:'), findsOneWidget);
    },
  );
}
