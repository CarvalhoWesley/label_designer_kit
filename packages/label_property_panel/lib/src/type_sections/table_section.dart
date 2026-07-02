import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;

import '../widgets/labeled_number_field.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [TableElement]: the data binding and row
/// height. Column definitions are shown read-only for now — layout/
/// rendering support for tables is deferred to a later roadmap step (see
/// `docs/ROADMAP.md`), so a full column editor isn't built yet either.
class TableSection extends StatelessWidget {
  const TableSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final TableElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Tabela',
      children: [
        LabeledTextField(
          label: 'Campo de dados (lista de linhas)',
          value: element.dataField,
          onChanged: (value) => onChange(
            (e) => (e as TableElement).copyWith(dataField: value),
          ),
        ),
        LabeledNumberField(
          label: 'Altura da linha',
          value: element.rowHeight,
          min: 0.1,
          suffixText: 'mm',
          onChanged: (value) => onChange(
            (e) => (e as TableElement).copyWith(rowHeight: value),
          ),
        ),
        Text('Colunas', style: Theme.of(context).textTheme.bodySmall),
        for (final column in element.columns)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${column.header} → ${column.dataField} '
              '(${column.width.toStringAsFixed(0)}mm)',
            ),
          ),
      ],
    );
  }
}
