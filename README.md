# Ledger UI

Componentes Phoenix LiveView com o design Ledger UI: HEEx estilizado **só com utilitários do Tailwind CSS v4**.
Nenhuma classe CSS do pacote, nenhum CSS de componente: o pacote traz apenas o tema (tokens, `@theme`, base e `@keyframes`).
Sem `lu-*`; o visual vem das utilitárias que o Tailwind do **seu** app gera a partir de `lib/` do pacote.

## Instalação

```elixir
# mix.exs
def deps do
  [{:ledger_ui, "~> 0.11.0"}]
end
```

CSS: o Tailwind v4 do app precisa rodar (no Phoenix 1.8 já roda, via `tailwind` do `mix.exs`). Importe o tema **depois** do Tailwind:

```css
/* assets/css/app.css */
@import "tailwindcss";
@import "../../deps/ledger_ui/assets/css/ledger_ui.css";   /* já traz o @source da lib do pacote */
```

O `@source "../../lib"` está dentro do `ledger_ui.css`: o Tailwind lê os componentes do pacote e gera só as utilitárias usadas.
Nada mais é carregado (não há `ledger.css` nem outra folha). O corpo recebe `font-size: 14px` (no `body`, nunca no `html`,
para os `rem` do Tailwind continuarem em 16px).

JavaScript (hooks dos componentes com comportamento no cliente):

```js
// assets/js/app.js  (esbuild: adicione a pasta deps ao NODE_PATH)
import {Hooks as LedgerHooks, DOM as LedgerDOM} from "ledger_ui"

new LiveSocket("/live", Socket, {
  hooks: {...LedgerHooks},
  dom: {onBeforeElUpdated(from, to) { LedgerDOM.onBeforeElUpdated(from, to) }},
  params: {_csrf_token: csrfToken}
})
```

As chaves de `Hooks` são `"LedgerUI.<Nome>"`. O módulo ES é `priv/static/ledger_ui.esm.js` (o `package.json` aponta para ele).
Sem bundler, sirva `priv/static` (`Plug.Static at: "/ledger_ui", from: {:ledger_ui, "priv/static"}`) e use
`<script type="module">` com `import {Hooks, DOM} from "/ledger_ui/ledger_ui.esm.js"`.
`ledger.js` é só a biblioteca de gráficos/runtime (`window.LedgerUI`); os ícones são renderizados no servidor.

`LedgerUI.open/2`, `close/2` e `toggle/2` abrem/fecham elementos (classe `open`) via `Phoenix.LiveView.JS`;
no servidor use `LedgerUI.open(socket, id)`.

## Performance

**Compressão do websocket.** O Phoenix vem com ela desligada. Os diffs do LiveView são texto repetitivo e comprimem de 30 a 70 vezes
(medido: uma tabela de 500 linhas, 4,26 MB sem compressão, vira 61 KB com gzip). Ligue no endpoint do app:

```elixir
# lib/my_app_web/endpoint.ex
socket "/live", Phoenix.LiveView.Socket,
  websocket: [compress: true, connect_info: [session: @session_options]]
```

**Tabelas.**

- `<.table rows={@users} row_id={&"user-#{&1.id}"}>`: passe um `row_id` único e o LiveView atualiza só a linha que mudou (sem `row_id`, ou com id repetido, a lista é acompanhada por posição, e inserir no topo reenvia as linhas seguintes).
- Tabela manual (`table_row` dentro de um `:for` do app): use `:key`. Sem ele, inserir uma linha no topo reenviou 63% do payload numa tabela de 500 linhas.

  ```heex
  <.table_row :for={user <- @users} :key={user.id}>
    <:cell>{user.name}</:cell>
  </.table_row>
  ```
- Listas longas ou que crescem: use streams (o servidor não guarda os itens), com `limit:` para não acumular linhas no DOM (`stream(socket, :users, users, limit: -100)`).

