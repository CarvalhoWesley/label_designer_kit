import 'package:flutter/material.dart';

import '../editor/editor_screen.dart';
import '../export/export_dialog.dart';
import '../print/print_dialog.dart';
import 'library_card.dart';
import 'library_entry.dart';
import 'library_repository.dart';

/// Home screen: the local library of saved templates, with new/open/
/// duplicate/delete/export/print — see `docs/ARCHITECTURE.md` section 20
/// for why none of this lives in `label_designer` itself.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.repository});

  final LibraryRepository repository;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<LibraryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _entriesFuture = widget.repository.list();
    });
  }

  Future<void> _openEntry(LibraryEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(repository: widget.repository, entry: entry),
      ),
    );
    _refresh();
  }

  Future<void> _createAndOpen() async {
    final entry = await widget.repository.create();
    if (!mounted) return;
    await _openEntry(entry);
  }

  Future<void> _duplicate(LibraryEntry entry) async {
    await widget.repository.duplicate(entry);
    _refresh();
  }

  Future<void> _delete(LibraryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir etiqueta'),
        content: Text('Excluir "${entry.document.name}" permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.delete(entry);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas etiquetas')),
      body: FutureBuilder<List<LibraryEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Falha ao carregar biblioteca: ${snapshot.error}'));
          }
          final entries = snapshot.data ?? const [];
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.label_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text('Nenhuma etiqueta ainda.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _createAndOpen,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova etiqueta'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 220,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return LibraryCard(
                entry: entry,
                onOpen: () => _openEntry(entry),
                onDuplicate: () => _duplicate(entry),
                onExport: () => ExportDialog.show(context, entry.document),
                onPrint: () => PrintDialog.show(context, entry.document),
                onDelete: () => _delete(entry),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAndOpen,
        icon: const Icon(Icons.add),
        label: const Text('Nova etiqueta'),
      ),
    );
  }
}
