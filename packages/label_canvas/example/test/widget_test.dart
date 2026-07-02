import 'package:flutter_test/flutter_test.dart';
import 'package:label_canvas_example/main.dart';

void main() {
  testWidgets('playground renders the sample document without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(const CanvasPlaygroundApp());
    await tester.pumpAndSettle();

    expect(find.text('label_canvas — playground'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
