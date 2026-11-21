# Relatório da migração para Tailwind CSS v4

Gerado em 2026-11-20 (`scripts/gen_migration_report.py`). Ramo `feature/tailwind`. Sem push, sem release.

## Resumo

* **141 componentes da referência** em HEEx + utilitários Tailwind v4 (tabela abaixo), 100% dos function components públicos da lib.
* Nenhuma classe `lu-*` e nenhum CSS de componente: `assets/css/ledger_ui.css` só tem tokens, `@theme`, `@layer base` e `@keyframes` (gerado por `scripts/tw/tw_theme.py`).
* **Paridade de pixels** (`parity/run.py`, sem filtro): 516 casos × 4 temas; maior diferença 0.41%; 473 casos em 0,00% nos 4 temas, 483 ≤ 0,01%, 507 ≤ 0,05%; **4 casos com alguma célula acima de 0,1%** (todos explicados em 'Desvios').
* **Tema próprio** (`parity/run.py --theme`, fúcsia + slate): 516 casos, 5 acima de 0,05% de pixels ainda na cor do Ledger: fx-color-picker-row (4.78% claro / 4.78% escuro), code-block-basic (0.08% claro / 0.08% escuro), code-block-diff (0.07% claro / 0.07% escuro), ref-code-block (0.09% claro / 0.09% escuro), theme-picker-grid (4.18% claro / 4.18% escuro).
* **Comparação visual canvas × vitrine** (`scripts/visual/run.sh`, claro e escuro, hover incluído): 400 seções, **327 dentro do limite** (0,6% da caixa e 15% da tinta), 69 acima, 0 com erro, 5 hovers perdidos.
* Templates (light): 18 telas, 9 abaixo de 1%, 17 abaixo de 5%, média 1.62%.
* Templates (dark): 18 telas, 10 abaixo de 1%, 18 abaixo de 5%, média 1.18%.

## Desvios que não zeraram

Cada item foi reverificado na rodada que gerou este relatório (números nas tabelas abaixo). O runner de paridade não tem
mecanismo de exceção: esta lista é o registro.

### Paridade de pixels (`parity/run.py`, limite 0,1%)

| caso | tema | % | motivo |
|---|---|---|---|
| `palette-bare`, `palette-typed` | crep-dark | 0,20 / 0,16 | Cor do placeholder do campo de busca: o original não define a cor (o navegador usa o cinza do UA) e o componente usa o token do tema, que no escuro de Crepúsculo é azulado. Só nessa combinação. |
| `avatar-legacy-t1` | crepusculo | 0,41 | O original (lib antiga sobre o CSS legado) tem o avatar `t1` com o teal fixo do Ledger; o componente usa o accent do tema (índigo em Crepúsculo). Regra do kit: nunca cor de marca fixa. |
| `radio-shapes` | light / crepusculo | 0,09 / 0,10 | Antialias do círculo/squircle do radio (mesma caixa, sem diferença de cor). |

### Tema próprio (`parity/run.py --theme`, limite 0,05% de pixels ainda na cor do Ledger)

| caso | % | motivo |
|---|---|---|
| `code-block-basic`, `code-block-diff`, `ref-code-block` | 0,07–0,09 | As cores da sintaxe são fixas (como no bundle): não derivam do accent. |
| `theme-picker-grid` | 4,18 | A grade mostra as amostras fixas dos temas (dado do seletor: `bg`/`accent`/`ink` de cada tema, inclusive o "Ledger" teal), não cor do componente. |
| `fx-color-picker-row` | 4,78 | Novo nesta rodada. As amostras do `variant="row"` reproduzem o conjunto fixo do canvas (inclui `#141514` e `#1f9282`, que coincidem com tokens do Ledger): são dados (cores escolhidas), não tema. |

### Decisões de design e do componente (não são bug)

* **`progress_bar` #1 e #8 (vitrine x canvas):** as demos do canvas usam o estilo "plano" antigo; o componente segue o bundle (`.lu-pg`).
* **`divider` com rótulo:** o texto é em maiúsculas, como no bundle (`text-xs tracking-[.06em] uppercase`).
* **`email` `variant="document"`:** mantém estilos inline (tabelas + `style=`), a única exceção a "só utilitários": cliente de e-mail não carrega
  CSS externo nem classes (documentado no módulo). `variant="preview"` é só utilitários.
* **`color_picker` `compact`:** o canvas desenha um mock com gradiente fixo; o componente desenha a área real de saturação/brilho e a barra de matiz.
* **`theme_toggle`/`theme_switch`:** o sol aparece no escuro (`dark:`), como a doc da lib original promete; o original nunca mostrava o sol (o hook
  só trocava o atributo `data-icon`, não o desenho: bug do original). Os casos de paridade aplicam o `d` do sol ao lado ORIGINAL.
* **`code_block`:** o `<pre>` mantém a família `monospace` do navegador, como o bundle (não `font-mono`).
* **Casos de `shell_b`:** o lado ORIGINAL recebe CSS extra (3º elemento do caso) onde o legado só renderiza "errado" fora do uso real
  (links do menu fora de `.lu-lnav`, `<button>` sem reset de padding).
* **Overlays animados (`drawer`, `sheet`, `modal`):** conferido nas imagens: o canvas mostra a demo `mo-*` congelada numa fase da animação de abrir,
  o componente anima com outra sequência, então caem em fases diferentes (algumas caixas ficam com altura diferente). Já estavam acima do limite
  na linha de base.

**Não analisado seção a seção:** as demais seções acima do limite da tabela "Seções acima do limite" (campos de formulário, tipografia, gráficos,
tabelas). A coluna "linha de base" mostra o valor de antes das rodadas de correção; nenhuma foi aceita aumentando limite.

### Casos de paridade acima de 0,1% nesta rodada

| caso | light | dark | crepusculo | crep-dark |
|---|---|---|---|---|
| avatar-legacy-t1 | 0.00% | 0.00% | 0.41% | 0.00% |
| palette-bare | 0.00% | 0.00% | 0.00% | 0.20% |
| palette-typed | 0.00% | 0.00% | 0.00% | 0.16% |
| radio-shapes | 0.09% | 0.03% | 0.10% | 0.04% |

## Comparação visual canvas × vitrine

Linha de base (antes das rodadas de correção e da remoção do CSS legado): 289/400 dentro do limite, 107 acima. Agora: 327/400, 69 acima.

Seções que **pioraram** além de 0,05 ponto em relação à linha de base: 14; que passavam e agora não passam: 5.

| seção | antes (máx %) | agora (máx %) |
|---|---|---|
| color-picker #1 | 0.00 | 4.57 |
| field #1 | 0.00 | 1.94 |
| kpi-card #2 | 0.00 | 1.83 |
| input #1 | 0.00 | 0.55 |
| hero-card #2 | 0.00 | 0.52 |
| hero-card #3 | 0.00 | 0.45 |
| hero-card #4 | 0.00 | 0.35 |
| calendar #2 | 0.00 | 0.28 |
| aura #2 | 0.00 | 0.28 |
| date-picker #2 | 0.00 | 0.16 |
| password-input #3 | 0.85 | 1.01 |
| typography #4 | 15.06 | 15.16 |
| divider #1 | 0.00 | 0.09 |
| date-time-picker #1 | 0.00 | 0.07 |

Nenhuma delas é efeito da remoção do CSS legado: o valor é o mesmo no commit anterior à remoção (comparação acima). A piora vem das rodadas de correção (a linha de base é anterior a elas) ou do ajuste do harness; `color-picker #1` é o mock de gradiente do canvas (ver Desvios). Não foram corrigidas aqui: decisão do dono.

**Efeito da remoção do CSS legado** (a mesma rodada, harness atual, sobre o commit anterior à remoção, 66b6158): antes 327/400 dentro do limite, depois 327/400. Seções que pioraram além de 0,05 ponto: 1: typography #4 (15.06 -> 15.16).

Templates (light): antes 9/18 < 1% (média 1.61%), agora 9/18 (média 1.62%).
Templates (dark): antes 10/18 < 1% (média 1.17%), agora 10/18 (média 1.18%).

Seções acima do limite (piores primeiro; `max` = % da caixa):

| seção | max % | tinta % | linha de base (máx %) | tamanho |
|---|---|---|---|---|
| progress-bar #1 | 99.64 | 99.8 | 99.64 |  |
| drawer #1 | 78.50 | 98.8 | 78.50 |  |
| modal #1 | 67.36 | 97.5 | 67.36 | diferente |
| sheet #1 | 59.03 | 99.3 | 59.03 |  |
| modal #3 | 35.73 | 94.5 | 35.73 | diferente |
| progress-bar #8 | 16.72 | 67.9 | 16.72 |  |
| typography #4 | 15.16 | 74.2 | 15.06 |  |
| modal #4 | 12.88 | 42.0 | 12.88 | diferente |
| typography #7 | 7.00 | 74.9 | 6.98 |  |
| line-chart #1 | 6.98 | 86.0 | 6.96 | diferente |
| typography #5 | 6.38 | 60.5 | 6.38 |  |
| bulk-bar #1 | 6.31 | 76.0 | 6.31 |  |
| tags-input #1 | 5.74 | 55.8 | 11.80 |  |
| input #6 | 5.70 | 58.7 | 5.70 |  |
| auth-split #1 | 5.49 | 45.7 | 5.49 |  |
| typography #8 | 5.36 | 75.8 | 5.36 |  |
| color-picker #1 | 4.57 | 34.9 | 0.00 |  |
| drawer #2 | 4.31 | 66.6 | 4.31 |  |
| donut-chart #1 | 3.55 | 42.1 | 3.55 |  |
| shell-floating #1 | 3.48 | 39.6 | 7.78 |  |
| pillbox #2 | 3.42 | 81.7 | 4.37 | diferente |
| table-toolbar #1 | 3.36 | 26.3 | 3.36 |  |
| button #1 | 2.99 | 13.0 | 2.99 |  |
| pixel-card #3 | 2.88 | 32.7 | 4.81 |  |
| phone-input #2 | 2.86 | 44.8 | 4.74 |  |
| textarea #4 | 2.72 | 51.4 | 2.72 | diferente |
| tooltip #1 | 2.55 | 87.8 | 2.55 |  |
| flow #1 | 2.41 | 52.5 | 2.41 | diferente |
| data-table #2 | 2.37 | 29.3 | 5.26 |  |
| password-input #5 | 2.20 | 42.3 | 2.86 |  |
| input #7 | 2.14 | 51.4 | 2.09 |  |
| data-table #1 | 2.06 | 35.6 | 4.72 |  |
| logo #4 | 2.03 | 12.4 | 6.15 |  |
| table #3 | 1.98 | 26.6 | 4.31 |  |
| field #1 | 1.94 | 35.8 | 0.00 |  |
| radio-choice #5 | 1.88 | 27.5 | 1.88 |  |
| rich-text-editor #1 | 1.87 | 19.6 | 4.85 |  |
| textarea #6 | 1.85 | 70.3 | 1.85 |  |
| kpi-card #2 | 1.83 | 22.0 | 0.00 |  |
| card-table #3 | 1.72 | 30.9 | 2.40 |  |
| input-group #2 | 1.69 | 27.5 | 1.69 |  |
| shell #3 | 1.68 | 13.1 | 2.97 |  |
| stat #4 | 1.50 | 22.8 | 2.37 |  |
| checkbox #5 | 1.38 | 32.7 | 1.38 |  |
| comment-editor #1 | 1.27 | 20.7 | 8.49 |  |
| input #3 | 1.24 | 19.5 | 1.24 |  |
| autocomplete #2 | 1.24 | 30.3 | 1.24 |  |
| password-input #2 | 1.22 | 33.3 | 3.64 |  |
| input #2 | 1.18 | 38.8 | 1.18 |  |
| stat #5 | 1.17 | 12.5 | 1.17 |  |
| input-group #1 | 1.16 | 16.7 | 1.16 |  |
| radio-choice #4 | 1.07 | 16.0 | 1.07 |  |
| password-input #3 | 1.01 | 11.8 | 0.85 |  |
| selection-bar #2 | 0.94 | 4.1 | 0.94 |  |
| conversation-list #1 | 0.93 | 12.9 | 0.93 |  |
| input #4 | 0.87 | 17.8 | 0.87 |  |
| otp-input #2 | 0.82 | 32.0 | 0.82 |  |
| divider #2 | 0.77 | 22.9 | 0.77 |  |
| password-input #1 | 0.77 | 13.1 | 0.90 |  |
| password-input #4 | 0.72 | 16.6 | 0.90 |  |
| checkbox #2 | 0.71 | 21.5 | 0.71 |  |
| select #3 | 0.63 | 8.5 | 2.09 |  |
| ai-proposal #1 | 0.61 | 4.0 | 0.68 |  |
| input #1 | 0.55 | 15.0 | 0.00 |  |
| date-picker #1 | 0.48 | 34.3 | 0.48 |  |
| command-palette-dialog #3 | 0.38 | 27.6 | 0.74 |  |
| command-palette-dialog #1 | 0.32 | 12.7 | 0.32 |  |
| checkbox #4 | 0.18 | 7.0 | 0.18 |  |
| divider #1 | 0.09 | 100.0 | 0.00 |  |
| dropdown #1 | 0.04 | 21.9 | 0.04 |  |
| action-menu #1 | 0.02 | 84.6 | 0.02 |  |
| action-menu #2 | 0.01 | 0.2 | 0.00 |  |
| button #2 | 0.01 | 0.1 | 0.01 |  |

