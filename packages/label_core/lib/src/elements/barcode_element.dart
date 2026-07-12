part of 'label_element.dart';

/// 1D barcode symbologies supported by [BarcodeElement].
///
/// New symbologies are added here and handled by `label_barcode`; the
/// element model itself stays agnostic of how each is encoded.
enum BarcodeSymbology { ean13, ean8, code39, code128, upc, itf, codabar }

/// A 1D barcode. See [QRCodeElement] for 2D symbologies.
class BarcodeElement extends LabelElement {
  const BarcodeElement({
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
    required this.data,
    required this.symbology,
    this.showText = true,
    this.moduleWidth = 0.33,
    this.textSize = 0,
  });

  /// Raw content or `{{ expression }}`, resolved by the Layout Engine.
  final String data;
  final BarcodeSymbology symbology;

  /// Whether the human-readable value is printed below the bars.
  final bool showText;

  /// Width of the narrowest bar, in millimeters.
  final double moduleWidth;

  /// Font size of the human-readable value, in millimeters. `0` (the
  /// default) means auto-derived from the element's own box height instead
  /// of a fixed size — see `CanvasRenderer`'s `_paintBarcode`. Same
  /// zero-means-default convention PPLA itself uses for barcode fields
  /// (Datamax manual: "Placing 0 ... in the symbol height field will
  /// result in the default bar code height").
  final double textSize;

  @override
  String get typeName => 'barcode';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitBarcode(this);

  BarcodeElement copyWith({
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
    String? data,
    BarcodeSymbology? symbology,
    bool? showText,
    double? moduleWidth,
    double? textSize,
  }) {
    return BarcodeElement(
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
      data: data ?? this.data,
      symbology: symbology ?? this.symbology,
      showText: showText ?? this.showText,
      moduleWidth: moduleWidth ?? this.moduleWidth,
      textSize: textSize ?? this.textSize,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'data': data,
    'symbology': symbology.name,
    'showText': showText,
    'moduleWidth': moduleWidth,
    'textSize': textSize,
  };

  static BarcodeElement fromJson(Map<String, dynamic> json) {
    return BarcodeElement(
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
      data: json['data'] as String,
      symbology: BarcodeSymbology.values.byName(json['symbology'] as String),
      showText: json['showText'] as bool? ?? true,
      moduleWidth: (json['moduleWidth'] as num?)?.toDouble() ?? 0.33,
      textSize: (json['textSize'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    data,
    symbology,
    showText,
    moduleWidth,
    textSize,
  ];
}
