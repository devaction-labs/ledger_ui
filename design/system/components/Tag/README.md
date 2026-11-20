# Tag

Marcador de categoria, opcionalmente removível e com cor de série.

**Grupo:** 06 · Exibição  
**Resumo visual:** color (8) × variant solid/soft/bordered/outline/flat · shape rounded/pill/square · removível

## Uso (Phoenix / HEEx)

```heex
<.tag color="chart-1" removable>Pro</.tag>
```

## Regras

- Amostra quadrada de 8px na cor da série do gráfico.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: tag)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's tags: clickable badges that represent an attribute, a filter or an action.

    <.tag href="#">Default</.tag>
    <.tag navigate={~p"/tags/elixir"} color="primary" shape="pill">Elixir</.tag>
    <.tag color="info" variant="bordered" shape="pill" phx-click="filter">Info</.tag>

A filter chip that can be selected takes `active`:

    <.tag :for={tag <- @tags} variant="soft" active={tag in @selected} phx-click="toggle" phx-value-tag={tag}>
      {tag}
    </.tag>

`tag_group/1` joins tags (and badges) side by side:

    <.tag_group>
      <.tag color="neutral">Primary</.tag>
      <.tag color="primary">55</.tag>
    </.tag_group>

A selected chip (`active`) is a solid primary fill with white text, for every variant but `flat`.

`variant="flat"` is the canvas tag (`lu-tag`): 26px, regular weight, muted text on the sunken fill; its
active state is the accent tint. `tint` paints a tag in a colour of its own (a user's label colour):

    <.tag variant="flat" active>Todos</.tag>
    <.tag variant="flat" tint="#0d8f91">VIP</.tag>
`count` puts a small pill with a number inside the tag.

With `href`, `navigate` or `patch` a tag is a link; otherwise it is a button.

A tag that only labels (inside a link or a table row) is not interactive: `as="span"` or `static`
renders a `<span>` with the same classes, so no button is nested in a link:

    <a href="/runs/1">Run 1 <.tag variant="flat" as="span">test</.tag></a>

### `<.tag>`

Renders a tag: a link with `href`, `navigate` or `patch`, a button otherwise.

    <.tag patch={~p"/posts?tag=elixir"} color="primary" variant="bordered" shape="pill">Elixir</.tag>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `light` |
| `variant` | `:string` | `"solid"` | `solid`, `soft`, `bordered`, `outline`, `flat` — `flat` is the canvas tag: muted text on the sunken fill, the accent tint when `active`; `color` does not apply to it. |
| `tint` | `:string` | `nil` | A colour of its own (any CSS colour, e.g. `"#8a5cd6"`): the text in that colour on a 14% tint of it. Overrides `color`. |
| `active` | `:boolean` | `false` | The selected state of a filter chip (and `aria-pressed="true"`): a solid `primary` fill with white text and a primary border whatever its `color`, or the accent tint for `variant="flat"`, so a list of chips only toggles this. |
| `count` | `:integer` | `nil` | A small pill with this number inside the tag, after the label (a filter's results). |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill`, `square` |
| `as` | `:string` | `nil` | ``, `span` — `span` renders a non-interactive `<span>` instead of a button or link (it ignores `type`, `href`, `navigate` and `patch`). |
| `static` | `:boolean` | `false` | The same as `as="span"`: a plain label with no button, for use inside links. |
| `type` | `:string` | `"button"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`, `name`, `value`, `disabled`.

Slots:

- `<:inner_block>` (required)

### `<.tag_group>`

Joins tags and badges side by side: the inner corners are squared and the borders overlap.

    <.tag_group>
      <.tag color="info" variant="soft">Message</.tag>
      <.tag color="info">65</.tag>
    </.tag_group>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
