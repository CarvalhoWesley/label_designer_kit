import 'package:flutter/widgets.dart';
import 'package:label_core/label_core.dart';

import 'barcode_section.dart';
import 'circle_section.dart';
import 'date_section.dart';
import 'ellipse_section.dart';
import 'group_section.dart';
import 'image_section.dart';
import 'line_section.dart';
import 'qr_code_section.dart';
import 'rectangle_section.dart';
import 'table_section.dart';
import 'text_section.dart';
import 'time_section.dart';
import 'variable_section.dart';

/// Dispatches to the right type-specific section widget via
/// [LabelElementVisitor], so adding a new [LabelElement] subtype is a
/// compile error here until this panel handles it too (see
/// `docs/ARCHITECTURE.md` section 18: Visitor).
class TypeSectionVisitor implements LabelElementVisitor<Widget> {
  const TypeSectionVisitor({
    required this.styles,
    required this.onChange,
  });

  final List<LabelStyle> styles;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget visitText(TextElement element) =>
      TextSection(element: element, styles: styles, onChange: onChange);

  @override
  Widget visitBarcode(BarcodeElement element) =>
      BarcodeSection(element: element, onChange: onChange);

  @override
  Widget visitQrCode(QRCodeElement element) =>
      QrCodeSection(element: element, onChange: onChange);

  @override
  Widget visitImage(ImageElement element) =>
      ImageSection(element: element, onChange: onChange);

  @override
  Widget visitRectangle(RectangleElement element) =>
      RectangleSection(element: element, onChange: onChange);

  @override
  Widget visitEllipse(EllipseElement element) =>
      EllipseSection(element: element, onChange: onChange);

  @override
  Widget visitCircle(CircleElement element) =>
      CircleSection(element: element, onChange: onChange);

  @override
  Widget visitLine(LineElement element) =>
      LineSection(element: element, onChange: onChange);

  @override
  Widget visitVariable(VariableElement element) =>
      VariableSection(element: element, styles: styles, onChange: onChange);

  @override
  Widget visitDate(DateElement element) =>
      DateSection(element: element, onChange: onChange);

  @override
  Widget visitTime(TimeElement element) =>
      TimeSection(element: element, onChange: onChange);

  @override
  Widget visitTable(TableElement element) =>
      TableSection(element: element, onChange: onChange);

  @override
  Widget visitGroup(GroupElement element) => GroupSection(element: element);
}
