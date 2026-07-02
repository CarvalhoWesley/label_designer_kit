import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

void main() {
  testWidgets(
    'renders a horizontal ruler without error inside a bounded width',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: SizedBox(
              width: 300,
              height: 20,
              child: LabelRuler(axis: RulerAxis.horizontal, pixelsPerMm: 4),
            ),
          ),
        ),
      );

      expect(find.byType(LabelRuler), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders a vertical ruler without error inside a bounded height',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: SizedBox(
              width: 20,
              height: 300,
              child: LabelRuler(
                axis: RulerAxis.vertical,
                pixelsPerMm: 2,
                originOffset: 15,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelRuler), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not throw when pixelsPerMm is zero (degenerate zoom)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: SizedBox(
            width: 100,
            height: 20,
            child: LabelRuler(axis: RulerAxis.horizontal, pixelsPerMm: 0),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
