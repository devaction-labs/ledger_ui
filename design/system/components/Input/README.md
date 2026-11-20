# Input

Campo de texto de uma linha. Mesmos eixos da API: `variant`, `size`, `shape`, `align`, `state`, `layout`, `label`, `label_hint`, `help`, `errors`, prefixo/sufixo e ícone.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** variant outlined · filled · plain × size sm · md · lg × shape rounded · pill · align · state · layout inline · label_hint · ícone, prefixo e sufixo · tipos

## Uso (Phoenix / HEEx)

```heex
<.input field={@form[:name]} label="Nome" />
<.input field={@form[:total]} align="right" label="Total"><:prefix>R$</:prefix></.input>
<.input field={@form[:email]} type="email" variant="filled" size="lg" state="success" help="E-mail verificado" />
<.input field={@form[:q]} shape="pill" layout="inline" label="Buscar" label_hint="opcional" />
```

## Regras

- Padrão: `outlined`, `md` (38px), `rounded` (raio 10). Pílula só quando pedido.
- `plain` para campos dentro de um bloco já emoldurado; `filled` em barras e filtros.
- `align="right"` para valores; o prefixo `R$` fica fora do valor.
- Foco: borda teal + anel de 3px. Erro: borda vermelha, a linha de ajuda vira a mensagem.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: input)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's text input (`input`, `input-sm`, `input-lg`, `input-ghost`, `input-success`, `input-error`): outlined
or filled, rounded or pill, three sizes, icons inside, success and error states, and input masks.

    <.input name="username" placeholder="Username" />
    <.input field={@form[:email]} type="email" label="Email" help="We never share it" />
    <.input name="q" variant="filled" shape="pill" size="lg" placeholder="Search" />
    <.input name="company" label="Company name" placeholder="Your Company">
      <:prefix><svg>…</svg></:prefix>
    </.input>
    <.input name="username" value="taken" state="error" help="Username is invalid" />
    <.input name="amount" size="sm" align="right" />

Without a caption, help or errors it renders the bare `<input>` (wrapped in a positioning
span when it has icons), so it can sit inside an `input_group`.

### Masks

`mask` formats what is typed, as Ledger UI's Cleave.js examples do. `mask_options` tunes it:

    <.input name="card" mask="credit_card" placeholder="xxxx xxxx xxxx xxxx" />
    <.input name="date" mask="date" mask_options={%{pattern: ~w(m d Y), delimiter: "-"}} />
    <.input name="time" mask="time" mask_options={%{pattern: ~w(h m s)}} />
    <.input name="phone" mask="phone" />
    <.input name="document" mask="cpf_cnpj" label="CPF ou CNPJ" mask_submit="raw" />
    <.input name="amount" mask="numeral" mask_options={%{thousands: "lakh"}} />
    <.input name="code" mask="blocks" mask_options={%{blocks: [3, 2, 3, 3], delimiters: [".", "_", "-"], uppercase: true}} />
    <.input name="ref" mask="blocks" mask_options={%{prefix: "Prefix", delimiter: "-", blocks: [6, 4, 4, 7]}} />

| mask | options |
|---|---|
| `blocks` | `blocks`, `delimiter`, `delimiters`, `prefix`, `uppercase`, `lowercase`, `numeric` |
| `credit_card` | `delimiter` (`" "`); blocks follow the card brand (Amex 4-6-5, Diners 4-6-4) |
| `date` | `pattern` of `d m y Y` (`~w(d m Y)`), `delimiter` (`"/"`) |
| `time` | `pattern` of `h m s` (`~w(h m s)`), `delimiter` (`":"`) |
| `phone` | `blocks` (`[3, 3, 4]`), `delimiter` (`" "`) |
| `cpf_cnpj` | none. Brazilian document: CPF (`000.000.000-00`) up to 11 digits, CNPJ (`00.000.000/0000-00`) beyond, switching by itself while typing, deleting and pasting; at most 14 digits. Sets `inputmode="numeric"` (override it with `inputmode`) |
| `numeral` | `thousands` (`thousand lakh wan none`), `decimals` (`2`), `delimiter` (`","`), `decimal_mark` (`"."`), `positive`, `prefix` (`"R$ "`, shown before the figure and left out of the raw value) |

The input submits the masked text. `mask_submit="raw"` submits the unmasked value instead
(digits, or a plain number like `1234.5` for `numeral`) through a hidden input that carries
the field's name; `phx-debounce`/`phx-throttle` are copied onto it.

    <.input field={@form[:amount]} mask="numeral" mask_submit="raw" phx-debounce="300" />

