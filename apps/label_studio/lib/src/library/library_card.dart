import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'library_entry.dart';

/// One card in the library grid: thumbnail (from
/// `DocumentMetadata.thumbnailBase64`, stamped by `LibraryRepository` on
/// every save), name, last-updated date, and a menu for the actions that
/// don't need the full editor — duplicate, export, print, delete.
class LibraryCard extends StatelessWidget {
  const LibraryCard({
    super.key,
    required this.entry,
    required this.onOpen,
    required this.onDuplicate,
    required this.onExport,
    required this.onPrint,
    required this.onDelete,
  });

  final LibraryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onPrint;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumbnail = entry.document.metadata.thumbnailBase64;
    final updatedAt = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(entry.document.metadata.updatedAt.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: thumbnail == null
                    ? const Center(
                        child: Icon(Icons.label_outline, size: 48),
                      )
                    : Center(
                        child: Image.memory(
                          base64Decode(thumbnail),
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.document.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Atualizado em $updatedAt',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<VoidCallback>(
                    onSelected: (action) => action(),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: onOpen,
                        child: const ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: onDuplicate,
                        child: const ListTile(
                          leading: Icon(Icons.copy_outlined),
                          title: Text('Duplicar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: onExport,
                        child: const ListTile(
                          leading: Icon(Icons.ios_share),
                          title: Text('Exportar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: onPrint,
                        child: const ListTile(
                          leading: Icon(Icons.print_outlined),
                          title: Text('Imprimir'),
                        ),
                      ),
                      PopupMenuItem(
                        value: onDelete,
                        child: const ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Excluir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
