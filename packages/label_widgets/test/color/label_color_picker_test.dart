import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Material(child: Center(child: child)),
);

void main() {
  testWidgets('tapping a preset swatch reports that color', (tester) async {
    Color? changedTo;
    await tester.pumpWidget(
      _wrap(
        LabelColorPicker(
          color: const Color(0xFF000000),
          onColorChanged: (c) => changedTo = c,
        ),
      ),
    );

    await tester.tap(find.byType(LabelColorSwatch).first);
    expect(
      changedTo?.toARGB32(),
      LabelColorPicker.defaultPresets.first.toARGB32(),
    );
  });

  testWidgets('marks the swatch matching the current color as selected', (
    tester,
  ) async {
    final target = LabelColorPicker.defaultPresets[3];
    await tester.pumpWidget(
      _wrap(LabelColorPicker(color: target, onColorChanged: (_) {})),
    );

    final swatches = tester
        .widgetList<LabelColorSwatch>(find.byType(LabelColorSwatch))
        .toList();
    final selectedCount = swatches.where((s) => s.selected).length;
    expect(selectedCount, 1);
    expect(
      swatches.firstWhere((s) => s.selected).color.toARGB32(),
      target.toARGB32(),
    );
  });

  testWidgets('submitting a valid hex value reports the parsed color', (
    tester,
  ) async {
    Color? changedTo;
    await tester.pumpWidget(
      _wrap(
        LabelColorPicker(
          color: const Color(0xFF000000),
          onColorChanged: (c) => changedTo = c,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '00FF00');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(changedTo?.toARGB32(), const Color(0xFF00FF00).toARGB32());
  });

  testWidgets('submitting an invalid hex value does not call onColorChanged', (
    tester,
  ) async {
    var callCount = 0;
    await tester.pumpWidget(
      _wrap(
        LabelColorPicker(
          color: const Color(0xFF000000),
          onColorChanged: (_) => callCount++,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'not-a-color');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(callCount, 0);
  });

  testWidgets('the hex field updates when color changes externally', (
    tester,
  ) async {
    final key = GlobalKey();
    Color color = const Color(0xFF000000);

    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          key: key,
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabelColorPicker(
                  color: color,
                  onColorChanged: (c) => setState(() => color = c),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => color = const Color(0xFFABCDEF)),
                  child: const Text('external change'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('external change'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '#ABCDEF');
  });
}
