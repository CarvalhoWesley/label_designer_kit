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
  });

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

  PageConfig copyWith({
    double? width,
    double? height,
    Unit? unit,
    Dpi? dpi,
    PageOrientation? orientation,
    EdgeInsets? margins,
  }) {
    return PageConfig(
      width: width ?? this.width,
      height: height ?? this.height,
      unit: unit ?? this.unit,
      dpi: dpi ?? this.dpi,
      orientation: orientation ?? this.orientation,
      margins: margins ?? this.margins,
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'unit': unit.name,
    'dpi': dpi.value,
    'orientation': orientation.name,
    'margins': margins.toJson(),
  };

  @override
  List<Object?> get props => [width, height, unit, dpi, orientation, margins];
}
