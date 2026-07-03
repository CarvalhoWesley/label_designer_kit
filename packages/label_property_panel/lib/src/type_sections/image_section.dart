import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';

/// Maps a file extension to the MIME subtype used in a `data:` URI —
/// covers the formats `dart:ui.instantiateImageCodec` decodes.
const _mimeSubtypeByExtension = {
  'jpg': 'jpeg',
  'jpeg': 'jpeg',
  'png': 'png',
  'gif': 'gif',
  'webp': 'webp',
  'bmp': 'bmp',
};

/// Type-specific fields for [ImageElement]: source and fit.
class ImageSection extends StatelessWidget {
  const ImageSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final ImageElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final files = result?.files;
    if (files == null || files.isEmpty) return;
    final file = files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final extension = (file.extension ?? '').toLowerCase();
    final subtype = _mimeSubtypeByExtension[extension] ?? 'png';
    final dataUri = 'data:image/$subtype;base64,${base64Encode(bytes)}';
    onChange((e) => (e as ImageElement).copyWith(source: dataUri));
  }

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Imagem',
      children: [
        LabeledTextField(
          label: 'Origem',
          value: element.source,
          onChanged: (value) => onChange(
            (e) => (e as ImageElement).copyWith(source: value),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('Escolher imagem…'),
        ),
        DropdownButtonFormField<ImageFit>(
          value: element.fit,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Ajuste',
            isDense: true,
          ),
          items: [
            for (final fit in ImageFit.values)
              DropdownMenuItem(value: fit, child: Text(fit.name)),
          ],
          onChanged: (value) {
            if (value != null) {
              onChange((e) => (e as ImageElement).copyWith(fit: value));
            }
          },
        ),
      ],
    );
  }
}