**Classes e ícones.** O kit evita reenviar nos diffs as classes e os ícones que não mudaram (#85); por exemplo, trocar o texto de um botão com ícone passou de 2 180 B para 45 B (sem compressão).

## Uso

```elixir
# em MyAppWeb.html_helpers/0 (ou onde importa componentes)
use LedgerUI
```

```heex
<.button color="primary" icon="huge-sparkles">Novo</.button>
```

### Junto com o CoreComponents do Phoenix (`only` / `except`)

O `use LedgerUI` importa todos os componentes. Os nomes que o `CoreComponents` gerado pelo Phoenix 1.8 também define
(`button`, `input`, `table`, `header`, `icon`, `modal`, `label`, `error`...) ficam ambíguos onde são chamados: o
compilador recusa `<.button>` se dois módulos importados têm `button/1`. Escolha de quem é cada nome com `except:`
(todos menos estes) ou `only:` (só estes); o nome vale para qualquer aridade, `nome: 1` para uma só:

```elixir
# em MyAppWeb.html_helpers/0
import MyAppWeb.CoreComponents
use LedgerUI, except: [:button, :input, :table, :header, :icon, :modal, :label, :error]

# ou só o que interessa
use LedgerUI, only: [:card, :badge, :progress_bar, :sidebar, :tabs]
```

O que ficou de fora continua à mão pelo módulo (`<LedgerUI.Components.Button.button>`), ou por um `import` seu com
prefixo. Um nome que não é componente do Ledger UI derruba a compilação.

## Temas e paletas

Duas chaves independentes no `<html>`: o **modo** e a **paleta**.

```html
<html data-theme="light"> <!-- ou "dark" -->
<html data-theme="dark" data-palette="crepusculo">
```

* `data-theme="light|dark"` troca o modo (todo componente tem `dark:`); `<.theme_switch>` alterna e guarda a escolha.
* `data-palette="crepusculo"` é a paleta pronta (índigo, Inter Tight nos títulos, céu rosado); sem o atributo vale o Ledger.
  `<.theme_picker>` escolhe a paleta. Qualquer modo combina com qualquer paleta.
* `<.theme_script />` no `<head>` do layout raiz aplica o modo e a paleta guardados antes da primeira pintura (sem flash).
* O tema declara `color-scheme` (`light` em `:root` e `[data-theme="light"]`, `dark` em `[data-theme="dark"]`): barras de rolagem,
  `<select>` nativo, `<input type="date">` e autofill acompanham o modo sem CSS do app. Um `[data-theme="light"]` dentro de um
  `dark` volta a `light`. As paletas não mexem nisso: valem em qualquer modo.

### Usar o Ledger só numa parte do site

Por padrão a camada `base` pinta o `body` (fundo, cor, fonte 14px/20px, suavização e `font-feature-settings`). Se o app só usa o kit
numa parte (por exemplo, app logado com a landing pública fora do Ledger), desligue a regra no `body`; o escopo `[data-ui="ledger"]`
recebe a mesma regra:

```heex
<body data-lu-base="off">
  <div data-ui="ledger">...</div>   <%!-- tipo, cor e fundo do Ledger só aqui --%>
</body>
```

Sem `data-lu-base` nada muda. Os seletores usam `:where()`, então a especificidade é zero e qualquer regra do app sobrescreve.

### Tema próprio

Como no Flux, o kit lê só duas entradas: o **accent** (3 variáveis) e a **escala de cinza** (`--color-gray-50…950`). Todo o resto
(tons 50–900 do accent, fundo suave, foco, fundos, bordas e textos) deriva delas em oklch; o padrão reproduz o Ledger.
Cole isto no `app.css`, depois dos dois `@import`s, e **todo** componente muda de accent e de cinza (a vitrine tem um gerador em `/temas`):

```css
@theme {                                   /* cinza: troque a escala inteira */
  --color-gray-50: var(--color-slate-50);
  --color-gray-100: var(--color-slate-100);
  --color-gray-200: var(--color-slate-200);
  --color-gray-300: var(--color-slate-300);
  --color-gray-400: var(--color-slate-400);
  --color-gray-500: var(--color-slate-500);
  --color-gray-600: var(--color-slate-600);
  --color-gray-700: var(--color-slate-700);
  --color-gray-800: var(--color-slate-800);
  --color-gray-900: var(--color-slate-900);
  --color-gray-950: var(--color-slate-950);
}
@theme {                                   /* accent */
  --color-accent: var(--color-fuchsia-600);
  --color-accent-content: var(--color-fuchsia-600);   /* texto colorido sobre o fundo */
  --color-accent-foreground: var(--color-white);      /* texto sobre o accent cheio */
}
@layer theme {
  [data-theme=dark] {                      /* o accent no escuro */
    --color-accent: var(--color-fuchsia-500);
    --color-accent-content: var(--color-fuchsia-400);
    --color-accent-foreground: var(--color-white);
  }
}
```

Utilitários do kit para o seu próprio HEEx: `bg-accent`, `text-accent-content`, `text-accent-foreground`, `bg-accent-50…900`,
`bg-accent-soft`, `bg-page|shell|tray|panel|sunken|hover|selected`, `border-line`, `text-ink|ink-2|muted|subtle`, `bg-inverse text-on-inverse`,
`bg-pos|neg|warn|info|lime|violet` (+ `-soft`), `shadow-xs…lg|btn`, `rounded-xs…2xl`, `font-sans|display|mono`.
A vitrine (página **Temas**) tem o gerador de tema com o CSS pronto para colar.

### Cores semânticas (`color=`)

`neutral`, `primary` (o accent), `secondary`, `info`, `success`, `warning`, `error`, `dark`, `white`, `lime`, `light`, `mono`, `current`.
`LedgerUI.Color.vars/1` devolve as quatro variáveis locais (`--c`, `--c-on`, `--c-soft`, `--c-ink`) que as variantes leem.

## Idioma / Locale

Todo texto padrão dos componentes (rótulos, `aria-label`, `title`, placeholders, textos só para leitores de tela, estados vazios, paginação, nomes de meses e dias da semana, toasts, upload, paleta de comandos, IA...) existe em inglês (`"en"`) e português do Brasil (`"pt_BR"`, também aceito como `"pt"`, `"pt-BR"` e `:pt_BR`). As traduções ficam em um só lugar, `LedgerUI.I18n`. O locale vale na seguinte ordem, do mais forte ao mais fraco:

1. o attr `locale` do componente: `<.pagination locale="pt_BR" ... />`;
2. o locale do processo: `LedgerUI.put_locale("pt_BR")`;
3. a config da aplicação: `config :ledger_ui, locale: "pt_BR"`;
4. `"en"` (o padrão: sem nada configurado nada muda).

Um texto passado pelo chamador (`label="Fechar"`, `close_label="Fechar"`...) vence qualquer tradução.

```elixir
# config/config.exs: o idioma de toda a aplicação
config :ledger_ui, locale: "pt_BR"

# um plug do pipeline do router: o idioma desta requisição (sessão, cookie, usuário...)
def set_locale(conn, _opts) do
  LedgerUI.put_locale(get_session(conn, :locale))
  conn
end

# uma LiveView: o idioma do processo dela, na renderização estática e na conectada
on_mount {LedgerUI.I18n, :default}              # lê "locale" da sessão (se houver)
on_mount {LedgerUI.I18n, {:locale, "pt_BR"}}    # ou um fixo
```

```heex
<.pagination page={3} total_pages={10} locale="pt_BR" />
```

O `on_mount` é necessário porque a LiveView conectada é outro processo, e o locale do processo da primeira renderização não passa para ele. Trocar o locale com a página aberta funciona pelo attr `locale` (que muda com um assign); mudar só o locale do processo vale a partir da próxima renderização completa do componente.

Os hooks de JS não têm texto próprio: os componentes mandam os textos traduzidos em atributos `data-lu-*` (o inglês só é o último recurso do hook, quando o atributo não vem). Para ficar idêntico ao de antes, o atributo só é escrito quando o texto difere do inglês.

**Componentes com texto padrão em português.** Estes já eram em português antes do i18n e continuam assim enquanto nenhum locale for configurado (attr, processo ou app); com `locale="en"` (ou `config :ledger_ui, locale: "en"`) passam para o inglês: `notification_center`, `rating` e `rating_distribution`, `tag` (`remove_label`), `tabs` (`soon_label`), `card_table` (`retry_label`), `cash_timer`, `table_toolbar` (`filters_label`, `clear_label`, `remove_label`), `textarea` (contador de mínimo), `number_input` (rótulos e separadores), `phone_input` (nomes dos países), `chart` (`line_chart`, `donut_chart` e `waterfall_chart`: o `label` padrão) e todo o `ai.ex` (`ai_chat`, `ai_composer`, `ai_proposal`, `ai_message`, `conversation_list`...).

**Erros dos campos (tradutor).** Os erros do changeset (`{msg, opts}`) que chegam por `field={@form[:x]}` saem como o Ecto os escreve, com `%{count}` e afins já trocados (`"can't be blank"`). Para traduzi-los (Gettext, por exemplo), configure um tradutor `{Módulo, :função}` que recebe o `{msg, opts}` e devolve o texto, igual ao `translate_error/1` do `core_components.ex` do Phoenix:

```elixir
config :ledger_ui, :error_translator, {MyAppWeb.CoreComponents, :translate_error}
```

```heex
<.input field={@form[:name]} label="Nome" />  <%!-- "não pode ficar em branco" --%>
```

Vale para todo componente que lê um `field` (`input`, `textarea`, `number_input`, `select`, `autocomplete`, `date_picker` com `field`, `start_field` e `end_field`, `date_time_picker`, `checkbox`, `switch`, `radio_group`, `pillbox`, `segmented`, `otp_input`, `phone_input`, `password_input`, `text_editor`...). Sem a config nada muda. As strings passadas à mão em `errors={[...]}` não passam pelo tradutor (já são o texto final); só os erros que vêm do `field`.

## Ícones

`<.icon>` desenha no servidor os 142 ícones do dicionário embutido (`LedgerUI.Components.Icon.names/0`).
Qualquer outro ícone do [Hugeicons Stroke Rounded](https://hugeicons.com/icons/stroke-rounded) (set gratuito, MIT)
vem para a sua app com `mix ledger_ui.icons`, sem dependência extra:

```elixir
# config/config.exs (numa release: {:minha_app, "priv/hugeicons"})
config :ledger_ui, :icons_path, "priv/hugeicons"
```

```sh
mix ledger_ui.icons get search-01 tick-02   # baixa esses (aceita huge-search-01)
mix ledger_ui.icons sync                    # baixa o que <.icon name="huge-..."> usa em lib/, assets/js e priv/templates
mix ledger_ui.icons sync --prune            # ...e remove os que ninguém usa
mix ledger_ui.icons search invoice          # procura nomes no repositório
mix ledger_ui.icons update                  # sobe para o commit mais novo de main (ou --ref TAG)
```

```heex
<.icon name="huge-invoice-01" size="sm" />
```

Os SVGs são convertidos para o formato do kit (traço `currentColor`, 1.5, pontas redondas, sem cor fixa: o `<svg>` do `<.icon>` define o traço) e gravados em `priv/hugeicons/` junto com `.hugeicons.json` (commit, nomes) e `LICENSE.md`. A pasta é
lida uma vez para o `:persistent_term`; o markup é o mesmo dos embutidos (`<svg data-icon="...">`). Ordem de busca:
nome embutido exato, arquivo vendorizado, nome embutido sem o sufixo `-NN`; nome desconhecido não renderiza e avisa
no log. Ícones baixados depois do boot são achados sem reiniciar. O download usa o commit fixado na task (ou o do manifesto).

## Skill do Claude Code

Gera `.claude/skills/ledger-ui/` na sua app a partir do pacote instalado (atributos, valores, slots e docs de cada
function component), para um agente escrever HEEx certo sem adivinhar:

```sh
mix ledger_ui.install       # escreve a skill, aponta AGENTS.md/CLAUDE.md para ela e imprime as linhas de setup
mix ledger_ui.gen.skill     # só (re)gera a skill; --path muda a pasta
```

```
.claude/skills/ledger-ui/
  SKILL.md                  # nome, versão, regras e a tabela de componentes
  references/<componente>.md
```

Para renovar a cada atualização do pacote, ligue o compilador no `mix.exs` da app:

```elixir
def project do
  [compilers: [:ledger_ui_skill] ++ Mix.compilers(), ...]
end
```

Ele regenera a skill quando a versão do `ledger_ui` instalada difere da registrada no `SKILL.md`; não faz nada se a
skill ainda não existe, se já está na versão e em `:prod`.

## Componentes

Um exemplo por componente, agrupado como na vitrine. Os atributos, valores e slots de cada um estão no `@doc`/`attr` do módulo
(e na skill, abaixo). Cada bloco é compilado por `test/readme_examples_test.exs`; a seção é gerada por
`mix run scripts/gen_readme_components.exs`.

<!-- components:start -->

### Fundamentos

#### Divider

A 1px separator in the `line` colour, horizontal or vertical, with optional centred or left-aligned text.

`<.divider>`

```heex
<.divider label="ou continue com" />
```

### Ações

#### Button

Buttons, styled only with Tailwind utilities: `button/1` (which also covers the icon-only, top bar (`appearance="topbar"`) and round "go" (`appearance="go"`) buttons), `button_group/1` and `insight_button/1`.

`<.button>`

```heex
<.button color="neutral" variant="outline" size="sm">Info</.button>
```

`<.button_group>` — Joins buttons side by side into one segmented control (corners only at the ends).

```heex
<.button_group>
  Texto
</.button_group>
```

`<.insight_button>` — The top bar pill with a count badge (`New AI insights`).

```heex
<.insight_button>
  Texto
</.insight_button>
```

#### Fab

Floating action buttons: `fab/1`, one button (the canvas's solid ink button, or the retracting pill) and `fab_dial/1`, a speed-dial that opens a column of…

`<.fab>`

```heex
<.fab id="new" label="Novo pedido" variant="canvas" offset={18} />
```

`<.fab_dial>`

```heex
<.fab_dial variant="pill" />
```

#### Icon

Server-side SVG icons (Hugeicons Stroke Rounded), no JavaScript needed.

`<.icon>`

```heex
<.icon />
```

### Formulários — texto

#### FormSection

A group of fields under a small title, laid out in a grid.

`<.form_section>` — Renders a form section; the inner block is its fields.

```heex
<.form_section variant="aside" />
```

#### Input

Single-line text field styled only with Tailwind utilities: `outlined`, `filled` or `plain`, `rounded` or `pill`, three sizes, icon, prefix and suffix,…

`<.input>` — Renders a text-like `<input>`, with its caption, help and errors when given.

```heex
<.input label="Razão social" />
```

#### InputGroup

Joins inputs, addons, selects and buttons into one row with shared borders.

`<.input_group>` — Renders the row; `label` adds a caption above it, `help` and `errors` a line below.

```heex
<.input_group variant="filled" />
```

`<.input_group_addon>` — A text or icon box at either end (or between the inputs) of an `input_group`.

```heex
<.input_group_addon>
  Texto
</.input_group_addon>
```

#### OtpInput

A one-time code made of single-character boxes.

`<.otp_input>` — Renders the boxes, with their caption, help and errors when given.

```heex
<.otp_input length={6} />
```

#### PasswordInput

A password field with the eye button that shows what was typed.

`<.password_input>` — Renders the field and the eye.

```heex
<.password_input value={@senha} />
```

#### TextEditor

Rich text editor on a plain `contenteditable` (bold, italic, underline, strike, quote, code, headings, lists, sub/superscript, indent, text direction, size,…

`<.comment_editor>` — Same as `text_editor/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.comment_editor />
```

`<.rich_text_editor>` — Same as `text_editor/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.rich_text_editor field={@form[:body]} toolbar={[:bold, :italic, :list, :link]} />
```

`<.text_editor>` — Renders a rich text editor.

```heex
<.text_editor />
```

`<.text_editor_content>` — Shows saved rich text, read-only, in the editor's type.

```heex
<.text_editor_content />
```

#### Textarea

Multi-line text field: `outlined`, `filled` or `plain`, fixed or resizable, with a live character counter, autogrow, `{{token}}` highlighting and optional…

`<.textarea>` — Renders a `<textarea>` inside its frame, with its caption, help and errors.

```heex
<.textarea value="Curto" />
```

#### Typography

Ledger UI's type scale: headings, running text, text links, inline code and keyboard keys.

`<.heading>` — A heading, `<h1>` to `<h6>`.

```heex
<.heading>
  Texto
</.heading>
```

`<.inline_code>` — Code inside running text: mono 12.5px on the fill colour, in the primary text colour.

```heex
<.inline_code>
  Texto
</.inline_code>
```

`<.kbd>` — A keyboard key.

```heex
<.kbd>↵</.kbd>
```

`<.text>` — A run of text, a paragraph unless `as` says otherwise.

```heex
<.text>
  Texto
</.text>
```

`<.text_link>` — A link inside running text, underlined (1px) in a theme colour and style.

```heex
<.text_link>
  Texto
</.text_link>
```

`<.typography>` — Same as `text/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.typography>
  Texto
</.typography>
```

### Formulários — seleção

#### Checkbox

`checkbox/1` (the box with label and description) and `checkbox_group/1` (one checkbox per option of a list field).

`<.checkbox>`

```heex
<.checkbox color="info" size="md" />
```

`<.checkbox_group>`

```heex
<.checkbox_group />
```

#### Chip

The chip: a small tag for a quick filter, an applied filter or a selected person.

`<.chip>`

```heex
<.chip label="Entrega" />
```

#### FilterMenu

A filter button that opens a menu of filters: one row per group that opens a second panel to its side with the group's options as checkboxes (or radios),…

`<.filter_menu>`

```heex
<.filter_menu placement="bottom-start">
  <:trigger>Filtrar</:trigger>
  Status Pago Aberto Atrasado Aplicar
</.filter_menu>
```

#### Pillbox

Multiple (or single) choice drawn as pills inside the field, with a searchable list under it.

`<.pillbox>`

```heex
<.pillbox />
```

#### Radio

Single choice among visible options: `radio_group/1`, in six forms.

`<.radio>` — A radio, or a group of them: with `options` (or `<:radio>` slots) it is `radio_group/1`; without, one radio with its `label`, `color` and `size`.

```heex
<.radio color="neutral" size="xs" />
```

`<.radio_choice>` — Same as `radio_group/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.radio_choice color="secondary" />
```

`<.radio_group>`

```heex
<.radio_group />
```

#### Segmented

A segmented control: a row of toggle buttons where exactly one is chosen.

`<.segmented>`

```heex
<.segmented size="sm">
  <:option selected>Dia</:option>
  <:option>Mês</:option>
</.segmented>
```

#### Select

Select: the styled native `<select>` (`native`) and a searchable listbox driven by the `LedgerUI.Select` hook (`priv/static/ledger_ui/hooks/select.js`).

`<.listbox>` — A static list of choices (the open panel of a select, without the trigger): the chosen row is bold with a check, a `disabled` option is dimmed and a `hint`…

```heex
<.listbox options={@options} />
```

`<.select>`

```heex
<.select value="mercad" />
```

#### Switch

A switch: a checkbox drawn as a track and thumb, for an effect that is immediate.

`<.switch>`

```heex
<.switch color="error" />
```

### Formulários — datas e valores

#### Calendar

A calendar for dates that matter (due dates, appointments, deadlines): a month grid or a week grid of hours with colored event chips, month/week switching…

`<.calendar>` — Renders the calendar.

```heex
<.calendar month={~D[2026-10-01]} events={@events} />
```

`<.due_calendar>` — The agenda of due items, one row per item: the weekday and day, the title, a status badge (overdue in `neg`, today highlighted) and the amount on the right.

```heex
<.due_calendar />
```

#### ColorPicker

A color picker that outputs hex text: a saturation/brightness area to drag, a hue slider, an optional opacity slider, a hex field and a row of preset swatches.

`<.color_picker>` — Renders the color picker.

```heex
<.color_picker field={@form[:color]} swatches={@palette} />
```

#### DatePicker

Date picker: one date, several dates or a range, with limits, disabled days, a custom text format and presets.

`<.date_picker>` — Renders a date input with its calendar.

```heex
<.date_picker field={@form[:period]} range presets={~w(this_month last_month qtd ytd)} />
```

`<.date_picker_calendar>` — The month: title, arrows, weekday letters and day buttons.

```heex
<.date_picker_calendar />
```

`<.date_picker_panel>` — The calendar surface of the picker: month title with arrows, weekday letters and the days, optionally with a column of `presets` on the left.

```heex
<.date_picker_panel />
```

#### DatetimePicker

A date and a time chosen in one panel: a calendar with a list of times beside it or, for a range, two months side by side with a start and an end time.

`<.date_time_picker>` — Same as `datetime_picker/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.date_time_picker />
```

`<.datetime_picker>` — Renders the date and time input with its panel.

```heex
<.datetime_picker />
```

`<.datetime_picker_panel>` — The static panel: a calendar with the list of times beside it.

```heex
<.datetime_picker_panel />
```

#### ImageInput

An image field: the picture (an avatar, a logo) in a round or rounded frame, with an edit overlay and a small button to remove or revert it.

`<.image_input>` — Renders the image field.

```heex
<.image_input size="sm" />
```

#### NumberInput

A numeric field for money and quantities that shows the number the way the person's locale writes it (`1.234,56` in pt-BR, `1,234.56` in en) and submits the…

`<.number_input>` — Renders the number input.

```heex
<.number_input />
```

`<.number_stepper>` — Same as `number_input/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.number_stepper value="3" />
```

#### PlacementStage

An image (a rendered PDF page, a photo) with a dashed box on it that the user positions by clicking or dragging, and resizes from a corner handle.

`<.placement_stage>`

```heex
<.placement_stage id="pdf-stage" src={@image} alt="Página 1" box={@box} on_place="place" on_resize="resize" />
```

#### Range

Range slider: a rounded track with a round thumb, one value or a range of two.

`<.range>` — Renders a range slider.

```heex
<.range />
```

`<.range_slider>` — Same as `range/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.range_slider value={54} color="info" />
```

#### Rating

A star rating: read-only, with a fractional value and the count of reviews, or interactive, as a group of native radios; and `rating_distribution/1`, the…

`<.rating>` — Renders a rating.

```heex
<.rating value={4} size="lg" />
```

`<.rating_distribution>` — The summary of a rating: the average, its stars, the total and a bar per grade.

```heex
<.rating_distribution counts={@counts} />
```

#### SignaturePad

A signature field: sign with a finger, a pen or the mouse (pointer events), or type a name that is set in a handwriting font.

`<.signature_pad>` — Renders the signature pad.

```heex
<.signature_pad field={@form[:signature]} />
```

#### TimePicker

Time picker: an input with a clock icon that opens a scrollable list of times (`variant="input"`), or a list of fixed slots (`variant="list"`).

`<.time_picker>` — Renders a time input.

```heex
<.time_picker field={@form[:at]} step={30} />
```

`<.time_picker_panel>` — The popup surface: a popover with the list of times (or, `variant="bare"`, the plain list).

```heex
<.time_picker_panel />
```

#### Upload

File uploads built on LiveView uploads: the drop panel with each file's progress, errors and cancel button (shown on finished entries too, so a sent file…

`<.upload>` — Renders the drop panel and the list of chosen files.

```heex
<.upload color="info" variant="soft" />
```

`<.upload_button>` — A button that opens the file chooser: a `<label>` with the button classes holding an invisible file input.

```heex
<.upload_button>
  Texto
</.upload_button>
```

`<.upload_drop>` — The dashed drop area: icon, label with the browse link, and a hint.

```heex
<.upload_drop />
```

`<.upload_file>` — A file card: badge, name, status, progress bar and the remove (or retry) button.

```heex
<.upload_file name="name" />
```

`<.upload_thumbs>` — The grid of 64px thumbnails.

```heex
<.upload_thumbs />
```

`<.upload_zone>` — The compact drop zone with the kit's variants, colors, shapes and sizes.

```heex
<.upload_zone>
  Texto
</.upload_zone>
```

### Exibição

#### Avatar

Avatars: an image or initials in a circle, a square, a squircle or any mask shape, with a status dot, a gradient ring, and stacked in groups.

`<.avatar>`

```heex
<.avatar initials="AN" />
```

`<.avatar_group>`

```heex
<.avatar_group>
  Texto
</.avatar_group>
```

#### Badge

Badges: `color` x `variant` x `size` x `shape`, with a dot, an icon or a remove button.

`<.badge>`

```heex
<.badge color="error" variant="solid">3</.badge>
```

`<.count>` — The little counter box (18px, rounded 5px) for unread items and pending work.

```heex
<.count>
  Texto
</.count>
```

`<.delta>` — A variation with its arrow: `up` or `down`, green or red by meaning.

```heex
<.delta>
  Texto
</.delta>
```

#### Card

The card of the system, styled only with Tailwind utilities: a tray (`bg-tray`, radius 20, 6px border) whose upper-case title hugs a panel (`bg-panel`,…

`<.card>`

```heex
<.card title="xs">
  …
</.card>
```

`<.card_actions>`

```heex
<.card_actions>
  Texto
</.card_actions>
```

`<.card_bleed>` — Content that bleeds to the card's edges (negative margin of the padding `--card-p`, 16px).

```heex
<.card_bleed>
  Texto
</.card_bleed>
```

`<.card_body>`

```heex
<.card_body>
  Texto
</.card_body>
```

`<.card_footer>`

```heex
<.card_footer>
  Texto
</.card_footer>
```

`<.card_header>`

```heex
<.card_header>
  Texto
</.card_header>
```

`<.card_heading>`

```heex
<.card_heading>
  Texto
</.card_heading>
```

`<.card_subheading>`

```heex
<.card_subheading>
  Texto
</.card_subheading>
```

#### Carousel

Carousels without Swiper: slides on a track, and the `LedgerUI.Carousel` hook for arrows, pagination, autoplay, keyboard, swipe and effects.

`<.carousel>`

```heex
<.carousel />
```

`<.carousel_slide>`

```heex
<.carousel_slide>
  Texto
</.carousel_slide>
```

#### Cover

The canvas cover: a wide band in the accent gradient (or a quiet surface) that heads a profile or a page, with a title on it, or a record's avatar…

`<.cover>`

```heex
<.cover />
```

`<.cover_card>` — Same as `cover/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.cover_card title="tone=neutral">
  …
</.cover_card>
```

#### DescriptionList

Label and value pairs in a grid, as the canvas description list: the label small and faint, the value in the ink colour.

`<.description_list>`

```heex
<.description_list variant="inline" />
```

#### HeroCard

The hero card: the welcome or the insight at the top of a page.

`<.hero_card>`

```heex
<.hero_card eyebrow="Configuração" title="Falta pouco para emitir sua primeira NF-e">
  <.step_group current={2} steps={@passos} />
  <:actions>
    <.button color="mono" variant="solid" size="md" shape="rounded">Continuar</.button>
  </:actions>
</.hero_card>
```

`<.hero_summit>` — The landscape of `hero_card/1`: a thin delegate to `LedgerUI.Components.Illustration.summit/1` (`svg.lu-summit` painted with the `--hero-*` tokens).

```heex
<.hero_summit />
```

#### Illustration

Light illustrations for empty states and result screens, drawn with the theme tokens (or inline SVG), so the package needs no static images.

`<.empty_box>`

```heex
<.empty_box />
```

`<.illustration>`

```heex
<.illustration color="info" />
```

`<.scene>`

```heex
<.scene name="voyage" />
```

`<.summit>` — The summit landscape of the design: sky, sun, stars, three ridges and a dotted trail, painted with the `--lu-hero-*` tokens (light, dark and `crepusculo`,…

```heex
<.summit />
```

#### MiniCard

The canvas's mini card: a small card for a shortcut (an icon box over a bold label) or for a short figure (a faint label over a mono value).

`<.mini_card>`

```heex
<.mini_card title="info">
  …
</.mini_card>
```

#### PixelCard

The pixel card: a card to choose from (a model, a module, an integration) that, on hover or keyboard focus, lights up a matrix of pixels in its top right…

`<.pixel_card>`

```heex
<.pixel_card title="title" />
```

#### StepGroup

A framed card for processes in steps (a build, a deploy, issuing an invoice, an import).

`<.step_group>`

```heex
<.step_group steps={@steps} />
```

`<.step_group_line>`

```heex
<.step_group_line n={1}>
  Texto
</.step_group_line>
```

#### Tag

Tags: clickable badges that represent an attribute, a filter or an action.

`<.tag>`

```heex
<.tag color="info" variant="soft">Varejo</.tag>
```

`<.tag_group>`

```heex
<.tag_group>
  Texto
</.tag_group>
```

#### Timeline

Events down a line, each marked by a filled, outlined, icon or avatar point.

`<.timeline>`

```heex
<.timeline items={@events} />
```

`<.timeline_day>`

```heex
<.timeline_day label="label" />
```

`<.timeline_event>`

```heex
<.timeline_event />
```

`<.timeline_item>`

```heex
<.timeline_item />
```

#### Treeview

A tree view: a hierarchical list whose branches expand and collapse.

`<.tree>` — A tree written as data: the same as `treeview/1` with one `tree_item/1` per map.

```heex
<.tree items={@folders} selected={@current} />
```

`<.tree_item>`

```heex
<.tree_item label="Inventário nov" icon="huge-file" />
```

`<.treeview>`

```heex
<.treeview>
  <.tree_item label="Fiscal" icon="huge-folder" count="12" expanded>
    <.tree_item label="NF-e emitidas" icon="huge-file" count="9" />
    <.tree_item label="Canceladas" icon="huge-file" count="3" selected />
  </.tree_item>
  <.tree_item label="Financeiro" icon="huge-folder" count="28">
  </.tree_item>
  <.tree_item label="Estoque" icon="huge-folder" count="41" expanded>
    <.tree_item label="Inventário nov" icon="huge-file" />
  </.tree_item>
</.treeview>
```

### Métricas e gráficos

#### Chart

Charts drawn by the package itself, as SVG (axis labels, grid lines, legend, tooltips, light and dark).

`<.bar_chart>`

```heex
<.bar_chart data={@monthly} highlight="Oct" />
```

`<.bar_list>`

```heex
<.bar_list>
  <:item>Texto</:item>
</.bar_list>
```

`<.chart>` — The generic, options-driven chart: ApexCharts-shaped options drawn as SVG by the `LedgerUI.Chart` hook (supported subset only; everything else is ignored).

```heex
<.chart id="id" options={@options} />
```

`<.cohort_heatmap>`

```heex
<.cohort_heatmap columns={@columns} rows={@rows} />
```

`<.donut_chart>`

```heex
<.donut_chart id="id" />
```

`<.heatmap>`

```heex
<.heatmap label="label" levels={@levels} />
```

`<.line_chart>`

```heex
<.line_chart id="id" />
```

`<.waterfall_chart>`

```heex
<.waterfall_chart />
```

#### KpiCard

Indicator card: a big tabular figure, its unit in `subtle` and a coloured delta in the footer.

`<.kpi_card>`

```heex
<.kpi_card color="neutral">
  …
</.kpi_card>
```

#### Sparkline

The canvas's sparkline: a line with a soft fill under it, drawn on the server from a list of numbers (the highest at the top), so it renders without JavaScript.

`<.sparkline>`

```heex
<.sparkline values={@series} />
```

#### Stat

Short figures side by side: the label over the number, a divider between them, inside a card, a sunken strip or a bare row.

`<.stat_group>`

```heex
<.stat_group card={false}>
  <.stat_item label="Abertas" value="12" />
  <.stat_item label="Vencidas" value="3" delta="1" trend="up" delta_tone="bad" />
  <.stat_item label="Pagas no mês" value="R$ 48,2 mil" delta="9%" trend="up" />
</.stat_group>
```

`<.stat_item>`

```heex
<.stat_item label="Itens" value="14" />
```

### Tabelas

#### BulkBar

The bar of bulk actions for a table with selection: how many are selected, optional fields, buttons for the actions and a close that clears the selection.

`<.bulk_bar>`

```heex
<.bulk_bar count={1} id="id" />
```

#### CardTable

The "card" table: one row per record in a rounded tray (styled with utilities only), with an optional heading, a footer line and sub-lines.

`<.card_table>`

```heex
<.card_table variant="flat" />
```

`<.ctable_sub>` — A second line inside a `card_table` cell (12px, faint) that leaves by its own `priority`; or, with `when_hidden="p2"`, shows only once the columns of…

```heex
<.ctable_sub>
  Texto
</.ctable_sub>
```

#### DataTable

A table with a search box, sortable headers, a pagination footer and row selection, in the two looks of Ledger UI: `advanced` (title bar, the table as a…

`<.data_table>`

```heex
<.data_table id="id" rows={@rows}>
  <:col>Texto</:col>
</.data_table>
```

`<.data_table_pager>` — The pager of the data table footer: the page numbers (`rounded`, `pill`, `circle`, `canvas`) or the buttons of `pages`.

```heex
<.data_table_pager page={1} pages={1} />
```

`<.table_search>` — The search field of the title bar (a sunken box, 32px).

```heex
<.table_search id="id" />
```

`<.table_toolbar>` — The toolbar above a table: search, controls, actions, and the row of applied filters as removable chips.

```heex
<.table_toolbar />
```

#### Table

Ledger UI's tables: basic, bordered, hoverable, zebra, the grid and the lean `data` looks, with `:col` slots the way Phoenix's generated…

`<.table>`

```heex
<.table variant="grid" />
```

`<.table_body>`

```heex
<.table_body>
  Texto
</.table_body>
```

`<.table_cell>`

```heex
<.table_cell />
```

`<.table_checkbox>`

```heex
<.table_checkbox label="label" />
```

`<.table_detail_row>`

```heex
<.table_detail_row row_id="row_id">
  Texto
</.table_detail_row>
```

`<.table_empty>`

```heex
<.table_empty id="id">
  Texto
</.table_empty>
```

`<.table_expand_toggle>`

```heex
<.table_expand_toggle row_id="row_id" />
```

`<.table_foot>`

```heex
<.table_foot />
```

`<.table_head>`

```heex
<.table_head />
```

`<.table_row>`

```heex
<.table_row />
```

`<.table_skeleton>`

```heex
<.table_skeleton id="id" />
```

### Fluxo de trabalho

#### CashTimer

Status card of a cash register shift: an icon in the colour of the state, a title and a line, the time the register has been open (ticking in the browser)…

`<.cash_timer>`

```heex
<.cash_timer id="id" title="title" />
```

#### Flow

Workflow editor: steps on a dotted board joined by connections that carry the condition of each branch, a toolbar at the bottom and the configuration panel…

`<.flow>`

```heex
<.flow id="id">
  <:node>Texto</:node>
</.flow>
```

`<.flow_chip>`

```heex
<.flow_chip>
  Texto
</.flow_chip>
```

`<.flow_chips>`

```heex
<.flow_chips>
  Texto
</.flow_chips>
```

`<.flow_panel_body>`

```heex
<.flow_panel_body>
  Texto
</.flow_panel_body>
```

`<.flow_panel_foot>`

```heex
<.flow_panel_foot>
  Texto
</.flow_panel_foot>
```

`<.flow_panel_head>`

```heex
<.flow_panel_head title="title" />
```

`<.flow_panel_tabs>`

```heex
<.flow_panel_tabs>
  Texto
</.flow_panel_tabs>
```

`<.flow_section>`

```heex
<.flow_section label="label">
  Texto
</.flow_section>
```

#### Kanban

Kanban board: a row of tinted columns holding cards that are dragged between them.

`<.kanban>`

```heex
<.kanban id="id">
  Texto
</.kanban>
```

`<.kanban_card>`

```heex
<.kanban_card id="id">
  Texto
</.kanban_card>
```

`<.kanban_column>`

```heex
<.kanban_column id="id" label="label" />
```

`<.kanban_lost>`

```heex
<.kanban_lost label="label" />
```

#### Timer

A timer that ticks in the browser: a ring with the time in the middle (a shift, a countdown, any stretch of time) and a small pill of it for a top bar.

`<.timer>`

```heex
<.timer color="primary" />
```

### Feedback

#### Alert

Persistent inline notice with colour, variant, shape, accent stripe, actions and a close button.

`<.alert>`

```heex
<.alert color="warning" accent="left" />
```

#### Aura

Ring of light that runs along the border of any element while something works in the background.

`<.aura>`

```heex
<.aura motion="spin" tone="ai">
  …
</.aura>
```

#### ConnectionBanner

The notice of a lost connection, as a toast: while the LiveView socket is down the toaster shows a `loading` toast with the ring of light (`aura`), and…

`<.connection_banner>`

```heex
<.connection_banner description="Conectado" />
```

#### EmptyState

Empty state: what the area is, why it is empty and the one next step.

`<.empty_state>`

```heex
<.empty_state title="title" />
```

`<.empty_state_card>` — Same as `empty_state/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.empty_state_card />
```

`<.inline_empty>` — The one-line empty state inside a panel or a table cell: an icon and a sentence, in a dashed box with no background (13/18px text, 8px gap).

```heex
<.inline_empty icon="inbox" text="Sem comentários" />
```

#### ErrorPage

The canvas's error screens (styled only with Tailwind utilities): the whole page an `ErrorHTML` renders (`error_page/1`), the error inside the app…

`<.error_links>`

```heex
<.error_links>
  <:link>Texto</:link>
</.error_links>
```

`<.error_page>`

```heex
<.error_page code={404} />
```

`<.error_state>`

```heex
<.error_state code={@code} />
```

#### Form

The pieces Ledger UI's forms are made of: a caption (`label/1`), a help line (`help_text/1`), an error line (`error/1`) and the `field/1` wrapper that puts…

`<.error>` — A validation message in the small red text.

```heex
<.error>
  Texto
</.error>
```

`<.field>` — Wraps a control with its caption, help line and errors.

```heex
<.field>
  Texto
</.field>
```

`<.help_text>` — The small line under a control.

```heex
<.help_text>
  Texto
</.help_text>
```

`<.label>` — A caption for the control with the id `for`.

```heex
<.label>
  Texto
</.label>
```

#### Progress

Progress bar (`progress/1`) and the stacked bar of parts of a total (`progress_stack/1`).

`<.progress>`

```heex
<.progress indeterminate />
```

`<.progress_bar>` — Same as `progress/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.progress_bar size="md" />
```

`<.progress_ring>` — Circular progress: a conic arc around a hole with the value in the centre.

```heex
<.progress_ring />
```

`<.progress_stack>`

```heex
<.progress_stack><:segment value={52} color="primary" />…</.progress_stack>
```

#### Skeleton

Loading placeholder that mirrors the final layout.

`<.skeleton>`

```heex
<.skeleton animation="wave" />
```

`<.skeleton_group>`

```heex
<.skeleton_group label="Carregando contas">…</.skeleton_group>
```

#### Spinner

Short loading indicator: five designs, five sizes and the system colours.

`<.spinner>`

```heex
<.spinner variant="border" size="md" color="info" />
```

#### Toast

Notifications: the toaster, toasts pushed by the server, and the cards drawn in the page.

`<.status_toast>`

```heex
<.status_toast status="run" title="Backup orbit-db na fila" />
```

`<.toast_card>`

```heex
<.toast_card kind="neutral" title="Pedido #2488 excluído" />
```

`<.toast_loop>`

```heex
<.toast_loop mode="swap" class="w-[380px]">
  <:toast><.toast_card kind="primary" icon="sparkles" title="Emitindo NF-e…" busy /></:toast>
  <:toast><.toast_card kind="success" icon="check-circle" title="NF-e autorizada" /></:toast>
</.toast_loop>
```

`<.toaster>`

```heex
<.toaster />
```

### Navegação

#### Breadcrumb

The trail of pages above the current one; the last `:item` is the current page.

`<.breadcrumb>`

```heex
<.breadcrumb variant="plain" />
```

#### ContextMenu

A menu that opens under the pointer on a right click.

`<.context_menu>`

```heex
<.context_menu placement="bottom-start">
  <:trigger>Abrir ↵</:trigger>
  Abrir ↵ Renomear F2 Copiar link ⌘ L Mover para Excluir ⌫
</.context_menu>
```

#### Dropdown

Dropdown menu: a button (or any trigger) that opens a floating menu of links and actions.

`<.dropdown>`

```heex
<.dropdown color="mono" />
```

`<.dropdown_checkbox>`

```heex
<.dropdown_checkbox>
  Texto
</.dropdown_checkbox>
```

`<.dropdown_footer>`

```heex
<.dropdown_footer />
```

`<.dropdown_header>`

```heex
<.dropdown_header>
  Texto
</.dropdown_header>
```

`<.dropdown_item>`

```heex
<.dropdown_item>
  Texto
</.dropdown_item>
```

`<.dropdown_label>`

```heex
<.dropdown_label>
  Texto
</.dropdown_label>
```

`<.dropdown_radio>`

```heex
<.dropdown_radio>
  Texto
</.dropdown_radio>
```

`<.dropdown_search>`

```heex
<.dropdown_search />
```

`<.dropdown_separator>`

```heex
<.dropdown_separator />
```

`<.dropdown_submenu>`

```heex
<.dropdown_submenu label="label">
  Texto
</.dropdown_submenu>
```

`<.menu_panel>` — The menu box on its own, always visible and in the flow of the page (no trigger, no top layer, no hook): the same surface as the open menu of `dropdown/1`,…

```heex
<.menu_panel>
  Texto
</.menu_panel>
```

`<.action_button>` — A `button/1`-looking icon button for an item with a single action (`danger` makes it the `error` colour).

```heex
<.action_button label="label" />
```

#### MenuList

Menu lists: a vertical list of links with one active entry, plus `menu_item` and `menu_row`.

`<.menu>` — Same as `menu_list/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.menu />
```

`<.menu_item>`

```heex
<.menu_item>
  Texto
</.menu_item>
```

`<.menu_list>`

```heex
<.menu_list color="primary" variant="pill" />
```

`<.menu_row>`

```heex
<.menu_row />
```

#### Pagination

Pagination: the canvas pager (`shape` `canvas`, `rounded` or `pill`) or the classic bar of buttons (`shape="classic"`), in three sizes.

`<.pagination>`

```heex
<.pagination size="sm" />
```

#### Scrollspy

A list of links to the sections of the page that marks the section in view.

`<.scrollspy>`

```heex
<.scrollspy target="#doc">
  <:item href="#dados">Dados</:item>
  <:item href="#fiscal">Fiscal</:item>
</.scrollspy>
```

#### Steps

Steps: numbered or plain points joined by a line (`steps/1`) and the progress stepper of a wizard (`stepper/1`).

`<.stepper>`

```heex
<.stepper color="info" />
```

`<.steps>`

```heex
<.steps>
  <:step>Texto</:step>
</.steps>
```

#### Tabs

Tabs: `line`, `boxed`, `pill`, `text`, `segmented` and `nav`, plus the `classic` underline tabs with count badges, horizontal or vertical.

`<.tabs>`

```heex
<.tabs variant="line">
  <:tab>Visão geral</:tab>
  <:tab>Faturas</:tab>
  <:tab>Uso</:tab>
</.tabs>
```

### Sobreposições

#### Accordion

A list of sections that open under their titles (`<.accordion>` with `<.accordion_item>`).

`<.accordion>`

```heex
<.accordion variant="basic" color="primary">
  <:item title="Como emitir uma NF-e?" open>…</:item>
</.accordion>
```

`<.accordion_item>`

```heex
<.accordion_item id="id" />
```

#### CommandPalette

A dialog opened with Ctrl K (or `LedgerUI.open/1`) where the person types, narrows the results by scope and jumps to a page or runs an action from the…

`<.command_palette>`

```heex
<.command_palette id="id" />
```

`<.command_palette_dialog>` — Same as `command_palette/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.command_palette_dialog />
```

#### Drawer

Side panel (`<.drawer>`) and its sheet parts (`<.sheet_header>`, `<.sheet_body>`, `<.sheet_footer>`).

`<.drawer>`

```heex
<.drawer id="account" placement="right" floating>…</.drawer>
```

`<.sheet>` — Same as `drawer/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.sheet id="sheet-exemplo" placement="bottom">
  <:title>…</:title>
  …
</.sheet>
```

`<.sheet_body>` — The scrolling body of a sheet: it takes the height the header and the footer leave.

```heex
<.sheet_body>
  Texto
</.sheet_body>
```

`<.sheet_footer>` — The footer of a sheet: the buttons, aligned to the end on a tinted bar.

```heex
<.sheet_footer>
  Texto
</.sheet_footer>
```

`<.sheet_header>` — The header of a sheet: title and description (or `:content`), a back arrow, buttons and the close ×.

```heex
<.sheet_header />
```

#### Modal

Modal dialog for short tasks and confirmations (`<.modal>`).

`<.modal>`

```heex
<.modal close_variant="plain" />
```

#### NotificationCenter

A bell with a count when something is unread and, under it, a panel with the notifications (`<.notification_center>`).

`<.notification_center>`

```heex
<.notification_center />
```

#### Popover

A card with an arrow next to its trigger (`<.popover>`), for more than a tooltip holds.

`<.popover>`

```heex
<.popover placement="top">
  <:trigger>top</:trigger>
  Ticket médio · R$ 168,40
</.popover>
```

#### Tool

A tool call an agent makes (running a command, reading a file), from input to output, as a line of a `LedgerUI.Components.Trace.trace/1`: a plain line while…

`<.tool>` — One tool call, as a line of a `trace/1` (or a panel).

```heex
<.tool />
```

`<.tool_approval>` — A tool call that waits for the user: the question, the input and Deny / Approve.

```heex
<.tool_approval id="id" />
```

#### Tooltip

A short hint around a trigger (`<.tooltip>`).

`<.tooltip>`

```heex
<.tooltip placement="top">
  <:trigger></:trigger>
  dark
</.tooltip>
```

`<.tooltip_tip>` — Only the bubble of a tooltip, in the page flow: no trigger, no hook, no floating.

```heex
<.tooltip_tip>
  Texto
</.tooltip_tip>
```

### Estrutura e shell

#### Shell

The one frame of the app: the side menu (data mode: `nav`, drawn by `sidebar/1`; or slot mode: your own `<:sidebar>`), the top bar, the page and the parts that lie over them. The building blocks of the slot mode (`main_sidebar/1`, `sidebar_panel/1`, `rail_link/1`, `page_header/1`...) are public components of the same module.

`<.shell>`

```heex
<.shell nav={[%{label: "Home", navigate: "/"}]} format="rail" full>
  <:topbar></:topbar>
  Texto
</.shell>
```

```heex
<.shell id="shell" full on_toggle="sidebar">
  <:sidebar></:sidebar>
  <:topbar></:topbar>
</.shell>
```

`<.framed_sidebar>` — The menu of the framed shell: the brand, an optional workspace and search, the navigation (`rail_link/1`, `rail_module/1`) and the bottom items.

```heex
<.framed_sidebar id="id">
  Texto
</.framed_sidebar>
```

`<.header>` — The header: the animated sidebar toggle, the search bar, the dark mode and monochrome toggles, the notifications, the right sidebar toggle and a profile slot.

```heex
<.header />
```

`<.horizontal_nav_divider>` — The line between the links of a horizontal navigation box.

```heex
<.horizontal_nav_divider />
```

`<.horizontal_nav_link>` — A link of a horizontal navigation box.

```heex
<.horizontal_nav_link>
  Texto
</.horizontal_nav_link>
```

`<.horizontal_nav_menu>` — A dropdown of the horizontal navigation: an icon and a label, and a box of links.

```heex
<.horizontal_nav_menu id="id" label="label" />
```

`<.icon_rail>` — Same as `main_sidebar/1` (same attributes and slots), under the name the design vitrine uses.

```heex
<.icon_rail />
```

`<.main_sidebar>` — The main sidebar: the icon rail with the logo, the section links and the bottom links.

```heex
<.main_sidebar />
```

`<.main_sidebar_link>` — One icon link of the main sidebar.

```heex
<.main_sidebar_link>
  Texto
</.main_sidebar_link>
```

`<.monochrome_toggle>` — The monochrome mode: the palette button of the header or a switch.

```heex
<.monochrome_toggle />
```

`<.page_header>` — The title of a page.

```heex
<.page_header />
```

`<.rail_heading>` — A small uppercase title over a group of `rail_link/1`s; hidden in the rail.

```heex
<.rail_heading>
  Texto
</.rail_heading>
```

`<.rail_link>` — A page of the framed menu: the icon, the label, an optional badge and a tooltip for the rail.

```heex
<.rail_link label="label" />
```

`<.rail_module>` — A module of the framed menu: a button that opens the pages under it.

```heex
<.rail_module id="id" label="label">
  <:icon>Texto</:icon>
  <:item>Texto</:item>
</.rail_module>
```

`<.rail_toggle>` — A button that collapses and expands the `framed_sidebar/1` with that id, from anywhere.

```heex
<.rail_toggle for="for" />
```

`<.rail_user>` — The person at the bottom of the framed menu: their picture and, outside the rail, their name.

```heex
<.rail_user name="name">
  Texto
</.rail_user>
```

`<.rail_workspace>` — The workspace switcher under the brand of the framed menu.

```heex
<.rail_workspace name="name" />
```

`<.right_sidebar>` — A drawer from the right with an overlay, a top row (`:title` and the close button), the content and a `:footer`.

```heex
<.right_sidebar id="id" />
```

`<.right_sidebar_toggle>` — The header button that toggles a `right_sidebar/1`.

```heex
<.right_sidebar_toggle target="target" />
```

`<.sidebar_min_divider>` — The line between the lists of the minimized panel.

```heex
<.sidebar_min_divider />
```

`<.sidebar_min_group>` — A list of icon links of the minimized panel.

```heex
<.sidebar_min_group>
  Texto
</.sidebar_min_group>
```

`<.sidebar_min_link>` — An icon link of the minimized panel.

```heex
<.sidebar_min_link>
  Texto
</.sidebar_min_link>
```

`<.sidebar_nav>` — A list of the sidebar panel (or the sideblock).

```heex
<.sidebar_nav>
  Texto
</.sidebar_nav>
```

`<.sidebar_nav_count>` — The count (or the key hint) at the end of a link of the sidebar panel (`<:count>` of `sidebar_nav_link/1` renders it).

```heex
<.sidebar_nav_count>
  Texto
</.sidebar_nav_count>
```

`<.sidebar_nav_divider>` — The line between the lists of the sidebar panel.

```heex
<.sidebar_nav_divider />
```

`<.sidebar_nav_group>` — A collapsible group of the sidebar panel.

```heex
<.sidebar_nav_group label="label">
  <:item>Texto</:item>
</.sidebar_nav_group>
```

`<.sidebar_nav_heading>` — The title over a group of links of the sidebar panel, with no toggle (`sidebar_nav_group/1` is the collapsible one).

```heex
<.sidebar_nav_heading>
  Texto
</.sidebar_nav_heading>
```

`<.sidebar_nav_link>` — A plain link of the sidebar panel, active with `active` or when its path is `current`.

```heex
<.sidebar_nav_link>
  Texto
</.sidebar_nav_link>
```

`<.sidebar_panel>` — The sidebar panel next to the main sidebar: its title and the scrolling body.

```heex
<.sidebar_panel title="title">
  Texto
</.sidebar_panel>
```

`<.sidebar_panel_min>` — The minimized sidebar panel (`layout="minimal"`): a header, the icon links and a footer.

```heex
<.sidebar_panel_min>
  Texto
</.sidebar_panel_min>
```

`<.sidebar_profile>` — The avatar at the bottom of the main sidebar and the profile box it opens on its right.

```heex
<.sidebar_profile id="id" name="name" src="src" />
```

`<.sidebar_toggle>` — The animated hamburger: three bars that turn into an arrow while the sidebar is open.

```heex
<.sidebar_toggle />
```

`<.sideblock>` — The sideblock (`layout="sideblock"`): one wide sidebar with the logo and the navigation.

```heex
<.sideblock>
  Texto
</.sideblock>
```

`<.sub_nav>` — The sub navigation next to the icon rail: a title and groups of links that open and close.

```heex
<.sub_nav title="Cases">
  <:group label="Status">…</:group>
</.sub_nav>
```

`<.tab_bar>` — A phone's bottom bar of tabs: one icon per section, the current one in the accent color.

```heex
<.tab_bar>
  <:tab>Texto</:tab>
</.tab_bar>
```

#### Container

Page containers: `container_fixed/1` centers its content up to the `xl` breakpoint (1280px), `container_fluid/1` fills the width.

`<.container>` — A centered container with a gutter, sized by `size`.

```heex
<.container size="lg">…</.container>
```

`<.container_fixed>` — A centered container, as wide as the `xl` breakpoint at most.

```heex
<.container_fixed />
```

`<.container_fluid>` — A container as wide as its parent.

```heex
<.container_fluid />
```

#### Hotkey

`hotkey/1`: a global keyboard shortcut that pushes an event to the LiveView or runs a `%JS{}`.

`<.hotkey>`

```heex
<.hotkey id="save" keys="Mod+s" on_press="save" />
```

#### LandingNav

The marketing-site top bar: the logo on the left, the links in the center (one may open a mega menu), Entrar and the primary button on the right.

`<.landing_announcement>` — The thin announcement strip above the bar; the close button hides it with `JS.hide`.

```heex
<.landing_announcement id="id">
  Texto
</.landing_announcement>
```

`<.landing_cta>` — The primary button of the bar.

```heex
<.landing_cta>
  Texto
</.landing_cta>
```

`<.landing_feature>` — One feature of the mega menu: an icon in a box, the title and a line of description.

```heex
<.landing_feature title="title" />
```

`<.landing_login>` — The "Entrar" link of the bar.

```heex
<.landing_login>
  Texto
</.landing_login>
```

`<.landing_mega>` — The mega menu content (inside a `:link` of `landing_nav/1`): the features and, optionally, a side panel.

```heex
<.landing_mega>
  Texto
</.landing_mega>
```

`<.landing_mega_side>` — The highlighted panel beside the features: an eyebrow, the title, the text, a thumbnail and a link.

```heex
<.landing_mega_side title="title" />
```

`<.landing_nav>`

```heex
<.landing_nav variant="tint" />
```

`<.landing_product>` — A product card of `landing_mega variant="cards"`: logo and name, a large title, a link and a preview.

```heex
<.landing_product title="title" />
```

#### Navbar

The app top bar: a container (`navbar/1`) and small pieces to put in it.

`<.navbar>`

```heex
<.navbar variant="float" />
```

`<.navbar_avatars>` — The people on the page, as overlapping avatars; the rest is a `+N` bubble.

```heex
<.navbar_avatars users={@users} />
```

`<.navbar_bell>` — The notifications button; `dot` shows the dot of something unread.

```heex
<.navbar_bell />
```

`<.navbar_brand>` — The logo and the name of the app.

```heex
<.navbar_brand />
```

`<.navbar_chip>` — A selector in a path of selectors (organization, project).

```heex
<.navbar_chip label="label" />
```

`<.navbar_cluster>` — The top-bar actions in one capsule: a single surface with a thin border; the buttons inside have no border of their own (the cluster takes it off, so the…

```heex
<.navbar_cluster shape="pill" size="sm">
  <.navbar_search icon_only phx-click="open_search" />
  <.navbar_bell count={12} />
</.navbar_cluster>
```

`<.navbar_crumbs>` — The path to the page.

```heex
<.navbar_crumbs items={@items} />
```

`<.navbar_env>` — The environment pill (`Produção`, `Homologação`); `tone` is `ok` (green) or `warn` (amber).

```heex
<.navbar_env label="label" />
```

`<.navbar_icon>` — An icon button of the bar (search on a small screen, help, the menu of the mobile bar).

```heex
<.navbar_icon label="label" name="name" />
```

`<.navbar_lang>` — The language switcher: a small segmented group.

```heex
<.navbar_lang locales={@locales} />
```

`<.navbar_links>` — The main links, centered.

```heex
<.navbar_links items={@items} />
```

`<.navbar_menu_head>` — The head of the user menu: the avatar, the name and the email, and a `:badge` (the role) at the end.

```heex
<.navbar_menu_head user={@user} />
```

`<.navbar_menu_item>` — An item of the menu: a link (`navigate`, `href`, `patch`, with `method="delete"` for a sign-out) or, with only `phx-click`, an action.

```heex
<.navbar_menu_item>
  Texto
</.navbar_menu_item>
```

`<.navbar_menu_row>` — A row of the menu with a label and a control at the end (`theme_switch/1`, `navbar_lang/1`).

```heex
<.navbar_menu_row label="label">
  Texto
</.navbar_menu_row>
```

`<.navbar_menu_status>` — The status line of the menu: a green dot, the label and an `:action` at the end.

```heex
<.navbar_menu_status label="label" />
```

`<.navbar_search>` — The search field of the bar.

```heex
<.navbar_search />
```

`<.navbar_sep>` — The thin vertical line between the icons and the user.

```heex
<.navbar_sep />
```

`<.navbar_slash>` — The `/` between two selectors.

```heex
<.navbar_slash />
```

`<.navbar_sync>` — The save state: a green check and a muted text (`Salvo há 2 min`).

```heex
<.navbar_sync text="text" />
```

`<.navbar_tabs>` — The tabs of the page, for the `:tabs` slot of `navbar/1`.

```heex
<.navbar_tabs items={@items} />
```

`<.navbar_title>` — The centered title of the mobile bar.

```heex
<.navbar_title>
  Texto
</.navbar_title>
```

`<.navbar_user>` — The user of the bar: the avatar, with a status ring (`"ring"`) or with the name (`"named"`).

```heex
<.navbar_user user={@user} />
```

`<.navbar_workspace>` — The workspace switcher: logo, name, a line under it and a chevron.

```heex
<.navbar_workspace name="name" />
```

#### PageTrail

`page_trail/1`: the screen tabs of the navbar.

`<.page_trail>`

```heex
<.page_trail id="trail" trail={@page_trail} recent={0} />
```

#### Persist

`persist/1`: keeps a piece of LiveView state in the browser and gives it back when it mounts.

`<.persist>`

```heex
<.persist id="draft-persist" key="draft" value={@draft} on_restore="restore" />
```

#### ScrollArea

A box that scrolls with a thin scrollbar (6px, transparent track).

`<.scroll_area>`

```heex
<.scroll_area class="h-64">…</.scroll_area>
```

#### ScrollTarget

`scroll_target/1`: scrolls smoothly to a block when the server changes `target`.

`<.scroll_target>`

```heex
<.scroll_target id="detail-st" target={@focus} block="start" scope="#detail-doc" />
```

#### Sidebar

The side menu of the shell, in four formats that read the same data:

`<.sidebar>`

```heex
<.sidebar variant="inset" />
```

### Temas e marca

#### GlowText

Text with a living gradient: the colors drift across the letters.

`<.glow_text>` — Renders the gradient text.

```heex
<.glow_text tone="warm">Black Friday</.glow_text>
```

#### Logo

The Ledger UI mark.

`<.logo>`

```heex
<.logo name="Ledgerly" context="Orbit Cloud · Finance" />
```

#### ThemePicker

Lets the user choose a named palette: a menu in the top bar or a grid of previews on a settings page.

`<.theme_picker>`

```heex
<.theme_picker themes={@themes} current="ledger" />
```

#### ThemeSwitch

The light / dark / system choice.

`<.theme_script>` — Inline script for the root layout `<head>`: applies the stored mode (`data-theme`) and palette (`data-palette`) before the first paint, so there is no flash.

```heex
<.theme_script />
```

`<.theme_switch>`

```heex
<.theme_switch variant="icons" />
```

`<.theme_toggle>` — A single button that flips light and dark: a moon in light mode, a sun in dark (both are in the markup, the `dark:` variant shows the right one).

```heex
<.theme_toggle />
```

### IA

#### Ai

The assistant ("Assistente (IA)"): the conversation, its messages, the proposals the user approves, the queries the assistant shows it made, the field to…

`<.ai_chat>` — The whole conversation: greeting and suggestions, the messages and the field to ask.

```heex
<.ai_chat id="id" />
```

`<.ai_composer>` — The field to ask the assistant: context chips, text, attachment and send (a form).

```heex
<.ai_composer />
```

`<.ai_greeting>` — The greeting of the assistant: the first line in a gradient and the question under it.

```heex
<.ai_greeting />
```

`<.ai_insights>` — Card of AI insights: icon, title, sentence with bold numbers, impact badge and action.

```heex
<.ai_insights insights={@insights} />
```

`<.ai_message>` — A message of the conversation.

```heex
<.ai_message />
```

`<.ai_promo>` — Call to the assistant pinned on the sidebar, with insight count and main action.

```heex
<.ai_promo />
```

`<.ai_proposal>` — An action the assistant proposes, which only happens when the user approves.

```heex
<.ai_proposal id="id" title="title" />
```

`<.ai_tool_trace>` — What the assistant consulted: summary (count and time) and one row per query.

```heex
<.ai_tool_trace steps={@steps} />
```

`<.conversation_list>` — The conversations of the assistant, by day, with a button for a new one and a search.

```heex
<.conversation_list conversations={@convs} current={@conv_id} />
```

`<.prompt_suggestions>` — The starting suggestions: cards, pills or a grey grid.

```heex
<.prompt_suggestions items={@items} />
```

#### CodeBlock

Code, terminal output, logs and diffs in a dark card (the same dark palette in every theme), styled only with Tailwind utilities: an optional header with a…

`<.code_block>` — Renders the code block.

```heex
<.code_block language="elixir" code={@code} />
```

#### Trace

What an agent did, one line per step: an icon, a title that truncates, an optional description (a count, a duration, a diff) and a status.

`<.trace>` — The list of steps.

```heex
<.trace spans={@spans} />
```

`<.trace_line>` — One step: icon, title, description and status; a link with `href`, `navigate` or `patch`.

```heex
<.trace_line />
```

`<.trace_step>` — A step that opens: the line is the summary and the block shows under it.

```heex
<.trace_step>
  Texto
</.trace_step>
```

### Outros

#### AuthSplit

The sign in and sign up screen in two halves, as the canvas draws it: on the left a centered column (the brand mark, the title and subtitle, the…

`<.auth_alert>` — The notice on top of a form with errors: a cross icon and the message (`role="alert"`).

```heex
<.auth_alert>
  Texto
</.auth_alert>
```

`<.auth_art>` — The art half of `auth_page/1`: the mountain landscape (`Illustration.summit/1`), floating `:chip` cards and a glass `:quote`.

```heex
<.auth_art />
```

`<.auth_page>` — The sign in / sign up / recovery screen of the canvas: on the left the brand, a centered column (max 380px, `inner_block`) and a footer line; on the right…

```heex
<.auth_page>
  Texto
</.auth_page>
```

`<.auth_sent>` — The "link sent" block: a tile with a mail icon and the message beside it (`role="status"`).

```heex
<.auth_sent>
  Texto
</.auth_sent>
```

`<.auth_split>`

```heex
<.auth_split>
  Texto
</.auth_split>
```

`<.auth_submit>` — The form's submit button, full width and accent.

```heex
<.auth_submit>
  Texto
</.auth_submit>
```

`<.oauth_button>` — A sign in button for an identity provider: the icon and the label, as a link (`href`) or a button.

```heex
<.oauth_button>
  Texto
</.oauth_button>
```

#### Autocomplete

A text input with a list of suggestions under it.

`<.autocomplete>`

```heex
<.autocomplete />
```

#### Clipboard

Copy to clipboard: `clipboard/1`, a button that copies a text, and `clipboard_input/1`, a field with a copy button joined to it.

`<.clipboard>`

```heex
<.clipboard id="id" />
```

`<.clipboard_input>`

```heex
<.clipboard_input id="id" />
```

#### Collapse

A section that opens and closes under its trigger (`<.collapse>`) and a text clamped to a few lines with a "show more" link (`<.collapse_text>`).

`<.collapse>`

```heex
<.collapse id="id">
  <:trigger>Texto</:trigger>
  Texto
</.collapse>
```

`<.collapse_text>` — A text clamped to `lines` lines, with a link under it that shows the rest and hides it again.

```heex
<.collapse_text id="id">
  Texto
</.collapse_text>
```

#### Email

Ledger UI's transactional e-mail: one layout for the e-mails a system sends (a sign-in code, a reset link, an order update): the logo, a card with an icon…

`<.email_code>` — A verification code, one box per character.

```heex
<.email_code value="value" />
```

`<.email_facts>` — Rows of label and value: `{label, value}`, `{label, value, :mono}` or `{label, value, :total}`.

```heex
<.email_facts rows={@rows} />
```

`<.email_layout>`

```heex
<.email_layout subject="subject" title="title">
  <:body>Texto</:body>
</.email_layout>
```

`<.email_p>` — A paragraph of the e-mail body, styled for mail clients.

```heex
<.email_p>
  Texto
</.email_p>
```

`<.email_steps>` — A row of steps: `{label, done?}` pairs, in order.

```heex
<.email_steps steps={@steps} />
```

#### Mask

Crops its content to one of nine mask shapes: `squircle`, `reuleaux-triangle`, `diamond`, `hexagon`, `hexagon-2`, `octagon`, `star`, `star-2` and `heart`.

`<.mask>`

```heex
<.mask />
```

#### Palette

Swatches of the kit palette: the accent scale, warm-neutral base, status signals and chart series.

`<.palette>`

```heex
<.palette />
```

#### PhoneInput

A phone number field with a country picker: a button at the left with the ISO code and the calling code (`BR +55`), and the number input.

`<.phone_input>` — Renders the phone input.

```heex
<.phone_input />
```

#### PillSelect

A quick filter of chips where the chosen ones take the accent: one choice by default, several with `multiple`.

`<.pill_select>`

```heex
<.pill_select options={@options} />
```

#### Sticky

A block that sticks to the top of the page and takes classes while the page is scrolled: a header that gets an edge, a bar that gets a shadow.

`<.sticky>`

```heex
<.sticky id="id">
  Texto
</.sticky>
```

#### TagsInput

A tag input: what is typed becomes a tag on Enter, Tab or a comma (pasting a comma separated list creates several); tags are removed with Backspace or their…

`<.tags_input>`

```heex
<.tags_input />
```

#### ViewSwitcher

The views of a collection (List, Board, Table...) as a segmented control, with an optional "+ View" menu to add one and a menu of saved views.

`<.view_switcher>`

```heex
<.view_switcher id="id" />
```

<!-- components:end -->

## Vitrine

A vitrine com todos os componentes, exemplos e templates é mantida à parte (com os dados de design, a paridade visual e a
publicação), fora deste repositório. Veja `CONVENTIONS.md` para contribuir com componentes e `MIGRATION.md` para as regras de
HEEx + Tailwind. O relatório da migração (paridade de pixels por caso e tema) está em `MIGRATION_REPORT.md`.

## Templates

A vitrine traz dez telas completas (`/templates`), montadas só com componentes da biblioteca e funcionando de verdade
(cada uma é uma LiveView, em tela cheia; `?theme=dark` escolhe o tema, `?palette=crepusculo` a paleta).
