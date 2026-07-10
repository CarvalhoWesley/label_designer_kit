import 'package:equatable/equatable.dart';

import '../geometry/edge_insets.dart';
import '../units/dpi.dart';
import '../units/unit.dart';

enum PageOrientation { portrait, landscape }

/// Physical dimensions and print resolution of a [LabelDocument].
class PageConfig extends Equatable {
  const PageConfig({
    required this.width,
    required this.height,
    this.unit = Unit.mm,
    this.dpi = Dpi.dpi203,
    this.orientation = PageOrientation.portrait,
    this.margins = const EdgeInsets.zero(),
    this.columns = 1,
    this.columnGap = 0,
  }) : assert(columns >= 1, 'columns must be at least 1'),
       assert(columnGap >= 0, 'columnGap cannot be negative');

  factory PageConfig.fromJson(Map<String, dynamic> json) {
    return PageConfig(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      unit: Unit.values.byName(json['unit'] as String? ?? 'mm'),
      dpi: Dpi.fromValue(json['dpi'] as int? ?? 203),
      orientation: PageOrientation.values.byName(
        json['orientation'] as String? ?? 'portrait',
      ),
      margins: json['margins'] == null
          ? const EdgeInsets.zero()
          : EdgeInsets.fromJson(json['margins'] as Map<String, dynamic>),
      columns: json['columns'] as int? ?? 1,
      columnGap: (json['columnGap'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Page width in millimeters.
  final double width;

  /// Page height in millimeters.
  final double height;

  /// Unit used to *display* [width]/[height] in the editor; storage is
  /// always millimeters regardless of this value.
  final Unit unit;
  final Dpi dpi;
  final PageOrientation orientation;
  final EdgeInsets margins;

  /// Number of labels laid out side by side on the physical roll this page
  /// was designed for, e.g. `2` for a roll with two columns of labels.
  /// Used by `LabelLayoutEngine.resolveBatch` to tile a batch of records
  /// across columns — has no effect on `resolve()`, which always resolves
  /// a single label. Defaults to `1` (single-column roll).
  final int columns;

  /// Horizontal gap between columns, in millimeters. Ignored when
  /// [columns] is `1`.
  final double columnGap;

  PageConfig copyWith({
    double? width,
    double? height,
    Unit? unit,
    Dpi? dpi,
    PageOrientation? orientation,
    EdgeInsets? margins,
    int? columns,
    double? columnGap,
  }) {
    return PageConfig(
      width: width ?? this.width,
      height: height ?? this.height,
      unit: unit ?? this.unit,
      dpi: dpi ?? this.dpi,
      orientation: orientation ?? this.orientation,
      margins: margins ?? this.margins,
      columns: columns ?? this.columns,
      columnGap: columnGap ?? this.columnGap,
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'unit': unit.name,
    'dpi': dpi.value,
    'orientation': orientation.name,
    'margins': margins.toJson(),
    'columns': columns,
    'columnGap': columnGap,
  };

  @override
  List<Object?> get props => [
    width,
    height,
    unit,
    dpi,
    orientation,
    margins,
    columns,
    columnGap,
  ];
}
