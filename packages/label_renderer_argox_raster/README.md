# label_renderer_argox_raster

Rasteriza um `ResolvedDocument` inteiro via `label_renderer_canvas` (tipografia real, código de barras, QR, formas preenchidas — o mesmo motor do Live Preview) e envia o resultado como uma imagem monocromática para uma impressora Argox, usando o comando de download de imagem do PPLA — em vez dos comandos nativos por elemento que `label_renderer_argox` usa.

Existe porque o PPLA nativo tem limites reais e permanentes: só uma família de fonte interna (tabela fixa de tamanhos, sem TrueType), sem preenchimento de forma, sem elipse de verdade, sem QR code — ver o README de `label_renderer_argox`. Este pacote contorna tudo isso ao custo de um job maior (imagem em vez de comandos compactos) e da nitidez nativa da fonte da impressora. Os dois renderers continuam disponíveis lado a lado; este não substitui o outro.

## De onde vem o protocolo de imagem do PPLA

Diferente de `label_renderer_argox` (que não teve acesso a um manual completo — ver o README dele), o comando de imagem aqui **foi extraído diretamente do Datamax Class Series 2 Programmer's Manual** (a mesma fonte que `label_renderer_argox` já cita para a tabela de fonte ASD, `Table C-6`), não é um palpite:

1. **Download da imagem** (`<STX>I`, "System-Level Command Functions", comando `STX I`): `<STX>Iabfnn...n<CR>data`, onde `a` é o banco de memória, `b` (opcional) é o tipo de dado (omitido = binário 8-bit cru), `f` é o designador de formato (`b`/`B` = BMP 8-bit padrão/invertido — confirmados 1:1 contra a tabela do manual junto com `F`/`I`/`i`/`P`/`p`), `nn...n` é o nome da imagem (até 16 caracteres) terminado por `<CR>`, seguido pelos bytes crus do arquivo.
2. O manual afirma que o formato de armazenamento interno da impressora para PCX/BMP é RLE-2 — ou seja, ela mesma faz o parse de um arquivo **BMP padrão**; não inventamos nenhum formato de pixel específico da Datamax/Argox.
3. **Colocar a imagem na etiqueta** ("Generating Label Formats", tabela "5: Images"): `1Ycd000ffffgggg<nome><CR>` — registro de mesmo formato posicional dos outros tipos (fonte, código de barras, gráfico) já usados em `label_renderer_argox`.
4. O terminador especial `FFFF<CR>` documentado no Apêndice N **não se aplica** aqui — ele é só para o formato alternativo "Datamax 7-bit ASCII" (designador `F`), que tem registros linha-a-linha sem tamanho auto-descrito. BMP já é auto-descrito pelo próprio cabeçalho, então os bytes do arquivo bastam, sem terminador extra.

## O que já foi confirmado em hardware real (Argox física)

- **Escala**: o pixel da imagem baixada mapeia 1:1 para "pontos endereçáveis" do PPLA, não para pontos físicos — numa cabeça 203 DPI cada endereço cobre um bloco físico 2x2 (`pplaDotMultiplier`). Renderizar no tamanho físico nominal imprimia ~2x grande demais; corrigido renderizando na grade endereçável (`ArgoxRasterRenderer` usa `pplaDotMultiplier(document.dpi)` para isso, mesmo com supersampling — ver abaixo).
- **Cores**: o parser de BMP da impressora não lê a paleta incorporada — assume convenção fixa `0 = preto, 1 = branco`. Corrigido invertendo os bits de pixel e a paleta juntos em `bmp_encoder.dart` (documentado lá).
- **Espelhamento horizontal**: a etiqueta saía espelhada da esquerda pra direita. Corrigido com `ArgoxRasterRendererOptions.mirrorHorizontal`, **default `true`** — confirmado em hardware real.
- **Um `biHeight` negativo trava a impressora.** A primeira tentativa de corrigir a ordem vertical das linhas usou o designador `B` ("flipped") do manual, que por spec BMP implica `biHeight` negativo — isso **trava a impressora de verdade** (ela para de responder, precisa desligar e ligar de novo), não é só "sai errado visualmente". O parser de BMP dela aparentemente não sabe lidar com altura negativa. Corrigido removendo essa possibilidade da raiz: `encodeMonochromeBmp` nunca mais escreve `biHeight` negativo nem o designador `B` — a ordem das linhas agora é controlada só por *quais bytes vão em qual posição do arquivo* (`reverseRowOrder`), com o cabeçalho sempre no formato seguro. Ver `bmp_encoder.dart`.

## O que ainda precisa de validação em hardware real

