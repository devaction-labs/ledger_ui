# Dropdown

Menu suspenso de escolhas a partir de um botão.

**Grupo:** 11 · Navegação  
**Resumo visual:** color (8) · toggle_icon dots/dots-vertical · shape rounded/pill/square · split · 12 posições · itens neutral/primary/error · media

## Uso (Phoenix / HEEx)

```heex
<.dropdown id="period"><:trigger>Oct 2026</:trigger><:item>…</:item></.dropdown>
```

## Regras

- Popover a 6px do gatilho, alinhado à esquerda; Esc fecha e devolve o foco.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: dropdown)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's dropdown menu: a white box under its button with links and actions, groups split by
separators, icons, a header, a search field, people.

    <.dropdown id="actions" label="Dropdown">
      <.dropdown_item href="#">Action</.dropdown_item>
      <.dropdown_item phx-click="archive">Archive</.dropdown_item>
      <.dropdown_separator />
      <.dropdown_item color="error" phx-click="delete">
        <:icon><svg>…</svg></:icon>
        Delete item
      </.dropdown_item>
    </.dropdown>

`toggle_icon` draws Ledger UI's flat icon button (10px corners) with the three dots (the menu of a card):

    <.dropdown id="card-menu" toggle_icon="dots" placement="bottom-end">
      <.dropdown_item href="#">Action</.dropdown_item>
    </.dropdown>

`label` draws Ledger UI's button with its turning chevron (`color` and `shape` style it); any
other trigger goes in the `:toggle` slot:

    <.dropdown id="more">
      <:toggle><.button icon variant="flat" aria-label="More">⋮</.button></:toggle>
      …
    </.dropdown>

An `:action` slot makes a split button: the slot is the main action (a button, or a link with
`href` / `navigate` / `patch`) and a square arrow button beside it opens the menu. Only the
arrow is the trigger, so keys and focus work as in any dropdown (Enter, Space or ↓ on the arrow
opens it); the menu opens under the arrow (`placement="bottom-end"` aligns it to the end of the group).

    <.dropdown id="save" color="mono" toggle_label="More options">
      <:action phx-click="save">Save</:action>
      <.dropdown_item phx-click="save_and_issue">Save and issue</.dropdown_item>
      <.dropdown_item phx-click="save_draft">Save as draft</.dropdown_item>
    </.dropdown>

A `dropdown_submenu` nests a menu that opens to the side, on hover, on click, or with → (←
or Esc goes back to its parent):

    <.dropdown id="row" toggle_icon="dots">
      <.dropdown_item phx-click="edit">Edit</.dropdown_item>
      <.dropdown_submenu label="Move to">
        <.dropdown_item phx-click="move" phx-value-to="archive">Archive</.dropdown_item>
        <.dropdown_item phx-click="move" phx-value-to="trash">Trash</.dropdown_item>
      </.dropdown_submenu>
    </.dropdown>

The menu floats above the page: opened, it sits in the browser's top layer (`popover="manual"`,
`position: fixed`, placed from the trigger's rectangle), so a table's horizontal scroll area, a
drawer's scrolling body or an ancestor's `z-index` / `transform` neither cut it off nor cover it,
and the "…" menu in the last column of a table opens whole. It follows the page and any box
around the trigger as they scroll, flips to the other side when there is no room, and closes
when its trigger scrolls out of sight. It stays in the LiveView's DOM where it was rendered, so
patches and `phx-click` on items work as usual. Without the Popover API (old browsers) it is a
fixed box on `--ledger-z-popover`.
### A filter menu

`dropdown_checkbox` and `dropdown_radio` are items that keep the menu open while they are toggled
(`menuitemcheckbox` and `menuitemradio`); a `dropdown_submenu` groups them and shows how many are
checked; `dropdown_footer` ends the menu with Clear / Apply. `keep_submenus` leaves an open submenu
open while the pointer moves elsewhere. Inside a form, an item with a `name` is a real (hidden) input, so
the form's `phx-change` hears every tick and `phx-submit` gets the checked ones:

    <.form for={@form} phx-change="filter" phx-submit="apply">
      <.dropdown id="filters" label="Filter" keep_submenus close_on_select={false}>
        <.dropdown_submenu label="Status">
          <.dropdown_checkbox
            :for={status <- @statuses}
            name="filter[status][]"
            value={status}
            checked={status in @filter.status}
            count={@counts[status]}
          >
            {status}
          </.dropdown_checkbox>
        </.dropdown_submenu>
        <.dropdown_separator />
        <.dropdown_label>Sort by</.dropdown_label>
        <.dropdown_radio name="filter[sort]" value="recent" checked={@filter.sort == "recent"}>
          Most recent
        </.dropdown_radio>
        <.dropdown_radio name="filter[sort]" value="value" checked={@filter.sort == "value"}>
          Highest value
        </.dropdown_radio>
        <.dropdown_footer locale="pt_BR" />
      </.dropdown>
    </.form>

