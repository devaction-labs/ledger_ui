# Ledger UI

UI kit novo e independente para produtos Phoenix/LiveView (dashboards, financeiro, operação). A referência visual é o dashboard **Ledgerly**: neutros quentes, um único teal para dados e marca, botão principal **preto**, e cards formados por uma **bandeja** cinza que abraça um **painel** branco. A segunda referência é o layout de operação com **trilho de ícones + subnavegação + main flutuante**. O inventário cobre o mesmo conjunto de componentes do canvas de referência, redesenhados neste visual (123 componentes, todos em claro e escuro). O canvas **Ledger UI · Componentes** mostra cada grupo numa página.

## Como ler este sistema

- **Cores**: tokens semânticos em `tokens.json`, temas **Claro** e **Escuro**. Componentes só usam tokens; o escuro vem de graça.
- **Componentes**: uma página por família (grupos numerados 01–15). Cada card tem preview ao vivo e guia (`README.md`) com uso em HEEx e regras.
- **CSS**: `components/bundle.css` (prefixo `.lu-`). **JS**: `components/bundle.js` expõe `window.LedgerUI` com `hydrate()` (ícones e interações), `lineChart`, `donut`, `waterfall`, `spark` e `mrrGrowth`.
- **Ícones**: **Hugeicons Stroke Rounded** (hugeicons.com/icons/stroke-rounded), extraídos do pacote oficial `@hugeicons/core-free-icons`. Em HTML puro: `<i data-i="trend-up"></i>` + `LedgerUI.hydrate()`.

## Grupos (uma página cada)

| # | Grupo | O que tem |
|---|---|---|
| 01 | Fundamentos | Palette, Typography, Icon, Divider |
| 02 | Ações | Button, IconButton, Fab, Clipboard, Kbd |
| 03 | Formulários — texto | Input, InputGroup, Mask, Field, Textarea, RichTextEditor, CommentEditor, OtpInput, PhoneInput, FormSection |
| 04 | Formulários — seleção | Select, Autocomplete, Pillbox, PillSelect, FilterMenu, Checkbox, RadioChoice, Switch, Segmented, Chip, TagsInput |
| 05 | Formulários — datas e valores | DatePicker, TimePicker, DateTimePicker, Calendar, NumberStepper, RangeSlider, Rating, ColorPicker, SignaturePad, Upload |
| 06 | Exibição | Avatar, AvatarGroup, AvatarVariants, Badge, Tag, Card, MiniCard, PixelCard, CoverCard, HeroCard, DescriptionList, Timeline, StepGroup, Treeview, Carousel |
| 07 | Métricas e gráficos | KpiCard, Stat, LineChart, DonutChart, WaterfallChart, CohortHeatmap, BarChart, Sparkline |
| 08 | Tabelas | Table, DataTable, CardTable, TableToolbar, SelectionBar, BulkBar |
| 09 | Fluxo de trabalho | Kanban, Flow, DueCalendar, CashTimer |
| 10 | Feedback | Alert, Toast, EmptyStateCard, InlineEmpty, ErrorPage, ProgressBar, Skeleton, Spinner |
| 11 | Navegação | Tabs, ViewSwitcher, Breadcrumb, Pagination, Stepper, Dropdown, Menu, ActionMenu |
| 12 | Sobreposições | Modal, Drawer, Sheet, Popover, Tooltip, CommandPaletteDialog, NotificationCenter, Accordion, Collapse |
| 13 | Estrutura e shell | Navbar, Sidebar, **Shell** (dashboard Ledgerly completo), **ShellFloating** (trilho + subnav + main flutuante), IconRail, SubNav, PageHeader, ScrollArea, EmailLayout, AuthSplit |
| 14 | Temas e marca | Logo, ThemeSwitch, ThemePicker |
| 15 | IA | AiInsights, AiPromo, AiChat, ConversationList, AiMessage, AiComposer, PromptSuggestions, AiProposal, AiToolTrace, Trace, CodeBlock, Tool |

## Fundamentos visuais

