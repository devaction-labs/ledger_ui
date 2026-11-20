# Field

Contêiner que alinha rótulo, controle e texto de ajuda; base de todos os campos.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** layout stacked/inline · state · as label/div

## Uso (Phoenix / HEEx)

```heex
<.field label="Moeda" help="Usada nos relatórios">…</.field>
```

## Regras

- Layout horizontal em páginas de configuração: rótulo e descrição à esquerda (1/3), controle à direita.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: form)

Todos os function components, atributos, valores e slots que este componente cobre.

The pieces Ledger UI's forms are made of: a caption, a help line, an error line and the
`field` wrapper that puts them around any control.

    <.label for="email">Email</.label>
    <.help_text>We never share it.</.help_text>
    <.error>can't be blank</.error>

    <.field label="Country" help="Where you live" errors={@form[:country].errors}>
      <select class="form-select ...">…</select>
    </.field>

`input`, `textarea`, `range` and the groups already render their own field, so `field` is
for the controls Ledger UI does not draw (a native `<select>`, a third-party widget).

### `<.label>`

A caption for the control with the id `for`.

    <.label for="username">Choose Username:</.label>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `for` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.error>`

A validation message, in Ledger UI's small red text. It has `role="alert"`, so a screen reader
announces it when it appears.

    <.error>Username is invalid</.error>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.help_text>`

The small line under a control that explains it. `state="success"` paints it green and
`state="error"` red, as Ledger UI's validation examples do; the green one starts with a 14px
check-circle icon.

    <.help_text>This is a help text</.help_text>
    <.help_text state="success">Username is valid</.help_text>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `state` | `:string` | `nil` | ``, `success`, `error` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.field>`

Wraps a control with its caption, help line and errors, laid out the way Ledger UI's forms
are: the caption on top, the control `mt-1.5` under it, then the help and the errors.

With `as="label"` (the default) the whole block is a `<label>`, so a click on the caption
focuses the control. Groups of checkboxes or radios use `as="div"`, and their own container
then lays the options out.

    <.field label="Category" help="Pick one">
      <select class="form-select w-full ...">…</select>
    </.field>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | Takes the errors from a form field. |
| `id` | `:string` |  | The id of the control, for the caption's `for`. |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `label_hint` | `:string` | `nil` | A dimmed note at the right of the caption, as the canvas's "opcional". |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `state` | `:string` | `nil` | ``, `success`, `error` |
| `as` | `:string` | `"label"` | `label`, `div` |
| `layout` | `:string` | `"stacked"` | `stacked`, `inline` — `stacked` puts the caption above the control; `inline` puts it at the left, right-aligned in a 180px column (the canvas's "Em linha"), with the help and the errors under the control. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:aside>` — A small piece (a character counter) on the same row as the help and the errors, at the right.
- `<:below>` — Content between the control and the help line (strength bars).
- `<:inner_block>` (required)
- `<:label_aside>` — Content at the right of the caption (a "Forgot?" link, a strength word), on the caption's row.
