import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Material(child: Center(child: child)),
);

void main() {
  testWidgets('invokes onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        LabelColorSwatch(
          color: const Color(0xFFFF0000),
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(LabelColorSwatch));
    expect(tapped, isTrue);
  });

  testWidgets('exposes selected state via Semantics', (tester) async {
    await tester.pumpWidget(
      _wrap(LabelColorSwatch(color: const Color(0xFFFF0000), selected: true)),
    );

    final semantics = tester.getSemantics(find.byType(LabelColorSwatch));
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
  });
}
