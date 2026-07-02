import 'package:equatable/equatable.dart';

import '../elements/label_element.dart';
import 'document_metadata.dart';
import 'label_layer.dart';
import 'label_style.dart';
import 'label_variable.dart';
import 'page_config.dart';

/// Current `.label` JSON schema version produced by [LabelDocument.toJson].
///
/// `label_serialization` uses this to decide whether an older file needs
/// migration before being decoded into a [LabelDocument].
const int labelDocumentSchemaVersion = 1;

/// The root aggregate of the Label Designer Framework's domain model.
///
/// A [LabelDocument] is a complete description of a label's layout: page
/// size, layers, reusable styles, declared variables and the elements
/// placed on the canvas. It knows nothing about printers, PPLA/ZPL/TSPL,
/// dots or DPI-specific rendering — see the architecture docs' layering
/// rules (`docs/ARCHITECTURE.md`).
class LabelDocument extends Equatable {
  const LabelDocument({
    this.version = labelDocumentSchemaVersion,
    required this.name,
    required this.page,
    this.layers = const [],
    this.styles = const [],
    this.variables = const [],
    this.elements = const [],
    required this.metadata,
  });

  /// Creates an empty document with a single default layer and an A7-ish
  /// 100x50mm page at 203 DPI, ready to be handed to the editor.
  factory LabelDocument.blank({String name = 'Nova etiqueta'}) {
    final now = DateTime.now();
    return LabelDocument(
      name: name,
      page: const PageConfig(width: 100, height: 50),
      layers: const [LabelLayer(id: 'layer-1', name: 'Base', order: 0)],
      metadata: DocumentMetadata(createdAt: now, updatedAt: now),
    );
  }

  factory LabelDocument.fromJson(Map<String, dynamic> json) {
    return LabelDocument(
      version: json['version'] as int? ?? labelDocumentSchemaVersion,
      name: json['name'] as String,
      page: PageConfig.fromJson(json['page'] as Map<String, dynamic>),
      layers: (json['layers'] as List<dynamic>? ?? [])
          .map((layer) => LabelLayer.fromJson(layer as Map<String, dynamic>))
          .toList(),
      styles: (json['styles'] as List<dynamic>? ?? [])
          .map((style) => LabelStyle.fromJson(style as Map<String, dynamic>))
          .toList(),
      variables: (json['variables'] as List<dynamic>? ?? [])
          .map(
            (variable) =>
                LabelVariable.fromJson(variable as Map<String, dynamic>),
          )
          .toList(),
      elements: (json['elements'] as List<dynamic>? ?? [])
          .map(
            (element) => LabelElement.fromJson(element as Map<String, dynamic>),
          )
          .toList(),
      metadata: DocumentMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
    );
  }

  final int version;
  final String name;
  final PageConfig page;
  final List<LabelLayer> layers;
  final List<LabelStyle> styles;
  final List<LabelVariable> variables;
  final List<LabelElement> elements;
  final DocumentMetadata metadata;

  LabelDocument copyWith({
    int? version,
    String? name,
    PageConfig? page,
    List<LabelLayer>? layers,
    List<LabelStyle>? styles,
    List<LabelVariable>? variables,
    List<LabelElement>? elements,
    DocumentMetadata? metadata,
  }) {
    return LabelDocument(
      version: version ?? this.version,
      name: name ?? this.name,
      page: page ?? this.page,
      layers: layers ?? this.layers,
      styles: styles ?? this.styles,
      variables: variables ?? this.variables,
      elements: elements ?? this.elements,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'name': name,
    'page': page.toJson(),
    'layers': layers.map((layer) => layer.toJson()).toList(),
    'styles': styles.map((style) => style.toJson()).toList(),
    'variables': variables.map((variable) => variable.toJson()).toList(),
    'elements': elements.map((element) => element.toJson()).toList(),
    'metadata': metadata.toJson(),
  };

  @override
  List<Object?> get props => [
    version,
    name,
    page,
    layers,
    styles,
    variables,
    elements,
    metadata,
  ];
}
