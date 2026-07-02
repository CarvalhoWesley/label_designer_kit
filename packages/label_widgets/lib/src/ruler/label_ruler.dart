import 'package:flutter/material.dart';

import 'ruler_ticks.dart';

/// Which edge of the canvas a [LabelRuler] is measuring.
enum RulerAxis { horizontal, vertical }

/// A horizontal or vertical millimeter ruler for `label_canvas`, showing
/// tick marks at [minorIntervalMm] and numeric labels at
/// [majorIntervalMm], positioned by [pixelsPerMm] (zoom) and
/// [originOffset] (where 0mm currently sits, i.e. pan).
///
/// Must be laid out with a bounded extent along its own axis (e.g. inside
/// a `Row`/`Column` with `Expanded`), since it reads that extent via
/// [LayoutBuilder] to know how many ticks to draw.
class LabelRuler extends StatelessWidget {
  const LabelRuler({
    super.key,
    required this.axis,
    required this.pixelsPerMm,
    this.originOffset = 0,
    this.majorIntervalMm = 10,
    this.minorIntervalMm = 1,
    this.thickness = 20,
    this.backgroundColor,
    this.tickColor,
    this.labelStyle,
  });

  final RulerAxis axis;
  final double pixelsPerMm;
  final double originOffset;
  final double majorIntervalMm;
  final double minorIntervalMm;
  final double thickness;
  final Color? backgroundColor;
  final Color? tickColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = axis == RulerAxis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final size = axis == RulerAxis.horizontal
            ? Size(extent, thickness)
            : Size(thickness, extent);
        return CustomPaint(
          size: size,
          painter: _RulerPainter(
            axis: axis,
            pixelsPerMm: pixelsPerMm,
            originOffset: originOffset,
            majorIntervalMm: majorIntervalMm,
            minorIntervalMm: minorIntervalMm,
            backgroundColor:
                backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
            tickColor: tickColor ?? theme.colorScheme.outline,
            labelStyle:
                labelStyle ??
                theme.textTheme.labelSmall ??
                const TextStyle(fontSize: 9),
          ),
        );
      },
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.axis,
    required this.pixelsPerMm,
    required this.originOffset,
    required this.majorIntervalMm,
    required this.minorIntervalMm,
    required this.backgroundColor,
    required this.tickColor,
    required this.labelStyle,
  });

  final RulerAxis axis;
  final double pixelsPerMm;
  final double originOffset;
  final double majorIntervalMm;
  final double minorIntervalMm;
  final Color backgroundColor;
  final Color tickColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    if (pixelsPerMm <= 0) return;

    final extent = axis == RulerAxis.horizontal ? size.width : size.height;
    final thickness = axis == RulerAxis.horizontal ? size.height : size.width;
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;

    final startMm = (0 - originOffset) / pixelsPerMm;
    final endMm = (extent - originOffset) / pixelsPerMm;

    for (final mm in rulerTicks(
      startMm: startMm,
      endMm: endMm,
      intervalMm: minorIntervalMm,
    )) {
      final pos = originOffset + mm * pixelsPerMm;
      final major = isMajorTick(mm, majorIntervalMm);
      final tickLength = thickness * (major ? 0.6 : 0.3);

      if (axis == RulerAxis.horizontal) {
        canvas.drawLine(
          Offset(pos, thickness - tickLength),
          Offset(pos, thickness),
          tickPaint,
        );
      } else {
        canvas.drawLine(
          Offset(thickness - tickLength, pos),
          Offset(thickness, pos),
          tickPaint,
        );
      }

      if (major) {
        final textPainter = TextPainter(
          text: TextSpan(text: mm.round().toString(), style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelOffset = axis == RulerAxis.horizontal
            ? Offset(pos + 2, 1)
            : Offset(1, pos + 2);
        textPainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return axis != oldDelegate.axis ||
        pixelsPerMm != oldDelegate.pixelsPerMm ||
        originOffset != oldDelegate.originOffset ||
        majorIntervalMm != oldDelegate.majorIntervalMm ||
        minorIntervalMm != oldDelegate.minorIntervalMm ||
        backgroundColor != oldDelegate.backgroundColor ||
        tickColor != oldDelegate.tickColor ||
        labelStyle != oldDelegate.labelStyle;
  }
}
