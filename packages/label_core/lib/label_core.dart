/// Domain model of the Label Designer Framework: [LabelDocument],
/// [LabelElement] and its subtypes, geometry and unit value objects.
///
/// This package has zero dependency on Flutter, printers or rendering —
/// see `docs/ARCHITECTURE.md` at the workspace root for the full layering
/// rules.
library;

export 'src/document/document_metadata.dart';
export 'src/document/label_document.dart';
export 'src/document/label_layer.dart';
export 'src/document/label_style.dart';
export 'src/document/label_variable.dart';
export 'src/document/page_config.dart';
export 'src/elements/element_transform.dart';
export 'src/elements/label_element.dart';
export 'src/elements/label_element_visitor.dart';
export 'src/elements/text_style_spec.dart';
export 'src/geometry/edge_insets.dart';
export 'src/geometry/point.dart';
export 'src/geometry/size2d.dart';
export 'src/units/dpi.dart';
export 'src/units/unit.dart';
