# label_core

Modelos de domínio do [Label Designer Framework](../../docs/ARCHITECTURE.md): `LabelDocument`, `LabelElement` e seus subtipos, além dos value objects de geometria e unidades.

Pacote Dart puro — sem dependência de Flutter, impressoras ou renderização. Ver `docs/ARCHITECTURE.md` na raiz do workspace para as regras de camadas.

## Conteúdo

- `LabelDocument`, `PageConfig`, `LabelLayer`, `LabelStyle`, `LabelVariable`, `DocumentMetadata`
- `LabelElement` (sealed) e subtipos: `TextElement`, `BarcodeElement`, `QRCodeElement`, `ImageElement`, `RectangleElement`, `EllipseElement`, `CircleElement`, `LineElement`, `VariableElement`, `DateElement`, `TimeElement`, `TableElement`, `GroupElement`
- `LabelElementVisitor<T>` para operações por tipo sem `is`/`as`
- Value objects: `Point`, `Size2D`, `EdgeInsets`, `Unit`, `Dpi`

## Testes

```
dart test
```
