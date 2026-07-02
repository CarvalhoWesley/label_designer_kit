part of 'label_element.dart';

/// How an image is fitted inside its bounding box, mirroring the
/// well-known `BoxFit` semantics without depending on Flutter.
enum ImageFit { contain, cover, fill, fitWidth, fitHeight, none }

/// A raster image placed on the label.
///
/// [source] is a reference the app resolves to bytes (asset path, file
/// path, URL or `{{ expression }}` for data-driven images) — `label_core`
/// does not load or decode image bytes itself.
class ImageElement extends LabelElement {
  const ImageElement({
    required super.id,
    required super.name,
    required super.position,
    required super.size,
    super.rotation,
    super.visible,
    super.locked,
    super.opacity,
    required super.layerId,
    super.zIndex,
    super.transform,
    required this.source,
    this.fit = ImageFit.contain,
    this.cropPosition,
    this.cropSize,
  });

  final String source;
  final ImageFit fit;

  /// Optional crop rectangle within the source image, in millimeters of
  /// the *source's own* coordinate space. `null` means no crop.
  final Point? cropPosition;
  final Size2D? cropSize;

  @override
  String get typeName => 'image';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitImage(this);

  ImageElement copyWith({
    String? id,
    String? name,
    Point? position,
    Size2D? size,
    double? rotation,
    bool? visible,
    bool? locked,
    double? opacity,
    String? layerId,
    int? zIndex,
    ElementTransform? transform,
    String? source,
    ImageFit? fit,
    Point? cropPosition,
    Size2D? cropSize,
  }) {
    return ImageElement(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: opacity ?? this.opacity,
      layerId: layerId ?? this.layerId,
      zIndex: zIndex ?? this.zIndex,
      transform: transform ?? this.transform,
      source: source ?? this.source,
      fit: fit ?? this.fit,
      cropPosition: cropPosition ?? this.cropPosition,
      cropSize: cropSize ?? this.cropSize,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'source': source,
    'fit': fit.name,
    if (cropPosition != null) 'cropPosition': cropPosition!.toJson(),
    if (cropSize != null) 'cropSize': cropSize!.toJson(),
  };

  static ImageElement fromJson(Map<String, dynamic> json) {
    return ImageElement(
      id: json['id'] as String,
      name: json['name'] as String,
      position: Point.fromJson(json['position'] as Map<String, dynamic>),
      size: Size2D.fromJson(json['size'] as Map<String, dynamic>),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      layerId: json['layerId'] as String,
      zIndex: json['zIndex'] as int? ?? 0,
      transform: json['transform'] == null
          ? const ElementTransform.identity()
          : ElementTransform.fromJson(
              json['transform'] as Map<String, dynamic>,
            ),
      source: json['source'] as String,
      fit: ImageFit.values.byName(json['fit'] as String? ?? 'contain'),
      cropPosition: json['cropPosition'] == null
          ? null
          : Point.fromJson(json['cropPosition'] as Map<String, dynamic>),
      cropSize: json['cropSize'] == null
          ? null
          : Size2D.fromJson(json['cropSize'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    source,
    fit,
    cropPosition,
    cropSize,
  ];
}
