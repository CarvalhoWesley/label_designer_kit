import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_property_panel/src/widgets/labeled_number_field.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('submitting valid text calls onChanged with the parsed value', (
    tester,
  ) async {
    double? changed;
    await tester.pumpWidget(
      _wrap(
        LabeledNumberField(
          label: 'X',
          value: 10,
          onChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(changed, 12.5);
  });

  testWidgets('submitting unparsable text reverts to the last value', (
    tester,
  ) async {
    var callCount = 0;
    await tester.pumpWidget(
      _wrap(
        LabeledNumberField(
          label: 'X',
          value: 10,
          onChanged: (_) => callCount++,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(callCount, 0);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('submitting a value below min reverts to the last value', (
    tester,
  ) async {
    var callCount = 0;
    await tester.pumpWidget(
      _wrap(
        LabeledNumberField(
          label: 'Largura',
          value: 10,
          min: 0.1,
          onChanged: (_) => callCount++,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '-5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(callCount, 0);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('updates its displayed text when value changes externally', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(LabeledNumberField(label: 'X', value: 10, onChanged: (_) {})),
    );
    expect(find.text('10'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(LabeledNumberField(label: 'X', value: 20, onChanged: (_) {})),
    );
    expect(find.text('20'), findsOneWidget);
  });
}
