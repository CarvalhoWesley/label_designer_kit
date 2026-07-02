import 'package:equatable/equatable.dart';

/// A width/height pair expressed in millimeters.
class Size2D extends Equatable {
  const Size2D({required this.width, required this.height});

  const Size2D.zero() : width = 0, height = 0;

  factory Size2D.fromJson(Map<String, dynamic> json) {
    return Size2D(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  /// Width in millimeters.
  final double width;

  /// Height in millimeters.
  final double height;

  Size2D copyWith({double? width, double? height}) {
    return Size2D(width: width ?? this.width, height: height ?? this.height);
  }

  Map<String, dynamic> toJson() => {'width': width, 'height': height};

  @override
  List<Object?> get props => [width, height];

  @override
  String toString() => 'Size2D(width: $width, height: $height)';
}
