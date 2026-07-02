import 'package:flutter_test/flutter_test.dart';
import 'package:label_designer/label_designer.dart';
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
}
