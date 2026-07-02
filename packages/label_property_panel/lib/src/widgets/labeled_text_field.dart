import 'package:flutter/material.dart';

/// A single/multi-line text input with a compact label, for string
/// properties (name, content, expression, ...) in the property panel.
///
/// Unlike [LabeledNumberField], any text is valid, so this commits on
/// every keystroke via [onChanged] rather than waiting for submit —
/// callers that need undo coalescing debounce on their own end.
class LabeledTextField extends StatefulWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<LabeledTextField> createState() => _LabeledTextFieldState();
}

class _LabeledTextFieldState extends State<LabeledTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant LabeledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label, isDense: true),
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
    );
  }
}
