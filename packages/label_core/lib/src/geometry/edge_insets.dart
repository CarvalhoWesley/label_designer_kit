import 'package:equatable/equatable.dart';

/// Margins expressed in millimeters, used by [PageConfig].
class EdgeInsets extends Equatable {
  const EdgeInsets({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  const EdgeInsets.zero() : top = 0, right = 0, bottom = 0, left = 0;

  const EdgeInsets.all(double value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  factory EdgeInsets.fromJson(Map<String, dynamic> json) {
    return EdgeInsets(
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
      left: (json['left'] as num).toDouble(),
    );
  }

  final double top;
  final double right;
  final double bottom;
  final double left;

  Map<String, dynamic> toJson() => {
    'top': top,
    'right': right,
    'bottom': bottom,
    'left': left,
  };

  @override
  List<Object?> get props => [top, right, bottom, left];

  @override
  String toString() =>
      'EdgeInsets(top: $top, right: $right, bottom: $bottom, left: $left)';
}