## Componentes migrados (referência → módulo/função)

| lote | componente da referência | módulo da lib | função |
|---|---|---|---|
| 1 Ações | Palette | `LedgerUI.Components.Palette` | `<.palette>` |
| 1 Ações | ActionButton | `LedgerUI.Components.ActionMenu` | `<.action_button>` |
| 1 Ações | Button | `LedgerUI.Components.Button` | `<.button>` |
| 1 Ações | IconButton | `LedgerUI.Components.Button` | `<.icon_button>` |
| 1 Ações | Clipboard | `LedgerUI.Components.Clipboard` | `<.clipboard>` |
| 1 Ações | Divider | `LedgerUI.Components.Divider` | `<.divider>` |
| 1 Ações | Fab | `LedgerUI.Components.Fab` | `<.fab>` |
| 1 Ações | FabDial | `LedgerUI.Components.Fab` | `<.fab_dial>` |
| 1 Ações | Icon | `LedgerUI.Components.Icon` | `<.icon>` |
| 1 Ações | Illustration | `LedgerUI.Components.Illustration` | `<.illustration>` |
| 1 Ações | Kbd | `LedgerUI.Components.Typography` | `<.kbd>` |
| 1 Ações | Typography | `LedgerUI.Components.Typography` | `<.typography>` |
| 2 Formulários | Autocomplete | `LedgerUI.Components.Autocomplete` | `<.autocomplete>` |
| 2 Formulários | Calendar | `LedgerUI.Components.Calendar` | `<.calendar>` |
| 2 Formulários | Checkbox | `LedgerUI.Components.Checkbox` | `<.checkbox>` |
| 2 Formulários | Chip | `LedgerUI.Components.Chip` | `<.chip>` |
| 2 Formulários | ColorPicker | `LedgerUI.Components.ColorPicker` | `<.color_picker>` |
| 2 Formulários | DatePicker | `LedgerUI.Components.DatePicker` | `<.date_picker>` |
| 2 Formulários | DateTimePicker | `LedgerUI.Components.DatetimePicker` | `<.date_time_picker>` |
| 2 Formulários | FilterMenu | `LedgerUI.Components.FilterMenu` | `<.filter_menu>` |
| 2 Formulários | Field | `LedgerUI.Components.Form` | `<.field>` |
| 2 Formulários | FormSection | `LedgerUI.Components.FormSection` | `<.form_section>` |
| 2 Formulários | ImageInput | `LedgerUI.Components.ImageInput` | `<.image_input>` |
| 2 Formulários | Input | `LedgerUI.Components.Input` | `<.input>` |
| 2 Formulários | InputGroup | `LedgerUI.Components.InputGroup` | `<.input_group>` |
| 2 Formulários | NumberStepper | `LedgerUI.Components.NumberInput` | `<.number_stepper>` |
| 2 Formulários | OtpInput | `LedgerUI.Components.OtpInput` | `<.otp_input>` |
| 2 Formulários | PasswordInput | `LedgerUI.Components.PasswordInput` | `<.password_input>` |
| 2 Formulários | PhoneInput | `LedgerUI.Components.PhoneInput` | `<.phone_input>` |
| 2 Formulários | PillSelect | `LedgerUI.Components.PillSelect` | `<.pill_select>` |
| 2 Formulários | Pillbox | `LedgerUI.Components.Pillbox` | `<.pillbox>` |
| 2 Formulários | RadioChoice | `LedgerUI.Components.Radio` | `<.radio_choice>` |
| 2 Formulários | RangeSlider | `LedgerUI.Components.Range` | `<.range_slider>` |
| 2 Formulários | Rating | `LedgerUI.Components.Rating` | `<.rating>` |
| 2 Formulários | Segmented | `LedgerUI.Components.Segmented` | `<.segmented>` |
| 2 Formulários | Select | `LedgerUI.Components.Select` | `<.select>` |
| 2 Formulários | SignaturePad | `LedgerUI.Components.SignaturePad` | `<.signature_pad>` |
| 2 Formulários | Switch | `LedgerUI.Components.Switch` | `<.switch>` |
| 2 Formulários | TagsInput | `LedgerUI.Components.TagsInput` | `<.tags_input>` |
| 2 Formulários | CommentEditor | `LedgerUI.Components.TextEditor` | `<.comment_editor>` |
| 2 Formulários | RichTextEditor | `LedgerUI.Components.TextEditor` | `<.rich_text_editor>` |
| 2 Formulários | Textarea | `LedgerUI.Components.Textarea` | `<.textarea>` |
| 2 Formulários | TimePicker | `LedgerUI.Components.TimePicker` | `<.time_picker>` |
| 2 Formulários | Upload | `LedgerUI.Components.Upload` | `<.upload>` |
| 3 Feedback | Alert | `LedgerUI.Components.Alert` | `<.alert>` |
| 3 Feedback | Aura | `LedgerUI.Components.Aura` | `<.aura>` |
| 3 Feedback | ConnectionBanner | `LedgerUI.Components.ConnectionBanner` | `<.connection_banner>` |
| 3 Feedback | EmptyStateCard | `LedgerUI.Components.EmptyState` | `<.empty_state_card>` |
| 3 Feedback | InlineEmpty | `LedgerUI.Components.EmptyState` | `<.inline_empty>` |
| 3 Feedback | ErrorPage | `LedgerUI.Components.ErrorPage` | `<.error_page>` |
| 3 Feedback | ProgressBar | `LedgerUI.Components.Progress` | `<.progress_bar>` |
| 3 Feedback | Skeleton | `LedgerUI.Components.Skeleton` | `<.skeleton>` |
| 3 Feedback | Spinner | `LedgerUI.Components.Spinner` | `<.spinner>` |
| 3 Feedback | StatusToast | `LedgerUI.Components.Toast` | `<.status_toast>` |
| 3 Feedback | ToastCard | `LedgerUI.Components.Toast` | `<.toast_card>` |
| 3 Feedback | Toaster | `LedgerUI.Components.Toast` | `<.toaster>` |
| 4 Overlays | Accordion | `LedgerUI.Components.Accordion` | `<.accordion>` |
| 4 Overlays | Collapse | `LedgerUI.Components.Collapse` | `<.collapse>` |
| 4 Overlays | CommandPaletteDialog | `LedgerUI.Components.CommandPalette` | `<.command_palette_dialog>` |
| 4 Overlays | Drawer | `LedgerUI.Components.Drawer` | `<.drawer>` |
| 4 Overlays | Sheet | `LedgerUI.Components.Drawer` | `<.sheet>` |
| 4 Overlays | Modal | `LedgerUI.Components.Modal` | `<.modal>` |
| 4 Overlays | NotificationCenter | `LedgerUI.Components.NotificationCenter` | `<.notification_center>` |
| 4 Overlays | Popover | `LedgerUI.Components.Popover` | `<.popover>` |
| 4 Overlays | Tooltip | `LedgerUI.Components.Tooltip` | `<.tooltip>` |
| 5 Navegação | ActionMenu | `LedgerUI.Components.ActionMenu` | `<.action_menu>` |
| 5 Navegação | Breadcrumb | `LedgerUI.Components.Breadcrumb` | `<.breadcrumb>` |
| 5 Navegação | ContextMenu | `LedgerUI.Components.ContextMenu` | `<.context_menu>` |
| 5 Navegação | Dropdown | `LedgerUI.Components.Dropdown` | `<.dropdown>` |
| 5 Navegação | Menu | `LedgerUI.Components.MenuList` | `<.menu>` |
| 5 Navegação | MenuList | `LedgerUI.Components.MenuList` | `<.menu_list>` |
| 5 Navegação | Pagination | `LedgerUI.Components.Pagination` | `<.pagination>` |
| 5 Navegação | Scrollspy | `LedgerUI.Components.Scrollspy` | `<.scrollspy>` |
| 5 Navegação | Stepper | `LedgerUI.Components.Steps` | `<.stepper>` |
| 5 Navegação | Tabs | `LedgerUI.Components.Tabs` | `<.tabs>` |
| 5 Navegação | ViewSwitcher | `LedgerUI.Components.ViewSwitcher` | `<.view_switcher>` |
| 6 Dados | Avatar | `LedgerUI.Components.Avatar` | `<.avatar>` |
| 6 Dados | AvatarGroup | `LedgerUI.Components.Avatar` | `<.avatar_group>` |
| 6 Dados | AvatarVariants | `LedgerUI.Components.Avatar` | `<.avatar>` |
| 6 Dados | Badge | `LedgerUI.Components.Badge` | `<.badge>` |
| 6 Dados | BulkBar | `LedgerUI.Components.BulkBar` | `<.bulk_bar>` |
| 6 Dados | SelectionBar | `LedgerUI.Components.BulkBar` | `<.selection_bar>` |
| 6 Dados | DueCalendar | `LedgerUI.Components.Calendar` | `<.due_calendar>` |
| 6 Dados | Card | `LedgerUI.Components.Card` | `<.card>` |
| 6 Dados | CardTable | `LedgerUI.Components.CardTable` | `<.card_table>` |
| 6 Dados | Carousel | `LedgerUI.Components.Carousel` | `<.carousel>` |
| 6 Dados | CashTimer | `LedgerUI.Components.CashTimer` | `<.cash_timer>` |
| 6 Dados | Cover | `LedgerUI.Components.Cover` | `<.cover>` |
| 6 Dados | CoverCard | `LedgerUI.Components.Cover` | `<.cover_card>` |
| 6 Dados | DataTable | `LedgerUI.Components.DataTable` | `<.data_table>` |
| 6 Dados | TableToolbar | `LedgerUI.Components.DataTable` | `<.table_toolbar>` |
| 6 Dados | DescriptionList | `LedgerUI.Components.DescriptionList` | `<.description_list>` |
| 6 Dados | Flow | `LedgerUI.Components.Flow` | `<.flow>` |
| 6 Dados | HeroCard | `LedgerUI.Components.HeroCard` | `<.hero_card>` |
| 6 Dados | Kanban | `LedgerUI.Components.Kanban` | `<.kanban>` |
| 6 Dados | Mask | `LedgerUI.Components.Mask` | `<.mask>` |
| 6 Dados | MiniCard | `LedgerUI.Components.MiniCard` | `<.mini_card>` |
| 6 Dados | PixelCard | `LedgerUI.Components.PixelCard` | `<.pixel_card>` |
| 6 Dados | StepGroup | `LedgerUI.Components.StepGroup` | `<.step_group>` |
| 6 Dados | Table | `LedgerUI.Components.Table` | `<.table>` |
| 6 Dados | Tag | `LedgerUI.Components.Tag` | `<.tag>` |
| 6 Dados | Timeline | `LedgerUI.Components.Timeline` | `<.timeline>` |
| 6 Dados | Timer | `LedgerUI.Components.Timer` | `<.timer>` |
| 6 Dados | Treeview | `LedgerUI.Components.Treeview` | `<.treeview>` |
| 7 Métricas/gráficos | BarChart | `LedgerUI.Components.Chart` | `<.bar_chart>` |
| 7 Métricas/gráficos | CohortHeatmap | `LedgerUI.Components.Chart` | `<.cohort_heatmap>` |
| 7 Métricas/gráficos | DonutChart | `LedgerUI.Components.Chart` | `<.donut_chart>` |
| 7 Métricas/gráficos | LineChart | `LedgerUI.Components.Chart` | `<.line_chart>` |
| 7 Métricas/gráficos | WaterfallChart | `LedgerUI.Components.Chart` | `<.waterfall_chart>` |
| 7 Métricas/gráficos | KpiCard | `LedgerUI.Components.KpiCard` | `<.kpi_card>` |
| 7 Métricas/gráficos | Sparkline | `LedgerUI.Components.Sparkline` | `<.sparkline>` |
| 7 Métricas/gráficos | Stat | `LedgerUI.Components.Stat` | `<.stat_item>` |
| 8 Shell/app | AiChat | `LedgerUI.Components.Ai` | `<.ai_chat>` |
| 8 Shell/app | AiComposer | `LedgerUI.Components.Ai` | `<.ai_composer>` |
| 8 Shell/app | AiInsights | `LedgerUI.Components.Ai` | `<.ai_insights>` |
| 8 Shell/app | AiMessage | `LedgerUI.Components.Ai` | `<.ai_message>` |
| 8 Shell/app | AiPromo | `LedgerUI.Components.Ai` | `<.ai_promo>` |
| 8 Shell/app | AiProposal | `LedgerUI.Components.Ai` | `<.ai_proposal>` |
| 8 Shell/app | AiToolTrace | `LedgerUI.Components.Ai` | `<.ai_tool_trace>` |
| 8 Shell/app | ConversationList | `LedgerUI.Components.Ai` | `<.conversation_list>` |
| 8 Shell/app | PromptSuggestions | `LedgerUI.Components.Ai` | `<.prompt_suggestions>` |
| 8 Shell/app | IconRail | `LedgerUI.Components.AppShell` | `<.icon_rail>` |
| 8 Shell/app | PageHeader | `LedgerUI.Components.AppShell` | `<.page_header>` |
| 8 Shell/app | ShellFloating | `LedgerUI.Components.AppShell` | `<.shell_floating>` |
| 8 Shell/app | SubNav | `LedgerUI.Components.AppShell` | `<.sub_nav>` |
| 8 Shell/app | AuthSplit | `LedgerUI.Components.AuthSplit` | `<.auth_split>` |
| 8 Shell/app | CodeBlock | `LedgerUI.Components.CodeBlock` | `<.code_block>` |
| 8 Shell/app | Container | `LedgerUI.Components.Container` | `<.container>` |
| 8 Shell/app | EmailLayout | `LedgerUI.Components.Email` | `<.email_layout>` |
| 8 Shell/app | GlowText | `LedgerUI.Components.GlowText` | `<.glow_text>` |
| 8 Shell/app | LandingNav | `LedgerUI.Components.LandingNav` | `<.landing_nav>` |
| 8 Shell/app | Logo | `LedgerUI.Components.Logo` | `<.logo>` |
| 8 Shell/app | Navbar | `LedgerUI.Components.Navbar` | `<.navbar>` |
| 8 Shell/app | ScrollArea | `LedgerUI.Components.ScrollArea` | `<.scroll_area>` |
| 8 Shell/app | Shell | `LedgerUI.Components.Shell` | `<.shell>` |
| 8 Shell/app | Sidebar | `LedgerUI.Components.Sidebar` | `<.sidebar>` |
| 8 Shell/app | Sticky | `LedgerUI.Components.Sticky` | `<.sticky>` |
| 8 Shell/app | ThemePicker | `LedgerUI.Components.ThemePicker` | `<.theme_picker>` |
| 8 Shell/app | ThemeSwitch | `LedgerUI.Components.ThemeSwitch` | `<.theme_switch>` |
| 8 Shell/app | Tool | `LedgerUI.Components.Tool` | `<.tool>` |
| 8 Shell/app | Trace | `LedgerUI.Components.Trace` | `<.trace>` |

