import 'dart:math' show max, min;

import 'package:label_core/label_core.dart';

/// The result of [groupElements]: the new group plus every sibling that
/// wasn't part of the selection, ready to be combined into a full element
/// list (e.g. `[...remainingSiblings, group]`) and dispatched via
/// `HistoryStore.replaceElements`.
typedef GroupResult = ({GroupElement group, List<LabelElement> remainingSiblings});

/// Groups every element in [allElements] whose id is in [selectedIds] into
/// one new `GroupElement` (GoF Composite — see `docs/ARCHITECTURE.md`
/// section 18), scoped to top-level elements only (an element already
/// nested inside another group isn't a valid group member here).
///
/// The new group's bounding box is the union of its members' bounding
/// boxes; each member's `position` is rebased to be relative to that box
/// (see [GroupElement]'s doc comment: children positions are relative to
/// the group's own). The group inherits the first selected member's
/// `layerId` and the highest `zIndex` among them, so it paints on top.
///
/// Throws [ArgumentError] if fewer than 2 of [selectedIds] match an
/// element in [allElements] — grouping a single element (or nothing)
/// isn't meaningful.
GroupResult groupElements({
  required List<LabelElement> allElements,
  required Set<String> selectedIds,
  required String groupId,
}) {
  final selected = [
    for (final element in allElements)
      if (selectedIds.contains(element.id)) element,
  ];
  if (selected.length < 2) {
    throw ArgumentError(
      'groupElements requires at least 2 matching elements, got '
      '${selected.length}',
    );
  }

  final minX = selected.map((e) => e.position.x).reduce(min);
  final minY = selected.map((e) => e.position.y).reduce(min);
  final maxX = selected.map((e) => e.position.x + e.size.width).reduce(max);
  final maxY = selected.map((e) => e.position.y + e.size.height).reduce(max);

  final children = [
    for (final element in selected)
      _withPosition(
        element,
        Point(x: element.position.x - minX, y: element.position.y - minY),
      ),
  ];

  final group = GroupElement(
    id: groupId,
    name: 'Grupo',
    position: Point(x: minX, y: minY),
    size: Size2D(width: maxX - minX, height: maxY - minY),
    layerId: selected.first.layerId,
    zIndex: selected.map((e) => e.zIndex).reduce(max),
    children: children,
  );

  final remainingSiblings = [
    for (final element in allElements)
      if (!selectedIds.contains(element.id)) element,
  ];

  return (group: group, remainingSiblings: remainingSiblings);
}

/// Reverses [groupElements]: returns [group]'s children with their
/// position translated back from group-relative to absolute page
/// coordinates. The caller combines this with the document's other
/// elements (minus [group] itself) and dispatches via
/// `HistoryStore.replaceElements`.
///
/// Nested sub-groups are returned as-is (only one level is un-nested per
/// call, matching "ungroup" acting on exactly the group the user selected
/// — ungrouping a sub-group afterwards is a separate action).
List<LabelElement> ungroupElement(GroupElement group) => [
  for (final child in group.children)
    _withPosition(
      child,
      Point(
        x: child.position.x + group.position.x,
        y: child.position.y + group.position.y,
      ),
    ),
];

LabelElement _withPosition(LabelElement element, Point position) =>
    switch (element) {
      TextElement e => e.copyWith(position: position),
      BarcodeElement e => e.copyWith(position: position),
      QRCodeElement e => e.copyWith(position: position),
      ImageElement e => e.copyWith(position: position),
      RectangleElement e => e.copyWith(position: position),
      EllipseElement e => e.copyWith(position: position),
      CircleElement e => e.copyWith(position: position),
      LineElement e => e.copyWith(position: position),
      VariableElement e => e.copyWith(position: position),
      DateElement e => e.copyWith(position: position),
      TimeElement e => e.copyWith(position: position),
      TableElement e => e.copyWith(position: position),
      GroupElement e => e.copyWith(position: position),
    };
