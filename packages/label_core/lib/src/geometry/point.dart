import 'package:equatable/equatable.dart';

/// A 2D position expressed in millimeters, relative to the top-left corner
/// of the label page.
///
/// All editing in the Label Designer Framework happens in millimeters.
/// Conversion to dots only ever occurs inside the Layout Engine.
class Point extends Equatable {
  const Point({required this.x, required this.y});

  const Point.zero() : x = 0, y = 0;

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  /// Horizontal offset in millimeters.
  final double x;

  /// Vertical offset in millimeters.
  final double y;

  Point copyWith({double? x, double? y}) {
    return Point(x: x ?? this.x, y: y ?? this.y);
  }

  Point translate(double dx, double dy) => Point(x: x + dx, y: y + dy);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'Point(x: $x, y: $y)';
}
