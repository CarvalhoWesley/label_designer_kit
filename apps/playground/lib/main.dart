import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide EdgeInsets;
import 'package:flutter_label_designer/flutter_label_designer.dart';

void main() => runApp(const PlaygroundApp());

/// Opens a native "Save As" dialog and returns the chosen path, or `null`
/// if the user cancelled. Extracted as a swappable function (rather than
/// called inline) so widget tests can fake it — `FilePicker.platform`
/// drives a real Win32 dialog with no test-harness mock, which would hang
/// or throw under `flutter test`.
typedef SaveFilePicker = Future<String?> Function({
  required String suggestedFileName,
});

Future<String?> _defaultSaveFilePicker({required String suggestedFileName}) {
  return FilePicker.platform.saveFile(
    dialogTitle: 'Salvar etiqueta',
    fileName: suggestedFileName,
    type: FileType.custom,
    allowedExtensions: ['label'],
  );
}

/// Internal sandbox app — see `docs/ARCHITECTURE.md` section 4 and
/// `docs/ROADMAP.md` etapa 14. Never imported by the consuming user
/// project; exists only to run `LabelDesigner` end-to-end by hand during
/// development.
class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({
    super.key,
    this.saveFilePicker = _defaultSaveFilePicker,
  });

  final SaveFilePicker saveFilePicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label Designer Playground',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: PlaygroundPage(saveFilePicker: saveFilePicker),
    );
  }
}

class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({
    super.key,
    this.saveFilePicker = _defaultSaveFilePicker,
  });

  final SaveFilePicker saveFilePicker;

  static const _codec = LabelDocumentCodec();

  /// Runs the full pipeline a consuming app would run at save/print/export
  /// time (see `docs/ARCHITECTURE.md`, seção 20, and `docs/ROADMAP.md`,
  /// etapa 17): saves the encoded `.label` to disk (suggesting the
  /// document's own name as the file name), then resolves it with the
  /// sample values already declared on the document's variables and hands
  /// the resolved layout to two real backends — one raster/vector (PDF,
  /// easy to eyeball) and one command-based (PPLA, what an actual Argox
  /// printer expects).
  ///
  /// No printer transport here on purpose — sending bytes to a physical
  /// printer is the consuming app's job, not this framework's (see the
  /// architecture doc). The `.label` save, on the other hand, *is* real
  /// file I/O — this app is the "projeto do usuário" stand-in the
  /// architecture doc refers to, so it's the right place to demonstrate it.
  Future<void> _handleSave(BuildContext context, LabelDocument document) async {
    final json = _codec.encode(document);
    debugPrint('--- LabelDocument codificado (${json.length} bytes) ---');
    debugPrint(json);

    final savePath = await saveFilePicker(
      suggestedFileName: '${document.name}.label',
    );
    if (savePath != null) {
      // `saveFile` only returns the chosen path on desktop — writing the
      // bytes is left to the caller (see `docs/ARCHITECTURE.md`, seção 20:
      // real file I/O is the consuming app's job, illustrated here by the
      // playground standing in for that app).
      await File(savePath).writeAsString(json);
    }

    final data = {
      for (final variable in document.variables)
        variable.name: variable.defaultValue,
    };
    const layoutEngine = LabelLayoutEngine();
    final resolved = layoutEngine.resolve(document, data);

    const pdfRenderer = PdfRenderer();
    final pdfBytes = await pdfRenderer.render(
      resolved,
      const PdfRendererOptions(),
    );
    debugPrint(
      '--- PDF gerado via label_renderer_pdf (${pdfBytes.length} bytes) ---',
    );

    const argoxRenderer = ArgoxRenderer();
    final pplaBytes = await argoxRenderer.render(
      resolved,
      const ArgoxRendererOptions(),
    );
    debugPrint(
      '--- PPLA gerado via label_renderer_argox (${pplaBytes.length} bytes) ---',
    );

    if (!context.mounted) return;
    final saveStatus = savePath == null
        ? 'salvamento cancelado'
        : 'salvo em $savePath';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'JSON: ${json.length}B ($saveStatus) · PDF: ${pdfBytes.length}B · '
          'PPLA: ${pplaBytes.length}B (ver console)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LabelDesigner(
        document: _sampleDocument(),
        onSave: (document) => _handleSave(context, document),
      ),
    );
  }
}

/// The same product-label fixture used by `label_renderer_canvas`'s
/// end-to-end test (see `docs/ROADMAP.md` etapa 6) — a border, a text
/// element with a `{{ }}` placeholder, a `VariableElement` exercising
/// `.currency()`, and a barcode whose data is itself an expression, with
/// every declared variable already given a sample value so the canvas,
/// property panel and preview all show something meaningful immediately.
LabelDocument _sampleDocument() {
  final now = DateTime.now();
  return LabelDocument(
    name: 'Etiqueta de exemplo',
    page: PageConfig(
      width: 50,
      height: 30,
      dpi: Dpi.dpi203,
      margins: EdgeInsets.all(5),
    ),
    layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
    variables: const [
      LabelVariable(name: 'produto', defaultValue: 'Parafuso Sextavado M6'),
      LabelVariable(name: 'codigo', defaultValue: '7898458151510'),
    ],
    elements: const [
      TextElement(
        id: 'nome',
        name: 'Nome do produto',
        position: Point(x: 0, y: 5),
        size: Size2D(width: 35, height: 5),
        layerId: 'layer-1',
        content: '{{ produto }}',
        style: TextStyleSpec(fontSize: 2.5, bold: true),
      ),
      BarcodeElement(
        id: 'codigo-el',
        name: 'Código de barras',
        position: Point(x: 30, y: 10),
        size: Size2D(width: 25, height: 10),
        rotation: 270,
        layerId: 'layer-1',
        data: '{{ codigo }}',
        symbology: BarcodeSymbology.code128,
      ),
    ],
    metadata: DocumentMetadata(createdAt: now, updatedAt: now),
  );
}
