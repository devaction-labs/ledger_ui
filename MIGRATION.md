# Migração para Tailwind CSS v4 (HEEx + utilitários)

Cada componente vira HEEx estilizado **só com utilitários do Tailwind** (estilo Fluxon/shadcn), com a mesma
imagem do original (`lu-*`) em claro, escuro e paleta `crepusculo`. O piloto (Icon, Button, Badge, Input, Card,
Stat + `Form.field/label/error/help_text`) está pronto e é o modelo: leia `lib/ledger_ui/components/{button,badge,card,input,stat}.ex`.
Nunca chame o kit de "LineaUI".

## Regras do kit (obrigatórias)

1. Só utilitários nos componentes; valores arbitrários valem (`h-[30px]`, `shadow-[…]`, `[--c:var(--lu-ink)]`, `bg-(--c-soft)`).
   Nenhuma classe CSS nova. Exceções no CSS: tokens, `@theme`, `@layer base` mínimo e `@keyframes`.
2. Variáveis de runtime com prefixo `--lu-`, trocadas por `data-theme="light|dark"` e `data-palette="crepusculo"`.
3. `dark:` = `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *))`.
4. **Tema como no Flux**: nunca cor de marca nem cinza fixos, e nunca escreva `teal`. Accent: `bg-accent`, `text-accent-content`,
   `text-accent-foreground`, `bg-accent-50…900`, `bg-accent-soft` (em arbitrário: `var(--color-accent)`, `var(--lu-accent-500)`).
   Neutros pelos tokens: `bg-page|shell|tray|panel|sunken|hover|selected`, `border-line|line-strong`, `text-ink|ink-2|muted|subtle`,
   `bg-inverse text-on-inverse`, `bg-pos|neg|warn|info|lime|violet` (+ `-soft`), `shadow-xs…lg|btn`, `rounded-xs|sm|md|lg|xl|2xl` (4/6/10/14/20/28px),
   `font-sans|display|mono`. Tudo deriva de `--color-accent*` e `--color-gray-50…950` (README, "Tema próprio").
5. Cores semânticas (`color=`): `LedgerUI.Color.vars(color)` (`--c`, `--c-on`, `--c-soft`, `--c-ink`); as variantes só leem essas quatro.
6. Arredondado por padrão; pílula só com `shape="pill"`.
7. Ícones: `<.icon name="huge-…" size="sm|md|base|lg|xl">` (Hugeicons Stroke Rounded, `priv/icons.json` = `priv/hugeicons.json` da referência).
8. Movimento: manter as animações originais (`@keyframes` no CSS gerado; `animate-[nome_dur_easing_infinite]`); interação por `Phoenix.LiveView.JS` + hooks.
9. Tudo é componente utilizável; atributos dirigem o visual; formulários aceitam `field={@form[:x]}` e mostram erros do changeset via `<.field>`.
10. `attr`/`slot` com `values:` e `doc`. **Nunca dependa da ordem das classes**: escolha UM utilitário por propriedade em Elixir
    (o tamanho decide `px` e `rounded`; `shape="square"` troca `px-N` por `w-N px-0`; a cor da borda mora na variante, não na base).
    `class` serve para layout (`w-full`, `ml-auto`), não para sobrescrever o visual do componente.
11. Sem `font-size` no `html`, só no `body` (o showcase força `html{font-size:16px}` por causa do CSS antigo).
12. Todo elemento do componente leva `data-part="<nome>"` (veja "Testes do showcase").
13. Espaço em branco dentro de contêiner flex vira item: escreva conteúdo inline "colado" (`>{@x}<span …`), como em `Button.button_content/1`.

## Ferramentas (reprodutível)

Requisitos: Elixir (mise), Chromium (`/usr/bin/chromium`), Python com `playwright pillow numpy beautifulsoup4 markdown`
em um venv **fora do repo** e o binário standalone do Tailwind v4.

