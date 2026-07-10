import 'package:label_core/label_core.dart';
import 'package:label_expression_engine/label_expression_engine.dart';

import 'errors.dart';
import 'geometry/rotation.dart';
import 'payload_resolver.dart';

/// The absolute position/rotation of the nesting level an element is being
/// resolved in — either the page itself (the root) or an ancestor
/// `GroupElement` that has already been resolved.
class _AncestorFrame {
  const _AncestorFrame({
    required this.absoluteCenter,
    required this.absoluteRotationDegrees,
    required this.pivotLocal,
  });

  final Point absoluteCenter;
  final double absoluteRotationDegrees;

  /// This frame owner's own center, expressed in *its* local (unrotated)
  /// coordinate space — i.e. `(size.width / 2, size.height / 2)` for a
  /// group, or the origin for the page. Used to find a child's offset
  /// from the pivot before rotating it.
  final Point pivotLocal;
}

/// Resolves a [LabelDocument] against a data map into a [ResolvedDocument]
/// — every `{{ }}` expression evaluated, every style reference applied,
/// every measurement converted from millimeters to dots, every rotation
/// (including nested groups) composed into an absolute value.
///
/// This is the **only** place in the framework allowed to do any of that;
/// renderers receive an already-resolved [ResolvedDocument] and must not
/// recompute layout (see `docs/ARCHITECTURE.md` sections 1–2 and 9).
class LabelLayoutEngine {
  const LabelLayoutEngine({this.expressionEngine = const ExpressionEngine()});

  final ExpressionEngine expressionEngine;

  ResolvedDocument resolve(LabelDocument document, Map<String, dynamic> data) {
    final dpi = document.page.dpi;
    final payloadResolver = PayloadResolver(
      document: document,
      data: data,
      expressionEngine: expressionEngine,
      dpi: dpi,
    );

    return ResolvedDocument(
      widthDots: dpi.mmToDots(document.page.width),
      heightDots: dpi.mmToDots(document.page.height),
      dpi: dpi.value,
      elements: _resolveElements(document, payloadResolver, dpi, 0),
    );
  }

  /// Resolves a batch of [records] (one data map per label) against
  /// [document], tiling them across `document.page.columns` columns the
  /// way they'll physically sit on the roll — see `docs/ARCHITECTURE.md`
  /// (colunas de rolo) and `docs/ROADMAP.md` etapa 19.
  ///
  /// Each returned [ResolvedDocument] is one physical row of the roll: its
  /// `widthDots`/`heightDots` always span the *full* row (`columns` labels
  /// plus the gaps between them), even for a trailing row with fewer than
  /// `columns` records, because that's what the printer's gap sensor sees
  /// as a single physical label. With `document.page.columns == 1`, this
  /// is equivalent, record by record, to calling [resolve] once per
  /// record.
  List<ResolvedDocument> resolveBatch(
    LabelDocument document,
    List<Map<String, dynamic>> records,
  ) {
    final page = document.page;
    final dpi = page.dpi;
    final columns = page.columns;
    final rowWidthDots = dpi.mmToDots(
      columns * page.width + (columns - 1) * page.columnGap,
    );
    final rowHeightDots = dpi.mmToDots(page.height);

    final rows = <ResolvedDocument>[];
    for (var start = 0; start < records.length; start += columns) {
      final rowRecords = records.skip(start).take(columns);
      final rowElements = <ResolvedElement>[];
      var column = 0;
      for (final data in rowRecords) {
        final payloadResolver = PayloadResolver(
          document: document,
          data: data,
          expressionEngine: expressionEngine,
          dpi: dpi,
        );
        final offsetXMm = column * (page.width + page.columnGap);
        rowElements.addAll(
          _resolveElements(document, payloadResolver, dpi, offsetXMm),
        );
        column++;
      }
      rows.add(
        ResolvedDocument(
          widthDots: rowWidthDots,
          heightDots: rowHeightDots,
          dpi: dpi.value,
          elements: rowElements,
        ),
      );
    }
    return rows;
  }

  List<ResolvedElement> _resolveElements(
    LabelDocument document,
    PayloadResolver payloadResolver,
    Dpi dpi,
    double offsetXMm,
  ) {
    final rootFrame = _AncestorFrame(
      absoluteCenter: Point(x: offsetXMm, y: 0),
      absoluteRotationDegrees: 0,
      pivotLocal: Point.zero(),
    );
    final resolvedElements = <ResolvedElement>[];
    for (final element in document.elements) {
      resolvedElements.addAll(
        _resolveElement(element, rootFrame, dpi, payloadResolver),
      );
    }
    return resolvedElements;
  }

  List<ResolvedElement> _resolveElement(
    LabelElement element,
    _AncestorFrame parent,
    Dpi dpi,
    PayloadResolver payloadResolver,
  ) {
    final localCenter = Point(
      x: element.position.x + element.size.width / 2,
      y: element.position.y + element.size.height / 2,
    );
    final offsetFromPivot = Point(
      x: localCenter.x - parent.pivotLocal.x,
      y: localCenter.y - parent.pivotLocal.y,
    );
    final rotatedOffset = rotateVector(
      offsetFromPivot,
      parent.absoluteRotationDegrees,
    );
    final absoluteCenter = Point(
      x: parent.absoluteCenter.x + rotatedOffset.x,
      y: parent.absoluteCenter.y + rotatedOffset.y,
    );
    final absoluteRotationDegrees =
        parent.absoluteRotationDegrees + element.rotation;

    if (element is GroupElement) {
      final childFrame = _AncestorFrame(
        absoluteCenter: absoluteCenter,
        absoluteRotationDegrees: absoluteRotationDegrees,
        pivotLocal: Point(
          x: element.size.width / 2,
          y: element.size.height / 2,
        ),
      );
      final resolved = <ResolvedElement>[];
      for (final child in element.children) {
        resolved.addAll(
          _resolveElement(child, childFrame, dpi, payloadResolver),
        );
      }
      return resolved;
    }

    final payload = element.accept(payloadResolver);
    if (payload == null) return const [];

    final topLeft = Point(
      x: absoluteCenter.x - element.size.width / 2,
      y: absoluteCenter.y - element.size.height / 2,
    );
    final widthDots = dpi.mmToDots(element.size.width);
    final heightDots = dpi.mmToDots(element.size.height);

    // A LineElement's "size" is a (dx, dy) delta to its end point (see
    // label_core's LineElement doc comment), so a purely horizontal or
    // vertical line legitimately resolves one axis to 0 — only a
    // zero-length line (both axes 0) is invalid. Every other element type
    // is a box and must be positive on both axes.
    final hasValidDimensions = element is LineElement
        ? widthDots != 0 || heightDots != 0
        : widthDots > 0 && heightDots > 0;

    if (!hasValidDimensions) {
      throw LayoutException(
        'Elemento "${element.name}" (${element.id}) resolveu para uma '
        'dimensão inválida: ${widthDots}x$heightDots dots. Verifique o '
        'tamanho do elemento e o DPI da página.',
      );
    }

    return [
      ResolvedElement(
        id: element.id,
        xDots: dpi.mmToDots(topLeft.x),
        yDots: dpi.mmToDots(topLeft.y),
        widthDots: widthDots,
        heightDots: heightDots,
        rotationDegrees: absoluteRotationDegrees,
        zIndex: element.zIndex,
        opacity: element.opacity,
        payload: payload,
      ),
    ];
  }
}
