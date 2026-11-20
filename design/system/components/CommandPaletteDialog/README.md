# CommandPaletteDialog

Paleta de comandos global (⌘K) para navegar e executar ações.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** variant canvas · classic · highlight always/typed · grupos · atalhos

## Uso (Phoenix / HEEx)

```heex
<.command_palette id="cmdk" />
```

## Regras

- Grupos: Ir para, Ações, Contas. Item realçado em `bg-hover`.
- Rodapé com dicas de teclado.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: command_palette)

Todos os function components, atributos, valores e slots que este componente cobre.

A command palette: a dialog opened with Ctrl K (or `LedgerUI.open/1`) where the person types, narrows the
results by scope and jumps to a page or runs an action from the keyboard.

    <.command_palette
      id="palette"
      scopes={[{"All", "all"}, {"Pages", "pages"}, {"Actions", "actions"}, {"Recent", "recent"}]}
      items={[
        %{group: "Go to", scope: "pages", label: "Orders", sub: "Sales", icon: "huge-shopping-cart-01",
          navigate: ~p"/orders", keys: ["G", "O"]},
        %{group: "Actions", scope: "actions", label: "New order", sub: "Opens the order form",
          icon: "huge-add-01", value: "new-order", keys: ["N"]}
      ]}
      assistant={%{label: "Ask the assistant: “%{query}”", sub: "Answers with your company's data"}}
      on_select="palette-select"
      on_assistant="ask"
    />

    <.button phx-click={LedgerUI.open("palette")}>Search</.button>

Item and assistant `icon`s are Hugeicons names (`huge-*`), which need the Tailwind plugin of the Icons
section of the README; without `icon`, the item shows no icon and the assistant row a sparkle.

The palette is a modal, so `LedgerUI.open/close/toggle` (in the browser or from the server) and the `open`,
`on_open` and `on_close` attrs work as they do for `modal`. `shortcut` (Ctrl K / ⌘ K by default) toggles it from
anywhere in the page.

The input is a `role="combobox"` over a `role="listbox"`; the arrows move the active row (`aria-activedescendant`),
Enter presses it, Ctrl Enter opens it in a new tab and Esc closes the palette. The scope chips are toggle buttons
(`aria-pressed`): the first scope starts selected, the scope `"all"` keeps every item and any other keeps the items
whose `scope` is the same. Every time the palette opens it starts empty on its first scope.

The items are filtered in the browser, by label, `sub` and `keywords` ignoring case and accents. With `on_search`
the server filters instead: the query is pushed (debounced) and the palette shows the `items` it renders, still
narrowed by scope.

`variant="canvas"` (the default; `variant="classic"` is the old Ledger UI palette) is the design canvas look (the canvas menu: a 14px panel, 34px rows with muted icons, small
faint group headings, mono keys); `hints={false}` drops the keys footer and `highlight="typed"` leaves the rows
unmarked until something is typed (or an arrow or the mouse picks one), as the canvas shows its "recent" list.
An item's `avatar` (the attrs of `LedgerUI.Components.Avatar.avatar/1`) takes the place of its icon:

    <.command_palette
      id="search"
      variant="canvas"
      hints={false}
      highlight="typed"
      items={[%{group: "Clientes", label: "Casa das Tintas", avatar: %{initials: "CD", tint: "#d97a1e"}}]}
    />

### Your own icons

An item that has neither `icon` nor `avatar` can draw its own icon (an SVG of the design) through the
`:item_icon` slot, which receives each item's map as you gave it (so it can branch on a `kind` key of yours):

    <.command_palette id="search" items={@entries}>
      <:item_icon :let={item}>
        <.design_icon name={item.kind} />
      </:item_icon>
    </.command_palette>

### Filtering on the server

By default the palette filters its `items` in the browser. With `on_search` it does not filter at all: the
query (and the scope) is pushed to the server after `debounce` milliseconds, the server answers by assigning
its own entries to `items`, and the palette only narrows them by scope. This is the mode for a registry of
entries that lives in the app:

    <.command_palette id="search" items={@results} on_search="search" on_select="go" />

    def handle_event("search", %{"query" => query}, socket) do
      {:noreply, assign(socket, :results, Registry.search(query))}
    end

