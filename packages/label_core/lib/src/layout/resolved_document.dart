import 'package:equatable/equatable.dart';

import 'resolved_element.dart';

/// The output of the Layout Engine: a [LabelDocument] with every variable,
/// expression and unit already resolved to dots, ready for a
/// `LabelRenderer` to convert to a printer language, PDF or image.
///
/// Renderers depend only on this type — never on `label_layout_engine`
/// itself — which is what lets `label_core` stay the single shared
/// contract between the two sides (dependency inversion; see
/// `docs/ARCHITECTURE.md` section 9).
class ResolvedDocument extends Equatable {
  const ResolvedDocument({
    required this.widthDots,
    required this.heightDots,
    required this.dpi,
    required this.elements,
  });

  final int widthDots;
  final int heightDots;

  /// Dots per inch this document was resolved for (203/300/600).
  final int dpi;

  /// Flattened, paint-ordered by nothing in particular — renderers should
  /// sort by [ResolvedElement.zIndex] themselves if their output format
  /// requires explicit ordering.
  final List<ResolvedElement> elements;

  @override
  List<Object?> get props => [widthDots, heightDots, dpi, elements];
}
