import 'dart:convert';
import 'dart:typed_data';

import 'package:label_core/label_core.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:test/test.dart';

/// A minimal fake used only to prove the [LabelRenderer] contract is
/// implementable and callable without pulling in a real backend package.
class _FakeRenderer implements LabelRenderer {
  const _FakeRenderer();

  @override
  Future<Uint8List> render(
    ResolvedDocument document,
    RendererOptions options,
  ) async {
    return Uint8List.fromList([document.elements.length]);
  }
}

class _FakeRendererOptions extends RendererOptions {
  const _FakeRendererOptions({required this.darkness});
  final int darkness;
}

/// A minimal command-based renderer used only to prove [BaseRenderer]'s
/// header -> elements (sorted by zIndex) -> footer flow, without pulling
/// in a real dialect like PPLA.
class _FakeCommandRenderer extends BaseRenderer {
  const _FakeCommandRenderer();

  @override
  String header(ResolvedDocument document, RendererOptions options) => 'H;';

  @override
  String encodeElement(
    ResolvedElement element,
    ResolvedDocument document,
    RendererOptions options,
  ) => '${element.id};';

  @override
  String footer(ResolvedDocument document, RendererOptions options) => 'F;';
}

void main() {
  test(
    'LabelRenderer implementations can be called through the interface',
    () async {
      const renderer = _FakeRenderer();
      const document = ResolvedDocument(
        widthDots: 10,
        heightDots: 10,
        dpi: 203,
        elements: [],
      );

      final bytes = await renderer.render(document, const RendererOptions());
      expect(bytes, Uint8List.fromList([0]));
    },
  );

  test(
    'a renderer-specific RendererOptions subclass can be passed through',
    () async {
      const renderer = _FakeRenderer();
      const document = ResolvedDocument(
        widthDots: 10,
        heightDots: 10,
        dpi: 203,
        elements: [],
      );

      final bytes = await renderer.render(
        document,
        const _FakeRendererOptions(darkness: 10),
      );
      expect(bytes, isNotEmpty);
    },
  );

  group('BaseRenderer', () {
    ResolvedElement fakeElement(String id, int zIndex) => ResolvedElement(
      id: id,
      xDots: 0,
      yDots: 0,
      widthDots: 1,
      heightDots: 1,
      rotationDegrees: 0,
      zIndex: zIndex,
      opacity: 1,
      payload: const ResolvedShapePayload(
        kind: ShapeKind.rectangle,
        style: ResolvedShapeStyle(strokeColor: 0xFF000000, strokeWidthDots: 0),
      ),
    );

    test('concatenates header, elements and footer in order', () async {
      const renderer = _FakeCommandRenderer();
      final document = ResolvedDocument(
        widthDots: 10,
        heightDots: 10,
        dpi: 203,
        elements: [fakeElement('a', 0)],
      );

      final bytes = await renderer.render(document, const RendererOptions());
      expect(latin1.decode(bytes), 'H;a;F;');
    });

    test('encodes elements in zIndex order regardless of list order', () async {
      const renderer = _FakeCommandRenderer();
      final document = ResolvedDocument(
        widthDots: 10,
        heightDots: 10,
        dpi: 203,
        elements: [fakeElement('front', 1), fakeElement('back', 0)],
      );

      final bytes = await renderer.render(document, const RendererOptions());
      expect(latin1.decode(bytes), 'H;back;front;F;');
    });

    test('encodeBytes defaults to Latin-1', () async {
      const renderer = _FakeCommandRenderer();
      const document = ResolvedDocument(
        widthDots: 10,
        heightDots: 10,
        dpi: 203,
        elements: [],
      );

      final bytes = await renderer.render(document, const RendererOptions());
      expect(bytes, Uint8List.fromList('H;F;'.codeUnits));
    });
  });
}
