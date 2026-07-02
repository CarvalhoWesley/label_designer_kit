/// Per-field `copyWith` dispatch for the properties every [LabelElement]
/// subtype shares (name, position, size, rotation, opacity, visible,
/// locked, layerId).
///
/// [LabelElement] is `sealed`, but each subtype has its own `copyWith`
/// with a different set of extra, type-specific named parameters — there
/// is no single `copyWith` on the base class to call generically. Editing
/// a common field from the property panel therefore goes through one of
/// these exhaustive switches instead, one per field, so adding a new
/// [LabelElement] subtype is a compile error here until handled.
library;

import 'package:label_core/label_core.dart';

LabelElement withName(LabelElement element, String name) => switch (element) {
  TextElement e => e.copyWith(name: name),
  BarcodeElement e => e.copyWith(name: name),
  QRCodeElement e => e.copyWith(name: name),
  ImageElement e => e.copyWith(name: name),
  RectangleElement e => e.copyWith(name: name),
  EllipseElement e => e.copyWith(name: name),
  CircleElement e => e.copyWith(name: name),
  LineElement e => e.copyWith(name: name),
  VariableElement e => e.copyWith(name: name),
  DateElement e => e.copyWith(name: name),
  TimeElement e => e.copyWith(name: name),
  TableElement e => e.copyWith(name: name),
  GroupElement e => e.copyWith(name: name),
};

LabelElement withLayerId(LabelElement element, String layerId) =>
    switch (element) {
      TextElement e => e.copyWith(layerId: layerId),
      BarcodeElement e => e.copyWith(layerId: layerId),
      QRCodeElement e => e.copyWith(layerId: layerId),
      ImageElement e => e.copyWith(layerId: layerId),
      RectangleElement e => e.copyWith(layerId: layerId),
      EllipseElement e => e.copyWith(layerId: layerId),
      CircleElement e => e.copyWith(layerId: layerId),
      LineElement e => e.copyWith(layerId: layerId),
      VariableElement e => e.copyWith(layerId: layerId),
      DateElement e => e.copyWith(layerId: layerId),
      TimeElement e => e.copyWith(layerId: layerId),
      TableElement e => e.copyWith(layerId: layerId),
      GroupElement e => e.copyWith(layerId: layerId),
    };

LabelElement withPosition(LabelElement element, Point position) =>
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

LabelElement withSize(LabelElement element, Size2D size) => switch (element) {
  TextElement e => e.copyWith(size: size),
  BarcodeElement e => e.copyWith(size: size),
  QRCodeElement e => e.copyWith(size: size),
  ImageElement e => e.copyWith(size: size),
  RectangleElement e => e.copyWith(size: size),
  EllipseElement e => e.copyWith(size: size),
  CircleElement e => e.copyWith(size: size),
  LineElement e => e.copyWith(size: size),
  VariableElement e => e.copyWith(size: size),
  DateElement e => e.copyWith(size: size),
  TimeElement e => e.copyWith(size: size),
  TableElement e => e.copyWith(size: size),
  GroupElement e => e.copyWith(size: size),
};

LabelElement withRotation(LabelElement element, double rotation) =>
    switch (element) {
      TextElement e => e.copyWith(rotation: rotation),
      BarcodeElement e => e.copyWith(rotation: rotation),
      QRCodeElement e => e.copyWith(rotation: rotation),
      ImageElement e => e.copyWith(rotation: rotation),
      RectangleElement e => e.copyWith(rotation: rotation),
      EllipseElement e => e.copyWith(rotation: rotation),
      CircleElement e => e.copyWith(rotation: rotation),
      LineElement e => e.copyWith(rotation: rotation),
      VariableElement e => e.copyWith(rotation: rotation),
      DateElement e => e.copyWith(rotation: rotation),
      TimeElement e => e.copyWith(rotation: rotation),
      TableElement e => e.copyWith(rotation: rotation),
      GroupElement e => e.copyWith(rotation: rotation),
    };

LabelElement withOpacity(LabelElement element, double opacity) =>
    switch (element) {
      TextElement e => e.copyWith(opacity: opacity),
      BarcodeElement e => e.copyWith(opacity: opacity),
      QRCodeElement e => e.copyWith(opacity: opacity),
      ImageElement e => e.copyWith(opacity: opacity),
      RectangleElement e => e.copyWith(opacity: opacity),
      EllipseElement e => e.copyWith(opacity: opacity),
      CircleElement e => e.copyWith(opacity: opacity),
      LineElement e => e.copyWith(opacity: opacity),
      VariableElement e => e.copyWith(opacity: opacity),
      DateElement e => e.copyWith(opacity: opacity),
      TimeElement e => e.copyWith(opacity: opacity),
      TableElement e => e.copyWith(opacity: opacity),
      GroupElement e => e.copyWith(opacity: opacity),
    };

LabelElement withVisible(LabelElement element, bool visible) =>
    switch (element) {
      TextElement e => e.copyWith(visible: visible),
      BarcodeElement e => e.copyWith(visible: visible),
      QRCodeElement e => e.copyWith(visible: visible),
      ImageElement e => e.copyWith(visible: visible),
      RectangleElement e => e.copyWith(visible: visible),
      EllipseElement e => e.copyWith(visible: visible),
      CircleElement e => e.copyWith(visible: visible),
      LineElement e => e.copyWith(visible: visible),
      VariableElement e => e.copyWith(visible: visible),
      DateElement e => e.copyWith(visible: visible),
      TimeElement e => e.copyWith(visible: visible),
      TableElement e => e.copyWith(visible: visible),
      GroupElement e => e.copyWith(visible: visible),
    };

LabelElement withLocked(LabelElement element, bool locked) =>
    switch (element) {
      TextElement e => e.copyWith(locked: locked),
      BarcodeElement e => e.copyWith(locked: locked),
      QRCodeElement e => e.copyWith(locked: locked),
      ImageElement e => e.copyWith(locked: locked),
      RectangleElement e => e.copyWith(locked: locked),
      EllipseElement e => e.copyWith(locked: locked),
      CircleElement e => e.copyWith(locked: locked),
      LineElement e => e.copyWith(locked: locked),
      VariableElement e => e.copyWith(locked: locked),
      DateElement e => e.copyWith(locked: locked),
      TimeElement e => e.copyWith(locked: locked),
      TableElement e => e.copyWith(locked: locked),
      GroupElement e => e.copyWith(locked: locked),
    };
