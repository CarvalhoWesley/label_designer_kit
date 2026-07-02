import 'package:flutter/material.dart';
import 'package:label_core/label_core.dart';

import '../widgets/labeled_text_field.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [QRCodeElement]: data and error correction.
class QrCodeSection extends StatelessWidget {
  const QrCodeSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final QRCodeElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'QR Code',
      children: [
        LabeledTextField(
          label: 'Dados',
          value: element.data,
          onChanged: (value) => onChange(
            (e) => (e as QRCodeElement).copyWith(data: value),
          ),
        ),
        DropdownButtonFormField<QrErrorCorrectionLevel>(
          value: element.errorCorrectionLevel,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Correção de erro',
            isDense: true,
          ),
          items: [
            for (final level in QrErrorCorrectionLevel.values)
              DropdownMenuItem(value: level, child: Text(level.name)),
          ],
          onChanged: (value) {
            if (value != null) {
              onChange(
                (e) => (e as QRCodeElement).copyWith(
                  errorCorrectionLevel: value,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
