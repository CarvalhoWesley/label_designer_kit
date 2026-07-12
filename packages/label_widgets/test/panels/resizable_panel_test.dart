import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_widgets/label_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
);

void main() {
  testWidgets('collapsed shows only the expand button, at collapsedWidth', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 200,
          onWidthChanged: (_) {},
          minWidth: 100,
          maxWidth: 300,
          collapsed: true,
          onCollapsedChanged: (_) {},
          child: const Text('conteúdo'),
        ),
      ),
    );

    expect(find.text('conteúdo'), findsNothing);
    expect(find.byTooltip('Expandir painel'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == ResizablePanel.collapsedWidth,
      ),
      findsOneWidget,
    );
  });

  testWidgets('expanded shows the child at the given width, plus the '
      'collapse handle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 220,
          onWidthChanged: (_) {},
          minWidth: 100,
          maxWidth: 300,
          collapsed: false,
          onCollapsedChanged: (_) {},
          child: const Text('conteúdo'),
        ),
      ),
    );

    expect(find.text('conteúdo'), findsOneWidget);
    expect(find.byTooltip('Recolher painel'), findsOneWidget);
  });

  testWidgets('tapping the expand button reports collapsed: false', (
    tester,
  ) async {
    bool? reported;
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 200,
          onWidthChanged: (_) {},
          minWidth: 100,
          maxWidth: 300,
          collapsed: true,
          onCollapsedChanged: (value) => reported = value,
          child: const Text('conteúdo'),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Expandir painel'));
    expect(reported, isFalse);
  });

  testWidgets('tapping the collapse button reports collapsed: true', (
    tester,
  ) async {
    bool? reported;
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 200,
          onWidthChanged: (_) {},
          minWidth: 100,
          maxWidth: 300,
          collapsed: false,
          onCollapsedChanged: (value) => reported = value,
          child: const Text('conteúdo'),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Recolher painel'));
    expect(reported, isTrue);
  });

  testWidgets('dragging the handle reports a clamped width', (tester) async {
    final widths = <double>[];
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            var width = 200.0;
            return ResizablePanel(
              width: width,
              onWidthChanged: (value) {
                widths.add(value);
                setState(() => width = value);
              },
              minWidth: 100,
              maxWidth: 220,
              collapsed: false,
              onCollapsedChanged: (_) {},
              child: const Text('conteúdo'),
            );
          },
        ),
      ),
    );

    await tester.drag(find.byTooltip('Recolher painel'), const Offset(50, 0));
    await tester.pump();

    expect(widths, isNotEmpty);
    // Started at 200, dragged +50 -> would be 250, clamped to maxWidth 220.
    expect(widths.last, 220);
  });

  testWidgets('resizeHandleOnLeft flips drag direction', (tester) async {
    final widths = <double>[];
    await tester.pumpWidget(
      _wrap(
        ResizablePanel(
          width: 200,
          onWidthChanged: widths.add,
          minWidth: 100,
          maxWidth: 300,
          collapsed: false,
          onCollapsedChanged: (_) {},
          resizeHandleOnLeft: true,
          child: const Text('conteúdo'),
        ),
      ),
    );

    await tester.drag(find.byTooltip('Recolher painel'), const Offset(20, 0));
    await tester.pump();

    // On the left-docked handle, dragging right (+20) shrinks the panel.
    expect(widths.last, lessThan(200));
  });
}
