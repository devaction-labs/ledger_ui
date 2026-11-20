# Kbd

Tecla ou atalho de teclado (`kbd`), em relevo ou plana.

**Grupo:** 02 · Ações  
**Resumo visual:** variant raised · flat · combinações e em fundo escuro

## Uso (Phoenix / HEEx)

```heex
<.kbd>⌘</.kbd><.kbd>K</.kbd>
<.kbd variant="flat">Esc</.kbd>
```

## Regras

- Use o símbolo do sistema (⌘ no Mac, Ctrl no resto).
- Em fundos escuros (tooltip, toast) use a variante escura.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: typography)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's typography: headings in every level and weight, display headings, gradient and
decorated text, decorated links, inline code and keyboard keys. A `display` heading is semibold unless
`weight` says otherwise.

    <.heading level={1}>Heading H1</.heading>
    <.heading level={3} weight="light" color="info">Light H3</.heading>
    <.heading display={2}>Display 2</.heading>

    <.text size="lg" decoration="underline">Underlined</.text>
    <.text as="span" size="lg" weight="semibold" gradient="sky-blue">Gradient</.text>
    <.text_link href="#" decoration_color="info" decoration_style="wavy">Tattooine</.text_link>

    Press <.kbd>Ctrl</.kbd> + <.kbd>K</.kbd>, or run <.inline_code>mix test</.inline_code>.

The canvas text roles are colours too: `ink` (titles and figures), `fg` (running text), `subtle` (secondary
text, the canvas `muted`) and `faint` (meta and help). `muted` keeps Ledger UI's light grey, which is the canvas
`faint` in the light theme. A page title is `size="title"`:

    <.heading level={1} size="title">Financeiro</.heading>
    <.text size="lead" color="subtle">Contas a pagar e a receber das filiais.</.text>
    <.text as="span" mono color="ink">R$ 3.120,50</.text>

### `<.heading>`

Renders a heading, `<h1>` to `<h6>`, sized as Ledger UI's. `display` renders Ledger UI's display
headings (an `<h1>` unless `level` says otherwise) from 1, the largest, to 5.

    <.heading level={3} weight="semibold" color="primary">Orders</.heading>
    <.heading display={1}>Welcome</.heading>

`size` sets the type size apart from the level, so a heading keeps its place in the outline and looks as
large as the design asks: `<.heading level={2} size="2xl">Overview</.heading>`. `size="title"` is the canvas
page title: 34/40, tight tracking, semibold, in the ink colour.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `level` | `:integer` | `nil` | ``, `1`, `2`, `3`, `4`, `5`, `6` |
| `size` | `:string` | `nil` | ``, `2xl`, `3xl`, `base`, `lg`, `sm`, `title`, `xl` |
| `display` | `:integer` | `nil` | ``, `1`, `2`, `3`, `4`, `5` |
| `weight` | `:string` | `nil` | ``, `normal`, `light`, `medium`, `semibold`, `bold` — `normal` by default, `semibold` for a `display` heading and for `size="title"`. |
| `color` | `:string` | `"default"` | `default`, `error`, `faint`, `fg`, `info`, `ink`, `muted`, `neutral`, `primary`, `secondary`, `subtle`, `success`, `warning` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.text>`

Renders a run of text: a paragraph unless `as` says otherwise.

    <.text size="lg" weight="semibold" gradient="amber-orange">Hello</.text>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `as` | `:string` | `"p"` | `p`, `span`, `div`, `strong`, `em`, `small` |
| `size` | `:string` | `"inherit"` | `inherit`, `xs`, `xs-plus`, `sm`, `base`, `lg`, `xl`, `meta`, `lead` — `meta` is the canvas 12.5px meta/help line, `lead` the 15/22 line under a page title. |
| `weight` | `:string` | `"normal"` | `normal`, `light`, `medium`, `semibold`, `bold` |
| `color` | `:string` | `"default"` | `default`, `error`, `faint`, `fg`, `info`, `ink`, `muted`, `neutral`, `primary`, `secondary`, `subtle`, `success`, `warning` |
| `mono` | `:boolean` | `false` | Sets the text in the mono face (figures, codes, keys). |
| `gradient` | `:string` | `nil` | ``, `sky-blue`, `green-fuchsia`, `fuchsia-pink`, `amber-orange`, `purple-indigo` — Paints the text with one of Ledger UI's gradients. |
| `decoration` | `:string` | `nil` | ``, `underline`, `overline`, `line-through`, `none` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.text_link>`

Renders a link inside running text, underlined (1px) in a theme color and style as Ledger UI's
text decoration examples. It keeps the weight of the text around it; give it
`class="font-semibold"` for a heavier one.

    <.text_link navigate={~p"/about"} decoration_color="secondary" decoration_style="dotted">
      About us
    </.text_link>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `decoration_color` | `:string` | `"current"` | `current`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `decoration_style` | `:string` | `"solid"` | `solid`, `wavy`, `double`, `dotted`, `dashed` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`.

Slots:

- `<:inner_block>` (required)

### `<.inline_code>`

Renders code inside running text, the way Ledger UI's pages show class names: mono 12.5px on
the fill color, in the primary text color.

    Use the <.inline_code>rounded-full</.inline_code> utility.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.kbd>`

Renders a keyboard key: mono 11.5px, with a 1px inset border and a 1px shadow under it.
`variant="flat"` is the canvas key (`lu-kbd`): 18px high, muted, on the sunken fill, with no shadow under it.

    <.kbd>Ctrl</.kbd> + <.kbd>K</.kbd>
    <.kbd variant="flat">⌘ K</.kbd>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"raised"` | `raised`, `flat` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
