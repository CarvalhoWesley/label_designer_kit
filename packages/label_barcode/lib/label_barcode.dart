/// Geração de símbolos de código de barras/QR — um padrão de módulos
/// abstrato, sem desenhar nada. Consumido por `label_renderer_canvas`,
/// `label_renderer_pdf` e qualquer renderer futuro. Ver
/// `docs/ARCHITECTURE.md` seção 11.
///
/// Adapta `package:barcode` (Adapter pattern) atrás de [BarcodeEncoder]/
/// [QrCodeEncoder] — nenhum consumidor deste pacote precisa importar
/// `package:barcode` diretamente.
library;

export 'src/encoders.dart';
export 'src/errors.dart';
export 'src/package_barcode_adapter.dart';
export 'src/symbol.dart';
