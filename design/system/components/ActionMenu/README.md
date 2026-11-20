# ActionMenu

Menu de ações de uma linha ou card, aberto pelo botão ⋯.

**Grupo:** 11 · Navegação  
**Resumo visual:** placement (4) · variant (9) · size xs–xl

## Uso (Phoenix / HEEx)

```heex
<.action_menu id={"acct-#{a.id}"}>…</.action_menu>
```

## Regras

- Sempre ícone `more-h` com `aria-label="Ações"`.
- Máximo de 7 ações; agrupe o resto.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: action_menu)

Todos os function components, atributos, valores e slots que este componente cobre.

The actions of one item (a table row, a card, a message), opened by a "⋯" button, as the design canvas's
ActionMenu. Unlike the generic `LedgerUI.Components.Dropdown` it has a look of its own so it is not mistaken for the
content behind it: a raised background, a stronger outline and a shadow, in the dark theme too. While it is open
the button looks pressed and the item's row is tinted, so it is clear whose actions these are.

    <.action_menu id={"actions-" <> company.id} label={"Actions of " <> company.name}>
      <:title>{company.name}</:title>
      <.action_menu_item navigate={~p"/companies/#{company.id}"} icon="huge-view" kbd="↵">
        Open company
      </.action_menu_item>
      <.action_menu_item phx-click="members" phx-value-id={company.id} icon="huge-user-multiple" kbd="M">
        Members
      </.action_menu_item>
      <.action_menu_separator />
      <.action_menu_item
        phx-click="invite"
        icon="huge-mail-01"
        disabled
        hint="Invite accepted on 02/18"
      >
        Resend invite
      </.action_menu_item>
      <.action_menu_item phx-click="delete" phx-value-id={company.id} icon="huge-delete-02" danger kbd="⌘⌫">
        Delete company
      </.action_menu_item>
    </.action_menu>

`label` is the accessible name of the button. The optional `:title` slot is the header with the item's name.
An item with `href`, `navigate` or `patch` is a link, any other is a button (`phx-click`...). `disabled` items stay
in the menu and say why in their `hint`; the keys skip them and they carry `aria-disabled`. `danger` paints an
item in the error color (put it last).

It uses the Dropdown's machinery (hook `LedgerUI.ActionMenu`, a Dropdown hook with the row marking): the menu
sits in the top layer under the button, aligned to its right edge (`placement="bottom-end"`), flips upwards when there
is no room below, follows scrolling, and closes with Esc (the focus goes back to the button), Tab or a click
outside; ↑ ↓ Home End and letters move among the items. `LedgerUI.open/close/toggle` work with its `id`.

### One action only

A menu for a single item is heavy: use `action_button/1`, a direct button (or link) that sits where the
"⋯" would be.

    <.action_button label={"Delete " <> c.name} icon="huge-delete-02" danger phx-click="delete" phx-value-id={c.id} />
    <.action_button label="Open" icon="huge-view" navigate={~p"/companies/#{c.id}"} />

### What is marked while it is open

The hook sets `data-am-open` on the nearest `[data-am-row]`, `tr` or card-table row (`.linea-ctable-row`) above the
button, and the CSS tints it (`color-mix(in srgb, var(--accent) 6%, var(--panel))`). Inside a `card_table` the
row is marked with no work of yours. For any other item (a list entry, a message) give its element
`data-am-row`; a card with no `data-am-row` is simply not marked. The button is pressed through
`aria-expanded="true"`.

    <.card_table id="companies" rows={@companies}>
      <:col :let={c} label="Company">{c.name}</:col>
      <:action :let={c}>
        <.action_menu id={"actions-" <> c.id} label={"Actions of " <> c.name}>
          <.action_menu_item phx-click="members" phx-value-id={c.id} icon="huge-user-multiple">
            Members
          </.action_menu_item>
        </.action_menu>
      </:action>
    </.card_table>

### `<.action_menu>`

Renders the "⋯" button and its menu.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` (required) | `:string` |  | The accessible name of the "⋯" button. |
| `placement` | `:string` | `"bottom-end"` | `bottom-start`, `bottom-end`, `top-start`, `top-end` — Where the menu opens, flipping when there is no room. |
| `class` | `:any` | `nil` | Merged into the menu box (`w-64`...). |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required) — `action_menu_item`s and `action_menu_separator`s.
- `<:title>` — A header with the name of the item the actions belong to.

### `<.action_menu_item>`

An item of the menu: a link with `href`, `navigate` or `patch`, a button otherwise (`phx-click`...).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `icon` | `:string` | `nil` | A Hugeicons name (`huge-delete-02`) drawn before the text. |
| `kbd` | `:string` | `nil` | A shortcut shown at the end, as text only: it binds no key. |
| `hint` | `:string` | `nil` | A second, smaller line, for the reason an item is disabled. |
| `danger` | `:boolean` | `false` |  |
| `disabled` | `:boolean` | `false` |  |
| `type` | `:string` | `"button"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `replace`, `download`, `target`, `rel`, `hreflang`, `referrerpolicy`, `form`, `name`, `value`.

Slots:

- `<:inner_block>` (required)

### `<.action_menu_separator>`

The line between two groups of items.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.action_button>`

A direct button for an item that has a single action, in place of an `action_menu/1`. It is a
`LedgerUI.Components.Button` (a link with `href`, `navigate` or `patch`) at the "⋯" button's size: an icon
button by default, or a text button when it has an inner block.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  | The accessible name (`aria-label`). |
| `icon` | `:string` | `nil` | A Hugeicons name (`huge-delete-02`). |
| `danger` | `:boolean` | `false` | Paints it in the error color. |
| `variant` | `:string` | `"outline"` | `solid`, `glow`, `outline`, `soft`, `bordered`, `flat`, `glass`, `ghost`, `dim` |
| `size` | `:string` | `"sm"` | `xs`, `sm`, `md`, `lg`, `xl` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`, `target`, `rel`, `form`, `name`, `value`, `disabled`.

Slots:

- `<:inner_block>` — A text for the button; without it the button holds only the `icon`.
