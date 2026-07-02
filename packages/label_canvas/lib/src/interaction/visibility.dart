import 'package:label_core/label_core.dart';

/// Whether [element] should be drawn at all: not hidden itself, and not on
/// a hidden layer. Locked has no bearing on visibility — a locked element
/// is still drawn normally, just not interactive (see
/// [isElementInteractable]).
bool isElementVisible(LabelElement element, List<LabelLayer> layers) {
  if (!element.visible) return false;
  return layerFor(element.layerId, layers)?.visible ?? true;
}

/// Whether [element] can currently be selected/dragged: not hidden or
/// locked itself, and not on a layer that is hidden or locked. Matches
/// how every layer-based editor treats "locked" — click-through, not
/// merely "can't be edited once selected".
bool isElementInteractable(LabelElement element, List<LabelLayer> layers) {
  if (element.locked) return false;
  if (!isElementVisible(element, layers)) return false;
  return !(layerFor(element.layerId, layers)?.locked ?? false);
}

LabelLayer? layerFor(String layerId, List<LabelLayer> layers) {
  for (final layer in layers) {
    if (layer.id == layerId) return layer;
  }
  return null;
}
