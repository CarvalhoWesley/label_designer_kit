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
}