### Clearing a focused input

`clear_on_submit` makes the field take the server's `value` after its form is submitted even
while it has focus:

    <.form for={@form} phx-submit="add">
      <.input id="todo" name="title" value={@title} clear_on_submit />
    </.form>

### Buttons inside the input

`:prefix` and `:suffix` hold icons and let clicks fall through to the input. Mark one
`interactive` to put a button there (send, clear, show the password):

    <.input name="message" value={@message} placeholder="Message">
      <:suffix interactive>
        <.button variant="flat" class="size-7 rounded-[var(--pill-in,8px)] p-0" type="submit" aria-label="Send">
          <.icon name="huge-sent" class="size-4" />
        </.button>
      </:suffix>
    </.input>

A suffix that holds text (a unit, a count) takes `text`: the box sizes to its content and the
input's right padding follows it (the `LedgerUI.InputSuffix` hook publishes the width, 2.25rem
until it runs, as for an icon). Icon suffixes are unchanged.

    <.input name="guests" type="number">
      <:suffix text>4 pessoas</:suffix>
    </.input>

### Beside the caption and under the box

`:label_aside` puts content at the right of the caption (a "Forgot?" link, the word of a strength meter) and
`:below` puts it between the box and the help line (the meter's bars). Both need the caption block, so they
go with `label` (`below` also works without one).

    <.input field={@form[:password]} type="password" label="Senha" help="Mínimo de 8 caracteres">
      <:label_aside><.link navigate={~p"/forgot"}>Esqueci</.link></:label_aside>
      <:below><div class="lu-meter">…</div></:below>
    </.input>

The mask runs in the `LedgerUI.InputMask` hook, so a masked input needs a stable `id` (it gets
one from `field`; pass one otherwise when the input re-renders).

### `<.input>`

Renders a text-like `<input>`, with its caption, help and errors when given.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `id` | `:string` |  | Defaults to the field's id. |
| `name` | `:string` |  | Defaults to the field's name. |
| `value` | `:any` |  |  |
| `type` | `:string` | `"text"` | `text`, `email`, `password`, `number`, `search`, `tel`, `url`, `date`, `time`, `datetime-local`, `month`, `week`, `color`, `file`, `hidden` |
| `variant` | `:string` | `"outlined"` | `outlined`, `filled`, `plain` — `plain` has no border nor background, for inputs inside a framed block. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` |
| `align` | `:string` | `"left"` | `left`, `right` — `right` aligns the typed text to the right, for amounts. |
| `state` | `:string` | `nil` | ``, `success`, `error` — Paints the border and the help line. Errors set `error` on their own. |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `label_hint` | `:string` | `nil` | A dimmed note at the right of the caption, as the canvas's "opcional". |
| `layout` | `:string` | `"stacked"` | `stacked`, `inline` — `inline` puts the caption at the left of the input instead of above it. |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `disabled` | `:boolean` | `false` |  |
| `options` | `:list` | `[]` | Suggestions, rendered as the input's `<datalist>`. |
| `mask` | `:string` | `nil` | ``, `blocks`, `credit_card`, `date`, `time`, `phone`, `numeral`, `cpf_cnpj` |
| `mask_options` | `:map` | `%{}` |  |
| `mask_submit` | `:string` | `"formatted"` | `formatted`, `raw` — `raw` submits the unmasked value (digits, a plain number) through a hidden input. |
| `clear_on_submit` | `:boolean` | `false` | LiveView never overwrites the value of a focused input, so a field that keeps focus after `phx-submit` (a todo or chat box) would keep its text. With this, the first server render after the surrounding form is submitted writes `value` into the input even while it has focus; render `value=""` to clear it. Needs a stable `id`. |
| `wrapper_class` | `:any` | `nil` | Classes of the block around a captioned input. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `accept`, `autocomplete`, `autofocus`, `form`, `list`, `max`, `maxlength`, `min`, `minlength`, `multiple`, `pattern`, `placeholder`, `readonly`, `required`, `size`, `step`, `inputmode`.

Slots:

- `<:below>` — Content between the input and the help line (strength bars).
- `<:label_aside>` — Content at the right of the caption (a "Esqueci" link, a strength word), on the caption's row.
- `<:prefix>` — attrs: `interactive`, `class` — An icon inside the input, on the left.
- `<:suffix>` — attrs: `interactive`, `text`, `class` — An icon inside the input, on the right; with `interactive`, a button (send, clear, show password).
