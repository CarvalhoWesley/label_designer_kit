import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:label_designer_kit/label_designer_kit.dart' hide EdgeInsets;

import '../common/live_preview.dart';
import '../common/sample_data_form.dart';

enum _ExportFormat { label, pdf, png, ppla }

extension on _ExportFormat {
  String get label => switch (this) {
    _ExportFormat.label => 'Projeto (.label)',
    _ExportFormat.pdf => 'PDF vetorial',
    _ExportFormat.png => 'Imagem (PNG)',
    _ExportFormat.ppla => 'Comando de impressora (PPLA)',
  };

  String get extension => switch (this) {
    _ExportFormat.label => 'label',
    _ExportFormat.pdf => 'pdf',
    _ExportFormat.png => 'png',
    _ExportFormat.ppla => 'prn',
  };
}

/// Renders [document] into a chosen output format — the `.label` project
/// file itself, or a PDF/PNG/PPLA render resolved with sample data the user
/// can override — and saves the bytes to a location the user picks, for
/// external applications to consume.
class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key, required this.document});

  final LabelDocument document;

  static Future<void> show(BuildContext context, LabelDocument document) {
    return showDialog<void>(
      context: context,
      builder: (_) => ExportDialog(document: document),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  _ExportFormat _format = _ExportFormat.pdf;
  Map<String, dynamic> _sampleData = const {};
  double _pngPixelRatio = 2;
  int _darkness = 10;
  int _copies = 1;
  ArgoxTransferType _transferType = ArgoxTransferType.directThermal;
  bool _isExporting = false;

  Future<Uint8List> _renderBytes() async {
    switch (_format) {
      case _ExportFormat.label:
        const codec = LabelDocumentCodec();
        return Uint8List.fromList(utf8.encode(codec.encode(widget.document)));
      case _ExportFormat.pdf:
        const layoutEngine = LabelLayoutEngine();
        final resolved = layoutEngine.resolve(widget.document, _sampleData);
        const renderer = PdfRenderer();
        return renderer.render(resolved, const PdfRendererOptions());
      case _ExportFormat.png:
        const layoutEngine = LabelLayoutEngine();
        final resolved = layoutEngine.resolve(widget.document, _sampleData);
        const renderer = CanvasRenderer();
        return renderer.render(
          resolved,
          CanvasRendererOptions(pixelRatio: _pngPixelRatio),
        );
      case _ExportFormat.ppla:
        const layoutEngine = LabelLayoutEngine();
        final resolved = layoutEngine.resolve(widget.document, _sampleData);
        const renderer = ArgoxRenderer();
        return renderer.render(
          resolved,
          ArgoxRendererOptions(
            darkness: _darkness,
            copies: _copies,
            transferType: _transferType,
          ),
        );
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await _renderBytes();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Exportar etiqueta',
        fileName: '${widget.document.name}.${_format.extension}',
        type: FileType.custom,
        allowedExtensions: [_format.extension],
      );
      if (savePath != null) {
        await File(savePath).writeAsBytes(bytes);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savePath == null
                ? 'Exportação cancelada'
                : 'Exportado em $savePath (${bytes.length} bytes)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao exportar: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar etiqueta'),
      content: SizedBox(
        width: 680,
        height: 440,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<_ExportFormat>(
                      value: _format,
                      decoration: const InputDecoration(labelText: 'Formato'),
                      items: [
                        for (final format in _ExportFormat.values)
                          DropdownMenuItem(
                            value: format,
                            child: Text(format.label),
                          ),
                      ],
                      onChanged: (format) =>
                          setState(() => _format = format ?? _format),
                    ),
                    const SizedBox(height: 12),
                    ..._optionsFor(_format),
                    if (widget.document.variables.isNotEmpty &&
                        _format != _ExportFormat.label) ...[
                      const Divider(height: 24),
                      Text(
                        'Dados de amostra',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SampleDataForm(
                        variables: widget.document.variables,
                        onChanged: (data) => setState(() => _sampleData = data),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _format == _ExportFormat.label
                  ? const Center(
                      child: Icon(Icons.description_outlined, size: 96),
                    )
                  : ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: LivePreview(
                        document: widget.document,
                        sampleData: _sampleData,
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isExporting ? null : _export,
          child: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Exportar...'),
        ),
      ],
    );
  }

  List<Widget> _optionsFor(_ExportFormat format) {
    switch (format) {
      case _ExportFormat.label:
        return const [
          Text(
            'Salva o documento editável, para reabrir aqui ou em outra instância deste app.',
          ),
        ];
      case _ExportFormat.pdf:
        return const [
          Text(
            'PDF vetorial pronto para visualização ou impressão em qualquer sistema.',
          ),
        ];
      case _ExportFormat.png:
        return [
          const Text('Bitmap da etiqueta renderizada.'),
          const SizedBox(height: 8),
          DropdownButtonFormField<double>(
            value: _pngPixelRatio,
            decoration: const InputDecoration(labelText: 'Resolução'),
            items: const [
              DropdownMenuItem(value: 1.0, child: Text('1x')),
              DropdownMenuItem(value: 2.0, child: Text('2x')),
              DropdownMenuItem(value: 3.0, child: Text('3x')),
            ],
            onChanged: (value) =>
                setState(() => _pngPixelRatio = value ?? _pngPixelRatio),
          ),
        ];
      case _ExportFormat.ppla:
        return [
          const Text('Comando PPLA pronto para enviar a uma impressora Argox.'),
          const SizedBox(height: 8),
          Text('Escurecimento (H${_darkness.toString().padLeft(2, '0')})'),
          Slider(
            value: _darkness.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            label: '$_darkness',
            onChanged: (value) => setState(() => _darkness = value.round()),
          ),
          Row(
            children: [
              const Text('Cópias'),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _copies.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '$_copies',
                  onChanged: (value) => setState(() => _copies = value.round()),
                ),
              ),
              SizedBox(width: 32, child: Text('$_copies')),
            ],
          ),
          DropdownButtonFormField<ArgoxTransferType>(
            value: _transferType,
            decoration: const InputDecoration(labelText: 'Tipo de impressão'),
            items: const [
              DropdownMenuItem(
                value: ArgoxTransferType.directThermal,
                child: Text('Térmica direta'),
              ),
              DropdownMenuItem(
                value: ArgoxTransferType.thermalTransfer,
                child: Text('Transferência térmica (ribbon)'),
              ),
            ],
            onChanged: (value) =>
                setState(() => _transferType = value ?? _transferType),
          ),
        ];
    }
  }
}
