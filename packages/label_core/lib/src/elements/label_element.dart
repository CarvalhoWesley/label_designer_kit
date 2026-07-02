import 'package:equatable/equatable.dart';

import '../geometry/point.dart';
import '../geometry/size2d.dart';
import 'element_transform.dart';
import 'label_element_visitor.dart';
import 'text_style_spec.dart';

part 'shape_style_spec.dart';
part 'group_element.dart';
part 'text_element.dart';
part 'barcode_element.dart';
part 'qr_code_element.dart';
part 'image_element.dart';
part 'rectangle_element.dart';
part 'ellipse_element.dart';
part 'circle_element.dart';
part 'line_element.dart';
part 'variable_element.dart';
part 'date_element.dart';
part 'time_element.dart';
part 'table_element.dart';

/// Base type for every object that can be placed on a [LabelDocument].
///
/// `sealed`: every concrete subtype lives in this same library (as a
/// `part` file), which lets any `switch` over a [LabelElement] be checked
/// exhaustively by the compiler. Per-type behaviour should still prefer
/// [accept] (Visitor pattern) over `switch`/`is` so that adding a new
/// element type is a compile error at every call site that needs updating.
///
/// All geometry (`position`, `size`) is expressed in millimeters. Nothing
/// in this class or its subtypes knows about dots, DPI or printer
/// languages — that knowledge belongs exclusively to the Layout Engine and
/// the renderers.
sealed class LabelElement extends Equatable {
  const LabelElement({
    required this.id,
    required this.name,
    required this.position,
    required this.size,
    this.rotation = 0,
    this.visible = true,
    this.locked = false,
    this.opacity = 1,
    required this.layerId,
    this.zIndex = 0,
    this.transform = const ElementTransform.identity(),
  });

  /// Stable, unique identifier within the owning [LabelDocument].
  final String id;

  /// User-facing label shown in the layer tree.
  final String name;

  /// Top-left position in millimeters, relative to the page origin (or the
  /// parent [GroupElement], if any).
  final Point position;

  /// Bounding box size in millimeters.
  final Size2D size;

  /// Rotation in degrees, clockwise, around the element's center.
  final double rotation;
  final bool visible;
  final bool locked;

  /// Opacity from 0 (transparent) to 1 (opaque).
  final double opacity;

  /// Id of the [LabelLayer] this element belongs to.
  final String layerId;

  /// Paint/stacking order relative to siblings on the same layer.
  final int zIndex;
  final ElementTransform transform;

  /// The discriminator written to `type` in JSON and used to pick the
  /// concrete subtype when decoding.
  String get typeName;

  /// Double-dispatch entry point for [LabelElementVisitor]s.
  T accept<T>(LabelElementVisitor<T> visitor);

  Map<String, dynamic> toJson();

  Map<String, dynamic> _commonJson() => {
    'type': typeName,
    'id': id,
    'name': name,
    'position': position.toJson(),
    'size': size.toJson(),
    'rotation': rotation,
    'visible': visible,
    'locked': locked,
    'opacity': opacity,
    'layerId': layerId,
    'zIndex': zIndex,
    'transform': transform.toJson(),
  };

  static LabelElement fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'text':
        return TextElement.fromJson(json);
      case 'barcode':
        return BarcodeElement.fromJson(json);
      case 'qrcode':
        return QRCodeElement.fromJson(json);
      case 'image':
        return ImageElement.fromJson(json);
      case 'rectangle':
        return RectangleElement.fromJson(json);
      case 'ellipse':
        return EllipseElement.fromJson(json);
      case 'circle':
        return CircleElement.fromJson(json);
      case 'line':
        return LineElement.fromJson(json);
      case 'variable':
        return VariableElement.fromJson(json);
      case 'date':
        return DateElement.fromJson(json);
      case 'time':
        return TimeElement.fromJson(json);
      case 'table':
        return TableElement.fromJson(json);
      case 'group':
        return GroupElement.fromJson(json);
      default:
        throw ArgumentError.value(type, 'type', 'Unknown LabelElement type');
    }
  }

  @override
  List<Object?> get props => [
    id,
    name,
    position,
    size,
    rotation,
    visible,
    locked,
    opacity,
    layerId,
    zIndex,
    transform,
  ];
}
