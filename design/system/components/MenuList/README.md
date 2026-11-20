# MenuList

Lista de links de navegação (menu lateral de configurações, índice de seções).

**Grupo:** 11 · Navegação  
**Resumo visual:** variant link · solid · pill · gradient · bordered · static × color primary/neutral

## Uso (Phoenix / HEEx)

```heex
<.menu_list variant="solid" color="primary">
  <:item icon="huge-shopping-cart-01" navigate={~p"/pedidos"} active>Pedidos</:item>
</.menu_list>
```

## Regras

- `link` só pinta o texto; `solid` e `gradient` preenchem o ativo; `pill` dá fundo suave arredondado; `bordered` contorna.
- `static` desativa o hover para listas só de leitura.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: menu_list)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's menu lists: a vertical list of links with one active entry.

    <.menu_list variant="solid">
      <:item navigate={~p"/start"} active>Getting start</:item>
      <:item navigate={~p"/shipping"}>Shipping</:item>
    </.menu_list>

An icon is the first child of an item; Ledger UI's icon colors (muted, darker on hover, current
color when active) come with it:

    <:item href="#"><svg class="size-5">…</svg><span>Payments</span></:item>

A trailing count (a badge, a number) goes in the `:count` slot of a `menu_item`, or in the
`count` attr of an `:item`; it is pushed to the end of the row:

    <.menu_item navigate="/inbox" variant="solid">
      <:icon><svg class="size-5">…</svg></:icon>
      Inbox
      <:count><.badge size="sm" shape="pill">12</.badge></:count>
    </.menu_item>

`variant` follows Ledger UI's examples: `link` (text only), `solid` (filled; `color` picks
primary or neutral), `pill` (rounded with a tinted hover), `gradient` and `bordered`.

Items that are not links take `on_select` (an event name or `%JS{}`), pushed with
`%{"value" => item_value}`:

    <.menu_list on_select="pick">
      <:item value="shipping">Shipping</:item>
    </.menu_list>

`variant="static"` is the canvas `lu-list`: plain rows (`menu_row`) with an icon, a title over a
sub line, a value at the right and an unread dot; see `menu_row`.

Streams render one `menu_item` per row:

    <.menu_list id="pages" rows={@streams.pages}>
      <:row :let={{_id, page}}>
        <.menu_item navigate={page.path} active={page.id == @current}>{page.title}</.menu_item>
      </:row>
    </.menu_list>

### `<.menu_list>`

Renders the list. Items come from `:item` slots (each takes `href`/`navigate`/`patch`,
`active`, `value`, and any HTML attribute), or from `rows` with a `:row` slot.

`on_select` is pushed with `%{"value" => value}` when an item that has a `value` is clicked;
it goes to `target` when given; a `%JS{}` is executed instead.

    <.menu_list variant="pill" on_select="pick">
      <:item value="shipping" active={@tab == "shipping"}>Shipping</:item>
      <:item navigate={~p"/payments"}><svg class="size-5">…</svg><span>Payments</span></:item>
    </.menu_list>

    def handle_event("pick", %{"value" => value}, socket), do: {:noreply, assign(socket, tab: value)}

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` |  |
| `variant` | `:string` | `"link"` | `link`, `solid`, `pill`, `gradient`, `bordered`, `static` — Ledger UI's menu list examples 1–2 (`link`), 3–4/7–8 (`solid`), 5–6 (`pill`), 9–10 (`gradient`), 11–12 (`bordered`). `static` is the canvas `lu-list` of `menu_row`s: a `<div>` (no `<ul>`), rows given by `rows` and `:row`, which render the `menu_row` themselves (with its `id`, for a stream) and `:item` slots become rows. |
| `color` | `:string` | `"primary"` | `primary`, `neutral` — The active item's color (Ledger UI's examples 7–8 are `neutral`). |
| `on_select` | `:any` | `nil` | Event name or `%JS{}`; pushed with `%{"value" => value}` by items with a `value`. |
| `target` | `:any` | `nil` | The `phx-target` `on_select` goes to. |
| `rows` | `:list` | `nil` | A list or a stream (`@streams.x`) rendered by `:row`. |
| `row_id` | `:any` | `nil` | A function giving each row's DOM id (streams give it). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:item>` — attrs: `href`, `navigate`, `patch`, `active`, `value`, `count`
- `<:row>` — Renders one row; takes the row (`{dom_id, item}` for a stream).

### `<.menu_row>`

Renders one static row of the canvas `lu-list` (`<.menu_list variant="static">`): an optional
icon or avatar, a title over a sub line, a value at the right and an unread dot. The row is a
`<div>`, or a link with `href`, `navigate` or `patch`; `phx-click` and any other attribute go
through `rest`. `id` is what a stream needs on each row.

    <.menu_row title="Fatura 1042" sub="Acme Ltda" unread>
      <:icon><.icon name="hero-document" class="size-4" /></:icon>
      <:value><span class="mono">R$ 480,00</span></:value>
    </.menu_row>

    <.menu_row navigate={~p"/clients/1"}><div class="t">Acme</div><div class="s">12 users</div></.menu_row>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` | `:string` | `nil` | The `.t` line. |
| `sub` | `:string` | `nil` | The `.s` line under the title. |
| `unread` | `:boolean` | `false` | Shows the unread dot after the value. |
| `unread_label` | `:string` | `"Unread"` | Screen reader text of the dot. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`, `replace`.

Slots:

- `<:icon>` — Before the text: an `lu-ic` tile, an avatar.
- `<:inner_block>` — Free content after `title` and `sub` (or alone).
- `<:value>` — At the right.

### `<.menu_item>`

Renders one entry of a menu list as a link (`href`, `navigate`, `patch`) or, without one,
a link-styled button that pushes `on_select` with `%{"value" => value}`. Used alone or in
a `menu_list` `:row`.

    <.menu_item variant="solid" navigate={~p"/start"} active>Getting start</.menu_item>
    <.menu_item value="b" on_select="pick">Beta</.menu_item>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"link"` | `link`, `solid`, `pill`, `gradient`, `bordered` |
| `color` | `:string` | `"primary"` | `primary`, `neutral` |
| `active` | `:boolean` | `false` |  |
| `value` | `:string` | `nil` |  |
| `on_select` | `:any` | `nil` | An event name or `%JS{}` run on click. |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`, `replace`.

Slots:

- `<:count>` — Pushed to the end of the row (a number, a badge).
- `<:icon>` — Drawn before the text; an `<svg>` gets Ledger UI's icon size and colors.
- `<:inner_block>` (required)
