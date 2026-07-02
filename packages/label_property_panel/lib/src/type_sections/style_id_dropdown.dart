import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

/// Picks a [LabelStyle] by id (or "Nenhum" for no reference), shared by
/// every text-like element's type section ([TextElement], [VariableElement],
/// [DateElement], [TimeElement]).
class StyleIdDropdown extends StatelessWidget {
  const StyleIdDropdown({
    super.key,
    required this.styleId,
    required this.styles,
    required this.onChanged,
  });

  final String? styleId;
  final List<LabelStyle> styles;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: styleId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Estilo nomeado',
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(child: Text('Nenhum')),
        for (final style in styles)
          DropdownMenuItem<String?>(value: style.id, child: Text(style.name)),
      ],
      onChanged: onChanged,
    );
  }
}