```bash
python3 -m venv /home/alex/ElixirProjects/open-source/.venv-ledger
/home/alex/ElixirProjects/open-source/.venv-ledger/bin/pip install playwright pillow numpy beautifulsoup4 markdown
(cd showcase && mix deps.get && mix tailwind.install)       # binário em showcase/_build/tailwind-linux-x64-4.1.7
export MIX_DEPS_PATH=/home/alex/ElixirProjects/open-source/ledger_ui/deps           # raiz (showcase: .../ledger_ui/showcase/deps)
export LEDGER_REF=/home/alex/ElixirProjects/open-source/ledger_ui_ref               # padrão: ../ledger_ui_ref ou ../../ledger_ui_ref
python=/home/alex/ElixirProjects/open-source/.venv-ledger/bin/python
$python scripts/tw/tw_theme.py                # regera assets/css/ledger_ui.css (NUNCA edite à mão)
$python parity/run.py [filtro ...]            # paridade de pixels; saída em /tmp/parity (PARITY_DIR)
$python parity/run.py --theme [filtro ...]    # verificação do tema próprio (fuchsia + slate)
```

Escolha do Tailwind: binário standalone pelo pacote hex `tailwind` (dep do showcase), sem Node. `TAILWIND_BIN` sobrescreve.
`scripts/tw/` guarda `tw_theme.py`, `render.py`, `ref.py` e `tokens.json` (cópia de `referencia/tokens.json`); a referência
(`LEDGER_REF`) é só leitura, nunca publicada nem lida em runtime: `ref.py` monta uma cópia dos geradores `gen/c*.py` em
`/tmp/parity/_refws` (eles esperam `out/design-system/…`) sem editar a referência.

## Receita por componente

1. **Leia as regras** em `ledger_ui_ref/gen/bundle.css` (`lu-*`). Regras duplicadas: a última vence; leia TODAS as ocorrências da classe.
2. **Gerador**: `ledger_ui_ref/gen/cN.py` (`comp("Nome", …)`) mostra a marcação de cada variação; `referencia/components/<Nome>/preview.html`.
3. **API**: `ledger_ui_ref/docs/heex.py` e `ex/` (piloto). A API do piloto vence; preserve capacidades existentes da lib que não a contradizem
   (`field=`, máscaras/hooks, `use LedgerUI, only:/except:`, `data-part`, ARIA). Nome de `attr` e `slot` iguais não compilam: reaproveite o
   atributo global (`title`, ver `Card`) ou renomeie o slot (`Input`: `prefix`/`suffix` viraram texto; slots `:leading`/`:trailing`).
4. **Escreva o `.ex`** em `lib/ledger_ui/components/<api>.ex` só com utilitários (mapas `@variants`/`@sizes`, um utilitário por propriedade).
5. **Casos de paridade** com o MESMO id em `parity/cases/<lote>.py` (lado original) e `parity/cases/<lote>.exs` (módulo
   `Parity.Cases.<Lote>` com `cases/0`): cor × variante × tamanho × forma × estados. Regra do original que só existe no CSS companheiro da lib
   entra como 3º elemento do caso (`(largura, html, css_extra)`), com comentário.
6. **Rode** `parity/run.py <filtro>` e `--theme <filtro>`. Meta 0,00% (aceito ≤ 0,1%), mesmo tamanho de caixa em
   light, dark, crepusculo e crep-dark. Divergiu: **corrija o componente, nunca o original**.
7. **Testes**: ajuste `test/ledger_ui/components/<api>_test.exs` para afirmar utilitários, não `lu-*`. `mix test`, `mix format` e
   `mix compile --warnings-as-errors` (raiz e `showcase/`).
8. **Marque como migrado para os testes do showcase**: acrescente os `data-part` do componente em `showcase/test/converted_parts.exs`
   (a `class` e o `style` desses elementos deixam de ser comparados; a paridade de pixels os substitui). Ajuste os exemplos
   `showcase/examples/<id>/NN.heex` para a API nova (animações legadas `mo-*` viram `animate-[…]`). Diferença legítima contra o canvas antigo:
   `showcase/test/parity_exceptions.exs` com o motivo.
9. **Commit**: `Tailwind: lote <grupo> (<componentes>)`.

