import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets_example/main.dart';

void main() {
  testWidgets('gallery renders every section without throwing', (tester) async {
    await tester.pumpWidget(const WidgetGalleryApp());
    await tester.pumpAndSettle();

    expect(find.text('label_widgets — playground'), findsOneWidget);
    expect(find.text('LabelToolbarButton'), findsOneWidget);
    expect(find.text('LabelButton'), findsOneWidget);
    expect(find.text('LabelColorPicker'), findsOneWidget);
    expect(find.text('LabelRuler'), findsOneWidget);
    expect(find.text('LabelIcons'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
