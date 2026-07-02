import 'package:label_core/label_core.dart';

/// Deep-clones [element] with a fresh id from [nextId] — recursively, so a
/// duplicated `GroupElement`'s children get fresh ids too (ids must stay
/// unique document-wide; two elements sharing an id would make
/// `findElementById`/`replaceElementById` ambiguous).
///
/// The clone is offset by [offset] (default 5mm right/down) so it lands
/// visibly next to the original instead of exactly on top of it. Nested
/// children are *not* additionally offset — their `position` is already
/// relative to the group's own, which already moved.
///
/// [LabelElement] is `sealed` with no shared `copyWith`, so this is
/// necessarily an exhaustive switch — see `label_property_panel`'s
/// `common_element_updates.dart` for the same shape applied to single-field
/// edits instead of a full clone.
LabelElement cloneElement(
  LabelElement element,
  String Function() nextId, {
  Point offset = const Point(x: 5, y: 5),
}) => _clone(element, nextId, offset: offset);

LabelElement _clone(
  LabelElement element,
  String Function() nextId, {
  required Point offset,
}) {
  final id = nextId();
  final position = Point(
    x: element.position.x + offset.x,
    y: element.position.y + offset.y,
  );
  return switch (element) {
    TextElement e => e.copyWith(id: id, position: position),
    BarcodeElement e => e.copyWith(id: id, position: position),
    QRCodeElement e => e.copyWith(id: id, position: position),
    ImageElement e => e.copyWith(id: id, position: position),
    RectangleElement e => e.copyWith(id: id, position: position),
    EllipseElement e => e.copyWith(id: id, position: position),
    CircleElement e => e.copyWith(id: id, position: position),
    LineElement e => e.copyWith(id: id, position: position),
    VariableElement e => e.copyWith(id: id, position: position),
    DateElement e => e.copyWith(id: id, position: position),
    TimeElement e => e.copyWith(id: id, position: position),
    TableElement e => e.copyWith(id: id, position: position),
    GroupElement e => e.copyWith(
      id: id,
      position: position,
      // Children keep their id-generation but no additional offset: their
      // position is relative to the group, which already moved as a whole.
      children: [
        for (final child in e.children)
          _clone(child, nextId, offset: Point.zero()),
      ],
    ),
  };
}