**Superfícies.** O app fica numa moldura (`bg-shell`, raio `radius-2xl`); o conteúdo em `bg-page`. Todo card é uma **bandeja** (`bg-tray`, borda 1px `line`, raio `radius-xl`, padding 6px `space-1-5`) com título em caixa-alta no cabeçalho, abraçando um **painel** (`bg-panel`, raio `radius-lg`). Essa borda dupla é a assinatura do sistema; não troque por sombra pesada.

**Cor.**
- `inverse` (preto no claro, quase branco no escuro) é o botão principal: *Export report*, *Run AI insights*. Um por região.
- `accent` (teal-500) é **dado e marca**: linha principal do gráfico, ponto live, donut, progresso, ícone ativo da sidebar. Texto em teal usa `accent-ink` (teal-600), como “Recover →”.
- Sinais têm significado, não direção: churn subir é `neg` (▲ vermelho). `pos` = ganho, `lime` = oportunidade (“+$4,200 potential”), `warn` = pendência.
- Séries: `chart-1` teal, `chart-2` teal profundo, `chart-3` âmbar, `chart-4` rosa, `chart-5` menta; `chart-ghost` para a comparação tracejada. 1 e 2 diferem em luminosidade, não só em matiz.
- Contraste: texto ≥ 4,5:1 nos dois temas; `subtle` é só para ícones e bordas (3:1), nunca para texto.

**Forma.** Nada de pílula. Todo controle usa cantos arredondados: botões e inputs `radius-md` (10), badges/kbd/segmentado/switch `radius-sm` (6), células de heatmap `radius-xs` (4). Só são circulares: avatar, ponto de status e o botão redondo teal “→” do KPI. Pílula existe apenas como opção de API.

**Segmentado (padrão do sistema).** Trilha cinza (`bg-sunken`), escolhido em branco (`bg-panel`) com `shadow-xs` e anel de 1px. Serve para Day/Month/Year, filtros com contagem e troca de visão.

**Tipografia.** Inter para tudo, com tracking negativo nos números grandes (`metric-xl` 44/48, −0,035em) e **algarismos tabulares** em todo número. Título de card em `overline` (12px, caixa-alta, .08em). Geist Mono para IDs (MRN-0204013), código, contagens da subnav e atalhos.

**Profundidade.** Plano por padrão. `shadow-xs` em botão secundário e segmento escolhido; `shadow-md` em menus e popovers; `shadow-lg` em modal, drawer, barra de seleção e toast; `shadow-btn` no botão preto.

**Movimento.** Transições de 150ms em cor e fundo. Spinners e shimmer respeitam `prefers-reduced-motion`.

## Interações (do vídeo de referência)

- **MRR growth**: passar o mouse no gráfico move a guia vertical tracejada, destaca o ponto e o rótulo do eixo X e mostra o tooltip com 2026 / 2025 / Net new. **Day · Month · Year** troca a série, o cabeçalho (`+$14,860 in October`, `+$70,320 since January`, `+$73,920 since Dec 2025`) e esconde a legenda quando há uma série só.
- **Revenue by plan**: passar o mouse num segmento ou na linha da legenda põe o nome e o % no centro do donut (ex.: `SCALE 26.6%`), destaca a linha e apaga os outros segmentos para 28%.
- **Toast** padrão: escuro, compacto, centralizado embaixo.

## Conteúdo (voz)

Curto e quantificado. Todo insight traz número, impacto e uma ação: “**7 of 11** Pro cancels followed a failed payment · −$3,400 MRR · Recover →”. Verbos nos botões. Só a primeira letra maiúscula. Datas e moeda seguem o locale da conta.

## Uso no Phoenix

As APIs estão escritas como function components HEEx (`<.button>`, `<.kpi_card>`, `<.segmented>`…). Para implementar: leve as classes de `bundle.css` para os seus function components (ou mapeie para o tema Tailwind via variáveis CSS do `tokens.json`), mantendo claro/escuro por `data-theme` no `<html>`.
