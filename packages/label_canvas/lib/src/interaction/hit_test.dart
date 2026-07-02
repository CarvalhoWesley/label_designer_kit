import 'dart:math' as math;

import 'package:label_core/label_core.dart';
import 'package:label_designer_state/label_designer_state.dart';

import '../geometry/element_bounds.dart';
import 'visibility.dart';

export 'visibility.dart' show isElementInteractable, isElementVisible;

/// The topmost interactable element under [pointerMm], or `null`.
///
/// A `GroupElement` is hit-tested as one opaque unit against its own
/// bounding box — clicking any of its children selects the group, since
/// `label_canvas` has no "enter group" mode (grouping/ungrouping UI is
/// deferred; see the package README).
String? hitTestElement({
  required List<LabelElement> elements,
  required List<LabelLayer> layers,
  required Point pointerMm,
}) {
  final byZIndexDescending = [...elements]
    ..sort((a, b) => b.zIndex.compareTo(a.zIndex));
  for (final element in byZIndexDescending) {
    if (!isElementInteractable(element, layers)) continue;
    if (ElementBounds.of(element).contains(pointerMm)) return element.id;
  }
  return null;
}

/// The closest resize/rotation handle of [bounds] to [pointerMm], if any
/// is within [hitRadiusMm] — callers convert a fixed on-screen hit radius
/// (e.g. 8px) to mm via `CanvasTransform.lengthToMm` so the grab target
/// stays a constant screen size regardless of zoom.
ResizeHandle? hitTestHandle({
  required ElementBounds bounds,
  required Point pointerMm,
  required double hitRadiusMm,
}) {
  ResizeHandle? closest;
  var closestDistanceSquared = hitRadiusMm * hitRadiusMm;
  for (final handle in ResizeHandle.values) {
    final handlePos = bounds.handlePosition(handle);
    final dx = pointerMm.x - handlePos.x;
    final dy = pointerMm.y - handlePos.y;
    final distanceSquared = dx * dx + dy * dy;
    if (distanceSquared <= closestDistanceSquared) {
      closest = handle;
      closestDistanceSquared = distanceSquared;
    }
  }
  return closest;
}

/// Ids of every interactable element whose (rotated) bounding box
/// intersects the axis-aligned rectangle spanned by [corner1]/[corner2] —
/// used for marquee/rubber-band selection.
Set<String> elementsInMarquee({
  required List<LabelElement> elements,
  required List<LabelLayer> layers,
  required Point corner1,
  required Point corner2,
}) {
  final left = math.min(corner1.x, corner2.x);
  final right = math.max(corner1.x, corner2.x);
  final top = math.min(corner1.y, corner2.y);
  final bottom = math.max(corner1.y, corner2.y);

  final result = <String>{};
  for (final element in elements) {
    if (!isElementInteractable(element, layers)) continue;
    final corners = ElementBounds.of(element).corners;
    final elLeft = corners.map((p) => p.x).reduce(math.min);
    final elRight = corners.map((p) => p.x).reduce(math.max);
    final elTop = corners.map((p) => p.y).reduce(math.min);
    final elBottom = corners.map((p) => p.y).reduce(math.max);
    final intersects =
        elLeft <= right &&
        elRight >= left &&
        elTop <= bottom &&
        elBottom >= top;
    if (intersects) result.add(element.id);
  }
  return result;
}
