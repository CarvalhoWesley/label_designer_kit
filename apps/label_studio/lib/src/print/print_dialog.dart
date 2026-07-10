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
/// roll — see `docs/ARCHITECTURE.md`, "colunas de rolo"), "Cópias" stops
/// meaning "ask the printer to repeat the same image in place" and instead
/// becomes the total label count, tiled across columns via
/// `LabelLayoutEngine.resolveBatch` and sent to the printer one physical
/// row at a time — see [_print]. "Um valor diferente por etiqueta" mode
/// additionally lets each of those labels carry its own data instead of
/// all being identical.
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
  /// column — when it does, `_print` always tiles across columns via
  /// `LabelLayoutEngine.resolveBatch` instead of resolving a single label.
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

      if (_hasColumns) {
        // "Cópias" *is* the label count here: each entry in `records`
        // becomes one physical label, tiled across `page.columns` by
        // resolveBatch — 1 -> column 1; 2 -> columns 1+2; 3 -> columns
        // 1+2, then column 1 of the next row; and so on. `_batchMode` only
        // changes *what* fills each of those labels (every one identical
        // to `_sampleData`, or a distinct record per label); it never
        // multiplies the row count on top of that.
        final records = _batchMode
            ? _records
            : List.generate(_copies, (_) => _sampleData);
        final rows = layoutEngine.resolveBatch(widget.document, records);
        // copies: 1 — the row count above already *is* the requested
        // quantity, so the printer must not additionally repeat each row.
        for (final resolved in rows) {
          await _renderAndSend(resolved, copies: 1);
        }
      } else {
        // Single-column roll: one resolve(), and the printer/driver's own
        // repeat mechanism (PPLA's `Q`, the PDF driver's `copies`) prints
        // it _copies times — cheaper than rendering N identical documents.
        final resolved = layoutEngine.resolve(widget.document, _sampleData);
        await _renderAndSend(resolved, copies: _copies);
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

  Future<void> _renderAndSend(
    ResolvedDocument resolved, {
    required int copies,
  }) async {
    switch (_format) {
      case _PrintFormat.pdf:
        const renderer = PdfRenderer();
        final bytes = await renderer.render(
          resolved,
          const PdfRendererOptions(),
        );
        await WindowsPdfPrintTransport(
          copies: copies,
        ).send(bytes, target: _selectedPrinter);
      case _PrintFormat.ppla:
        const renderer = ArgoxRenderer();
        final bytes = await renderer.render(
          resolved,
          ArgoxRendererOptions(
            darkness: _darkness,
            copies: copies,
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
                    if (_hasColumns &&
                        widget.document.variables.isNotEmpty) ...[
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Um valor diferente por etiqueta'),
                        subtitle: const Text(
                          'Em vez de repetir os mesmos dados em todas as '
                          'etiquetas do lote, informe um registro por '
                          'etiqueta (a quantidade vira o total de registros).',
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
    // In "um valor diferente por etiqueta" mode, the label count is however
    // many records were entered below, not this slider — showing both
    // would be two conflicting quantity controls on screen at once.
    final showCopies = !(_hasColumns && _batchMode);
    switch (format) {
      case _PrintFormat.pdf:
        return [if (showCopies) _copiesField()];
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
          if (showCopies) _copiesField(),
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

  /// The "Cópias"/"Quantidade de etiquetas" slider. On a single-column
  /// roll it's a literal copy count handed to the printer/driver. On a
  /// multi-column roll (outside "um valor diferente por etiqueta" mode)
  /// it *is* the total number of labels to print, tiled across
  /// `page.columns` by [_print] — hence the different label/hint text.
  Widget _copiesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_hasColumns ? 'Quantidade de etiquetas' : 'Cópias'),
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
        if (_hasColumns)
          Text(
            'Distribuídas automaticamente pelas ${widget.document.page.columns} '
            'colunas do rolo.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
      ],
    );
  }

  /// One [SampleDataForm] row per record, for "um valor diferente por
  /// etiqueta" mode — only shown when the document declares variables
  /// (see the `SwitchListTile` gating `_batchMode` above).
  Widget _buildBatchRecords(BuildContext context) {
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
