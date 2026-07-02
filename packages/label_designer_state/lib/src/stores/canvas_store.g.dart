// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CanvasStore on CanvasStoreBase, Store {
  Computed<bool>? _$hasActiveGuidesComputed;

  @override
  bool get hasActiveGuides => (_$hasActiveGuidesComputed ??= Computed<bool>(
    () => super.hasActiveGuides,
    name: 'CanvasStoreBase.hasActiveGuides',
  )).value;

  late final _$isDraggingAtom = Atom(
    name: 'CanvasStoreBase.isDragging',
    context: context,
  );

  @override
  bool get isDragging {
    _$isDraggingAtom.reportRead();
    return super.isDragging;
  }

  @override
  set isDragging(bool value) {
    _$isDraggingAtom.reportWrite(value, super.isDragging, () {
      super.isDragging = value;
    });
  }

  late final _$activeResizeHandleAtom = Atom(
    name: 'CanvasStoreBase.activeResizeHandle',
    context: context,
  );

  @override
  ResizeHandle? get activeResizeHandle {
    _$activeResizeHandleAtom.reportRead();
    return super.activeResizeHandle;
  }

  @override
  set activeResizeHandle(ResizeHandle? value) {
    _$activeResizeHandleAtom.reportWrite(value, super.activeResizeHandle, () {
      super.activeResizeHandle = value;
    });
  }

  late final _$activeGuidesXAtom = Atom(
    name: 'CanvasStoreBase.activeGuidesX',
    context: context,
  );

  @override
  ObservableList<double> get activeGuidesX {
    _$activeGuidesXAtom.reportRead();
    return super.activeGuidesX;
  }

  @override
  set activeGuidesX(ObservableList<double> value) {
    _$activeGuidesXAtom.reportWrite(value, super.activeGuidesX, () {
      super.activeGuidesX = value;
    });
  }

  late final _$activeGuidesYAtom = Atom(
    name: 'CanvasStoreBase.activeGuidesY',
    context: context,
  );

  @override
  ObservableList<double> get activeGuidesY {
    _$activeGuidesYAtom.reportRead();
    return super.activeGuidesY;
  }

  @override
  set activeGuidesY(ObservableList<double> value) {
    _$activeGuidesYAtom.reportWrite(value, super.activeGuidesY, () {
      super.activeGuidesY = value;
    });
  }

  late final _$dragPreviewPositionsAtom = Atom(
    name: 'CanvasStoreBase.dragPreviewPositions',
    context: context,
  );

  @override
  ObservableMap<String, Point> get dragPreviewPositions {
    _$dragPreviewPositionsAtom.reportRead();
    return super.dragPreviewPositions;
  }

  @override
  set dragPreviewPositions(ObservableMap<String, Point> value) {
    _$dragPreviewPositionsAtom.reportWrite(
      value,
      super.dragPreviewPositions,
      () {
        super.dragPreviewPositions = value;
      },
    );
  }

  late final _$resizingElementIdAtom = Atom(
    name: 'CanvasStoreBase.resizingElementId',
    context: context,
  );

  @override
  String? get resizingElementId {
    _$resizingElementIdAtom.reportRead();
    return super.resizingElementId;
  }

  @override
  set resizingElementId(String? value) {
    _$resizingElementIdAtom.reportWrite(value, super.resizingElementId, () {
      super.resizingElementId = value;
    });
  }

  late final _$resizePreviewPositionAtom = Atom(
    name: 'CanvasStoreBase.resizePreviewPosition',
    context: context,
  );

  @override
  Point? get resizePreviewPosition {
    _$resizePreviewPositionAtom.reportRead();
    return super.resizePreviewPosition;
  }

  @override
  set resizePreviewPosition(Point? value) {
    _$resizePreviewPositionAtom.reportWrite(
      value,
      super.resizePreviewPosition,
      () {
        super.resizePreviewPosition = value;
      },
    );
  }

  late final _$resizePreviewSizeAtom = Atom(
    name: 'CanvasStoreBase.resizePreviewSize',
    context: context,
  );

  @override
  Size2D? get resizePreviewSize {
    _$resizePreviewSizeAtom.reportRead();
    return super.resizePreviewSize;
  }

  @override
  set resizePreviewSize(Size2D? value) {
    _$resizePreviewSizeAtom.reportWrite(value, super.resizePreviewSize, () {
      super.resizePreviewSize = value;
    });
  }

  late final _$rotatingElementIdAtom = Atom(
    name: 'CanvasStoreBase.rotatingElementId',
    context: context,
  );

  @override
  String? get rotatingElementId {
    _$rotatingElementIdAtom.reportRead();
    return super.rotatingElementId;
  }

  @override
  set rotatingElementId(String? value) {
    _$rotatingElementIdAtom.reportWrite(value, super.rotatingElementId, () {
      super.rotatingElementId = value;
    });
  }

  late final _$rotationPreviewDegreesAtom = Atom(
    name: 'CanvasStoreBase.rotationPreviewDegrees',
    context: context,
  );

  @override
  double? get rotationPreviewDegrees {
    _$rotationPreviewDegreesAtom.reportRead();
    return super.rotationPreviewDegrees;
  }

  @override
  set rotationPreviewDegrees(double? value) {
    _$rotationPreviewDegreesAtom.reportWrite(
      value,
      super.rotationPreviewDegrees,
      () {
        super.rotationPreviewDegrees = value;
      },
    );
  }

  late final _$marqueeStartAtom = Atom(
    name: 'CanvasStoreBase.marqueeStart',
    context: context,
  );

  @override
  Point? get marqueeStart {
    _$marqueeStartAtom.reportRead();
    return super.marqueeStart;
  }

  @override
  set marqueeStart(Point? value) {
    _$marqueeStartAtom.reportWrite(value, super.marqueeStart, () {
      super.marqueeStart = value;
    });
  }

  late final _$marqueeEndAtom = Atom(
    name: 'CanvasStoreBase.marqueeEnd',
    context: context,
  );

  @override
  Point? get marqueeEnd {
    _$marqueeEndAtom.reportRead();
    return super.marqueeEnd;
  }

  @override
  set marqueeEnd(Point? value) {
    _$marqueeEndAtom.reportWrite(value, super.marqueeEnd, () {
      super.marqueeEnd = value;
    });
  }

  late final _$CanvasStoreBaseActionController = ActionController(
    name: 'CanvasStoreBase',
    context: context,
  );

  @override
  void beginDrag({ResizeHandle? handle}) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.beginDrag',
    );
    try {
      return super.beginDrag(handle: handle);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endDrag() {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.endDrag',
    );
    try {
      return super.endDrag();
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setGuides({List<double> x = const [], List<double> y = const []}) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.setGuides',
    );
    try {
      return super.setGuides(x: x, y: y);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearGuides() {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.clearGuides',
    );
    try {
      return super.clearGuides();
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginElementDrag(Map<String, Point> startPositions) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.beginElementDrag',
    );
    try {
      return super.beginElementDrag(startPositions);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateElementDrag(Map<String, Point> livePositions) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.updateElementDrag',
    );
    try {
      return super.updateElementDrag(livePositions);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endElementDrag() {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.endElementDrag',
    );
    try {
      return super.endElementDrag();
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginResize(
    String elementId,
    ResizeHandle handle, {
    required Point position,
    required Size2D size,
  }) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.beginResize',
    );
    try {
      return super.beginResize(
        elementId,
        handle,
        position: position,
        size: size,
      );
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateResize({required Point position, required Size2D size}) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.updateResize',
    );
    try {
      return super.updateResize(position: position, size: size);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endResize() {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.endResize',
    );
    try {
      return super.endResize();
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginRotate(String elementId, {required double rotationDegrees}) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.beginRotate',
    );
    try {
      return super.beginRotate(elementId, rotationDegrees: rotationDegrees);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateRotate(double rotationDegrees) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.updateRotate',
    );
    try {
      return super.updateRotate(rotationDegrees);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endRotate() {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.endRotate',
    );
    try {
      return super.endRotate();
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginMarquee(Point start) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.beginMarquee',
    );
    try {
      return super.beginMarquee(start);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateMarquee(Point current) {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.updateMarquee',
    );
    try {
      return super.updateMarquee(current);
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void endMarquee() {
    final _$actionInfo = _$CanvasStoreBaseActionController.startAction(
      name: 'CanvasStoreBase.endMarquee',
    );
    try {
      return super.endMarquee();
    } finally {
      _$CanvasStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isDragging: ${isDragging},
activeResizeHandle: ${activeResizeHandle},
activeGuidesX: ${activeGuidesX},
activeGuidesY: ${activeGuidesY},
dragPreviewPositions: ${dragPreviewPositions},
resizingElementId: ${resizingElementId},
resizePreviewPosition: ${resizePreviewPosition},
resizePreviewSize: ${resizePreviewSize},
rotatingElementId: ${rotatingElementId},
rotationPreviewDegrees: ${rotationPreviewDegrees},
marqueeStart: ${marqueeStart},
marqueeEnd: ${marqueeEnd},
hasActiveGuides: ${hasActiveGuides}
    ''';
  }
}
