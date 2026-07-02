# label_layout_engine

Resolve um `LabelDocument` + dados de negócio em um `ResolvedDocument` — a única camada que conhece variáveis, expressões, milímetros, DPI, dots, alinhamento e rotação. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 9.

Nenhum renderer recalcula layout: eles recebem sempre um `ResolvedDocument` já pronto.

## Uso

```dart
const engine = LabelLayoutEngine();

final resolved = engine.resolve(document, {
  'produto': 'Parafuso M6',
  'preco': 3.9,
});
```

- `{{ }}` em `TextElement.content`, `BarcodeElement.data`, `QRCodeElement.data` e `ImageElement.source` são resolvidos; uma expressão que falha vira o marcador `#ERROR#` em vez de abortar a impressão inteira.
- `GroupElement` é achatado recursivamente — filhos herdam posição e rotação do grupo (incluindo grupos aninhados), e o grupo em si não aparece no resultado.
- Problemas estruturais do template (ex.: elemento com dimensão resolvida ≤ 0, `DateElement` com `source: variable` sem `variableName`) lançam `LayoutException` — são bugs do template, não dados ausentes de uma linha específica.

## Testes

```
dart test
```
