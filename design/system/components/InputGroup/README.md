# InputGroup

Agrupa input com select ou botão compartilhando a mesma borda.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** shape rounded/pill · size sm/md/lg · variant outline/filled · state success/error

## Uso (Phoenix / HEEx)

```heex
<.input_group><.select … /><.input … /><.button>Aplicar</.button></.input_group>
```

## Regras

- Só a primeira e a última peça têm cantos arredondados.
- Use para pares inseparáveis (moeda + valor, filtro + busca).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: input_group)

Todos os function components, atributos, valores e slots que este componente cobre.

Joins inputs, addons, selects and buttons into one row with shared borders (kit CSS's `join`). Only the outer
ends keep their rounded corners.

    <.input_group>
      <.input_group_addon>@</.input_group_addon>
      <.input name="username" placeholder="Username" />
    </.input_group>

    <.input_group label="Price">
      <.input_group_addon variant="filled">$</.input_group_addon>
      <.input name="price" placeholder="Enter price" />
      <.input_group_addon variant="filled">.00</.input_group_addon>
    </.input_group>

    <.input_group shape="pill">
      <select class="select …">…</select>
      <.input name="price" placeholder="Price" />
      <.button>Purchase</.button>
    </.input_group>

    <.input_group size="sm" label="Amount" errors={["must be positive"]}>
      <.input_group_addon variant="filled">$</.input_group_addon>
      <.input name="amount" state="error" />
    </.input_group>

`size` (kit CSS's `sm`, `md`, `lg`) sizes the addons, selects, inputs and buttons together. The joined ends have
the theme's field corners (a button at the end too), and the `outline` addon is drawn as a field with muted text.
`errors` turns the shared border red and shows the messages under the row.

### `<.input_group>`

Renders the row. `label` adds a caption above it, `help` and `errors` a line below it.

The row is a `role="group"` named by the caption (`aria-labelledby`; pass an `id` to keep the
caption's id stable). With `errors` (or `state="error"`) every border of the row turns red
and the row gets `aria-invalid` and an `aria-describedby` that points at the messages; to
mark the control itself, give the `input` inside `state="error"` too.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | The row's id; the caption and messages derive theirs. Without it the id comes from the label, so give each group its own `id` when two share a label (rows of a repeated form). |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — Sizes the addons, selects, inputs and buttons together: 32px, 38px or 44px high. |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `help` | `:string` | `nil` | The small line under the row. |
| `errors` | `:list` | `[]` | Messages to show under the row; the shared border turns red. |
| `state` | `:string` | `nil` | ``, `success`, `error` |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (grid placement, spacing). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.input_group_addon>`

A text or icon box at either end (or between the inputs) of an `input_group`. `size` sets the text of
the box to match the `size` of the inputs next to it.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"outline"` | `outline`, `filled` |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
