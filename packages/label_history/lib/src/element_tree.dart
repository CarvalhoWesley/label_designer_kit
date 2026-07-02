import 'package:label_core/label_core.dart';

/// Where a [LabelElement] lives inside a [LabelDocument]'s element tree.
///
/// [parentId] is `null` when the element is top-level (directly in
/// `LabelDocument.elements`); otherwise it is the id of the [GroupElement]
/// whose `children` list contains it. [index] is the position within that
/// list, needed to restore an element at its original spot on undo.
class ElementLocation {
  const ElementLocation({
    required this.element,
    required this.parentId,
    required this.index,
  });

  final LabelElement element;
  final String? parentId;
  final int index;
}

/// Recursively finds the element with [id] in [elements] or any nested
/// [GroupElement.children], returning `null` if none matches.
LabelElement? findElementById(List<LabelElement> elements, String id) {
  for (final element in elements) {
    if (element.id == id) return element;
    if (element case GroupElement(:final children)) {
      final found = findElementById(children, id);
      if (found != null) return found;
    }
  }
  return null;
}

/// Like [findElementById], but also reports where the element sits in the
/// tree (its parent group id, if any, and its index in that list).
ElementLocation? locateElement(List<LabelElement> elements, String id) {
  for (var i = 0; i < elements.length; i++) {
    final element = elements[i];
    if (element.id == id) {
      return ElementLocation(element: element, parentId: null, index: i);
    }
    if (element case GroupElement(:final children)) {
      final nested = locateElement(children, id);
      if (nested != null) {
        return nested.parentId == null
            ? ElementLocation(
                element: nested.element,
                parentId: element.id,
                index: nested.index,
              )
            : nested;
      }
    }
  }
  return null;
}

/// Returns a new tree with the element matching [id] replaced by
/// `update(element)`, searching recursively through [GroupElement]
/// children. Throws [ArgumentError] if no element with [id] exists.
List<LabelElement> replaceElementById(
  List<LabelElement> elements,
  String id,
  LabelElement Function(LabelElement element) update,
) {
  final result = _tryReplace(elements, id, update);
  if (result == null) {
    throw ArgumentError.value(
      id,
      'id',
      'No LabelElement with this id was found in the tree',
    );
  }
  return result;
}

List<LabelElement>? _tryReplace(
  List<LabelElement> elements,
  String id,
  LabelElement Function(LabelElement element) update,
) {
  for (var i = 0; i < elements.length; i++) {
    final element = elements[i];
    if (element.id == id) {
      final result = List<LabelElement>.of(elements);
      result[i] = update(element);
      return result;
    }
    if (element case GroupElement(:final children)) {
      final updatedChildren = _tryReplace(children, id, update);
      if (updatedChildren != null) {
        final result = List<LabelElement>.of(elements);
        result[i] = element.copyWith(children: updatedChildren);
        return result;
      }
    }
  }
  return null;
}

/// Returns a new tree with the element matching [id] removed, searching
/// recursively through [GroupElement] children. Throws [ArgumentError] if
/// no element with [id] exists.
List<LabelElement> removeElementById(List<LabelElement> elements, String id) {
  final result = _tryRemove(elements, id);
  if (result == null) {
    throw ArgumentError.value(
      id,
      'id',
      'No LabelElement with this id was found in the tree',
    );
  }
  return result;
}

List<LabelElement>? _tryRemove(List<LabelElement> elements, String id) {
  for (var i = 0; i < elements.length; i++) {
    final element = elements[i];
    if (element.id == id) {
      return List<LabelElement>.of(elements)..removeAt(i);
    }
    if (element case GroupElement(:final children)) {
      final updatedChildren = _tryRemove(children, id);
      if (updatedChildren != null) {
        final result = List<LabelElement>.of(elements);
        result[i] = element.copyWith(children: updatedChildren);
        return result;
      }
    }
  }
  return null;
}

/// Returns a new tree with [element] inserted at [index] (append when
/// `null`), either top-level or inside the [GroupElement] identified by
/// [parentId]. Throws [ArgumentError] if [parentId] is set but no matching
/// [GroupElement] exists.
List<LabelElement> insertElementAt(
  List<LabelElement> elements,
  LabelElement element,
  int? index, {
  String? parentId,
}) {
  if (parentId == null) {
    final result = List<LabelElement>.of(elements);
    result.insert((index ?? result.length).clamp(0, result.length), element);
    return result;
  }
  return replaceElementById(elements, parentId, (parent) {
    if (parent is! GroupElement) {
      throw ArgumentError.value(
        parentId,
        'parentId',
        'LabelElement with this id is not a GroupElement',
      );
    }
    final children = List<LabelElement>.of(parent.children);
    children.insert(
      (index ?? children.length).clamp(0, children.length),
      element,
    );
    return parent.copyWith(children: children);
  });
}
