import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_label_designer/flutter_label_designer.dart' hide EdgeInsets;

/// A debounced `LabelDocument` -> `LabelLayoutEngine` -> `CanvasRenderer` ->
/// `Image.memory` preview, local to this app.
///
/// This deliberately re-implements the same small pattern as
/// `packages/label_preview` instead of depending on that package directly:
/// `flutter_label_designer`'s barrel (see its doc comment) exposes exactly
/// `LabelLayoutEngine` and `CanvasRenderer` as the intended way for a
/// consuming app to build its own previews, and reserves `label_preview`
/// itself as an internal implementation detail of `label_designer`. Staying
/// on the kit keeps this app a faithful example of what an external
/// consumer project is expected to do.
class LivePreview extends StatefulWidget {
  const LivePreview({
    super.key,
    required this.document,
    required this.sampleData,
    this.pixelRatio = 2.0,
  });

  final LabelDocument document;
  final Map<String, dynamic> sampleData;
  final double pixelRatio;

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> {
  static const _debounceDuration = Duration(milliseconds: 300);

  Timer? _debounce;
  int _requestId = 0;
  Uint8List? _png;
  Object? _error;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_render);
  }

  @override
  void didUpdateWidget(covariant LivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        !_sameData(oldWidget.sampleData, widget.sampleData) ||
        oldWidget.pixelRatio != widget.pixelRatio) {
      _debounce?.cancel();
      _debounce = Timer(_debounceDuration, _render);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  static bool _sameData(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value)
        return false;
    }
    return true;
  }

  Future<void> _render() async {
    if (!mounted) return;
    final requestId = ++_requestId;
    Uint8List? png;
    Object? error;
    try {
      const layoutEngine = LabelLayoutEngine();
      final resolved = layoutEngine.resolve(widget.document, widget.sampleData);
      const renderer = CanvasRenderer();
      png = await renderer.render(
        resolved,
        CanvasRendererOptions(pixelRatio: widget.pixelRatio),
      );
    } catch (e) {
      error = e;
    }
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _error = error;
      if (png != null) _png = png;
    });
  }

  @override
  Widget build(BuildContext context) {
    final png = _png;
    if (png == null) {
      if (_error != null) return _buildError(context);
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Image.memory(png, gaplessPlayback: true)),
        if (_error != null) _buildError(context, compact: true),
      ],
    );
  }

  Widget _buildError(BuildContext context, {bool compact = false}) {
    final colors = Theme.of(context).colorScheme;
    final message = Text(
      '$_error',
      textAlign: TextAlign.center,
      style: TextStyle(color: colors.onErrorContainer),
    );
    return compact
        ? Container(
            width: double.infinity,
            color: colors.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: message,
          )
        : Center(
            child: Padding(padding: const EdgeInsets.all(16), child: message),
          );
  }
}