## Testes do showcase (migração em andamento)

* `showcase/assets/css/app.css` carrega `priv/static/ledger.css` e `ledger_ui.css` na camada `legacy` (abaixo de `utilities`) para os componentes
  ainda não migrados. Um migrado não pode depender deles. Quando o último for migrado, apague os dois `@import … layer(legacy)` e
  `legacy_icons.css` (`scripts/tw/legacy_icons.py` o gera: regras antigas `.x .lu-i` para `svg[data-icon]`).
* `LedgerShowcase.Parity` compara marcação com o canvas antigo. Elementos com `data-part` listado em `test/converted_parts.exs` não
  comparam `class`/`style`. Ícones comparam só nome e tamanho (`sm|md|lg|xl`).
* `TemplatesParityTest` tem a lista `@exceptions` (páginas com `input`/`field` migrados: auth-*, tabela-modal). O lote Templates as reativa.

## Ordem dos lotes

Ações → Formulários → Feedback → Overlays → Navegação → Dados → Métricas/gráficos → Shell/app → Templates.
Lotes em paralelo não podem repetir componente: use a tabela abaixo (uma linha = um dono).

## Arquivos compartilhados (não editar em paralelo)

`lib/ledger_ui/{components.ex,component.ex,helpers.ex,color.ex}`, `lib/ledger_ui.ex`, `mix.exs`, `assets/css/ledger_ui.css`
(gerado), `scripts/tw/*`, `parity/run.py`, `parity/cases.exs`, `parity/app.css`, `showcase/assets/css/app.css`, `showcase/mix.exs`,
`showcase/lib/**`, `showcase/test/support/**`, `components/icon.ex`, `form.ex`.
Precisa de mudança num deles? Peça ao coordenador (ou faça em um commit próprio, rebaseando antes).

Como adicionar sem conflito:
* **Casos de paridade**: um arquivo por lote (`parity/cases/<lote>.py` + `.exs`); `run.py` e `cases.exs` os descobrem sozinhos. Ids de caso
  prefixados pelo componente e sem repetição (o driver falha em ids repetidos).
* **`test/converted_parts.exs` e `test/parity_exceptions.exs`**: só acrescente linhas no fim do seu componente (uma linha por componente).
* **Keyframe novo** ou token novo: vem do bundle/tokens da referência; peça regeneração do CSS (`tw_theme.py`), nunca edite à mão.
* Cor semântica nova: entrada em `LedgerUI.Color` (compartilhado).

## Interações a preservar nos lotes seguintes

Drawer/modal abrir e fechar; toasts; upload abrindo o seletor de arquivos e arrastar-e-soltar; treeview expandir/recolher com
marcação em cascata; flow com nós arrastáveis e "+" em cada card abrindo uma ramificação (Condição → Sim/Não); calendário; OTP; slider;
rating; olho da senha (`password-toggle`). Botão `loading` do showcase é alternado por JS legado (`.loading`): ao migrar os exemplos, use `loading={…}`.

## Notas do piloto

* `Card`: padrão `variant="tray"` (API do piloto). Superfícies antigas (`default`, `bordered`, `solid`, `gradient`…) seguem como variantes;
  `flat` é o painel sem bandeja. `body`/`divider`/`highlight` ficam reservados (sem estilo no design). Título: `title="…"` ou slot `<:title>`.
* `Input`: `class` vai para a caixa, `wrapper_class` para o campo; `prefix`/`suffix` são texto; `Form.field` é o quadro de rótulo/ajuda/erros
  de todo controle de formulário.
* `Badge`/`Button` aceitam `color="current"`/`"light"`/`"lime"` por `LedgerUI.Color` (a lib já os aceitava).
* Sem consenso do design: ícone dentro de `lu-bd` (o original não tem regra; adotado 13px como `lu-badge`).

## Tabela de componentes

Lote = quem migra. "API" é o módulo de função da lib (`PARIDADE.md`); vários componentes da referência podem ser do mesmo módulo
(migre-os juntos). Templates (`showcase/lib/**/templates`) formam o último lote, sem componente de referência.

