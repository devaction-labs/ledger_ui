# Card

O card do sistema: uma bandeja cinza com título em caixa-alta que abraça um painel branco.

**Grupo:** 06 · Exibição  
**Resumo visual:** variant (11) · color (6) · gradient (5) · size xs–lg · body · divider · shape

## Uso (Phoenix / HEEx)

```heex
<.card title="Revenue by plan">
  <:actions><.button size="sm" icon_right="arrow-up-right">Plans</.button></:actions>
  …
</.card>
```

## Regras

- Estrutura: `.lu-card` (tray, raio 20, padding 6) > header (título overline + ações) > `.lu-card-b` (painel, raio 14).
- Ações do header: botão `sm` secundário com ↗, menu ⋯ ou segmentado.
- Rodapé opcional fora do painel, em `muted` (como o delta dos KPIs).
- Variante `flat` sem bandeja para listas simples.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: card)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's card (`card card-border` on `base-100`, `card-body`, `card-title`): the panel, soft, a link row, and
the gradient-outlined card, with optional composable parts (header, body, footer).

    <.card>
      <:title>Simple Card</:title>
      Lorem ipsum dolor sit amet.
    </.card>
    <.card variant="bordered" shape="xl">…</.card>
    <.card variant="flat">No shadow</.card>
    <.card variant="solid" color="primary"><:title>Primary Card</:title>…</.card>
    <.card variant="gradient" gradient="purple-indigo">…</.card>
    <.card variant="gradient_outline" gradient="sky-blue">…</.card>

`navigate`, `patch` or `href` make the whole card a link, laid out as a row that ends in an
arrow:

    <.card navigate={~p"/banks/1"}>
      <div class="grow">Banco do Brasil</div>
    </.card>

Without `:title` the content fills the card as is, padded evenly like a bordered `div`;
`padded={false}` drops the default padding, for cards laid out by hand
(`<.card padded={false} class="px-4 pb-4 sm:px-5">`).

### Parts

A card is made of optional parts; use the ones you need. Anything placed directly in the card
keeps the card's padding.

    <.card variant="soft" body="inset" size="lg">
      <.card_header>
        <.card_heading>Profile</.card_heading>
        <.card_subheading>Make yourself at home</.card_subheading>
        <.card_actions><.button icon size="sm" variant="flat" aria-label="More">…</.button></.card_actions>
      </.card_header>
      <.card_body class="space-y-6">
        <.input name="name" label="Name" value="Olivia Martin" />
      </.card_body>
      <.card_footer>
        <span class="text-xs">All changes saved</span>
        <.card_actions><.button size="sm">Save</.button></.card_actions>
      </.card_footer>
    </.card>

* `card_header/1` holds `card_heading/1`, `card_subheading/1` and `card_actions/1`. Actions
  sit in the corner, centered on the heading; written before the heading they go to the
  leading side. Small buttons hang in the header's padding without making it taller.
* `card_body/1` is the main content. It may hold its own `card_header/1` and `card_footer/1`
  as sub-sections, spaced and padded by the body.
* `card_footer/1` holds supporting text and actions, or a heading, subheading and actions
  exactly like a header.
* `card_header/1` and `card_footer/1` also work outside a card; give them the `size` of the
  card they stand with.
* `card_bleed/1` makes media fill the card's sides, reach the top or bottom when it is the
  first or last thing in the body, and round only the corners it touches.

      <.card body="inset">
        <.card_body><.card_bleed><img src={@cover} alt="" /></.card_bleed></.card_body>
        <.card_footer>
          <.card_heading>Morning hike</.card_heading>
          <.card_subheading>Sept 12</.card_subheading>
        </.card_footer>
      </.card>

* A `table/1` with `bleed` inside a card runs its rows edge to edge while its content stays
  aligned with the card's, and reaches the top and bottom of the body when it is the only
  thing in it.

### Surfaces and treatments

`variant` is the surface: `default` (soft shadow in light, elevation in dark, a faint
highlight along the inside top edge in light mode unless `highlight={false}`), `flat`,
`bordered`, `outline` (border only), `muted` and `soft` (quiet tints that adapt to the color
behind them, in light and dark), `filled` (a tint without border) and the colored `solid`,
`glow`, `gradient`, `gradient_outline`.

