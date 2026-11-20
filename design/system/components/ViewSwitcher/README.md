# ViewSwitcher

Alterna a forma de ver o mesmo conjunto de dados e acessa visões salvas.

**Grupo:** 11 · Navegação  
**Resumo visual:** segmentado com ícone · visões salvas · columns 1/2

## Uso (Phoenix / HEEx)

```heex
<.view_switcher views={~w(list board calendar)} current={@view} saved={@saved_views} />
```

## Regras

- Segmentado com ícone + rótulo; visões salvas num menu ao lado (como Board packs, Pro churn watch).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: view_switcher)

Todos os function components, atributos, valores e slots que este componente cobre.

The views of a collection (List, Board, Table…) as a row of tabs, with a "+ View" button whose menu offers
the views that can still be added: an icon tile, a name and a line of description each, in two columns. It
is the canvas's `ViewSwitcher`.

    <.view_switcher
      id="invoice-views"
      aria-label="Invoice views"
      value={@view}
      on_change="set_view"
      on_add="add_view"
      views={[
        %{label: "List", value: "list", icon: "huge-left-to-right-list-bullet"},
        %{label: "Board", value: "board", icon: "huge-kanban"}
      ]}
      options={[
        %{label: "Simple", value: "gallery", icon: "huge-grid-view", description: "Gallery view of invoices"},
        %{label: "Timeline", value: "timeline", icon: "huge-time-quarter-pass", description: "Timeline of invoices"},
        %{label: "Table", value: "table", icon: "huge-table-01", description: "Table view of invoices"}
      ]}
    />

### Views

`views` are the tabs: maps with `:label` and `:value`, and optionally `:icon` (a `huge-*` name), `:count`
and `:disabled`. The tab whose value is `value` is the chosen one. A tab is a button that sends `on_change`
with `%{"view" => value}`; a view with `:patch`, `:navigate` or `:href` is a link instead, and the chosen one
carries `aria-current="page"`:

    views={[
      %{label: "List", value: "list", patch: ~p"/invoices?view=list"},
      %{label: "Board", value: "board", patch: ~p"/invoices?view=board"}
    ]}

### The menu

`options` are the views on offer: maps with `:label` and `:value`, and optionally `:icon`, `:description`,
`:added` (a check at the end, for a view that is already a tab) and `:disabled`. Choosing one sends `on_add`
with `%{"view" => value}` and closes the menu. Without `options` there is no button. `add_label` and
`menu_title` are its texts and `columns` is `2` or `1`.

The menu is a `dropdown/1` (`id` is `"#{id}-add"`): it floats in the top layer, flips when there is no room,
works with ↑ ↓ Home End, letters and Esc, and closes with `LedgerUI.close(socket, "invoice-views-add")`.

### `<.view_switcher>`

Renders the tabs of the views and the menu that adds one.

Events: `on_change` and `on_add` receive `%{"view" => value}`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `value` | `:any` | `nil` | The value of the chosen view. |
| `views` | `:list` | `[]` | The tabs: maps with `:label` and `:value` (see the module doc). |
| `options` | `:list` | `[]` | The views the menu offers (see the module doc). |
| `on_change` | `:any` | `nil` | An event name or a `%JS{}`, run by a tab. |
| `on_add` | `:any` | `nil` | An event name or a `%JS{}`, run by an option of the menu. |
| `target` | `:any` | `nil` | The `phx-target` of both events. |
| `add_label` | `:string` | `"View"` |  |
| `menu_title` | `:string` | `"Add a new view"` |  |
| `columns` | `:integer` | `2` | `1`, `2` |
| `placement` | `:string` | `"bottom-start"` | Where the menu opens (as in `dropdown/1`). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
