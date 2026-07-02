// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PropertyStore on PropertyStoreBase, Store {
  Computed<List<LabelElement>>? _$selectedElementsComputed;

  @override
  List<LabelElement> get selectedElements =>
      (_$selectedElementsComputed ??= Computed<List<LabelElement>>(
        () => super.selectedElements,
        name: 'PropertyStoreBase.selectedElements',
      )).value;
  Computed<LabelElement?>? _$singleSelectedElementComputed;

  @override
  LabelElement? get singleSelectedElement =>
      (_$singleSelectedElementComputed ??= Computed<LabelElement?>(
        () => super.singleSelectedElement,
        name: 'PropertyStoreBase.singleSelectedElement',
      )).value;

  @override
  String toString() {
    return '''
selectedElements: ${selectedElements},
singleSelectedElement: ${singleSelectedElement}
    ''';
  }
}