Todos os function components públicos da lib (um exemplo de cada no README): 325 em 110 módulos.

## Paridade de pixels por caso (516 casos × 4 temas, % de pixels diferentes)

| caso | light | dark | crepusculo | crep-dark |
|---|---|---|---|---|
| palette-ramp | 0.00 | 0.00 | 0.00 | 0.00 |
| palette-chips | 0.00 | 0.00 | 0.00 | 0.00 |
| palette-swatches | 0.00 | 0.00 | 0.00 | 0.00 |
| palette-swatches-chart | 0.00 | 0.00 | 0.00 | 0.00 |
| palette-chart-2 | 0.00 | 0.00 | 0.00 | 0.00 |
| divider-horizontal | 0.00 | 0.00 | 0.00 | 0.00 |
| divider-vertical | 0.00 | 0.00 | 0.00 | 0.00 |
| kbd-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| typography-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| typography-gradients | 0.00 | 0.00 | 0.00 | 0.00 |
| typography-decoration | 0.00 | 0.00 | 0.00 | 0.00 |
| typography-links | 0.00 | 0.00 | 0.00 | 0.00 |
| typography-inline-code | 0.00 | 0.00 | 0.00 | 0.00 |
| typography-headings | 0.00 | 0.00 | 0.00 | 0.00 |
| illustration-states | 0.00 | 0.00 | 0.00 | 0.00 |
| illustration-tones | 0.00 | 0.00 | 0.00 | 0.00 |
| clipboard-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| clipboard-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| clipboard-input | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-pill-hover | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-pill-expanded | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-pill-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-pill-collapsed | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-positions | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-dial-open | 0.00 | 0.00 | 0.00 | 0.00 |
| fab-dial-closed | 0.00 | 0.00 | 0.00 | 0.00 |
| button-canvas-looks | 0.00 | 0.00 | 0.00 | 0.00 |
| illustration-summit | 0.00 | 0.00 | 0.00 | 0.00 |
| illustration-summit-crop | 0.00 | 0.00 | 0.00 | 0.00 |
| button-solid | 0.00 | 0.00 | 0.00 | 0.00 |
| button-glow | 0.00 | 0.00 | 0.00 | 0.00 |
| button-outline | 0.00 | 0.00 | 0.00 | 0.00 |
| button-soft | 0.00 | 0.00 | 0.00 | 0.00 |
| button-bordered | 0.00 | 0.00 | 0.00 | 0.00 |
| button-flat | 0.00 | 0.00 | 0.00 | 0.00 |
| button-glass | 0.00 | 0.00 | 0.00 | 0.00 |
| button-ghost | 0.00 | 0.00 | 0.00 | 0.00 |
| button-dim | 0.00 | 0.00 | 0.00 | 0.00 |
| button-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| button-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| button-states | 0.00 | 0.00 | 0.00 | 0.00 |
| button-group | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-solid | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-glow | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-soft | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-outline | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-flat | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-bordered | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| button-matrix-xs | 0.00 | 0.00 | 0.00 | 0.00 |
| button-matrix-md | 0.00 | 0.00 | 0.00 | 0.00 |
| button-matrix-lg | 0.00 | 0.00 | 0.00 | 0.00 |
| button-matrix-xl | 0.00 | 0.00 | 0.00 | 0.00 |
| button-pill | 0.00 | 0.00 | 0.00 | 0.00 |
| button-square | 0.00 | 0.00 | 0.00 | 0.00 |
| button-loading-pip | 0.00 | 0.00 | 0.00 | 0.00 |
| button-current | 0.00 | 0.00 | 0.00 | 0.00 |
| button-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| icon-button | 0.00 | 0.00 | 0.00 | 0.00 |
| icon-button-topbar | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-colors-all | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-icon | 0.00 | 0.00 | 0.00 | 0.00 |
| badge-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| icon-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-status | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-rings | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-kinds | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-custom | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-image | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-legacy | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-legacy-t1 | 0.00 | 0.00 | 0.41 | 0.00 |
| avatar-group | 0.00 | 0.00 | 0.00 | 0.00 |
| avatar-group-more | 0.00 | 0.00 | 0.00 | 0.00 |
| tag-matrix | 0.00 | 0.00 | 0.00 | 0.00 |
| tag-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| tag-pressable | 0.00 | 0.00 | 0.00 | 0.00 |
| tag-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| description-list-cols | 0.00 | 0.00 | 0.00 | 0.00 |
| description-list-inline | 0.00 | 0.00 | 0.00 | 0.00 |
| mini-card-panel | 0.00 | 0.00 | 0.00 | 0.00 |
| mini-card-value | 0.00 | 0.00 | 0.00 | 0.00 |
| mini-card-surface | 0.00 | 0.00 | 0.00 | 0.00 |
| pixel-card-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| pixel-card-states | 0.00 | 0.00 | 0.00 | 0.00 |
| cover-bands | 0.00 | 0.00 | 0.00 | 0.00 |
| cover-avatar | 0.00 | 0.00 | 0.00 | 0.00 |
| cover-image | 0.00 | 0.00 | 0.00 | 0.00 |
| mask-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| mask-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| mask-image | 0.00 | 0.00 | 0.00 | 0.00 |
| timer-ring | 0.00 | 0.00 | 0.00 | 0.00 |
| timer-extras | 0.00 | 0.00 | 0.00 | 0.00 |
| timer-mini | 0.00 | 0.00 | 0.00 | 0.00 |
| cash-timer-states | 0.00 | 0.00 | 0.00 | 0.00 |
| bulk-bar-pill | 0.00 | 0.00 | 0.00 | 0.00 |
| bulk-bar-progress | 0.00 | 0.00 | 0.00 | 0.00 |
| bulk-bar-inline | 0.00 | 0.00 | 0.00 | 0.00 |
| bulk-bar-float | 0.00 | 0.00 | 0.00 | 0.00 |
| carousel-slide | 0.00 | 0.01 | 0.00 | 0.01 |
| card-table-tray | 0.00 | 0.00 | 0.00 | 0.00 |
| kanban-board | 0.00 | 0.00 | 0.00 | 0.00 |
| kanban-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| kanban-scroll | 0.00 | 0.00 | 0.00 | 0.00 |
| timeline-markers | 0.00 | 0.00 | 0.00 | 0.00 |
| timeline-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| timeline-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| timeline-dot | 0.00 | 0.00 | 0.00 | 0.00 |
| timeline-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| step-group-states | 0.00 | 0.00 | 0.00 | 0.00 |
| step-group-plain | 0.00 | 0.00 | 0.00 | 0.00 |
| step-group-logs | 0.03 | 0.03 | 0.03 | 0.03 |
| tree-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| tree-data | 0.00 | 0.00 | 0.00 | 0.00 |
| tree-check | 0.00 | 0.00 | 0.00 | 0.00 |
| hero-soft | 0.00 | 0.00 | 0.00 | 0.00 |
| hero-lg-meter | 0.00 | 0.00 | 0.00 | 0.00 |
| hero-panel-steps | 0.00 | 0.00 | 0.00 | 0.00 |
| hero-ai | 0.00 | 0.00 | 0.00 | 0.00 |
| hero-picture | 0.00 | 0.00 | 0.00 | 0.00 |
| flow-edges | 0.00 | 0.00 | 0.00 | 0.00 |
| flow-panel | 0.00 | 0.00 | 0.00 | 0.00 |
| flow-grid | 0.00 | 0.00 | 0.00 | 0.00 |
| table-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| table-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| table-select | 0.01 | 0.01 | 0.01 | 0.01 |
| table-select-all | 0.01 | 0.01 | 0.02 | 0.01 |
| table-expand | 0.02 | 0.02 | 0.02 | 0.02 |
| table-hand | 0.01 | 0.01 | 0.01 | 0.01 |
| table-priority | 0.00 | 0.00 | 0.00 | 0.00 |
| table-card | 0.00 | 0.00 | 0.00 | 0.00 |
| table-details | 0.00 | 0.00 | 0.00 | 0.00 |
| table-edit | 0.00 | 0.00 | 0.00 | 0.00 |
| table-skeleton | 0.00 | 0.00 | 0.00 | 0.00 |
| data-table-advanced | 0.01 | 0.01 | 0.01 | 0.01 |
| data-table-grid | 0.01 | 0.01 | 0.01 | 0.01 |
| data-table-pagers | 0.01 | 0.01 | 0.01 | 0.01 |
| data-table-states | 0.01 | 0.01 | 0.01 | 0.01 |
| table-toolbar | 0.00 | 0.00 | 0.00 | 0.00 |
| card-tray | 0.00 | 0.00 | 0.00 | 0.00 |
| card-flat | 0.00 | 0.00 | 0.00 | 0.00 |
| card-surfaces | 0.00 | 0.00 | 0.00 | 0.00 |
| card-surface-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| card-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| card-parts | 0.00 | 0.00 | 0.00 | 0.00 |
| card-sizes-heading | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-soft | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-bordered | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-outline | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-solid | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-pill | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-accent | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-actions | 0.00 | 0.00 | 0.00 | 0.00 |
| alert-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| aura-modes | 0.00 | 0.00 | 0.00 | 0.00 |
| aura-modes-accent | 0.00 | 0.00 | 0.00 | 0.00 |
| aura-tones | 0.00 | 0.00 | 0.00 | 0.00 |
| aura-tones-dual | 0.00 | 0.00 | 0.00 | 0.00 |
| aura-tones-glow | 0.00 | 0.00 | 0.00 | 0.00 |
| aura-widths | 0.00 | 0.00 | 0.00 | 0.00 |
| aura-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| spinner-variants | 0.06 | 0.06 | 0.06 | 0.06 |
| spinner-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| skeleton-animation | 0.00 | 0.00 | 0.00 | 0.00 |
| skeleton-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| skeleton-layout | 0.00 | 0.00 | 0.00 | 0.00 |
| skeleton-lineone | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-solid | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-soft | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-gradient | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-default | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-heights | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-states | 0.00 | 0.00 | 0.00 | 0.00 |
| progress-stack | 0.00 | 0.00 | 0.00 | 0.00 |
| empty-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| empty-card | 0.00 | 0.00 | 0.00 | 0.00 |
| empty-card-heading | 0.00 | 0.00 | 0.00 | 0.00 |
| empty-inline | 0.00 | 0.00 | 0.00 | 0.00 |
| empty-plain | 0.00 | 0.00 | 0.00 | 0.00 |
| empty-table | 0.00 | 0.00 | 0.00 | 0.00 |
| error-page-404 | 0.03 | 0.04 | 0.03 | 0.04 |
| error-page-500 | 0.00 | 0.00 | 0.00 | 0.00 |
| error-page-tones | 0.00 | 0.00 | 0.00 | 0.00 |
| error-state | 0.00 | 0.00 | 0.00 | 0.00 |
| error-links | 0.00 | 0.00 | 0.00 | 0.00 |
| toast-card-light | 0.00 | 0.00 | 0.00 | 0.00 |
| toast-card-dark | 0.00 | 0.00 | 0.00 | 0.00 |
| toast-card-plain | 0.00 | 0.00 | 0.00 | 0.00 |
| toast-card-actions | 0.00 | 0.00 | 0.00 | 0.00 |
| toast-card-aura | 0.00 | 0.00 | 0.00 | 0.00 |
| toast-card-progress | 0.00 | 0.00 | 0.00 | 0.00 |
| toast-status | 0.00 | 0.00 | 0.00 | 0.00 |
| toaster-static | 0.00 | 0.00 | 0.00 | 0.00 |
| toaster-static-top | 0.00 | 0.00 | 0.00 | 0.00 |
| connection-banner-toast | 0.00 | 0.00 | 0.00 | 0.00 |
| connection-banner | 0.00 | 0.00 | 0.00 | 0.00 |
| input-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| input-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| input-states | 0.05 | 0.05 | 0.05 | 0.05 |
| input-pill-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| input-inline-hint | 0.00 | 0.00 | 0.00 | 0.00 |
| checkbox-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| checkbox-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| checkbox-desc | 0.00 | 0.00 | 0.00 | 0.00 |
| checkbox-outline | 0.00 | 0.00 | 0.00 | 0.00 |
| switch-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| switch-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| switch-inset | 0.00 | 0.00 | 0.00 | 0.00 |
| switch-labels | 0.00 | 0.00 | 0.00 | 0.00 |
| radio-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| radio-shapes | 0.09 | 0.03 | 0.10 | 0.04 |
| radio-card | 0.00 | 0.00 | 0.00 | 0.00 |
| radio-chip | 0.00 | 0.00 | 0.00 | 0.00 |
| radio-tile | 0.00 | 0.00 | 0.00 | 0.00 |
| segmented-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| chip-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| pill-select-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| textarea-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| textarea-counter | 0.00 | 0.00 | 0.00 | 0.00 |
| textarea-state | 0.00 | 0.00 | 0.00 | 0.00 |
| textarea-bars | 0.00 | 0.00 | 0.00 | 0.00 |
| otp-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| otp-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| otp-states | 0.00 | 0.00 | 0.00 | 0.00 |
| number-styles | 0.00 | 0.00 | 0.04 | 0.08 |
| number-addons | 0.00 | 0.00 | 0.00 | 0.00 |
| number-states | 0.00 | 0.00 | 0.00 | 0.00 |
| password-strength | 0.00 | 0.00 | 0.00 | 0.00 |
| input-group-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| form-section-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| select-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| select-open | 0.03 | 0.03 | 0.03 | 0.03 |
| pillbox-basic | 0.04 | 0.04 | 0.04 | 0.04 |
| autocomplete-open | 0.00 | 0.00 | 0.02 | 0.00 |
| autocomplete-closed | 0.00 | 0.00 | 0.00 | 0.00 |
| tags-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| phone-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| filter-menu-open | 0.00 | 0.00 | 0.00 | 0.00 |
| filter-menu-closed | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-month | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-month-handlers | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-month-more | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-month-noheader | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-week | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-week-handlers | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-day | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-mini-dot | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-mini-tint | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-mini-range | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-mini-multi | 0.00 | 0.00 | 0.00 | 0.00 |
| calendar-mini-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| color-picker-full | 0.00 | 0.00 | 0.00 | 0.00 |
| color-picker-alpha | 0.00 | 0.00 | 0.00 | 0.00 |
| color-picker-popover | 0.00 | 0.00 | 0.00 | 0.00 |
| color-picker-swatches | 0.00 | 0.00 | 0.00 | 0.00 |
| date-picker-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| date-picker-states | 0.00 | 0.00 | 0.00 | 0.00 |
| date-picker-open | 0.00 | 0.00 | 0.00 | 0.00 |
| date-picker-open-range | 0.00 | 0.00 | 0.00 | 0.00 |
| date-picker-panel | 0.00 | 0.00 | 0.00 | 0.00 |
| time-picker-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| time-picker-list | 0.00 | 0.00 | 0.00 | 0.00 |
| datetime-picker-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| datetime-picker-panel | 0.00 | 0.00 | 0.00 | 0.00 |
| image-input-states | 0.00 | 0.00 | 0.00 | 0.00 |
| image-input-field | 0.00 | 0.00 | 0.00 | 0.00 |
| rating-readonly | 0.00 | 0.00 | 0.00 | 0.00 |
| rating-interactive | 0.00 | 0.00 | 0.00 | 0.00 |
| rating-distribution | 0.00 | 0.00 | 0.00 | 0.00 |
| range-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| range-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| range-wrapped | 0.05 | 0.05 | 0.05 | 0.05 |
| range-vertical | 0.00 | 0.00 | 0.00 | 0.00 |
| signature-pad | 0.00 | 0.00 | 0.00 | 0.00 |
| upload-drop | 0.00 | 0.00 | 0.00 | 0.00 |
| upload-zone | 0.00 | 0.00 | 0.00 | 0.00 |
| upload-file | 0.00 | 0.00 | 0.00 | 0.00 |
| upload-thumbs | 0.06 | 0.06 | 0.06 | 0.06 |
| text-editor-default | 0.02 | 0.02 | 0.02 | 0.02 |
| text-editor-comment | 0.00 | 0.00 | 0.00 | 0.00 |
| text-editor-content | 0.00 | 0.00 | 0.00 | 0.00 |
| due-calendar | 0.00 | 0.00 | 0.00 | 0.00 |
| due-calendar-animated | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-toast-steps | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-ring | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-conn | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-palette-nomatch | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-tooltip-tip | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-count-delta | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-error-compact | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-calendar-mini-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-calendar-mini-dots | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-calendar-mini-week | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-time-list-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-color-picker-row | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-signature-typed | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-text-editor-compact | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-view-switcher-stretch | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-pagination-sides | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-ai-tool-trace-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-navbar-search-typing | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-theme-picker-menu-open | 0.02 | 0.02 | 0.02 | 0.00 |
| fx-theme-switch-value | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-sidebar-nav-color | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-sidebar-nav-count | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-main-sidebar-count | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-rail-workspace-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| fx-ai-chat-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| kpi-card-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| kpi-card-trend | 0.03 | 0.03 | 0.03 | 0.03 |
| kpi-card-spark | 0.01 | 0.01 | 0.01 | 0.01 |
| kpi-card-progress | 0.00 | 0.00 | 0.00 | 0.00 |
| kpi-card-badge | 0.00 | 0.00 | 0.00 | 0.00 |
| kpi-card-badge-icon | 0.00 | 0.00 | 0.00 | 0.00 |
| kpi-card-badge-count | 0.00 | 0.00 | 0.00 | 0.00 |
| kpi-card-loading | 0.00 | 0.00 | 0.00 | 0.00 |
| sparkline-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| sparkline-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| bar-chart-default | 0.00 | 0.00 | 0.00 | 0.00 |
| bar-chart-shapes | 0.00 | 0.00 | 0.00 | 0.00 |
| donut-chart-default | 0.02 | 0.01 | 0.02 | 0.02 |
| donut-chart-variants | 0.01 | 0.01 | 0.01 | 0.02 |
| waterfall-chart-default | 0.00 | 0.00 | 0.00 | 0.00 |
| waterfall-chart-auto | 0.00 | 0.00 | 0.00 | 0.00 |
| cohort-heatmap-default | 0.00 | 0.00 | 0.00 | 0.00 |
| cohort-heatmap-thresholds | 0.00 | 0.00 | 0.00 | 0.00 |
| line-chart-default | 0.00 | 0.00 | 0.00 | 0.00 |
| line-chart-single | 0.00 | 0.00 | 0.00 | 0.00 |
| line-chart-sub-delta | 0.01 | 0.01 | 0.01 | 0.02 |
| bar-list-default | 0.00 | 0.00 | 0.00 | 0.00 |
| heatmap-default | 0.00 | 0.00 | 0.00 | 0.00 |
| stat-default | 0.00 | 0.00 | 0.00 | 0.00 |
| stat-sunken | 0.00 | 0.00 | 0.00 | 0.00 |
| stat-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| stat-rich | 0.00 | 0.00 | 0.00 | 0.00 |
| tabs-matrix | 0.00 | 0.00 | 0.00 | 0.00 |
| tabs-color | 0.00 | 0.00 | 0.00 | 0.00 |
| tabs-active | 0.00 | 0.00 | 0.00 | 0.00 |
| tabs-vertical | 0.00 | 0.00 | 0.00 | 0.00 |
| tabs-count | 0.00 | 0.00 | 0.00 | 0.00 |
| tabs-classic | 0.00 | 0.00 | 0.00 | 0.00 |
| tabs-links | 0.00 | 0.00 | 0.00 | 0.00 |
| breadcrumb-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| breadcrumb-icon | 0.00 | 0.00 | 0.00 | 0.00 |
| breadcrumb-truncated | 0.00 | 0.00 | 0.00 | 0.00 |
| pagination-matrix | 0.00 | 0.00 | 0.00 | 0.00 |
| pagination-current | 0.00 | 0.00 | 0.00 | 0.00 |
| pagination-classic | 0.00 | 0.00 | 0.00 | 0.00 |
| pagination-footer | 0.00 | 0.00 | 0.00 | 0.00 |
| steps-color | 0.00 | 0.00 | 0.00 | 0.00 |
| steps-size | 0.00 | 0.00 | 0.00 | 0.00 |
| steps-vertical | 0.00 | 0.00 | 0.00 | 0.00 |
| steps-classic | 0.00 | 0.00 | 0.00 | 0.00 |
| menu-list-matrix | 0.00 | 0.00 | 0.00 | 0.00 |
| menu-list-count | 0.00 | 0.00 | 0.00 | 0.00 |
| menu-row | 0.00 | 0.00 | 0.00 | 0.00 |
| scrollspy-demo | 0.00 | 0.00 | 0.00 | 0.00 |
| view-switcher-seg | 0.00 | 0.00 | 0.00 | 0.00 |
| view-switcher-row | 0.00 | 0.00 | 0.00 | 0.00 |
| dropdown-open | 0.00 | 0.00 | 0.00 | 0.00 |
| dropdown-open-end | 0.00 | 0.00 | 0.00 | 0.00 |
| dropdown-triggers | 0.00 | 0.00 | 0.00 | 0.00 |
| dropdown-kebab | 0.00 | 0.00 | 0.00 | 0.00 |
| dropdown-split | 0.00 | 0.00 | 0.00 | 0.00 |
| dropdown-items | 0.05 | 0.05 | 0.05 | 0.04 |
| dropdown-rich | 0.00 | 0.00 | 0.00 | 0.00 |
| dropdown-extras | 0.01 | 0.01 | 0.01 | 0.05 |
| dropdown-placement | 0.00 | 0.00 | 0.00 | 0.00 |
| action-menu-open | 0.00 | 0.00 | 0.00 | 0.00 |
| action-menu-trigger | 0.00 | 0.00 | 0.00 | 0.00 |
| action-menu-rich | 0.00 | 0.00 | 0.00 | 0.00 |
| action-button-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| action-button-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| action-button-label | 0.00 | 0.00 | 0.00 | 0.00 |
| action-button-row | 0.00 | 0.00 | 0.00 | 0.00 |
| context-menu-box | 0.00 | 0.00 | 0.00 | 0.00 |
| steps-loop | 0.00 | 0.00 | 0.00 | 0.00 |
| pagination-loop | 0.00 | 0.00 | 0.00 | 0.00 |
| menu-list-loop | 0.00 | 0.00 | 0.00 | 0.00 |
| accordion-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| accordion-header | 0.00 | 0.00 | 0.00 | 0.00 |
| accordion-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| collapse-chevron | 0.00 | 0.00 | 0.00 | 0.00 |
| collapse-closed | 0.00 | 0.00 | 0.00 | 0.00 |
| collapse-text | 0.00 | 0.00 | 0.00 | 0.00 |
| collapse-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| drawer-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| drawer-float | 0.00 | 0.00 | 0.00 | 0.00 |
| drawer-flush | 0.00 | 0.00 | 0.00 | 0.00 |
| drawer-left | 0.00 | 0.00 | 0.00 | 0.00 |
| drawer-page | 0.00 | 0.00 | 0.00 | 0.00 |
| drawer-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-align | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-corner | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-destructive | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-page | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-page-header | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-sizes | 0.00 | 0.00 | 0.00 | 0.00 |
| modal-tones | 0.00 | 0.00 | 0.00 | 0.00 |
| notif-bell | 0.00 | 0.00 | 0.00 | 0.00 |
| notif-bell-closed | 0.00 | 0.00 | 0.00 | 0.00 |
| notif-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| notif-classic | 0.00 | 0.00 | 0.00 | 0.00 |
| notif-empty | 0.00 | 0.00 | 0.00 | 0.00 |
| palette-bare | 0.00 | 0.00 | 0.00 | 0.20 |
| palette-canvas | 0.04 | 0.03 | 0.04 | 0.03 |
| palette-classic | 0.04 | 0.03 | 0.04 | 0.03 |
| palette-scopes | 0.05 | 0.05 | 0.06 | 0.05 |
| palette-typed | 0.00 | 0.00 | 0.00 | 0.16 |
| popover-closed | 0.00 | 0.00 | 0.00 | 0.00 |
| popover-default | 0.00 | 0.00 | 0.00 | 0.00 |
| popover-placements | 0.00 | 0.00 | 0.00 | 0.00 |
| sheet-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| sheet-bottom | 0.00 | 0.00 | 0.00 | 0.00 |
| tooltip-closed | 0.00 | 0.00 | 0.00 | 0.00 |
| tooltip-colors | 0.00 | 0.00 | 0.00 | 0.00 |
| tooltip-content | 0.00 | 0.00 | 0.00 | 0.00 |
| tooltip-placements | 0.00 | 0.00 | 0.00 | 0.00 |
| glow-text-tones | 0.00 | 0.00 | 0.00 | 0.00 |
| code-block-basic | 0.00 | 0.00 | 0.00 | 0.00 |
| code-block-plain | 0.00 | 0.00 | 0.00 | 0.00 |
| code-block-diff | 0.00 | 0.00 | 0.00 | 0.00 |
| code-block-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| code-block-parts | 0.00 | 0.00 | 0.00 | 0.00 |
| email-preview | 0.00 | 0.00 | 0.00 | 0.00 |
| email-preview-bare | 0.00 | 0.00 | 0.00 | 0.00 |
| trace-lines | 0.00 | 0.00 | 0.00 | 0.00 |
| trace-spans | 0.00 | 0.00 | 0.00 | 0.00 |
| trace-steps | 0.00 | 0.00 | 0.00 | 0.00 |
| tool-lines | 0.00 | 0.00 | 0.00 | 0.00 |
| tool-panels | 0.00 | 0.00 | 0.00 | 0.00 |
| tool-approval | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-insights-card | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-insights-list | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-promo-card | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-promo-rail | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-greeting | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-message-roles | 0.01 | 0.02 | 0.01 | 0.01 |
| ai-message-stream | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-message-trace | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-tool-trace-open | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-proposal-pending | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-proposal-layouts | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-proposal-status | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-composer-default | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-composer-states | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-composer-canvas | 0.00 | 0.00 | 0.00 | 0.00 |
| prompt-suggestions-card | 0.00 | 0.00 | 0.00 | 0.00 |
| prompt-suggestions-pill-grid | 0.00 | 0.00 | 0.00 | 0.00 |
| conversation-list-card | 0.00 | 0.00 | 0.00 | 0.00 |
| conversation-list-rail | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-chat-card | 0.01 | 0.01 | 0.00 | 0.01 |
| ai-chat-start | 0.00 | 0.00 | 0.00 | 0.00 |
| ai-chat-variants | 0.02 | 0.02 | 0.01 | 0.02 |
| ref-ai-insights | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-ai-promo | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-ai-message | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-ai-composer | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-conversation-list | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-ai-proposal | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-ai-tool-trace | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-trace | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-code-block | 0.00 | 0.00 | 0.00 | 0.00 |
| ref-glow-text | 0.00 | 0.00 | 0.00 | 0.00 |
| container-fixed | 0.00 | 0.00 | 0.00 | 0.00 |
| container-fluid | 0.00 | 0.00 | 0.00 | 0.00 |
| container-preview | 0.00 | 0.00 | 0.00 | 0.00 |
| scroll-plain | 0.00 | 0.00 | 0.00 | 0.00 |
| scroll-panel | 0.00 | 0.00 | 0.00 | 0.00 |
| scroll-preview | 0.00 | 0.00 | 0.00 | 0.00 |
| sticky-preview | 0.00 | 0.00 | 0.00 | 0.00 |
| sticky-bar | 0.00 | 0.00 | 0.00 | 0.00 |
| logo-chart | 0.07 | 0.05 | 0.07 | 0.06 |
| logo-hexagon | 0.00 | 0.00 | 0.00 | 0.00 |
| theme-switch-matrix | 0.00 | 0.00 | 0.00 | 0.00 |
| theme-picker-grid | 0.00 | 0.00 | 0.00 | 0.00 |
| theme-picker-menu | 0.00 | 0.00 | 0.00 | 0.00 |
| icon-rail | 0.03 | 0.03 | 0.03 | 0.03 |
| sidebar-panel | 0.00 | 0.00 | 0.00 | 0.00 |
| page-header-inline | 0.00 | 0.00 | 0.00 | 0.00 |
| page-header-page | 0.00 | 0.00 | 0.00 | 0.00 |
| app-shell-sidebar | 0.00 | 0.00 | 0.00 | 0.00 |
| app-shell-framed | 0.00 | 0.00 | 0.00 | 0.00 |
| app-shell-minimal | 0.00 | 0.00 | 0.00 | 0.00 |
| shell-floating | 0.00 | 0.00 | 0.00 | 0.00 |
| app-shell-sideblock | 0.00 | 0.00 | 0.00 | 0.00 |
| app-shell-horizontal | 0.00 | 0.00 | 0.00 | 0.00 |
| header-full | 0.00 | 0.00 | 0.00 | 0.00 |
| framed-sidebar | 0.00 | 0.00 | 0.00 | 0.00 |
| tab-bar | 0.00 | 0.00 | 0.00 | 0.00 |
| right-sidebar | 0.00 | 0.00 | 0.00 | 0.00 |
| monochrome | 0.00 | 0.00 | 0.00 | 0.00 |
| shell-wire | 0.00 | 0.00 | 0.00 | 0.00 |
| shell-app | 0.00 | 0.00 | 0.00 | 0.00 |
| sidebar-sections | 0.00 | 0.00 | 0.00 | 0.00 |
| sidebar-collapsed | 0.00 | 0.00 | 0.00 | 0.00 |
| sidebar-tree | 0.00 | 0.00 | 0.00 | 0.00 |
| sidebar-rail | 0.00 | 0.00 | 0.00 | 0.00 |
| sidebar-items | 0.00 | 0.00 | 0.00 | 0.00 |
| navbar-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| navbar-pieces | 0.00 | 0.00 | 0.01 | 0.00 |
| landing-nav-variants | 0.00 | 0.00 | 0.00 | 0.00 |
| landing-nav-responsive | 0.00 | 0.00 | 0.00 | 0.00 |
| landing-mega | 0.03 | 0.02 | 0.03 | 0.02 |
| landing-products | 0.00 | 0.00 | 0.00 | 0.00 |
| landing-announcement | 0.00 | 0.00 | 0.00 | 0.00 |
| auth-split-card | 0.02 | 0.03 | 0.02 | 0.03 |
| auth-split-art | 0.00 | 0.00 | 0.00 | 0.00 |
| auth-page | 0.00 | 0.00 | 0.00 | 0.00 |

