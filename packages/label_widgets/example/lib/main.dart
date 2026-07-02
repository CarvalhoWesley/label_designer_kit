import 'package:flutter/material.dart';
import 'package:label_widgets/label_widgets.dart';

void main() {
  runApp(const WidgetGalleryApp());
}

/// Manual playground for `label_widgets` — a single-screen gallery of
/// every component, used to eyeball visual/interaction changes during
/// development. Not code intended for the framework's end users (see
/// `docs/ARCHITECTURE.md` section 4: only `apps/playground` at the
/// workspace root plays that role for the full engine).
class WidgetGalleryApp extends StatelessWidget {
  const WidgetGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'label_widgets — playground',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const _GalleryPage(),
    );
  }
}

class _GalleryPage extends StatefulWidget {
  const _GalleryPage();

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  bool _toolbarSelected = false;
  Color _pickedColor = const Color(0xFF2196F3);
  double _zoom = 4;
  double _pan = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('label_widgets — playground')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              title: 'LabelToolbarButton',
              child: Row(
                children: [
                  LabelToolbarButton(
                    icon: LabelIcons.select,
                    tooltip: 'Selecionar',
                    selected: _toolbarSelected,
                    onPressed: () =>
                        setState(() => _toolbarSelected = !_toolbarSelected),
                  ),
                  const SizedBox(width: 8),
                  LabelToolbarButton(
                    icon: LabelIcons.move,
                    tooltip: 'Mover',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  LabelToolbarButton(
                    icon: LabelIcons.rotate,
                    tooltip: 'Girar',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  const LabelToolbarButton(
                    icon: LabelIcons.lock,
                    tooltip: 'Bloqueado (desabilitado)',
                  ),
                ],
              ),
            ),
            _Section(
              title: 'LabelButton',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  LabelButton(
                    label: 'Salvar',
                    icon: LabelIcons.duplicate,
                    onPressed: () {},
                  ),
                  LabelButton(
                    label: 'Cancelar',
                    variant: LabelButtonVariant.secondary,
                    onPressed: () {},
                  ),
                  LabelButton(
                    label: 'Excluir',
                    icon: LabelIcons.delete,
                    variant: LabelButtonVariant.danger,
                    onPressed: () {},
                  ),
                  const LabelButton(label: 'Desabilitado'),
                ],
              ),
            ),
            _Section(
              title: 'LabelColorPicker',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 260,
                    child: LabelColorPicker(
                      color: _pickedColor,
                      onColorChanged: (color) =>
                          setState(() => _pickedColor = color),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selecionada:'),
                      const SizedBox(height: 4),
                      LabelColorSwatch(color: _pickedColor, size: 40),
                      const SizedBox(height: 4),
                      Text(colorToHex(_pickedColor)),
                    ],
                  ),
                ],
              ),
            ),
            _Section(
              title: 'LabelRuler',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Zoom (px/mm): '),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: 12,
                          value: _zoom,
                          onChanged: (v) => setState(() => _zoom = v),
                        ),
                      ),
                      Text(_zoom.toStringAsFixed(1)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Pan (px): '),
                      Expanded(
                        child: Slider(
                          min: -100,
                          max: 100,
                          value: _pan,
                          onChanged: (v) => setState(() => _pan = v),
                        ),
                      ),
                      Text(_pan.toStringAsFixed(0)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    child: LabelRuler(
                      axis: RulerAxis.horizontal,
                      pixelsPerMm: _zoom,
                      originOffset: _pan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 160,
                        child: LabelRuler(
                          axis: RulerAxis.vertical,
                          pixelsPerMm: _zoom,
                          originOffset: _pan,
                        ),
                      ),
                      Container(width: 1, height: 160, color: Colors.black12),
                    ],
                  ),
                ],
              ),
            ),
            _Section(
              title: 'LabelIcons',
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final entry in _labelIconSamples.entries)
                    Column(
                      children: [
                        Icon(entry.value),
                        const SizedBox(height: 4),
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelSmall,
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

const _labelIconSamples = {
  'select': LabelIcons.select,
  'move': LabelIcons.move,
  'rotate': LabelIcons.rotate,
  'group': LabelIcons.group,
  'lock': LabelIcons.lock,
  'undo': LabelIcons.undo,
  'redo': LabelIcons.redo,
  'delete': LabelIcons.delete,
  'zoomIn': LabelIcons.zoomIn,
  'grid': LabelIcons.grid,
  'textElement': LabelIcons.textElement,
  'barcodeElement': LabelIcons.barcodeElement,
  'imageElement': LabelIcons.imageElement,
};

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
