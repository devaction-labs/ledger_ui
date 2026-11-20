# EmptyStateCard

Estado vazio de uma lista ou card, explicando o que vai aparecer e como começar.

**Grupo:** 10 · Feedback  
**Resumo visual:** variant canvas/card/inline/table/plain · tone default/gradient/positive · color · level

## Uso (Phoenix / HEEx)

```heex
<.empty_state icon="table-01" title="Nenhuma coorte ainda">…</.empty_state>
```

## Regras

- Diga o que vai aparecer aqui e dê uma ação direta.
- Sem ilustrações de pessoas; só o ícone com anéis.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: empty_state)

Todos os function components, atributos, valores e slots que este componente cobre.

An empty state: what the area is, why it is empty and the one next step, with the icon on a quadriculated grid.

    <.empty_state
      icon="huge-money-bag-01"
      kicker="Receivables"
      title="No receivable yet"
    >
      A receivable is created when an invoice paid in installments is authorized.
      <:action>
        <.button color="primary" variant="solid">New order</.button>
      </:action>
    </.empty_state>

    <.empty_state variant="inline" icon="huge-search-01" title="Nothing for “dipirona 1 g”">
      Try another term or clear the filters.
    </.empty_state>

`icon` is a Hugeicons name (`huge-*`), which needs the Tailwind plugin of the Icons section of the README;
leave it out, or pass the `illustration` slot, to draw something else.

The `canvas` variant is the default (below); `card` is the old Ledger UI centered block for a whole area; the `inline` one is a compact notice for inside
tables, lists and search results, in a neutral, success or error color.

The `canvas` variant is the design canvas's `lu-empty`: the icon on a 96×72 sunken tile, the title, the
reason and the actions, centered (`tone="positive"` paints the icon green, for an "all done" state).
The `plain` variant is the canvas's one-line notice inside a card: a small faint icon, the title and the
content (say, a link) on one line.

    <.empty_state variant="canvas" icon="huge-search-01" title="Nothing for “cement”">
      Check the spelling or search by SKU.
      <:action><.button variant="outline">Clear search</.button></:action>
    </.empty_state>

    <.empty_state variant="plain" icon="huge-attachment-01" title="No attachment.">
      <a href="#">Add</a>
    </.empty_state>

### `<.empty_state>`

Renders an empty state.

The content is the reason it is empty; `action` takes the one next step (a button, or a button and a quiet link).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"canvas"` | `canvas`, `card`, `inline`, `table`, `plain` — `card` fills an area, `inline` is a compact notice for lists and search results, `table` is the centered notice (a 48px disc, a title, the reason and the next step) for the body of an empty table, `canvas` the canvas's `lu-empty` (icon on a 96×72 tile), `plain` the canvas's faint one-line notice. |
| `title` (required) | `:string` |  | What is missing, as a short sentence. |
| `kicker` | `:string` | `nil` | The small uppercase line above the title (`card` only). |
| `icon` | `:string` | `nil` | A `LedgerUI.Components.Icon.icon/1` name; the `:illustration` slot replaces it. |
| `tone` | `:string` | `"default"` | `default`, `gradient`, `positive` — The icon tile of the `card` variant: white with a glow, or the indigo to purple gradient. In the `canvas` variant, `positive` paints the icon in the canvas's green. |
| `color` | `:string` | `"neutral"` | `neutral`, `success`, `error` — The color of the `inline` variant. |
| `level` | `:integer` | `2` | `2`, `3`, `4` — The heading level of the title of a `card`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — The next step.
- `<:illustration>` — Replaces the `icon`, for an illustration or a custom glyph.
- `<:inner_block>` — The reason it is empty.
