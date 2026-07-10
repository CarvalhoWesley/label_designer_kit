import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart' hide EdgeInsets;
import 'package:label_core/label_core.dart' as core show EdgeInsets;
import 'package:label_property_panel/label_property_panel.dart';

/// Dialog for editing document-level metadata: the label's name and its
/// [PageConfig] (size, dpi, orientation, margins). Neither is tied to a
/// specific [LabelElement], so there's no natural home for them in
/// `label_property_panel`'s per-element sections — this dialog is
/// `label_designer`'s own, opened from [DesignerToolbar].
///
/// Purely a form: it reads an initial snapshot and returns the edited
/// values via [onSave] when the user confirms — the caller decides how to
/// apply them (`HistoryStore.updateDocumentMeta`), keeping every edit
/// undo-able by construction.
class LabelPropertiesDialog extends StatefulWidget {
  const LabelPropertiesDialog({
    super.key,
    required this.name,
    required this.page,
    required this.onSave,
  });

  final String name;
  final PageConfig page;
  final void Function(String name, PageConfig page) onSave;

  static Future<void> show(
    BuildContext context, {
    required String name,
    required PageConfig page,
    required void Function(String name, PageConfig page) onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          LabelPropertiesDialog(name: name, page: page, onSave: onSave),
    );
  }

  @override
  State<LabelPropertiesDialog> createState() => _LabelPropertiesDialogState();
}

class _LabelPropertiesDialogState extends State<LabelPropertiesDialog> {
  late String _name = widget.name;
  late PageConfig _page = widget.page;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Propriedades da etiqueta'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledTextField(
                label: 'Nome',
                value: _name,
                onChanged: (value) => _name = value,
              ),
              const SizedBox(height: 16),
              PropertyPanelSection(
                title: 'Tamanho',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LabeledNumberField(
                          label: 'Largura',
                          value: _page.width,
                          min: 1,
                          suffixText: 'mm',
                          onChanged: (value) => setState(
                            () => _page = _page.copyWith(width: value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LabeledNumberField(
                          label: 'Altura',
                          value: _page.height,
                          min: 1,
                          suffixText: 'mm',
                          onChanged: (value) => setState(
                            () => _page = _page.copyWith(height: value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<Dpi>(
                    value: _page.dpi,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'DPI',
                      isDense: true,
                    ),
                    items: [
                      for (final dpi in Dpi.values)
                        DropdownMenuItem(
                          value: dpi,
                          child: Text('${dpi.value}'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _page = _page.copyWith(dpi: value));
                      }
                    },
                  ),
                  DropdownButtonFormField<PageOrientation>(
                    value: _page.orientation,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Orientação',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: PageOrientation.portrait,
                        child: Text('Retrato'),
                      ),
                      DropdownMenuItem(
                        value: PageOrientation.landscape,
                        child: Text('Paisagem'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(
                          () => _page = _page.copyWith(orientation: value),
                        );
                      }
                    },
                  ),
                ],
              ),
              PropertyPanelSection(
                title: 'Colunas do rolo',
                children: [
                  Text(
                    'Quantas etiquetas o rolo tem lado a lado — usado ao '
                    'imprimir vários registros de uma vez, distribuindo-os '
                    'automaticamente pelas colunas.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LabeledNumberField(
                          label: 'Colunas',
                          value: _page.columns.toDouble(),
                          min: 1,
                          onChanged: (value) => setState(
                            () =>
                                _page = _page.copyWith(columns: value.round()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LabeledNumberField(
                          label: 'Espaço entre colunas',
                          value: _page.columnGap,
                          min: 0,
                          suffixText: 'mm',
                          onChanged: (value) => setState(
                            () => _page = _page.copyWith(columnGap: value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PropertyPanelSection(
                title: 'Margens',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _marginField(
                          'Superior',
                          (v) => core.EdgeInsets(
                            top: v,
                            right: _page.margins.right,
                            bottom: _page.margins.bottom,
                            left: _page.margins.left,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _marginField(
                          'Direita',
                          (v) => core.EdgeInsets(
                            top: _page.margins.top,
                            right: v,
                            bottom: _page.margins.bottom,
                            left: _page.margins.left,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _marginField(
                          'Inferior',
                          (v) => core.EdgeInsets(
                            top: _page.margins.top,
                            right: _page.margins.right,
                            bottom: v,
                            left: _page.margins.left,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _marginField(
                          'Esquerda',
                          (v) => core.EdgeInsets(
                            top: _page.margins.top,
                            right: _page.margins.right,
                            bottom: _page.margins.bottom,
                            left: v,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_name, _page);
            Navigator.of(context).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _marginField(
    String label,
    core.EdgeInsets Function(double value) apply,
  ) {
    final current = switch (label) {
      'Superior' => _page.margins.top,
      'Direita' => _page.margins.right,
      'Inferior' => _page.margins.bottom,
      _ => _page.margins.left,
    };
    return LabeledNumberField(
      label: label,
      value: current,
      min: 0,
      suffixText: 'mm',
      onChanged: (value) =>
          setState(() => _page = _page.copyWith(margins: apply(value))),
    );
  }
}
