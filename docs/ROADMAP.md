# Roadmap de Implementação Incremental

> Depende da aprovação de [ARCHITECTURE.md](./ARCHITECTURE.md). Cada etapa só começa depois que a anterior está funcional, organizada e testável. Nenhuma etapa gera "o projeto inteiro" — apenas o pacote/funcionalidade daquela etapa.

Formato de cada etapa ao ser executada: **objetivo**, **arquivos criados**, **explicação**, **testes**, **próximo passo**.

| # | Etapa | Pacote(s) | Entrega funcional |
|---|---|---|---|
| 0 | Workspace | raiz, `melos.yaml`, `analysis_options.yaml` | `melos bootstrap` funcionando, CI mínimo, nenhum pacote ainda |
| 1 | Domínio base | `label_core` | `LabelDocument`, `LabelElement` e subtipos, value objects, conversão mm/dot — testado, sem UI |
| 2 | Serialização | `label_serialization` | `.label` (JSON) ⇄ `LabelDocument`, round-trip testado, migração de versão v1 |
| 3 | Expressões | `label_expression_engine` | Parser/avaliador de `{{ }}` funcionando isoladamente, testado com dezenas de casos |
| 4 | Layout Engine | `label_layout_engine` | `resolve(document, data)` → `ResolvedDocument`, testado com variáveis, grupos, rotação, múltiplos DPI |
| 5 | Barcode | `label_barcode` | Geração de símbolos (EAN13, Code128, QRCode no mínimo) testada contra encodings conhecidos |
| 6 | Renderer base + Canvas | `label_renderer`, `label_renderer_canvas` | `ArgoxRenderer`-like pipeline validado ponta a ponta gerando PNG a partir de um `LabelDocument` de exemplo — primeira vez que se "vê" uma etiqueta |
| 7 | Histórico | `label_history` | `Command`, `HistoryManager`, undo/redo testado sobre `LabelDocument` |
| 8 | Estado | `label_designer_state` | Stores MobX ligando core+history+layout, testado sem Flutter widgets |
| 9 | UI Kit | `label_widgets` | Componentes base (botões, color picker, réguas) com playground de widgets |
| 10 | Canvas editor | `label_canvas` | Editor visual: selecionar, mover, redimensionar, rotacionar, zoom/pan, grid/snap — widget tests |
| 11 | Painel de propriedades | `label_property_panel` | Edição de propriedades reativa, ligada ao `PropertyStore` |
| 12 | Preview | `label_preview` | Preview ao vivo usando Layout Engine + CanvasRenderer |
| 13 | Composição do editor | `label_designer` | Editor completo (toolbar, painéis, atalhos de teclado) |
| 14 | Playground app | `apps/playground` | Sandbox validando o pipeline completo manualmente, sem app "de produto" |
| 15 | Renderer PDF | `label_renderer_pdf` | Exportação vetorial validada visualmente |
| 16 | Renderers de impressora | `label_renderer_argox`, `label_renderer_zebra`, `label_renderer_tsc` | Um por vez; bytes de saída validados contra fixtures de comandos conhecidos (PPLA/PPLB, ZPL II, TSPL) |
| 17 | Guia de integração | (documentação + smoke test em `apps/playground`) | Passo a passo de como adicionar os pacotes via `path:`/`git:` no `pubspec.yaml` de um projeto Flutter existente e embutir `LabelDesigner` + um `label_renderer_*` — validado num projeto Flutter de teste real, fora deste workspace |

Não há etapas de "app standalone" (desktop/web) — o consumidor final é o projeto Flutter já existente do usuário, que importa os pacotes conforme a [seção 20 da arquitetura](./ARCHITECTURE.md#20-integração-no-projeto-existente-do-usuário).

## Extensões futuras (fora do escopo inicial, arquitetura já preparada)

- Novos renderers: `label_renderer_brother`, `_godex`, `_datamax`, `_sato`, `_cab`, `_epson`, `_bixolon`, `_elgin` — cada um só implementa `BaseRenderer`.
- `TableElement` — modelo já reservado em `label_core`, implementação de renderização adiada.
- Camada de transporte de impressão (USB/rede/Bluetooth) — fica a critério do projeto do usuário; opcionalmente um pacote `label_print_transport` reutilizável, consumido apenas por projetos externos, nunca pelo domínio.
- Colaboração/multiplayer — viabilizado pela escolha de `Command` imutável no `label_history`.

## Regra de avanço

Uma etapa só é considerada concluída quando:

1. O pacote compila isoladamente (`melos exec` no pacote).
2. Testes da etapa passam.
3. Nenhuma regra da arquitetura foi violada (ex.: pacote de domínio importando Flutter, canvas importando renderer).
4. Foi apresentado objetivo, arquivos criados, explicação, testes e próximo passo antes de seguir.
