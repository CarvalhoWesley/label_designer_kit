import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Material(child: Center(child: child)),
);

void main() {
  testWidgets('renders the label text', (tester) async {
    await tester.pumpWidget(
      _wrap(LabelButton(label: 'Salvar', onPressed: () {})),
    );
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets('renders an icon before the label when icon is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        LabelButton(
          label: 'Excluir',
          icon: LabelIcons.delete,
          onPressed: () {},
        ),
      ),
    );
    expect(find.byIcon(LabelIcons.delete), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
  });

  testWidgets('invokes onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(LabelButton(label: 'OK', onPressed: () => tapped = true)),
    );

    await tester.tap(find.byType(LabelButton));
    expect(tapped, isTrue);
  });

  for (final variant in LabelButtonVariant.values) {
    testWidgets('renders without error for variant $variant', (tester) async {
      await tester.pumpWidget(
        _wrap(LabelButton(label: 'Botão', variant: variant, onPressed: () {})),
      );
      expect(find.byType(LabelButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