- **Orientação vertical** (`ArgoxRasterRendererOptions.reverseRowOrder`, agora padrão `false`): o teste anterior (linhas invertidas via `B`/altura negativa) travou a impressora antes de confirmar se a direção estava certa. Meio caminho andado: sabemos que o padrão anterior (`true`, ordem espelhada/bottom-up) estava errado, e a nova tentativa (`false`, ordem natural) é a mesma direção que a impressora parecia estar pedindo — mas ainda não confirmado com uma impressão real bem-sucedida. Sem risco de travar dessa vez; o switch "Linhas invertidas" no diálogo de impressão pode ser trocado livremente para achar o lado certo.
- **`ArgoxRasterRendererOptions.fullResolution` (padrão `true`, `D11` em vez de `D22`)**: ainda não testado em hardware real. Diferente de `flipped`, não há indício de que isso seja perigoso (o comando `D` é documentado como um ajuste de resolução válido em qualquer combinação `w`/`h`, `D22` é só o *default* de fábrica para cabeças 203 DPI, não o único valor suportado — e um job raster não tem nenhum campo de largura de módulo de código de barras, o outro lugar onde o multiplicador importa, para dessincronizar), mas é uma mudança nova o suficiente para valer um teste dedicado. Tem switch próprio no diálogo de impressão para desligar rápido se algo sair errado (tamanho, distorção).
- **Letra do banco de memória** (`ArgoxRasterRendererOptions.memoryBank`, padrão `'D'`): é só o exemplo usado pelo próprio manual, não confirmado para o modelo específico do usuário.
- Se o registro `1Y` com posição `0000`/`0000` realmente ancora a imagem no canto inferior-esquerdo da etiqueta como esperado (mesma convenção de origem que `ArgoxRenderer._argoxY` já usa para os comandos nativos).
- Se o parser de BMP da impressora aceita um arquivo mínimo/padrão de 1bpp sem exigir alguma particularidade além do spec (alinhamento de linha diferente, etc.).

Tudo o resto (matemática da codificação BMP, threshold de luminância RGBA→1bpp, downsample por blocos) é testável sem impressora — ver `test/`.

## Qualidade da imagem em baixo DPI

Duas alavancas independentes, uma em cima da outra:

**1. Resolução endereçável real (`fullResolution`, padrão `true`)** — o comando `D` da manual muda a resolução física de impressão, e `D22` (o que uma cabeça 203 DPI usa por padrão) é literalmente metade da resolução: cada ponto endereçável cobre um bloco físico 2x2. `D11` (1x1, sem dobrar) usa a resolução nativa completa do cabeçote — o manual deixa claro que `D22` é só o *default* de fábrica para 203 DPI, não o único valor válido (`D` aceita `w`/`h` de 1 a 2/3 independente do modelo). Um job raster não tem nenhum comando de código de barras (o único outro lugar onde esse multiplicador importa) para dessincronizar, então `ArgoxRasterRenderer` manda `D11` só para o job de imagem via `dotMultiplierOverride`, sem tocar no `ArgoxRenderer` nativo (que continua em `D22` a 203 DPI, já validado). Isso dobra os pontos endereçáveis de verdade — detalhe real, não só suavização de borda.

**2. Supersampling (`supersample`, padrão `4`)** — dado o tamanho final da imagem (já em resolução `fullResolution`), nada obriga a *renderizar* exatamente nesse tamanho. `ArgoxRasterRendererOptions.supersample` manda o `CanvasRenderer` desenhar a etiqueta numa resolução `supersample`x mais fina, e `downsampleRgba` reduz de volta à grade final fazendo a média de cada bloco `supersample`x`supersample` (filtro de caixa) antes do threshold monocromático. O resultado tem a mesma contagem de pixels finais — mesmo tamanho físico impresso — só que cada ponto foi decidido com informação de sub-pixel em vez de uma amostra única, produzindo bordas mais suaves em texto e curvas.

Nenhuma das duas muda o tamanho físico impresso — só quantos pontos existem (`fullResolution`) e quão bem cada um é decidido (`supersample`). Custam apenas tempo de renderização/dados locais (irrelevante para uma imagem do tamanho de uma etiqueta). `fullResolution: false` volta ao `D22` de fábrica; `supersample: 1` desliga a suavização.

## Uso

```dart
const layoutEngine = LabelLayoutEngine();
const renderer = ArgoxRasterRenderer();

final resolved = layoutEngine.resolve(document, dados);
final pplaBytes = await renderer.render(
  resolved,
  const ArgoxRasterRendererOptions(
    base: ArgoxRendererOptions(darkness: 12, copies: 1),
  ),
);
```

## Testes

```
flutter test
```

(O pacote depende de Flutter via `label_renderer_canvas`, então os testes rodam com `flutter test`, não `dart test`, mesmo a lógica testada — codificação BMP, threshold monocromático — sendo Dart puro sem `dart:ui`.)
