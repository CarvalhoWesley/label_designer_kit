import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_layout_engine/label_layout_engine.dart';
import 'package:label_renderer/label_renderer.dart';
import 'package:label_renderer_canvas/label_renderer_canvas.dart';

/// Live preview of a [LabelDocument]: the exact same pipeline used for a
/// PNG/JPEG export job, `LabelLayoutEngine` → `CanvasRenderer`, run against
/// [sampleData] and shown via `Image.memory` (see `docs/ARCHITECTURE.md`
/// section 16). By construction, whatever bug would show up in a printed
/// label shows up here identically — there is no separate "editor drawing
/// code" for the preview to diverge from.
///
/// [document] and [sampleData] are plain values, not stores: this widget
/// doesn't know about `label_designer_state`/MobX (see section 6 — it only
/// depends on `label_layout_engine` and `label_renderer_canvas`). The
/// caller is expected to observe its own document source and rebuild this
/// widget with a new [document] on change; resolving+rendering is async
/// work, so redundant rebuilds are coalesced with [debounce] rather than
/// re-run on every one.
class LabelPreview extends StatefulWidget {
  const LabelPreview({
    super.key,
    required this.document,
    this.sampleData = const {},
    this.debounce = const Duration(milliseconds: 300),
    this.rendererOptions = const CanvasRendererOptions(),
    this.layoutEngine = const LabelLayoutEngine(),
    this.renderer = const CanvasRenderer(),
    this.errorBuilder,
  });

  final LabelDocument document;
  final Map<String, dynamic> sampleData;
  final Duration debounce;
  final RendererOptions rendererOptions;
  final LabelLayoutEngine layoutEngine;
  final LabelRenderer renderer;

  /// Builds the widget shown when resolving/rendering [document] fails
  /// (e.g. a [LayoutException] from an element with zero-or-negative
  /// resolved dimensions). Defaults to a centered error message.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  State<LabelPreview> createState() => _LabelPreviewState();
}

class _LabelPreviewState extends State<LabelPreview> {
  Timer? _debounceTimer;
  int _requestId = 0;

  Uint8List? _lastPng;
  Object? _error;
  bool _isRendering = false;

  @override
  void initState() {
    super.initState();
    // Deferred: `resolve()` can throw synchronously (e.g. LayoutException),
    // and calling `_render` directly here would then call `setState` back
    // inside `initState`'s own call stack, before the first build — Flutter
    // disallows that. A microtask guarantees `_render` always runs after
    // this build completes, success or failure.
    scheduleMicrotask(_render);
  }

  @override
  void didUpdateWidget(covariant LabelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        !_sameData(oldWidget.sampleData, widget.sampleData)) {
      _scheduleRender();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  static bool _sameData(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  void _scheduleRender() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, _render);
  }

  Future<void> _render() async {
    if (!mounted) return;
    final requestId = ++_requestId;
    setState(() => _isRendering = true);

    Uint8List? png;
    Object? error;
    try {
      final resolved = widget.layoutEngine.resolve(
        widget.document,
        widget.sampleData,
      );
      png = await widget.renderer.render(resolved, widget.rendererOptions);
    } catch (e) {
      error = e;
    }

    if (!mounted || requestId != _requestId) return;
    setState(() {
      _isRendering = false;
      _error = error;
      // Keep the last good PNG visible on error / while a new render is in
      // flight, rather than flashing a blank widget between renders.
      if (png != null) _lastPng = png;
    });
  }

  @override
  Widget build(BuildContext context) {
    final png = _lastPng;
    if (png == null) {
      if (_error != null) return _buildError(context, _error!);
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.memory(png, gaplessPlayback: true),
        if (_error != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildError(context, _error!, compact: true),
          )
        else if (_isRendering)
          const Positioned(
            right: 8,
            top: 8,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error, {
    bool compact = false,
  }) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error);
    }
    final colors = Theme.of(context).colorScheme;
    final message = Text(
      '$error',
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
