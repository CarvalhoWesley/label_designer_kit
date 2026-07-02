part of 'label_element.dart';

/// Error correction levels for [QRCodeElement], per the QR Code standard.
enum QrErrorCorrectionLevel { low, medium, quartile, high }

/// A QR Code. PDF417 and DataMatrix will be introduced as additional 2D
/// symbologies when `label_barcode` (implementation of the barcode/QR
/// encoding logic) is built; this element only models what the QR Code
/// standard specifically needs (error correction level).
class QRCodeElement extends LabelElement {
  const QRCodeElement({
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
    this.errorCorrectionLevel = QrErrorCorrectionLevel.medium,
  });

  /// Raw content or `{{ expression }}`, resolved by the Layout Engine.
  final String data;
  final QrErrorCorrectionLevel errorCorrectionLevel;

  @override
  String get typeName => 'qrcode';

  @override
  T accept<T>(LabelElementVisitor<T> visitor) => visitor.visitQrCode(this);

  QRCodeElement copyWith({
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
    QrErrorCorrectionLevel? errorCorrectionLevel,
  }) {
    return QRCodeElement(
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
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._commonJson(),
    'data': data,
    'errorCorrectionLevel': errorCorrectionLevel.name,
  };

  static QRCodeElement fromJson(Map<String, dynamic> json) {
    return QRCodeElement(
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
      errorCorrectionLevel: QrErrorCorrectionLevel.values.byName(
        json['errorCorrectionLevel'] as String? ?? 'medium',
      ),
    );
  }

  @override
  List<Object?> get props => [...super.props, data, errorCorrectionLevel];
}