Without a form, give an item `phx-click` and `phx-value-*`; the checked state is the item's `checked`
(the server wins when it changes it, a patch that did not change it keeps what was ticked in the browser).

A long menu scrolls inside a `scroll_area` (`LedgerUI.Components.ScrollArea`); keep submenus out
of a scrolling box inside the menu, which would clip them.

The keyboard works as in a menu (↑ ↓ Home End, letters, Esc, Tab). It opens and closes from
the browser (`LedgerUI.toggle("actions")`), from the server (`LedgerUI.close(socket, "actions")`)
or from `open`; `on_open` / `on_close` run whoever opened or closed it.

### `<.dropdown>`

Renders a dropdown menu.

Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` | `:string` | `nil` | Draws Ledger UI's dropdown button with this text. |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `mono` — The color of the `label` button, and of both halves of a split button (`mono` is the canvas's dark solid button). |
| `toggle_icon` | `:string` | `nil` | ``, `dots`, `dots-vertical` — Draws Ledger UI's flat icon-button trigger with three dots, horizontal (`dots`) or vertical (`dots-vertical`). It inherits the parent's text color and is `size-8` with 10px corners (the `pill` shape makes it round); `label` and the `:toggle` slot win over it. |
| `toggle_class` | `:any` | `nil` | Merged into the `toggle_icon` button (`-mr-2 size-7`...). |
| `toggle_label` | `:string` | `"Menu"` | The accessible name of the `toggle_icon` button. |
| `shape` | `:string` | `nil` | ``, `rounded`, `pill`, `square` — The shape of the trigger button. `nil` is `rounded` (10px corners) for both the `label` and the `toggle_icon` button; `pill` is opt-in. |
| `control` | `:boolean` | `false` | Opt-in: the `label` button, or both halves of a split button, take the height of the form controls of their size (`sm` 32px, `md` 36px, `lg` 48px), so a filter bar row lines up. See `button/1`. |
| `open` | `:boolean` | `false` |  |
| `hover` | `:boolean` | `false` | Opens when the pointer is over the trigger or the menu, and closes shortly after it leaves (a click still works). |
| `placement` | `:string` | `"bottom-start"` | `bottom-start`, `bottom`, `bottom-end`, `top-start`, `top`, `top-end`, `left-start`, `left`, `left-end`, `right-start`, `right`, `right-end` — Where the menu opens, from the trigger. A split button places it from the whole group (main action and arrow), so `bottom-start` aligns it with the main action. |
| `offset` | `:integer` | `4` | Pixels between the trigger and the menu. |
| `close_on_select` | `:boolean` | `true` |  |
| `keep_submenus` | `:boolean` | `false` | An open submenu stays open when the pointer moves to another item, until another submenu opens or the menu closes. |
| `on_open` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_close` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_open` / `on_close` events. |
| `class` | `:any` | `nil` | Merged into the menu box (`w-72`, `h-36 overflow-y-auto`...). |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — attrs: `href`, `navigate`, `patch`, `type`, `disabled`, `class`, `id`, `phx-click`, `phx-target`, `phx-value-id` — The main action of a split button; the arrow beside it (named by `toggle_label`) opens the menu.
- `<:inner_block>` (required)
- `<:toggle>` — A trigger of your own instead of the `label` button.

### `<.dropdown_item>`

An item of the menu: a link with `href`, `navigate` or `patch`, a button otherwise
(`phx-click`, `type="submit"`...). A link takes `target`, `rel`, `download`, `hreflang` and
`referrerpolicy`, so it can open in a new tab or download a file:

    <.dropdown_item href={@danfe_url} target="_blank" rel="noopener">Open DANFE</.dropdown_item>
    <.dropdown_item href={@xml_url} download="nfe.xml">Download XML</.dropdown_item>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `error` |
| `variant` | `:string` | `"default"` | `default`, `media` — `media` is the taller row Ledger UI uses for people (an avatar and two lines). |
| `disabled` | `:boolean` | `false` |  |
| `shortcut` | `:string` | `nil` | A keyboard hint at the end of the row, in mono text (`Ctrl E`). Text only: it binds no key. |
| `type` | `:string` | `"button"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `replace`, `download`, `target`, `rel`, `hreflang`, `referrerpolicy`, `form`, `name`, `value`.

Slots:

- `<:icon>` — Drawn before the text, as in Ledger UI's "Dropdown Icons".
- `<:inner_block>` (required)

### `<.dropdown_submenu>`

An item that opens a nested menu to its side, holding `dropdown_item`s (and separators,
headers, or further submenus). It opens when the pointer rests on it, on click, and with →,
Enter or Space, which also move the focus into it; ← and Esc close it and give the focus back.
It opens on the `placement` side, or the other one when the screen has no room there.

    <.dropdown_submenu label="Export">
      <:icon><.icon name="huge-download-04" class="size-4.5" /></:icon>
      <.dropdown_item phx-click="export" phx-value-format="csv">CSV</.dropdown_item>
      <.dropdown_item phx-click="export" phx-value-format="pdf">PDF</.dropdown_item>
    </.dropdown_submenu>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | Generated when not given. |
