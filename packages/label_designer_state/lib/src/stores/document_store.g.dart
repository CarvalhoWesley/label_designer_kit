// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DocumentStore on DocumentStoreBase, Store {
  Computed<List<LabelElement>>? _$elementsComputed;

  @override
  List<LabelElement> get elements =>
      (_$elementsComputed ??= Computed<List<LabelElement>>(
        () => super.elements,
        name: 'DocumentStoreBase.elements',
      )).value;
  Computed<List<LabelLayer>>? _$layersComputed;

  @override
  List<LabelLayer> get layers =>
      (_$layersComputed ??= Computed<List<LabelLayer>>(
        () => super.layers,
        name: 'DocumentStoreBase.layers',
      )).value;
  Computed<List<LabelStyle>>? _$stylesComputed;

  @override
  List<LabelStyle> get styles =>
      (_$stylesComputed ??= Computed<List<LabelStyle>>(
        () => super.styles,
        name: 'DocumentStoreBase.styles',
      )).value;
  Computed<List<LabelVariable>>? _$variablesComputed;

  @override
  List<LabelVariable> get variables =>
      (_$variablesComputed ??= Computed<List<LabelVariable>>(
        () => super.variables,
        name: 'DocumentStoreBase.variables',
      )).value;

  late final _$documentAtom = Atom(
    name: 'DocumentStoreBase.document',
    context: context,
  );

  @override
  LabelDocument get document {
    _$documentAtom.reportRead();
    return super.document;
  }

  @override
  set document(LabelDocument value) {
    _$documentAtom.reportWrite(value, super.document, () {
      super.document = value;
    });
  }

  late final _$DocumentStoreBaseActionController = ActionController(
    name: 'DocumentStoreBase',
    context: context,
  );

  @override
  void replaceDocument(LabelDocument newDocument) {
    final _$actionInfo = _$DocumentStoreBaseActionController.startAction(
      name: 'DocumentStoreBase.replaceDocument',
    );
    try {
      return super.replaceDocument(newDocument);
    } finally {
      _$DocumentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
document: ${document},
elements: ${elements},
layers: ${layers},
styles: ${styles},
variables: ${variables}
    ''';
  }
}
