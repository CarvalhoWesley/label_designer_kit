import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Material(child: Center(child: child)),
);

void main() {
  testWidgets('shows the tooltip and icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LabelToolbarButton(
          icon: LabelIcons.rotate,
          tooltip: 'Girar',
          onPressed: () {},
        ),
      ),
    );

    expect(find.byIcon(LabelIcons.rotate), findsOneWidget);
    expect(find.byTooltip('Girar'), findsOneWidget);
  });

  testWidgets('invokes onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        LabelToolbarButton(
          icon: LabelIcons.undo,
          tooltip: 'Desfazer',
          onPressed: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('does not throw when tapped while disabled (onPressed null)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LabelToolbarButton(icon: LabelIcons.redo, tooltip: 'Refazer'),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();
  });
}
