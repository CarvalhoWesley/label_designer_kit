import 'package:equatable/equatable.dart';

/// A single "ink" rectangle of an encoded symbol, positioned and sized as
/// a fraction (0.0–1.0) of the symbol's own bounding box — e.g. `left:
/// 0.2, width: 0.05` means a mark starting 20% of the way across and 5%
/// wide, regardless of how many dots that ends up being at render time.
class SymbolModule extends Equatable {
  const SymbolModule({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  @override
  List<Object?> get props => [left, top, width, height];
}

/// The output of encoding data for a symbology: a flat list of "ink"
/// rectangles, with no notion of pixels, dots or color.
///
/// A 1D symbology (EAN13, Code128, ...) produces full-height bars; a 2D
/// symbology (QR Code, ...) produces many small square modules. Renderers
/// don't need to tell the two apart — they scale every rectangle to the
/// element's box in dots and paint it.
class BarcodeSymbol {
  const BarcodeSymbol({required this.modules});

  final List<SymbolModule> modules;
}
