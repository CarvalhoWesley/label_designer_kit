import 'package:flutter/material.dart';

/// A numeric input with a compact label, for millimeter/degree/etc.
/// properties (position, size, rotation, ...) in the property panel.
///
/// Invalid input (unparsable, or outside [min]/[max]) is rejected on
/// submit: the field snaps back to [value] instead of calling
/// [onChanged], so callers never observe an out-of-range value.
class LabeledNumberField extends StatefulWidget {
  const LabeledNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.suffixText,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double? min;
  final double? max;
  final String? suffixText;

  @override
  State<LabeledNumberField> createState() => _LabeledNumberFieldState();
}

class _LabeledNumberFieldState extends State<LabeledNumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant LabeledNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _format(double value) =>
      value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);

  void _submit(String text) {
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    final min = widget.min;
    final max = widget.max;
    if (parsed == null ||
        (min != null && parsed < min) ||
        (max != null && parsed > max)) {
      _controller.text = _format(widget.value);
      return;
    }
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.suffixText,
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      onSubmitted: _submit,
      onTapOutside: (_) => _submit(_controller.text),
    );
  }
}
