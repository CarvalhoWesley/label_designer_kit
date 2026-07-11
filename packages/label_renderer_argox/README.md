# label_renderer_argox

Renderiza um `ResolvedDocument` em comandos PPLA (Printer Programming Language A) para impressoras Argox, via o `BaseRenderer` Template Method de `label_renderer`. Ver [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md), seção 11, e [docs/ROADMAP.md](../../docs/ROADMAP.md), etapa 16.

PPLB (Eltron/EPL2-compatível) é o segundo dialeto que este mesmo pacote deve cobrir (`ArgoxRendererOptions.dialect`), mas ainda não está implementado — `ArgoxRenderer.render` lança `UnimplementedError` para `ArgoxDialect.pplb`.

## Por que a exatidão de bytes aqui é diferente da dos outros renderers

`label_renderer_canvas` e `label_renderer_pdf` produzem PNG/PDF — formatos abertos, com especificação pública completa. PPLA é uma linguagem de impressora proprietária da Argox, sem manual de programação facilmente disponível online (o link oficial mais citado, `ArgoxPPLA.pdf`, está fora do ar). Não tive acesso a um manual completo nem a uma impressora real para validar.

Em vez de adivinhar a partir de memória, o layout de campos deste renderer foi **reconstruído e cruzado contra três implementações PPLA independentes e reais**, escritas por autores diferentes em linguagens diferentes:

1. [`ThomasDebrunner/label-printer-ppla`](https://github.com/ThomasDebrunner/label-printer-ppla) (Python) — testado pelo autor contra uma impressora Argox R-400 plus real via USB.
2. [`laghi/ppla-builder`](https://github.com/laghi/ppla-builder) (Node.js) — tem testes unitários com fixtures de bytes exatos.
3. [`gillianpalhano/printer-ppla`](https://github.com/gillianpalhano/printer-ppla) (TypeScript) — pacote npm mantido atualmente.

Os comandos de **texto** e **código de barras** (formato, largura de campo, ordem dos parâmetros) são idênticos nas três fontes — alta confiança. **Box/linha** têm uma divergência entre fontes (3 dígitos + letra maiúscula vs. 4 dígitos + minúscula); segui a versão mais recente/consistente internamente, mas é o ponto de menor confiança do pacote.

**Duas correções desde então, feitas contra uma impressora Argox real (203 DPI)** — nenhuma das três fontes acima cobria estes dois pontos corretamente:
1. Os campos de posição/dimensão (X/Y de elemento, altura de código de barras, espessura de caixa) são **centésimos de polegada**, não dots — ver `pplaHundredthsOfInch`.
2. O código de tamanho da fonte ASD smooth (campo `eee` do comando de texto) segue a tabela `Ann` do manual Datamax Class Series 2 (ex. `A12` para 12pt), não uma tabela numérica `000`-`006` inventada — ver `pplaAsdFontSubtype`. O código antigo enviava `000`-`006`, que ou é reservado (300 DPI+) ou não existe, fazendo a impressora cair num fonte padrão bem maior que o configurado.

O restante (comandos de orientação, código de barras, box/linha) ainda não foi validado contra hardware real além do que está descrito acima.

## Decisões de arquitetura e limitações conhecidas

- **Origem do sistema de coordenadas**: PPLA usa o canto **inferior-esquerdo** como origem, com Y crescendo para cima — o oposto de `ResolvedElement` (topo-esquerda, Y para baixo, igual a todos os outros renderers). `ArgoxRenderer._argoxY` faz essa conversão uma vez; X não precisa de ajuste. Diferente do `label_renderer_pdf`, não há risco de espelhar conteúdo (texto/imagem) — aqui é só um número numa string, não uma transformação de matriz.
- **Só 4 rotações fixas**: PPLA não suporta rotação arbitrária, apenas 0°/90°/180°/270°, com códigos não-sequenciais (`1`/`4`/`3`/`2`). `rotationDegrees` é arredondado para o múltiplo de 90° mais próximo.
- **Sem elipse/círculo**: PPLA só tem primitivas de retângulo (`box`, contorno apenas) e linha (`line`, reta ortogonal). `ShapeKind.ellipse`/`.circle` caem para o retângulo delimitador; `ShapeKind.line` diagonal (com `width` e `height` ambos não-nulos) não tem equivalente exato — a impressora provavelmente desenha um retângulo em vez de uma diagonal.
- **Sem preenchimento sólido**: o comando de caixa do PPLA só desenha contorno; `ResolvedShapeStyle.fillColor` não tem efeito nesta v1.
- **Fonte sempre ASD (`9`)**: PPLA não tem fontes TrueType nem tamanho arbitrário — só fontes bitmap fixas e uma família "ASD smooth" com tamanhos fixos em pt (6/8/10/12/14/18/24/30/36/48 em qualquer DPI; 4 e 72 só a partir de 300 DPI), por `Ann` (Tabela C-6 do manual Datamax Class Series 2). `pplaAsdFontSubtype` arredonda `fontSizeDots` para o tamanho disponível mais próximo. Negrito/itálico não têm equivalente na família ASD e são ignorados nesta v1.
- **QR Code e imagens não implementados**: nenhuma das três fontes de referência codifica QR em bytes reais (existe uma função de alto nível documentada em uma DLL fechada da Argox, mas não o formato de bytes). Imagem exigiria o subsistema de download de gráficos HEX/BMP do PPLA — fora do escopo desta etapa. Ambos são pulados silenciosamente (elemento não aparece na etiqueta) em vez de lançar exceção ou emitir um palpite não validado.
- **Unidades**: X/Y/largura/altura dos elementos, altura de código de barras e espessura de caixa são convertidos de `dots` para **centésimos de polegada** via `pplaHundredthsOfInch` — confirmado no manual Datamax ("Field data is interpreted in hundredths of an inch"), e não como as três fontes de referência sugeriam (dots diretos). A exceção é a largura de barra do código de barras (campos `c`/`d`), que o manual documenta explicitamente em dots.

## Uso

```dart
const layoutEngine = LabelLayoutEngine();
const renderer = ArgoxRenderer();

final resolved = layoutEngine.resolve(document, dados);
final pplaBytes = await renderer.render(resolved, const ArgoxRendererOptions(darkness: 12, copies: 1));
```

## Testes

```
dart test
```

Os testes de `ppla_fields_test.dart` fixam os valores exatos cruzados entre as três fontes (códigos de orientação, alfabeto de escala `0-9,A-O`, letras de tipo de código de barras). Os testes de `argox_renderer_test.dart` constroem a string esperada a partir dos campos individuais (não como um literal longo digitado à mão) — um dígito a mais ou a menos numa string de largura fixa de 20+ caracteres é fácil de errar e passaria despercebido num literal copiado errado.
