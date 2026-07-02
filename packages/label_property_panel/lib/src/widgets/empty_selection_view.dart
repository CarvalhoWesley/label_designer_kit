import 'package:flutter/material.dart';

/// Shown in [LabelPropertyPanel] when [SelectionStore.selectedIds] is
/// empty.
class EmptySelectionView extends StatelessWidget {
  const EmptySelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Selecione um elemento para editar suas propriedades.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }
}