## Tema próprio por caso (516 casos, % de pixels ainda na cor do Ledger)

| caso | light | dark |
|---|---|---|
| palette-ramp | 0.00 | 0.00 |
| palette-chips | 0.00 | 0.00 |
| palette-swatches | 0.00 | 0.00 |
| palette-swatches-chart | 0.00 | 0.00 |
| palette-chart-2 | 0.00 | 0.00 |
| divider-horizontal | 0.00 | 0.00 |
| divider-vertical | 0.00 | 0.00 |
| kbd-variants | 0.00 | 0.00 |
| typography-sizes | 0.00 | 0.00 |
| typography-gradients | 0.00 | 0.00 |
| typography-decoration | 0.00 | 0.00 |
| typography-links | 0.00 | 0.00 |
| typography-inline-code | 0.00 | 0.00 |
| typography-headings | 0.00 | 0.00 |
| illustration-states | 0.00 | 0.00 |
| illustration-tones | 0.00 | 0.00 |
| clipboard-variants | 0.00 | 0.00 |
| clipboard-sizes | 0.00 | 0.00 |
| clipboard-input | 0.00 | 0.00 |
| fab-canvas | 0.00 | 0.00 |
| fab-pill-hover | 0.00 | 0.00 |
| fab-pill-expanded | 0.00 | 0.00 |
| fab-pill-colors | 0.00 | 0.00 |
| fab-pill-collapsed | 0.00 | 0.00 |
| fab-positions | 0.00 | 0.00 |
| fab-dial-open | 0.00 | 0.00 |
| fab-dial-closed | 0.00 | 0.00 |
| button-canvas-looks | 0.00 | 0.00 |
| illustration-summit | 0.00 | 0.00 |
| illustration-summit-crop | 0.00 | 0.00 |
| button-solid | 0.00 | 0.00 |
| button-glow | 0.00 | 0.00 |
| button-outline | 0.00 | 0.00 |
| button-soft | 0.01 | 0.01 |
| button-bordered | 0.02 | 0.02 |
| button-flat | 0.00 | 0.00 |
| button-glass | 0.00 | 0.00 |
| button-ghost | 0.00 | 0.00 |
| button-dim | 0.00 | 0.00 |
| button-sizes | 0.00 | 0.00 |
| button-shapes | 0.00 | 0.00 |
| button-states | 0.00 | 0.00 |
| button-group | 0.00 | 0.00 |
| badge-solid | 0.00 | 0.00 |
| badge-glow | 0.00 | 0.00 |
| badge-soft | 0.00 | 0.00 |
| badge-outline | 0.00 | 0.00 |
| badge-flat | 0.00 | 0.00 |
| badge-bordered | 0.00 | 0.00 |
| badge-sizes | 0.00 | 0.00 |
| button-matrix-xs | 0.00 | 0.00 |
| button-matrix-md | 0.00 | 0.00 |
| button-matrix-lg | 0.00 | 0.00 |
| button-matrix-xl | 0.00 | 0.00 |
| button-pill | 0.00 | 0.00 |
| button-square | 0.00 | 0.00 |
| button-loading-pip | 0.00 | 0.00 |
| button-current | 0.00 | 0.00 |
| button-canvas | 0.00 | 0.00 |
| icon-button | 0.00 | 0.00 |
| icon-button-topbar | 0.00 | 0.00 |
| badge-shapes | 0.00 | 0.00 |
| badge-colors-all | 0.00 | 0.00 |
| badge-icon | 0.00 | 0.00 |
| badge-canvas | 0.00 | 0.00 |
| icon-sizes | 0.00 | 0.00 |
| avatar-colors | 0.00 | 0.00 |
| avatar-sizes | 0.00 | 0.00 |
| avatar-shapes | 0.00 | 0.00 |
| avatar-status | 0.00 | 0.00 |
| avatar-rings | 0.00 | 0.00 |
| avatar-kinds | 0.00 | 0.00 |
| avatar-custom | 0.00 | 0.00 |
| avatar-image | 0.00 | 0.00 |
| avatar-legacy | 0.00 | 0.00 |
| avatar-legacy-t1 | 0.00 | 0.00 |
| avatar-group | 0.00 | 0.00 |
| avatar-group-more | 0.00 | 0.00 |
| tag-matrix | 0.00 | 0.00 |
| tag-shapes | 0.00 | 0.00 |
| tag-pressable | 0.00 | 0.00 |
| tag-canvas | 0.00 | 0.00 |
| description-list-cols | 0.00 | 0.00 |
| description-list-inline | 0.00 | 0.00 |
| mini-card-panel | 0.00 | 0.00 |
| mini-card-value | 0.00 | 0.00 |
| mini-card-surface | 0.00 | 0.00 |
| pixel-card-colors | 0.00 | 0.00 |
| pixel-card-states | 0.00 | 0.00 |
| cover-bands | 0.00 | 0.00 |
| cover-avatar | 0.00 | 0.00 |
| cover-image | 0.00 | 0.00 |
| mask-shapes | 0.00 | 0.00 |
| mask-sizes | 0.00 | 0.00 |
| mask-image | 0.00 | 0.00 |
| timer-ring | 0.00 | 0.00 |
| timer-extras | 0.00 | 0.00 |
| timer-mini | 0.00 | 0.00 |
| cash-timer-states | 0.00 | 0.00 |
| bulk-bar-pill | 0.00 | 0.00 |
| bulk-bar-progress | 0.00 | 0.00 |
| bulk-bar-inline | 0.00 | 0.00 |
| bulk-bar-float | 0.00 | 0.00 |
| carousel-slide | 0.00 | 0.00 |
| card-table-tray | 0.00 | 0.00 |
| kanban-board | 0.00 | 0.00 |
| kanban-colors | 0.00 | 0.00 |
| kanban-scroll | 0.00 | 0.00 |
| timeline-markers | 0.00 | 0.00 |
| timeline-sizes | 0.00 | 0.00 |
| timeline-colors | 0.00 | 0.00 |
| timeline-dot | 0.00 | 0.00 |
| timeline-canvas | 0.00 | 0.00 |
| step-group-states | 0.00 | 0.00 |
| step-group-plain | 0.00 | 0.00 |
| step-group-logs | 0.00 | 0.00 |
| tree-basic | 0.00 | 0.00 |
| tree-data | 0.00 | 0.00 |
| tree-check | 0.00 | 0.00 |
| hero-soft | 0.00 | 0.00 |
| hero-lg-meter | 0.00 | 0.00 |
| hero-panel-steps | 0.00 | 0.00 |
| hero-ai | 0.00 | 0.00 |
| hero-picture | 0.00 | 0.00 |
| flow-edges | 0.00 | 0.00 |
| flow-panel | 0.00 | 0.00 |
| flow-grid | 0.00 | 0.00 |
| table-variants | 0.00 | 0.00 |
| table-shapes | 0.00 | 0.00 |
| table-select | 0.00 | 0.00 |
| table-select-all | 0.00 | 0.00 |
| table-expand | 0.00 | 0.00 |
| table-hand | 0.00 | 0.00 |
| table-priority | 0.00 | 0.00 |
| table-card | 0.00 | 0.00 |
| table-details | 0.00 | 0.00 |
| table-edit | 0.00 | 0.00 |
| table-skeleton | 0.00 | 0.00 |
| data-table-advanced | 0.00 | 0.00 |
| data-table-grid | 0.00 | 0.00 |
| data-table-pagers | 0.00 | 0.00 |
| data-table-states | 0.00 | 0.00 |
| table-toolbar | 0.00 | 0.00 |
| card-tray | 0.00 | 0.00 |
| card-flat | 0.00 | 0.00 |
| card-surfaces | 0.00 | 0.00 |
| card-surface-colors | 0.00 | 0.00 |
| card-sizes | 0.00 | 0.00 |
| card-parts | 0.00 | 0.00 |
| card-sizes-heading | 0.00 | 0.00 |
| alert-canvas | 0.00 | 0.00 |
| alert-soft | 0.00 | 0.00 |
| alert-bordered | 0.00 | 0.00 |
| alert-outline | 0.00 | 0.00 |
| alert-solid | 0.00 | 0.00 |
| alert-pill | 0.00 | 0.00 |
| alert-accent | 0.00 | 0.00 |
| alert-actions | 0.00 | 0.00 |
| alert-bare | 0.00 | 0.00 |
| aura-modes | 0.00 | 0.00 |
| aura-modes-accent | 0.00 | 0.00 |
| aura-tones | 0.00 | 0.00 |
| aura-tones-dual | 0.00 | 0.00 |
| aura-tones-glow | 0.00 | 0.00 |
| aura-widths | 0.00 | 0.00 |
| aura-shapes | 0.00 | 0.00 |
| spinner-variants | 0.00 | 0.00 |
| spinner-colors | 0.00 | 0.00 |
| skeleton-animation | 0.00 | 0.00 |
| skeleton-shapes | 0.00 | 0.00 |
| skeleton-layout | 0.00 | 0.00 |
| skeleton-lineone | 0.00 | 0.00 |
| progress-solid | 0.00 | 0.00 |
| progress-soft | 0.00 | 0.00 |
| progress-gradient | 0.00 | 0.00 |
| progress-default | 0.00 | 0.00 |
| progress-sizes | 0.00 | 0.00 |
| progress-heights | 0.00 | 0.00 |
| progress-states | 0.00 | 0.00 |
| progress-stack | 0.00 | 0.00 |
| empty-canvas | 0.00 | 0.00 |
| empty-card | 0.00 | 0.00 |
| empty-card-heading | 0.00 | 0.00 |
| empty-inline | 0.00 | 0.00 |
| empty-plain | 0.00 | 0.00 |
| empty-table | 0.00 | 0.00 |
| error-page-404 | 0.00 | 0.00 |
| error-page-500 | 0.00 | 0.00 |
| error-page-tones | 0.00 | 0.00 |
| error-state | 0.00 | 0.00 |
| error-links | 0.00 | 0.00 |
| toast-card-light | 0.00 | 0.00 |
| toast-card-dark | 0.00 | 0.00 |
| toast-card-plain | 0.00 | 0.00 |
| toast-card-actions | 0.00 | 0.00 |
| toast-card-aura | 0.00 | 0.00 |
| toast-card-progress | 0.00 | 0.00 |
| toast-status | 0.00 | 0.00 |
| toaster-static | 0.00 | 0.00 |
| toaster-static-top | 0.00 | 0.00 |
| connection-banner-toast | 0.00 | 0.00 |
| connection-banner | 0.00 | 0.00 |
| input-basic | 0.00 | 0.00 |
| input-variants | 0.00 | 0.00 |
| input-states | 0.00 | 0.00 |
| input-pill-sizes | 0.00 | 0.00 |
| input-inline-hint | 0.00 | 0.00 |
| checkbox-colors | 0.00 | 0.00 |
| checkbox-sizes | 0.00 | 0.00 |
| checkbox-desc | 0.00 | 0.00 |
| checkbox-outline | 0.00 | 0.00 |
| switch-colors | 0.00 | 0.00 |
| switch-sizes | 0.00 | 0.00 |
| switch-inset | 0.00 | 0.00 |
| switch-labels | 0.00 | 0.00 |
| radio-basic | 0.00 | 0.00 |
| radio-shapes | 0.00 | 0.00 |
| radio-card | 0.00 | 0.00 |
| radio-chip | 0.00 | 0.00 |
| radio-tile | 0.00 | 0.00 |
| segmented-basic | 0.00 | 0.00 |
| chip-basic | 0.00 | 0.00 |
| pill-select-basic | 0.00 | 0.00 |
| textarea-variants | 0.00 | 0.00 |
| textarea-counter | 0.00 | 0.00 |
| textarea-state | 0.00 | 0.00 |
| textarea-bars | 0.00 | 0.00 |
| otp-sizes | 0.00 | 0.00 |
| otp-variants | 0.00 | 0.00 |
| otp-states | 0.00 | 0.00 |
| number-styles | 0.00 | 0.00 |
| number-addons | 0.00 | 0.00 |
| number-states | 0.00 | 0.00 |
| password-strength | 0.00 | 0.00 |
| input-group-basic | 0.00 | 0.00 |
| form-section-basic | 0.00 | 0.00 |
| select-basic | 0.00 | 0.00 |
| select-open | 0.00 | 0.00 |
| pillbox-basic | 0.00 | 0.00 |
| autocomplete-open | 0.00 | 0.00 |
| autocomplete-closed | 0.00 | 0.00 |
| tags-basic | 0.00 | 0.00 |
| phone-basic | 0.00 | 0.00 |
| filter-menu-open | 0.00 | 0.00 |
| filter-menu-closed | 0.00 | 0.00 |
| calendar-month | 0.00 | 0.00 |
| calendar-month-handlers | 0.00 | 0.00 |
| calendar-month-more | 0.00 | 0.00 |
| calendar-month-noheader | 0.00 | 0.00 |
| calendar-week | 0.00 | 0.00 |
| calendar-week-handlers | 0.00 | 0.00 |
| calendar-day | 0.00 | 0.00 |
| calendar-mini-dot | 0.00 | 0.00 |
| calendar-mini-tint | 0.00 | 0.00 |
| calendar-mini-range | 0.00 | 0.00 |
| calendar-mini-multi | 0.00 | 0.00 |
| calendar-mini-bare | 0.00 | 0.00 |
| color-picker-full | 0.01 | 0.01 |
| color-picker-alpha | 0.00 | 0.00 |
| color-picker-popover | 0.00 | 0.00 |
| color-picker-swatches | 0.00 | 0.00 |
| date-picker-basic | 0.00 | 0.00 |
| date-picker-states | 0.00 | 0.00 |
| date-picker-open | 0.00 | 0.00 |
| date-picker-open-range | 0.00 | 0.00 |
| date-picker-panel | 0.00 | 0.00 |
| time-picker-basic | 0.00 | 0.00 |
| time-picker-list | 0.00 | 0.00 |
| datetime-picker-basic | 0.00 | 0.00 |
| datetime-picker-panel | 0.00 | 0.00 |
| image-input-states | 0.00 | 0.00 |
| image-input-field | 0.00 | 0.00 |
| rating-readonly | 0.00 | 0.00 |
| rating-interactive | 0.00 | 0.00 |
| rating-distribution | 0.00 | 0.00 |
| range-colors | 0.00 | 0.00 |
| range-sizes | 0.00 | 0.00 |
| range-wrapped | 0.00 | 0.00 |
| range-vertical | 0.00 | 0.00 |
| signature-pad | 0.00 | 0.00 |
| upload-drop | 0.00 | 0.00 |
| upload-zone | 0.00 | 0.00 |
| upload-file | 0.00 | 0.00 |
| upload-thumbs | 0.00 | 0.00 |
| text-editor-default | 0.00 | 0.00 |
| text-editor-comment | 0.00 | 0.00 |
| text-editor-content | 0.00 | 0.00 |
| due-calendar | 0.00 | 0.00 |
| due-calendar-animated | 0.00 | 0.00 |
| fx-toast-steps | 0.00 | 0.00 |
| fx-ring | 0.00 | 0.00 |
| fx-conn | 0.00 | 0.00 |
| fx-palette-nomatch | 0.00 | 0.00 |
| fx-tooltip-tip | 0.00 | 0.00 |
| fx-count-delta | 0.00 | 0.00 |
| fx-error-compact | 0.00 | 0.00 |
| fx-calendar-mini-sizes | 0.00 | 0.00 |
| fx-calendar-mini-dots | 0.00 | 0.00 |
| fx-calendar-mini-week | 0.00 | 0.00 |
| fx-time-list-bare | 0.00 | 0.00 |
| fx-color-picker-row | 4.78 | 4.78 |
| fx-signature-typed | 0.00 | 0.00 |
| fx-text-editor-compact | 0.00 | 0.00 |
| fx-view-switcher-stretch | 0.00 | 0.00 |
| fx-pagination-sides | 0.00 | 0.00 |
| fx-ai-tool-trace-bare | 0.00 | 0.00 |
| fx-navbar-search-typing | 0.00 | 0.00 |
| fx-theme-picker-menu-open | 0.00 | 0.00 |
| fx-theme-switch-value | 0.00 | 0.00 |
| fx-sidebar-nav-color | 0.00 | 0.00 |
| fx-sidebar-nav-count | 0.00 | 0.00 |
| fx-main-sidebar-count | 0.00 | 0.00 |
| fx-rail-workspace-bare | 0.00 | 0.00 |
| fx-ai-chat-variants | 0.00 | 0.00 |
| kpi-card-canvas | 0.00 | 0.00 |
| kpi-card-trend | 0.00 | 0.00 |
| kpi-card-spark | 0.00 | 0.00 |
| kpi-card-progress | 0.00 | 0.00 |
| kpi-card-badge | 0.00 | 0.00 |
| kpi-card-badge-icon | 0.00 | 0.00 |
| kpi-card-badge-count | 0.00 | 0.00 |
| kpi-card-loading | 0.00 | 0.00 |
| sparkline-colors | 0.00 | 0.00 |
| sparkline-shapes | 0.00 | 0.00 |
| bar-chart-default | 0.00 | 0.00 |
| bar-chart-shapes | 0.00 | 0.00 |
| donut-chart-default | 0.00 | 0.00 |
| donut-chart-variants | 0.00 | 0.00 |
| waterfall-chart-default | 0.00 | 0.00 |
| waterfall-chart-auto | 0.00 | 0.00 |
| cohort-heatmap-default | 0.00 | 0.00 |
| cohort-heatmap-thresholds | 0.00 | 0.00 |
| line-chart-default | 0.00 | 0.00 |
| line-chart-single | 0.00 | 0.00 |
| line-chart-sub-delta | 0.00 | 0.00 |
| bar-list-default | 0.00 | 0.00 |
| heatmap-default | 0.00 | 0.00 |
| stat-default | 0.00 | 0.00 |
| stat-sunken | 0.00 | 0.00 |
| stat-bare | 0.00 | 0.00 |
| stat-rich | 0.00 | 0.00 |
| tabs-matrix | 0.00 | 0.00 |
| tabs-color | 0.00 | 0.00 |
| tabs-active | 0.00 | 0.00 |
| tabs-vertical | 0.00 | 0.00 |
| tabs-count | 0.00 | 0.00 |
| tabs-classic | 0.00 | 0.00 |
| tabs-links | 0.00 | 0.00 |
| breadcrumb-variants | 0.00 | 0.00 |
| breadcrumb-icon | 0.00 | 0.00 |
| breadcrumb-truncated | 0.00 | 0.00 |
| pagination-matrix | 0.00 | 0.00 |
| pagination-current | 0.00 | 0.00 |
| pagination-classic | 0.00 | 0.00 |
| pagination-footer | 0.00 | 0.00 |
| steps-color | 0.00 | 0.00 |
| steps-size | 0.00 | 0.00 |
| steps-vertical | 0.00 | 0.00 |
| steps-classic | 0.00 | 0.00 |
| menu-list-matrix | 0.00 | 0.00 |
| menu-list-count | 0.00 | 0.00 |
| menu-row | 0.00 | 0.00 |
| scrollspy-demo | 0.00 | 0.00 |
| view-switcher-seg | 0.00 | 0.00 |
| view-switcher-row | 0.00 | 0.00 |
| dropdown-open | 0.00 | 0.00 |
| dropdown-open-end | 0.00 | 0.00 |
| dropdown-triggers | 0.00 | 0.00 |
| dropdown-kebab | 0.00 | 0.00 |
| dropdown-split | 0.00 | 0.00 |
| dropdown-items | 0.00 | 0.00 |
| dropdown-rich | 0.00 | 0.00 |
| dropdown-extras | 0.00 | 0.00 |
| dropdown-placement | 0.00 | 0.00 |
| action-menu-open | 0.00 | 0.00 |
| action-menu-trigger | 0.00 | 0.00 |
| action-menu-rich | 0.00 | 0.00 |
| action-button-variants | 0.00 | 0.00 |
| action-button-sizes | 0.00 | 0.00 |
| action-button-label | 0.00 | 0.00 |
| action-button-row | 0.00 | 0.00 |
| context-menu-box | 0.00 | 0.00 |
| steps-loop | 0.00 | 0.00 |
| pagination-loop | 0.00 | 0.00 |
| menu-list-loop | 0.00 | 0.00 |
| accordion-colors | 0.00 | 0.00 |
| accordion-header | 0.00 | 0.00 |
| accordion-variants | 0.00 | 0.00 |
| collapse-chevron | 0.00 | 0.00 |
| collapse-closed | 0.00 | 0.00 |
| collapse-text | 0.00 | 0.00 |
| collapse-variants | 0.00 | 0.00 |
| drawer-bare | 0.00 | 0.00 |
| drawer-float | 0.00 | 0.00 |
| drawer-flush | 0.00 | 0.00 |
| drawer-left | 0.00 | 0.00 |
| drawer-page | 0.00 | 0.00 |
| drawer-sizes | 0.00 | 0.00 |
| modal-align | 0.00 | 0.00 |
| modal-basic | 0.00 | 0.00 |
| modal-corner | 0.00 | 0.00 |
| modal-destructive | 0.00 | 0.00 |
| modal-page | 0.00 | 0.00 |
| modal-page-header | 0.00 | 0.00 |
| modal-sizes | 0.00 | 0.00 |
| modal-tones | 0.00 | 0.00 |
| notif-bell | 0.00 | 0.00 |
| notif-bell-closed | 0.00 | 0.00 |
| notif-canvas | 0.00 | 0.00 |
| notif-classic | 0.00 | 0.00 |
| notif-empty | 0.00 | 0.00 |
| palette-bare | 0.00 | 0.00 |
| palette-canvas | 0.00 | 0.00 |
| palette-classic | 0.00 | 0.00 |
| palette-scopes | 0.00 | 0.00 |
| palette-typed | 0.00 | 0.00 |
| popover-closed | 0.00 | 0.00 |
| popover-default | 0.00 | 0.00 |
| popover-placements | 0.00 | 0.00 |
| sheet-bare | 0.00 | 0.00 |
| sheet-bottom | 0.00 | 0.00 |
| tooltip-closed | 0.00 | 0.00 |
| tooltip-colors | 0.00 | 0.00 |
| tooltip-content | 0.00 | 0.00 |
| tooltip-placements | 0.00 | 0.00 |
| glow-text-tones | 0.00 | 0.02 |
| code-block-basic | 0.08 | 0.08 |
| code-block-plain | 0.00 | 0.00 |
| code-block-diff | 0.07 | 0.07 |
| code-block-variants | 0.05 | 0.05 |
| code-block-parts | 0.04 | 0.04 |
| email-preview | 0.00 | 0.00 |
| email-preview-bare | 0.00 | 0.00 |
| trace-lines | 0.00 | 0.00 |
| trace-spans | 0.00 | 0.00 |
| trace-steps | 0.00 | 0.00 |
| tool-lines | 0.00 | 0.00 |
| tool-panels | 0.00 | 0.00 |
| tool-approval | 0.00 | 0.00 |
| ai-insights-card | 0.00 | 0.00 |
| ai-insights-list | 0.00 | 0.00 |
| ai-promo-card | 0.00 | 0.00 |
| ai-promo-rail | 0.00 | 0.00 |
| ai-greeting | 0.00 | 0.00 |
| ai-message-roles | 0.00 | 0.00 |
| ai-message-stream | 0.00 | 0.00 |
| ai-message-trace | 0.00 | 0.00 |
| ai-tool-trace-open | 0.00 | 0.00 |
| ai-proposal-pending | 0.00 | 0.00 |
| ai-proposal-layouts | 0.00 | 0.00 |
| ai-proposal-status | 0.00 | 0.00 |
| ai-composer-default | 0.00 | 0.00 |
| ai-composer-states | 0.00 | 0.00 |
| ai-composer-canvas | 0.00 | 0.00 |
| prompt-suggestions-card | 0.00 | 0.00 |
| prompt-suggestions-pill-grid | 0.00 | 0.00 |
| conversation-list-card | 0.00 | 0.00 |
| conversation-list-rail | 0.00 | 0.00 |
| ai-chat-card | 0.00 | 0.00 |
| ai-chat-start | 0.00 | 0.00 |
| ai-chat-variants | 0.00 | 0.00 |
| ref-ai-insights | 0.00 | 0.00 |
| ref-ai-promo | 0.00 | 0.00 |
| ref-ai-message | 0.00 | 0.00 |
| ref-ai-composer | 0.00 | 0.00 |
| ref-conversation-list | 0.00 | 0.00 |
| ref-ai-proposal | 0.00 | 0.00 |
| ref-ai-tool-trace | 0.00 | 0.00 |
| ref-trace | 0.00 | 0.00 |
| ref-code-block | 0.09 | 0.09 |
| ref-glow-text | 0.00 | 0.02 |
| container-fixed | 0.00 | 0.00 |
| container-fluid | 0.00 | 0.00 |
| container-preview | 0.00 | 0.00 |
| scroll-plain | 0.00 | 0.00 |
| scroll-panel | 0.00 | 0.00 |
| scroll-preview | 0.00 | 0.00 |
| sticky-preview | 0.00 | 0.00 |
| sticky-bar | 0.00 | 0.00 |
| logo-chart | 0.00 | 0.00 |
| logo-hexagon | 0.00 | 0.00 |
| theme-switch-matrix | 0.00 | 0.00 |
| theme-picker-grid | 4.18 | 4.18 |
| theme-picker-menu | 0.00 | 0.00 |
| icon-rail | 0.00 | 0.00 |
| sidebar-panel | 0.00 | 0.00 |
| page-header-inline | 0.00 | 0.00 |
| page-header-page | 0.00 | 0.00 |
| app-shell-sidebar | 0.00 | 0.00 |
| app-shell-framed | 0.00 | 0.00 |
| app-shell-minimal | 0.00 | 0.00 |
| shell-floating | 0.00 | 0.00 |
| app-shell-sideblock | 0.00 | 0.00 |
| app-shell-horizontal | 0.00 | 0.00 |
| header-full | 0.00 | 0.00 |
| framed-sidebar | 0.00 | 0.00 |
| tab-bar | 0.00 | 0.00 |
| right-sidebar | 0.00 | 0.00 |
| monochrome | 0.00 | 0.00 |
| shell-wire | 0.00 | 0.00 |
| shell-app | 0.00 | 0.00 |
| sidebar-sections | 0.00 | 0.00 |
| sidebar-collapsed | 0.00 | 0.00 |
| sidebar-tree | 0.00 | 0.00 |
| sidebar-rail | 0.00 | 0.00 |
| sidebar-items | 0.00 | 0.00 |
| navbar-variants | 0.00 | 0.00 |
| navbar-pieces | 0.00 | 0.00 |
| landing-nav-variants | 0.00 | 0.00 |
| landing-nav-responsive | 0.00 | 0.00 |
| landing-mega | 0.00 | 0.00 |
| landing-products | 0.00 | 0.00 |
| landing-announcement | 0.00 | 0.00 |
| auth-split-card | 0.00 | 0.00 |
| auth-split-art | 0.00 | 0.00 |
| auth-page | 0.00 | 0.00 |