| `label` (required) | `:string` |  |  |
| `placement` | `:string` | `"right"` | `right`, `left` — The side it opens to, when there is room. |
| `disabled` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` | Merged into the nested menu box (`w-48`...). |
| `trigger_class` | `:any` | `nil` | Merged into the item that opens it. |
| `count` | `:integer` | `nil` | How many of its checkboxes are checked, in a round badge on the item; hidden at 0. The browser keeps it up to date as they are ticked. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — Drawn before the label.
- `<:inner_block>` (required)

### `<.dropdown_header>`

A title over the items, as in Ledger UI's "HTML Content" dropdown, with an optional small line under it.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `subtitle` | `:string` | `nil` | A second, smaller line (an e-mail, a role). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.dropdown_separator>`

The line between two groups of items.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.dropdown_search>`

The search field of the menu, an inset field (8px margins, 32px high, 6px radius) with Ledger UI's magnifier. Typing in it is not taken by the
menu's keys; `phx-change`, `phx-debounce` and `name` pass through.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `placeholder` | `:string` | `nil` |  |
| `name` | `:string` | `nil` |  |
| `value` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `phx-debounce`, `phx-throttle`, `autocomplete`, `form`.

### `<.dropdown_checkbox>`

A checkbox item (`menuitemcheckbox`). Choosing it flips it and leaves the menu open, for filters. With a
`name` it is a real input too (`value` is what a checked one submits), so a surrounding `phx-change`
hears it and `phx-submit` gets the checked ones; without one, give it `phx-click` and `phx-value-*`.

    <.dropdown_checkbox name="filter[status][]" value="paid" checked={"paid" in @status} count={3}>
      Paid
    </.dropdown_checkbox>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `checked` | `:boolean` | `false` | The checked state. The server wins when it changes it; a patch that did not change it keeps the browser's choice. |
| `name` | `:string` | `nil` | The name of the input the item submits as. |
| `value` | `:string` | `"true"` | What a checked item submits. |
| `id` | `:string` | `nil` | Of the input; derived from `name` and `value` when not given. |
| `count` | `:any` | `nil` | A muted number or text at the end (results for this option). |
| `disabled` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`.

Slots:

- `<:inner_block>` (required)

### `<.dropdown_radio>`

A radio item (`menuitemradio`): choosing it checks it and unchecks the other radios of its group (the ones
with the same `name` in the same menu). The menu stays open.

    <.dropdown_radio name="filter[sort]" value="recent" checked={@sort == "recent"}>Most recent</.dropdown_radio>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `checked` | `:boolean` | `false` | The checked state; as in `dropdown_checkbox/1`. |
| `name` | `:string` | `nil` | The group of the radio and the name of its input. |
| `value` | `:string` | `"true"` | What the checked radio submits. |
| `id` | `:string` | `nil` | Of the input; derived from `name` and `value` when not given. |
| `count` | `:any` | `nil` | A muted number or text at the end. |
| `disabled` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`.

Slots:

- `<:inner_block>` (required)

### `<.dropdown_label>`

A small caption over a group of items ("Sort by"), as in a filter menu.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.dropdown_footer>`

The end of a filter menu: a Clear button, which unchecks every checkbox item (and fires their `phx-change`),
and an Apply button, which closes the menu. Without `on_apply` the button submits the surrounding form;
with one it runs that event (or `%JS{}`) instead.

    <.dropdown_footer locale="pt_BR" apply_count={@pending} on_apply="apply_filters" />

The buttons are menu items, so the arrow keys reach them. `apply_color="mono"` makes Apply the solid black
button of the canvas's filter menus.

    <.dropdown_footer apply_color="mono" on_apply="apply_filters" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `locale` | `:string` | `"en"` | `en`, `pt_BR` |
| `clear_label` | `:string` | `nil` | "Clear" ("Limpar" in pt_BR) by default. |
| `apply_label` | `:string` | `nil` | "Apply" ("Aplicar" in pt_BR) by default. |
| `apply_count` | `:integer` | `nil` | Written after Apply as `Apply (3)`. |
| `on_clear` | `:any` | `nil` | An event name or a `%JS{}` run after the checkboxes are cleared. |
| `on_apply` | `:any` | `nil` | An event name or a `%JS{}`; without it Apply submits the form. |
| `close_on_apply` | `:boolean` | `true` |  |
| `apply_color` | `:string` | `"primary"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `mono` — The color of the Apply button; `mono` is the canvas's solid black (ink) button. Primary (teal) by default. |
| `show_apply` | `:boolean` | `true` | `false` leaves only Clear (a menu that applies as it is ticked). |
| `target` | `:any` | `nil` | The `phx-target` of `on_clear` and `on_apply` when they are event names. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