Choosing an item closes the palette and runs `on_select`. An item with `navigate`, `patch` or `href` is a real link
(so Ctrl Enter opens its address in a new window) and the navigation happens as for any link.

### `<.command_palette>`

Renders the palette, closed unless `open`.

Each of `items` is a map with `label` (required) and optionally `value` (what `on_select` receives, the label by
default), `sub` (the line under the label), `icon` (a `LedgerUI.Components.Icon.icon/1` name), `avatar` (a map of
`LedgerUI.Components.Avatar.avatar/1` attrs, drawn 24px and square in place of the icon), `keys` (a list of key
names shown on the right), `group` (the heading it is listed under; items without one are listed first, without a
heading), `scope`, `keywords` (more text the query matches) and one of `navigate`, `patch` or `href`.

`assistant` is a map with `label` (`%{query}` is replaced by what was typed), `sub` and `icon`: the row that offers
to ask the assistant. It shows when the query has no match, or whenever something is typed with
`assistant_mode="always"`.

Events (an event name or a `%JS{}`; a `%JS{}` push receives the same payload):

  * `on_select` - `%{"id" => palette id, "value" => item value, "new_tab" => boolean}`; `new_tab` is true after
    Ctrl Enter or a Ctrl/⌘ click.
  * `on_assistant` - `%{"id" => palette id, "query" => text typed}`.
  * `on_search` - an event name only; `%{"id" => palette id, "query" => text typed, "scope" => scope value}`, after
    `debounce` milliseconds.
  * `on_open` / `on_close` - `%{"id" => palette id}`, as for `modal`.

All go to `target` when given.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` | The server's state; the browser can still open and close it. |
| `label` | `:string` | `"Command palette"` | The accessible name of the dialog and of the list. |
| `placeholder` | `:string` | `"Search or type a command"` |  |
| `scopes` | `:list` | `[]` | The scope chips: strings, `{label, value}` tuples or maps with `:label` and `:value`. The first starts selected. |
| `scopes_label` | `:string` | `"Where to search"` | The accessible name of the chips. |
| `items` | `:list` | `[]` | The rows, see the function doc. |
| `empty` | `:string` | `"Nothing found"` | Shown when no item matches and there is no assistant row. |
| `assistant` | `:map` | `nil` | The assistant row: `label` (with `%{query}`), `sub` and `icon`. |
| `assistant_mode` | `:string` | `"no_match"` | `no_match`, `always` — `no_match` offers the assistant only when nothing matched; `always` whenever something is typed. |
| `on_select` | `:any` | `nil` | An event name or a `%JS{}`, run when an item is chosen. |
| `on_assistant` | `:any` | `nil` | An event name or a `%JS{}`, run when the assistant row is chosen. |
| `on_search` | `:string` | `nil` | An event name: the server filters the items. |
| `debounce` | `:integer` | `200` | Milliseconds between the last keystroke and the `on_search` push. |
| `query` | `:string` | `""` | The text the input holds every time the palette opens, narrowing the items. |
| `on_open` | `:any` | `nil` |  |
| `on_close` | `:any` | `nil` |  |
| `target` | `:any` | `nil` | The `phx-target` of every event. |
| `shortcut` | `:any` | `"Mod+k"` | The key that toggles the palette from anywhere: `Mod` is Ctrl or ⌘. `nil` leaves it to `LedgerUI.open/1`. |
| `variant` | `:string` | `"canvas"` | `canvas`, `classic` — `canvas` (the default): the design canvas menu look (34px rows, muted icons, faint headings, mono keys). |
| `hints` | `:boolean` | `true` | Shows the footer with the keys hints. |
| `highlight` | `:string` | `"always"` | `always`, `typed` — `always` marks the first row as active; `typed` only once something is typed or an arrow or the mouse picks a row. |
| `hint_navigate` | `:string` | `"Navigate"` |  |
| `hint_open` | `:string` | `"Open"` |  |
| `hint_new_tab` | `:string` | `"Open in new tab"` |  |
| `class` | `:any` | `nil` | Merged into the dialog card. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:footer>` — Content at the right end of the footer, e.g. a status line.
- `<:item_icon>` — Your own icon (an SVG) for the items without `icon` and `avatar`; receives each item's map with `:let`.
