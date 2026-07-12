import 'package:flutter/material.dart';

/// A width-constrained, resizable and collapsible side panel — the
/// building block behind `label_designer`'s layers and properties/preview
/// sidebars (see `docs/ARCHITECTURE.md` section 7: a "componente visual
/// puro" belongs in this package, not in `label_designer` itself).
///
/// [width]/[onWidthChanged] and [collapsed]/[onCollapsedChanged] are
/// externally controlled — this widget holds no state of its own beyond
/// what it's given, the same pattern every other widget in this package
/// follows. The caller decides where that state actually lives (session
/// UI state, not the `LabelDocument` — resizing a sidebar isn't
/// undo-able, same category as `ViewportStore`'s zoom/pan).
class ResizablePanel extends StatelessWidget {
  const ResizablePanel({
    super.key,
    required this.child,
    required this.width,
    required this.onWidthChanged,
    required this.minWidth,
    required this.maxWidth,
    required this.collapsed,
    required this.onCollapsedChanged,
    this.resizeHandleOnLeft = false,
  }) : assert(minWidth <= maxWidth, 'minWidth must be <= maxWidth');

  final Widget child;

  /// Current expanded width — ignored while [collapsed] is `true` (the
  /// caller should keep this value around anyway, so expanding restores
  /// it instead of resetting to some default).
  final double width;
  final ValueChanged<double> onWidthChanged;
  final double minWidth;
  final double maxWidth;
  final bool collapsed;
  final ValueChanged<bool> onCollapsedChanged;

  /// Whether the drag/collapse handle sits on the panel's left edge (for
  /// a panel docked on the right side of the screen) instead of the
  /// right edge (the default, for a panel docked on the left).
  final bool resizeHandleOnLeft;

  static const double collapsedWidth = 32;
  static const double _handleWidth = 20;

  Widget _handleButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return SizedBox(
        width: collapsedWidth,
        child: Align(
          alignment: Alignment.topCenter,
          child: _handleButton(
            context,
            icon: resizeHandleOnLeft
                ? Icons.chevron_left
                : Icons.chevron_right,
            tooltip: 'Expandir painel',
            onPressed: () => onCollapsedChanged(false),
          ),
        ),
      );
    }

    final handle = MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          final delta = resizeHandleOnLeft
              ? -details.delta.dx
              : details.delta.dx;
          onWidthChanged((width + delta).clamp(minWidth, maxWidth));
        },
        child: SizedBox(
          width: _handleWidth,
          child: Align(
            alignment: Alignment.topCenter,
            child: _handleButton(
              context,
              icon: resizeHandleOnLeft
                  ? Icons.chevron_right
                  : Icons.chevron_left,
              tooltip: 'Recolher painel',
              onPressed: () => onCollapsedChanged(true),
            ),
          ),
        ),
      ),
    );

    final content = SizedBox(width: width, child: child);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: resizeHandleOnLeft ? [handle, content] : [content, handle],
    );
  }
}
