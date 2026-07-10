import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:label_designer_kit/label_designer_kit.dart' hide EdgeInsets;
import 'package:label_print_transport_windows/label_print_transport_windows.dart';

import '../common/live_preview.dart';
import '../common/sample_data_form.dart';

enum _PrintFormat { pdf, ppla }

/// Resolves [document] with sample data and sends the result straight to a
/// Windows printer via `label_print_transport_windows`: a PDF through the
/// system print pipeline (works with any installed driver), or a raw PPLA
/// byte stream for a directly-connected Argox thermal printer
/// ([WindowsRawPrintTransport], which bypasses Windows' own rendering so
/// the printer gets exactly the bytes `label_renderer_argox` produced).
///
/// When [LabelDocument.page]'s `columns` is more than 1 (a multi-column
/// roll — see `docs/ARCHITECTURE.md`, "colunas de rolo"), this dialog also
/// offers a batch mode: one data record per physical label, tiled across
/// columns via `LabelLayoutEngine.resolveBatch` and sent to the printer one
/// physical row at a time.
class PrintDialog extends StatefulWidget {
  const PrintDialog({super.key, required this.document});

  final LabelDocument document;

  static Future<void> show(BuildContext context, LabelDocument document) {
    return showDialog<void>(
      context: context,
      builder: (_) => PrintDialog(document: document),
    );
  }

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  _PrintFormat _format = _PrintFormat.pdf;
  Map<String, dynamic> _sampleData = const {};
  int _copies = 1;
  int _darkness = 10;
  ArgoxTransferType _transferType = ArgoxTransferType.directThermal;

  /// Whether the roll this document was designed for has more than one
  /// column — when it does, the dialog offers batch printing tiled across
  /// columns via `LabelLayoutEngine.resolveBatch` instead of just the
  /// single-label path.
  bool get _hasColumns => widget.document.page.columns > 1;

  bool _batchMode = false;
  List<Map<String, dynamic>> _records = [const {}];

  String? _selectedPrinter;
  List<String> _printers = const [];
  bool _loadingPrinters = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    List<String> printers;
    try {
      printers = await const WindowsPrinterDiscovery().listAvailable();
    } catch (_) {
      printers = const [];
    }
    if (!mounted) return;
    setState(() {
      _printers = printers;
      _selectedPrinter = printers.isEmpty ? null : printers.first;
      _loadingPrinters = false;
    });
  }

  Future<void> _print() async {
    setState(() => _isPrinting = true);
    try {
      const layoutEngine = LabelLayoutEngine();
      final resolvedRows = _batchMode && _hasColumns
          ? layoutEngine.resolveBatch(widget.document, _records)
          : [layoutEngine.resolve(widget.document, _sampleData)];

      for (final resolved in resolvedRows) {
        switch (_format) {
          case _PrintFormat.pdf:
            const renderer = PdfRenderer();
            final bytes = await renderer.render(
              resolved,
              const PdfRendererOptions(),
            );
            await WindowsPdfPrintTransport(
              copies: _copies,
            ).send(bytes, target: _selectedPrinter);
          case _PrintFormat.ppla:
            const renderer = ArgoxRenderer();
            final bytes = await renderer.render(
              resolved,
              ArgoxRendererOptions(
                darkness: _darkness,
                copies: _copies,
                transferType: _transferType,
                dialect: ArgoxDialect.ppla,
              ),
            );
            await const WindowsRawPrintTransport().send(
              bytes,
              target: _selectedPrinter,
            );
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviado para a impressora')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao imprimir: $e')));
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AlertDialog(
        title: const Text('Imprimir'),
        content: const Text(
          'Impressão direta só está disponível na versão Windows deste app. '
          'Use "Exportar" para gerar o arquivo e imprimir por outro meio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Imprimir etiqueta'),
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
                    _loadingPrinters
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          )
                        : DropdownButtonFormField<String?>(
                            value: _selectedPrinter,
                            decoration: const InputDecoration(
                              labelText: 'Impressora',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Impressora padrão do sistema'),
                              ),
                              for (final printer in _printers)
                                DropdownMenuItem(
                                  value: printer,
                                  child: Text(printer),
                                ),
                            ],
                            onChanged: (printer) =>
                                setState(() => _selectedPrinter = printer),
                          ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<_PrintFormat>(
                      value: _format,
                      decoration: const InputDecoration(labelText: 'Conteúdo'),
                      items: const [
                        DropdownMenuItem(
                          value: _PrintFormat.pdf,
                          child: Text('PDF (driver da impressora)'),
                        ),
                        DropdownMenuItem(
                          value: _PrintFormat.ppla,
                          child: Text('PPLA (comando direto, Argox)'),
                        ),
                      ],
                      onChanged: (format) =>
                          setState(() => _format = format ?? _format),
                    ),
                    const SizedBox(height: 12),
                    ..._optionsFor(_format),
                    if (_hasColumns) ...[
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Impressão em lote'),
                        subtitle: Text(
                          'Rolo com ${widget.document.page.columns} colunas — '
                          'distribui vários registros pelas colunas '
                          'automaticamente.',
                        ),
                        value: _batchMode,
                        onChanged: (value) =>
                            setState(() => _batchMode = value),
                      ),
                    ],
                    if (_batchMode && _hasColumns) ...[
                      const SizedBox(height: 8),
                      _buildBatchRecords(context),
                    ] else if (widget.document.variables.isNotEmpty) ...[
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
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          onPressed: _isPrinting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isPrinting ? null : _print,
          child: _isPrinting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Imprimir'),
        ),
      ],
    );
  }

  List<Widget> _optionsFor(_PrintFormat format) {
    switch (format) {
      case _PrintFormat.pdf:
        return [
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
        ];
      case _PrintFormat.ppla:
        return [
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

  /// Data-entry UI for batch printing: one row per record when the
  /// document declares variables (reusing [SampleDataForm] per row), or
  /// just a count when it doesn't (e.g. printing N identical labels tiled
  /// across the roll's columns).
  Widget _buildBatchRecords(BuildContext context) {
    if (widget.document.variables.isEmpty) {
      return Row(
        children: [
          const Text('Quantidade de etiquetas'),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: _records.length.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_records.length}',
              onChanged: (value) => setState(
                () => _records = List.generate(value.round(), (_) => const {}),
              ),
            ),
          ),
          SizedBox(width: 32, child: Text('${_records.length}')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _records.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${i + 1}'),
                const SizedBox(width: 8),
                Expanded(
                  child: SampleDataForm(
                    // Keyed by index, not a stable record id — removing a
                    // row other than the last one re-seeds that row's form
                    // state from the record that shifted into its slot,
                    // rather than preserving in-progress edits. Acceptable
                    // for this first cut; revisit if that proves annoying.
                    key: ValueKey(i),
                    variables: widget.document.variables,
                    onChanged: (data) => _records[i] = data,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remover registro',
                  onPressed: _records.length <= 1
                      ? null
                      : () => setState(() => _records.removeAt(i)),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() => _records = [..._records, const {}]),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar registro'),
        ),
      ],
    );
  }
}
