import 'label_element.dart';

/// Visitor over the [LabelElement] hierarchy (GoF Visitor pattern).
///
/// Consumers that need per-type behaviour (drawing on the canvas,
/// serializing, resolving layout) implement this instead of scattering
/// `is`/`as` checks. Adding a new element type is a compile error here
/// until every visitor implementation handles it.
abstract interface class LabelElementVisitor<T> {
  T visitText(TextElement element);
  T visitBarcode(BarcodeElement element);
  T visitQrCode(QRCodeElement element);
  T visitImage(ImageElement element);
  T visitRectangle(RectangleElement element);
  T visitEllipse(EllipseElement element);
  T visitCircle(CircleElement element);
  T visitLine(LineElement element);
  T visitVariable(VariableElement element);
  T visitDate(DateElement element);
  T visitTime(TimeElement element);
  T visitTable(TableElement element);
  T visitGroup(GroupElement element);
}
