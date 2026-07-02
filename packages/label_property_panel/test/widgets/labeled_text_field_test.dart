import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_property_panel/src/widgets/labeled_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('calls onChanged on every keystroke', (tester) async {
    var latest = '';
    await tester.pumpWidget(
      _wrap(
        LabeledTextField(
          label: 'Nome',
          value: '',
          onChanged: (value) => latest = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Produto');
    expect(latest, 'Produto');
  });

  testWidgets('updates its displayed text when value changes externally', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(LabeledTextField(label: 'Nome', value: 'A', onChanged: (_) {})),
    );
    expect(find.text('A'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(LabeledTextField(label: 'Nome', value: 'B', onChanged: (_) {})),
    );
    expect(find.text('B'), findsOneWidget);
  });
}