| Lote | Componente da referência | API (`PARIDADE.md`) | Módulo da lib | Estado |
|---|---|---|---|---|
| 1 Ações | Palette | `palette` | `LedgerUI.Components.Palette` (`lib/ledger_ui/components/palette.ex`) |  |
| 1 Ações | ActionButton | `action_menu` | `LedgerUI.Components.ActionMenu` (`lib/ledger_ui/components/action_menu.ex`) |  |
| 1 Ações | Button | `button` | `LedgerUI.Components.Button` (`lib/ledger_ui/components/button.ex`) | piloto ✓ |
| 1 Ações | IconButton | `button` | `LedgerUI.Components.Button` (`lib/ledger_ui/components/button.ex`) | piloto ✓ |
| 1 Ações | Clipboard | `clipboard` | `LedgerUI.Components.Clipboard` (`lib/ledger_ui/components/clipboard.ex`) |  |
| 1 Ações | Divider | `divider` | `LedgerUI.Components.Divider` (`lib/ledger_ui/components/divider.ex`) |  |
| 1 Ações | Fab | `fab` | `LedgerUI.Components.Fab` (`lib/ledger_ui/components/fab.ex`) |  |
| 1 Ações | FabDial | `fab` | `LedgerUI.Components.Fab` (`lib/ledger_ui/components/fab.ex`) |  |
| 1 Ações | Icon | `icon` | `LedgerUI.Components.Icon` (`lib/ledger_ui/components/icon.ex`) | piloto ✓ |
| 1 Ações | Illustration | `illustration` | `LedgerUI.Components.Illustration` (`lib/ledger_ui/components/illustration.ex`) |  |
| 1 Ações | Kbd | `typography` | `LedgerUI.Components.Typography` (`lib/ledger_ui/components/typography.ex`) |  |
| 1 Ações | Typography | `typography` | `LedgerUI.Components.Typography` (`lib/ledger_ui/components/typography.ex`) |  |
| 2 Formulários | Autocomplete | `autocomplete` | `LedgerUI.Components.Autocomplete` (`lib/ledger_ui/components/autocomplete.ex`) |  |
| 2 Formulários | Calendar | `calendar` | `LedgerUI.Components.Calendar` (`lib/ledger_ui/components/calendar.ex`) |  |
| 2 Formulários | Checkbox | `checkbox` | `LedgerUI.Components.Checkbox` (`lib/ledger_ui/components/checkbox.ex`) |  |
| 2 Formulários | Chip | `chip` | `LedgerUI.Components.Chip` (`lib/ledger_ui/components/chip.ex`) |  |
| 2 Formulários | ColorPicker | `color_picker` | `LedgerUI.Components.ColorPicker` (`lib/ledger_ui/components/color_picker.ex`) |  |
| 2 Formulários | DatePicker | `date_picker` | `LedgerUI.Components.DatePicker` (`lib/ledger_ui/components/date_picker.ex`) |  |
| 2 Formulários | DateTimePicker | `datetime_picker` | `LedgerUI.Components.DatetimePicker` (`lib/ledger_ui/components/datetime_picker.ex`) |  |
| 2 Formulários | FilterMenu | `filter_menu` | `LedgerUI.Components.FilterMenu` (`lib/ledger_ui/components/filter_menu.ex`) |  |
| 2 Formulários | Field | `form` | `LedgerUI.Components.Form` (`lib/ledger_ui/components/form.ex`) | piloto ✓ |
| 2 Formulários | FormSection | `form_section` | `LedgerUI.Components.FormSection` (`lib/ledger_ui/components/form_section.ex`) |  |
| 2 Formulários | ImageInput | `image_input` | `LedgerUI.Components.ImageInput` (`lib/ledger_ui/components/image_input.ex`) |  |
| 2 Formulários | Input | `input` | `LedgerUI.Components.Input` (`lib/ledger_ui/components/input.ex`) | piloto ✓ |
| 2 Formulários | InputGroup | `input_group` | `LedgerUI.Components.InputGroup` (`lib/ledger_ui/components/input_group.ex`) |  |
| 2 Formulários | NumberStepper | `number_input` | `LedgerUI.Components.NumberInput` (`lib/ledger_ui/components/number_input.ex`) |  |
| 2 Formulários | OtpInput | `otp_input` | `LedgerUI.Components.OtpInput` (`lib/ledger_ui/components/otp_input.ex`) |  |
| 2 Formulários | PasswordInput | `password_input` | `LedgerUI.Components.PasswordInput` (`lib/ledger_ui/components/password_input.ex`) |  |
| 2 Formulários | PhoneInput | `phone_input` | `LedgerUI.Components.PhoneInput` (`lib/ledger_ui/components/phone_input.ex`) |  |
| 2 Formulários | PillSelect | `pill_select` | `LedgerUI.Components.PillSelect` (`lib/ledger_ui/components/pill_select.ex`) |  |
| 2 Formulários | Pillbox | `pillbox` | `LedgerUI.Components.Pillbox` (`lib/ledger_ui/components/pillbox.ex`) |  |
| 2 Formulários | RadioChoice | `radio` | `LedgerUI.Components.Radio` (`lib/ledger_ui/components/radio.ex`) |  |
| 2 Formulários | RangeSlider | `range` | `LedgerUI.Components.Range` (`lib/ledger_ui/components/range.ex`) |  |
| 2 Formulários | Rating | `rating` | `LedgerUI.Components.Rating` (`lib/ledger_ui/components/rating.ex`) |  |
| 2 Formulários | Segmented | `segmented` | `LedgerUI.Components.Segmented` (`lib/ledger_ui/components/segmented.ex`) |  |
| 2 Formulários | Select | `select` | `LedgerUI.Components.Select` (`lib/ledger_ui/components/select.ex`) |  |
| 2 Formulários | SignaturePad | `signature_pad` | `LedgerUI.Components.SignaturePad` (`lib/ledger_ui/components/signature_pad.ex`) |  |
| 2 Formulários | Switch | `switch` | `LedgerUI.Components.Switch` (`lib/ledger_ui/components/switch.ex`) |  |
| 2 Formulários | TagsInput | `tags_input` | `LedgerUI.Components.TagsInput` (`lib/ledger_ui/components/tags_input.ex`) |  |
| 2 Formulários | CommentEditor | `text_editor` | `LedgerUI.Components.TextEditor` (`lib/ledger_ui/components/text_editor.ex`) |  |
| 2 Formulários | RichTextEditor | `text_editor` | `LedgerUI.Components.TextEditor` (`lib/ledger_ui/components/text_editor.ex`) |  |
| 2 Formulários | Textarea | `textarea` | `LedgerUI.Components.Textarea` (`lib/ledger_ui/components/textarea.ex`) |  |
| 2 Formulários | TimePicker | `time_picker` | `LedgerUI.Components.TimePicker` (`lib/ledger_ui/components/time_picker.ex`) |  |
| 2 Formulários | Upload | `upload` | `LedgerUI.Components.Upload` (`lib/ledger_ui/components/upload.ex`) |  |
| 3 Feedback | Alert | `alert` | `LedgerUI.Components.Alert` (`lib/ledger_ui/components/alert.ex`) |  |
| 3 Feedback | Aura | `aura` | `LedgerUI.Components.Aura` (`lib/ledger_ui/components/aura.ex`) |  |
| 3 Feedback | ConnectionBanner | `connection_banner` | `LedgerUI.Components.ConnectionBanner` (`lib/ledger_ui/components/connection_banner.ex`) |  |
| 3 Feedback | EmptyStateCard | `empty_state` | `LedgerUI.Components.EmptyState` (`lib/ledger_ui/components/empty_state.ex`) |  |
| 3 Feedback | InlineEmpty | `empty_state` | `LedgerUI.Components.EmptyState` (`lib/ledger_ui/components/empty_state.ex`) |  |
| 3 Feedback | ErrorPage | `error_page` | `LedgerUI.Components.ErrorPage` (`lib/ledger_ui/components/error_page.ex`) |  |
| 3 Feedback | ProgressBar | `progress` | `LedgerUI.Components.Progress` (`lib/ledger_ui/components/progress.ex`) |  |
| 3 Feedback | Skeleton | `skeleton` | `LedgerUI.Components.Skeleton` (`lib/ledger_ui/components/skeleton.ex`) |  |
| 3 Feedback | Spinner | `spinner` | `LedgerUI.Components.Spinner` (`lib/ledger_ui/components/spinner.ex`) |  |
| 3 Feedback | StatusToast | `toast` | `LedgerUI.Components.Toast` (`lib/ledger_ui/components/toast.ex`) |  |
| 3 Feedback | ToastCard | `toast` | `LedgerUI.Components.Toast` (`lib/ledger_ui/components/toast.ex`) |  |
| 3 Feedback | Toaster | `toast` | `LedgerUI.Components.Toast` (`lib/ledger_ui/components/toast.ex`) |  |
| 4 Overlays | Accordion | `accordion` | `LedgerUI.Components.Accordion` (`lib/ledger_ui/components/accordion.ex`) |  |
| 4 Overlays | Collapse | `collapse` | `LedgerUI.Components.Collapse` (`lib/ledger_ui/components/collapse.ex`) |  |
| 4 Overlays | CommandPaletteDialog | `command_palette` | `LedgerUI.Components.CommandPalette` (`lib/ledger_ui/components/command_palette.ex`) |  |
| 4 Overlays | Drawer | `drawer` | `LedgerUI.Components.Drawer` (`lib/ledger_ui/components/drawer.ex`) |  |
| 4 Overlays | Sheet | `drawer` | `LedgerUI.Components.Drawer` (`lib/ledger_ui/components/drawer.ex`) |  |
| 4 Overlays | Modal | `modal` | `LedgerUI.Components.Modal` (`lib/ledger_ui/components/modal.ex`) |  |
| 4 Overlays | NotificationCenter | `notification_center` | `LedgerUI.Components.NotificationCenter` (`lib/ledger_ui/components/notification_center.ex`) |  |
| 4 Overlays | Popover | `popover` | `LedgerUI.Components.Popover` (`lib/ledger_ui/components/popover.ex`) |  |
| 4 Overlays | Tooltip | `tooltip` | `LedgerUI.Components.Tooltip` (`lib/ledger_ui/components/tooltip.ex`) |  |
| 5 Navegação | ActionMenu | `action_menu` | `LedgerUI.Components.ActionMenu` (`lib/ledger_ui/components/action_menu.ex`) |  |
| 5 Navegação | Breadcrumb | `breadcrumb` | `LedgerUI.Components.Breadcrumb` (`lib/ledger_ui/components/breadcrumb.ex`) |  |
| 5 Navegação | ContextMenu | `context_menu` | `LedgerUI.Components.ContextMenu` (`lib/ledger_ui/components/context_menu.ex`) |  |
| 5 Navegação | Dropdown | `dropdown` | `LedgerUI.Components.Dropdown` (`lib/ledger_ui/components/dropdown.ex`) |  |
| 5 Navegação | Menu | `menu_list` | `LedgerUI.Components.MenuList` (`lib/ledger_ui/components/menu_list.ex`) |  |
| 5 Navegação | MenuList | `menu_list` | `LedgerUI.Components.MenuList` (`lib/ledger_ui/components/menu_list.ex`) |  |
| 5 Navegação | Pagination | `pagination` | `LedgerUI.Components.Pagination` (`lib/ledger_ui/components/pagination.ex`) |  |
| 5 Navegação | Scrollspy | `scrollspy` | `LedgerUI.Components.Scrollspy` (`lib/ledger_ui/components/scrollspy.ex`) |  |
| 5 Navegação | Stepper | `steps` | `LedgerUI.Components.Steps` (`lib/ledger_ui/components/steps.ex`) |  |
| 5 Navegação | Tabs | `tabs` | `LedgerUI.Components.Tabs` (`lib/ledger_ui/components/tabs.ex`) |  |
| 5 Navegação | ViewSwitcher | `view_switcher` | `LedgerUI.Components.ViewSwitcher` (`lib/ledger_ui/components/view_switcher.ex`) |  |
| 6 Dados | Avatar | `avatar` | `LedgerUI.Components.Avatar` (`lib/ledger_ui/components/avatar.ex`) |  |
| 6 Dados | AvatarGroup | `avatar` | `LedgerUI.Components.Avatar` (`lib/ledger_ui/components/avatar.ex`) |  |
| 6 Dados | AvatarVariants | `avatar` | `LedgerUI.Components.Avatar` (`lib/ledger_ui/components/avatar.ex`) |  |
| 6 Dados | Badge | `badge` | `LedgerUI.Components.Badge` (`lib/ledger_ui/components/badge.ex`) | piloto ✓ |
| 6 Dados | BulkBar | `bulk_bar` | `LedgerUI.Components.BulkBar` (`lib/ledger_ui/components/bulk_bar.ex`) |  |
| 6 Dados | SelectionBar | `bulk_bar` | `LedgerUI.Components.BulkBar` (`lib/ledger_ui/components/bulk_bar.ex`) |  |
| 6 Dados | DueCalendar | `calendar` | `LedgerUI.Components.Calendar` (`lib/ledger_ui/components/calendar.ex`) |  |
| 6 Dados | Card | `card` | `LedgerUI.Components.Card` (`lib/ledger_ui/components/card.ex`) | piloto ✓ |
| 6 Dados | CardTable | `card_table` | `LedgerUI.Components.CardTable` (`lib/ledger_ui/components/card_table.ex`) |  |
| 6 Dados | Carousel | `carousel` | `LedgerUI.Components.Carousel` (`lib/ledger_ui/components/carousel.ex`) |  |
| 6 Dados | CashTimer | `cash_timer` | `LedgerUI.Components.CashTimer` (`lib/ledger_ui/components/cash_timer.ex`) |  |
| 6 Dados | Cover | `cover` | `LedgerUI.Components.Cover` (`lib/ledger_ui/components/cover.ex`) |  |
| 6 Dados | CoverCard | `cover` | `LedgerUI.Components.Cover` (`lib/ledger_ui/components/cover.ex`) |  |
| 6 Dados | DataTable | `data_table` | `LedgerUI.Components.DataTable` (`lib/ledger_ui/components/data_table.ex`) |  |
| 6 Dados | TableToolbar | `data_table` | `LedgerUI.Components.DataTable` (`lib/ledger_ui/components/data_table.ex`) |  |
| 6 Dados | DescriptionList | `description_list` | `LedgerUI.Components.DescriptionList` (`lib/ledger_ui/components/description_list.ex`) |  |
| 6 Dados | Flow | `flow` | `LedgerUI.Components.Flow` (`lib/ledger_ui/components/flow.ex`) |  |
| 6 Dados | HeroCard | `hero_card` | `LedgerUI.Components.HeroCard` (`lib/ledger_ui/components/hero_card.ex`) |  |
| 6 Dados | Kanban | `kanban` | `LedgerUI.Components.Kanban` (`lib/ledger_ui/components/kanban.ex`) |  |
| 6 Dados | Mask | `mask` | `LedgerUI.Components.Mask` (`lib/ledger_ui/components/mask.ex`) |  |
| 6 Dados | MiniCard | `mini_card` | `LedgerUI.Components.MiniCard` (`lib/ledger_ui/components/mini_card.ex`) |  |
| 6 Dados | PixelCard | `pixel_card` | `LedgerUI.Components.PixelCard` (`lib/ledger_ui/components/pixel_card.ex`) |  |
| 6 Dados | StepGroup | `step_group` | `LedgerUI.Components.StepGroup` (`lib/ledger_ui/components/step_group.ex`) |  |
| 6 Dados | Table | `table` | `LedgerUI.Components.Table` (`lib/ledger_ui/components/table.ex`) |  |
| 6 Dados | Tag | `tag` | `LedgerUI.Components.Tag` (`lib/ledger_ui/components/tag.ex`) |  |
| 6 Dados | Timeline | `timeline` | `LedgerUI.Components.Timeline` (`lib/ledger_ui/components/timeline.ex`) |  |
| 6 Dados | Timer | `timer` | `LedgerUI.Components.Timer` (`lib/ledger_ui/components/timer.ex`) |  |
| 6 Dados | Treeview | `treeview` | `LedgerUI.Components.Treeview` (`lib/ledger_ui/components/treeview.ex`) |  |
| 7 Métricas/gráficos | BarChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | CohortHeatmap | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | DonutChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | LineChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | WaterfallChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | KpiCard | `kpi_card` | `LedgerUI.Components.KpiCard` (`lib/ledger_ui/components/kpi_card.ex`) |  |
| 7 Métricas/gráficos | Sparkline | `sparkline` | `LedgerUI.Components.Sparkline` (`lib/ledger_ui/components/sparkline.ex`) |  |
| 7 Métricas/gráficos | Stat | `stat` | `LedgerUI.Components.Stat` (`lib/ledger_ui/components/stat.ex`) | piloto ✓ |
| 8 Shell/app | AiChat | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiComposer | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiInsights | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiMessage | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiPromo | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiProposal | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiToolTrace | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | ConversationList | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | PromptSuggestions | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | IconRail | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | PageHeader | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | ShellFloating | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | SubNav | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | AuthSplit | `auth_split` | `LedgerUI.Components.AuthSplit` (`lib/ledger_ui/components/auth_split.ex`) |  |
| 8 Shell/app | CodeBlock | `code_block` | `LedgerUI.Components.CodeBlock` (`lib/ledger_ui/components/code_block.ex`) |  |
| 8 Shell/app | Container | `container` | `LedgerUI.Components.Container` (`lib/ledger_ui/components/container.ex`) |  |
| 8 Shell/app | EmailLayout | `email` | `LedgerUI.Components.Email` (`lib/ledger_ui/components/email.ex`) |  |
| 8 Shell/app | GlowText | `glow_text` | `LedgerUI.Components.GlowText` (`lib/ledger_ui/components/glow_text.ex`) |  |
| 8 Shell/app | LandingNav | `landing_nav` | `LedgerUI.Components.LandingNav` (`lib/ledger_ui/components/landing_nav.ex`) |  |
| 8 Shell/app | Logo | `logo` | `LedgerUI.Components.Logo` (`lib/ledger_ui/components/logo.ex`) |  |
| 8 Shell/app | Navbar | `navbar` | `LedgerUI.Components.Navbar` (`lib/ledger_ui/components/navbar.ex`) |  |
| 8 Shell/app | ScrollArea | `scroll_area` | `LedgerUI.Components.ScrollArea` (`lib/ledger_ui/components/scroll_area.ex`) |  |
| 8 Shell/app | Shell | `shell` | `LedgerUI.Components.Shell` (`lib/ledger_ui/components/shell.ex`) |  |
| 8 Shell/app | Sidebar | `sidebar` | `LedgerUI.Components.Sidebar` (`lib/ledger_ui/components/sidebar.ex`) |  |
| 8 Shell/app | Sticky | `sticky` | `LedgerUI.Components.Sticky` (`lib/ledger_ui/components/sticky.ex`) |  |
| 8 Shell/app | ThemePicker | `theme_picker` | `LedgerUI.Components.ThemePicker` (`lib/ledger_ui/components/theme_picker.ex`) |  |
| 8 Shell/app | ThemeSwitch | `theme_switch` | `LedgerUI.Components.ThemeSwitch` (`lib/ledger_ui/components/theme_switch.ex`) |  |
| 8 Shell/app | Tool | `tool` | `LedgerUI.Components.Tool` (`lib/ledger_ui/components/tool.ex`) |  |
| 8 Shell/app | Trace | `trace` | `LedgerUI.Components.Trace` (`lib/ledger_ui/components/trace.ex`) |  |
