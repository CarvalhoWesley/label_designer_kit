// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewport_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ViewportStore on ViewportStoreBase, Store {
  late final _$zoomAtom = Atom(
    name: 'ViewportStoreBase.zoom',
    context: context,
  );

  @override
  double get zoom {
    _$zoomAtom.reportRead();
    return super.zoom;
  }

  @override
  set zoom(double value) {
    _$zoomAtom.reportWrite(value, super.zoom, () {
      super.zoom = value;
    });
  }

  late final _$panAtom = Atom(name: 'ViewportStoreBase.pan', context: context);

  @override
  Point get pan {
    _$panAtom.reportRead();
    return super.pan;
  }

  @override
  set pan(Point value) {
    _$panAtom.reportWrite(value, super.pan, () {
      super.pan = value;
    });
  }

  late final _$showGridAtom = Atom(
    name: 'ViewportStoreBase.showGrid',
    context: context,
  );

  @override
  bool get showGrid {
    _$showGridAtom.reportRead();
    return super.showGrid;
  }

  @override
  set showGrid(bool value) {
    _$showGridAtom.reportWrite(value, super.showGrid, () {
      super.showGrid = value;
    });
  }

  late final _$gridSizeMmAtom = Atom(
    name: 'ViewportStoreBase.gridSizeMm',
    context: context,
  );

  @override
  double get gridSizeMm {
    _$gridSizeMmAtom.reportRead();
    return super.gridSizeMm;
  }

  @override
  set gridSizeMm(double value) {
    _$gridSizeMmAtom.reportWrite(value, super.gridSizeMm, () {
      super.gridSizeMm = value;
    });
  }

  late final _$snapEnabledAtom = Atom(
    name: 'ViewportStoreBase.snapEnabled',
    context: context,
  );

  @override
  bool get snapEnabled {
    _$snapEnabledAtom.reportRead();
    return super.snapEnabled;
  }

  @override
  set snapEnabled(bool value) {
    _$snapEnabledAtom.reportWrite(value, super.snapEnabled, () {
      super.snapEnabled = value;
    });
  }

  late final _$showRulersAtom = Atom(
    name: 'ViewportStoreBase.showRulers',
    context: context,
  );

  @override
  bool get showRulers {
    _$showRulersAtom.reportRead();
    return super.showRulers;
  }

  @override
  set showRulers(bool value) {
    _$showRulersAtom.reportWrite(value, super.showRulers, () {
      super.showRulers = value;
    });
  }

  late final _$ViewportStoreBaseActionController = ActionController(
    name: 'ViewportStoreBase',
    context: context,
  );

  @override
  void setZoom(double value) {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.setZoom',
    );
    try {
      return super.setZoom(value);
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void zoomBy(double factor) {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.zoomBy',
    );
    try {
      return super.zoomBy(factor);
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPan(Point value) {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.setPan',
    );
    try {
      return super.setPan(value);
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void panBy(double dx, double dy) {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.panBy',
    );
    try {
      return super.panBy(dx, dy);
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetView() {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.resetView',
    );
    try {
      return super.resetView();
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void fitToPage({
    required double pageWidthMm,
    required double pageHeightMm,
    required double viewportWidthPx,
    required double viewportHeightPx,
  }) {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.fitToPage',
    );
    try {
      return super.fitToPage(
        pageWidthMm: pageWidthMm,
        pageHeightMm: pageHeightMm,
        viewportWidthPx: viewportWidthPx,
        viewportHeightPx: viewportHeightPx,
      );
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleGrid() {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.toggleGrid',
    );
    try {
      return super.toggleGrid();
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleSnap() {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.toggleSnap',
    );
    try {
      return super.toggleSnap();
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleRulers() {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.toggleRulers',
    );
    try {
      return super.toggleRulers();
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setGridSize(double mm) {
    final _$actionInfo = _$ViewportStoreBaseActionController.startAction(
      name: 'ViewportStoreBase.setGridSize',
    );
    try {
      return super.setGridSize(mm);
    } finally {
      _$ViewportStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
zoom: ${zoom},
pan: ${pan},
showGrid: ${showGrid},
gridSizeMm: ${gridSizeMm},
snapEnabled: ${snapEnabled},
showRulers: ${showRulers}
    ''';
  }
}
