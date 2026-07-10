import 'package:flutter/material.dart';
import 'package:label_designer_kit/label_designer_kit.dart' hide EdgeInsets;

import '../export/export_dialog.dart';
import '../library/library_entry.dart';
import '../library/library_repository.dart';
import '../print/print_dialog.dart';

/// Full visual editor for one library entry: `LabelDesigner` (canvas,
/// layers, properties — see `packages/label_designer`) plus this app's own
/// save/export/print, which `LabelDesigner` deliberately doesn't know how
/// to do on its own.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.repository, required this.entry});

  final LibraryRepository repository;
  final LibraryEntry entry;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Tracks the most recently *saved* version, for the app bar title and for
  // Export/Print (which act on the last save, not on in-progress edits —
  // `LabelDesigner` only ever hands its document out through `onSave`).
  late LibraryEntry _lastSaved = widget.entry;
  bool _isSaving = false;

  Future<void> _handleSave(LabelDocument document) async {
    setState(() => _isSaving = true);
    try {
      final saved = await widget.repository.save(
        id: widget.entry.id,
        document: document,
      );
      if (!mounted) return;
      setState(() => _lastSaved = saved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Etiqueta salva')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lastSaved.document.name),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Exportar a última versão salva',
            icon: const Icon(Icons.ios_share),
            onPressed: () => ExportDialog.show(context, _lastSaved.document),
          ),
          IconButton(
            tooltip: 'Imprimir a última versão salva',
            icon: const Icon(Icons.print),
            onPressed: () => PrintDialog.show(context, _lastSaved.document),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // `widget.entry.document` (fixed for the lifetime of this screen) is
      // intentional, not `_lastSaved.document`: `LabelDesigner` resets its
      // undo history whenever the `document` it's given changes identity
      // (see its `didUpdateWidget`), which would happen right after every
      // save if it were fed the ever-updating `_lastSaved` instead.
      body: LabelDesigner(document: widget.entry.document, onSave: _handleSave),
    );
  }
}