`body` is how the parts are told apart: `seamless` (one surface, parts spaced by the card's
padding), `divided` (hairlines between parts, `divider="inset"` stops them at the content
edges), `separated` (tinted bands for header and footer), `inset` (the body is a panel inside
the card, with corners concentric to the card's: raised on a tinted card, recessed on a plain
one) and `flush` (the same panel running to the card's sides). With `padded={false}` the
parts pad themselves and `body` has no effect.

`size` (`xs`, `sm`, `md`, `lg`) sets padding, type, corners and the spacing between parts.
The card publishes these as CSS variables (`--card-p`, `--card-r`, `--card-i`, and per
treatment `--card-hx`, `--card-hy`, `--card-bx`, `--card-by`, `--card-bleed-x`...), which the
parts and the `bleed` of `table/1` read; the rules live in `assets/css/parts/card.css`.

### `<.card>`

Renders a card, with an optional `:title` above the content, or composed of
`card_header/1`, `card_body/1` and `card_footer/1`.

    <.card variant="glow" color="info">
      <:title>Revenue</:title>
      <p>$12,400 this month.</p>
    </.card>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"default"` | `default`, `flat`, `bordered`, `outline`, `muted`, `soft`, `filled`, `solid`, `glow`, `gradient`, `gradient_outline` — `default` is Ledger UI's white panel with a soft shadow (elevation in dark); `flat` is the same panel without the shadow; `bordered` adds a border; `outline` is the border only; `muted` and `soft` are quiet tints (`muted` the stronger) and `filled` a tint without border, all adapting to the color behind them; `solid` and `glow` use `color`; `gradient` and `gradient_outline` use `gradient`. |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg` — Padding, type, corners and the spacing between parts. |
| `body` | `:string` | `"seamless"` | `seamless`, `divided`, `separated`, `inset`, `flush` — How `card_header/1`, `card_body/1` and `card_footer/1` are told apart: one surface, hairlines, tinted bands, a body panel inside the card with concentric corners, or a body panel that reaches the card's sides. |
| `divider` | `:string` | `"full"` | `full`, `inset` — With `body="divided"`, `inset` stops the lines at the content edges. |
| `highlight` | `:boolean` | `true` | A faint highlight along the inside top edge of the `default`, `muted`, `soft` and `filled` surfaces in light mode. |
| `color` | `:string` | `"primary"` | `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `gradient` | `:string` | `"purple-indigo"` | `purple-indigo`, `fuchsia-pink`, `amber-orange`, `sky-blue`, `green-fuchsia` |
| `shape` | `:string` | `"rounded"` | `rounded`, `xl` — `xl` is `rounded-2xl`; on `gradient_outline` the outer edge and the inner panel follow it. |
| `padded` | `:boolean` | `true` | `false` leaves the card without padding; its parts then pad themselves. |
| `navigate` | `:string` | `nil` | Makes the whole card a link (`<.link navigate>`): a row with an arrow at the end. |
| `patch` | `:string` | `nil` | As `navigate`, with `<.link patch>`. |
| `href` | `:string` | `nil` | As `navigate`, with `<.link href>`. |
| `arrow` | `:boolean` | `true` | The chevron at the end of a linked card (`navigate`, `patch` or `href`). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `target`, `rel`, `download`, `replace`, `method`.

Slots:

- `<:inner_block>`
- `<:title>` — attrs: `class` — The card's heading, followed by the content.

### `<.card_header>`

The top of a card: `card_heading/1`, `card_subheading/1` and `card_actions/1`.

    <.card_header>
      <.card_actions><.button icon size="sm" variant="flat" aria-label="More">…</.button></.card_actions>
      <.card_heading>Activity</.card_heading>
      <.card_subheading>Last 30 days</.card_subheading>
    </.card_header>

Inside a card it follows the card's `body`; nested in a `card_body/1` it follows the body's
padding. Outside a card it adds no padding of its own and `size` sets its type.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `size` | `:string` | `nil` | ``, `xs`, `sm`, `md`, `lg` — The size of the card it stands with, when used outside a card. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.card_heading>`

The title of a `card_header/1` or `card_footer/1`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `size` | `:string` | `"base"` | `base`, `lg`, `xl` — `base` is the header's type size; `lg` and `xl` are for standalone headings. |
| `level` | `:integer` | `2` | `1`, `2`, `3`, `4`, `5`, `6` — The heading level of the element (`h1` to `h6`). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.card_subheading>`

The line under the heading of a `card_header/1` or `card_footer/1`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.card_actions>`

Buttons or links of a `card_header/1` or `card_footer/1`. They sit in the corner, centered on
the heading (at the trailing side, or at the leading side when written before the heading);
small buttons hang in the part's padding and do not make it taller.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.card_body>`

The main content of a card. In the `inset` and `flush` treatments it is the panel; a
`card_header/1` or `card_footer/1` nested in it follows the body's padding.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.card_footer>`

The bottom of a card: supporting text and `card_actions/1`, or a `card_heading/1`,
`card_subheading/1` and actions laid out like a header. Buttons written directly in it are
placed by `align`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `align` | `:string` | `"end"` | `start`, `center`, `end`, `between` — Where loose content (text, buttons) sits on the row. |
| `size` | `:string` | `nil` | ``, `xs`, `sm`, `md`, `lg` — The size of the card it stands with, when used outside a card. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.card_bleed>`

Media for a `card_body/1`: it reaches the card's sides, the top when it is the first thing in
the body and the bottom when it is the last, and rounds only the corners it touches (the
panel's in `inset` and `flush`).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
