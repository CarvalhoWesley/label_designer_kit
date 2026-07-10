import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:label_designer_kit/label_designer_kit.dart' hide EdgeInsets;
import 'package:windows_printer/windows_printer.dart';

import '../common/live_preview.dart';
import '../common/sample_data_form.dart';

enum _PrintFormat { pdf, ppla }

/// Resolves [document] with sample data and sends the result straight to a
/// Windows printer: a PDF through the system print pipeline (works with any
/// installed driver), or a raw PPLA byte stream for a directly-connected
/// Argox thermal printer (see `windows_printer`'s `printRawData`, which
/// bypasses Windows' own rendering so the printer gets exactly the bytes
/// `label_renderer_argox` produced).
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
      printers = await WindowsPrinter.getAvailablePrinters();
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
      final resolved = layoutEngine.resolve(widget.document, _sampleData);
      switch (_format) {
        case _PrintFormat.pdf:
          const renderer = PdfRenderer();
          final bytes = await renderer.render(resolved, const PdfRendererOptions());
          await WindowsPrinter.printPdf(
            printerName: _selectedPrinter,
            data: bytes,
            copies: _copies,
          );
        case _PrintFormat.ppla:
          const renderer = ArgoxRenderer();
          final bytes = await renderer.render(
            resolved,
            ArgoxRendererOptions(
              darkness: _darkness,
              copies: _copies,
              transferType: _transferType,
            ),
          );
          await WindowsPrinter.printRawData(
            printerName: _selectedPrinter,
            data: bytes,
            useRawDatatype: true,
          );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enviado para a impressora')));
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
                                DropdownMenuItem(value: printer, child: Text(printer)),
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
                    if (widget.document.variables.isNotEmpty) ...[
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
}
