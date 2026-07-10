import 'package:label_core/label_core.dart';

/// Moves every element whose id is in [selectedIds] to the end of
/// [elements] (paint order — last painted is on top), then reassigns
/// `zIndex` sequentially so it stays a clean, monotonic 0..n-1 rather than
/// accumulating stale/duplicate values across repeated bring-to-front
/// calls.
///
/// Scoped over the whole top-level element list rather than per-layer:
/// `zIndex` is documented as "relative to siblings on the same layer", but
/// `label_canvas`'s painter currently sorts purely by `zIndex` — see
/// `docs/ARCHITECTURE.md` section 8. Reassigning across all elements keeps
/// that painter's ordering correct; a per-layer-scoped version can follow
/// once cross-layer z-fighting actually matters.
List<LabelElement> bringToFront(
  List<LabelElement> elements,
  Set<String> selectedIds,
) => _reorder(elements, selectedIds, selectedLast: true);

/// The mirror of [bringToFront]: moves the selected elements to the start
/// of the paint order instead.
List<LabelElement> sendToBack(
  List<LabelElement> elements,
  Set<String> selectedIds,
) => _reorder(elements, selectedIds, selectedLast: false);

List<LabelElement> _reorder(
  List<LabelElement> elements,
  Set<String> selectedIds, {
  required bool selectedLast,
}) {
  final selected = <LabelElement>[];
  final rest = <LabelElement>[];
  for (final element in elements) {
    (selectedIds.contains(element.id) ? selected : rest).add(element);
  }
  final ordered = selectedLast
      ? [...rest, ...selected]
      : [...selected, ...rest];
  return [for (var i = 0; i < ordered.length; i++) _withZIndex(ordered[i], i)];
}

LabelElement _withZIndex(LabelElement element, int zIndex) => switch (element) {
  TextElement e => e.copyWith(zIndex: zIndex),
  BarcodeElement e => e.copyWith(zIndex: zIndex),
  QRCodeElement e => e.copyWith(zIndex: zIndex),
  ImageElement e => e.copyWith(zIndex: zIndex),
  RectangleElement e => e.copyWith(zIndex: zIndex),
  EllipseElement e => e.copyWith(zIndex: zIndex),
  CircleElement e => e.copyWith(zIndex: zIndex),
  LineElement e => e.copyWith(zIndex: zIndex),
  VariableElement e => e.copyWith(zIndex: zIndex),
  DateElement e => e.copyWith(zIndex: zIndex),
  TimeElement e => e.copyWith(zIndex: zIndex),
  TableElement e => e.copyWith(zIndex: zIndex),
  GroupElement e => e.copyWith(zIndex: zIndex),
};
