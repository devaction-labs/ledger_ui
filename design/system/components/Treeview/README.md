# Treeview

Hierarquia navegável (pastas, contas, departamentos).

**Grupo:** 06 · Exibição  
**Resumo visual:** variant canvas · lineone · checked true/false/mixed · expansão

## Uso (Phoenix / HEEx)

```heex
<.tree items={@folders} selected={@current} />
```

## Regras

- Indente 18px por nível; contagem em mono à direita.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: treeview)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's tree view: a hierarchical list whose branches expand and collapse.

    <.treeview id="files">
      <.tree_item id="app" label="Application" expanded>
        <.tree_item label="Chrome" />
        <.tree_item label="VS Code" />
      </.tree_item>
      <.tree_item id="docs" label="Document">
        <.tree_item label="React App" />
      </.tree_item>
    </.treeview>

An item with children is a branch (a native `<details>`), one without is a leaf. Give an
item an `:icon` slot and it takes Ledger UI's "advanced" look (folder icons, darker text):

    <.tree_item label="Design">
      <:icon><svg class="size-6 text-warning">…</svg></:icon>
      <.tree_item label="Web Apps"><:icon>…</:icon></.tree_item>
    </.tree_item>

### State

A branch opens from its `expanded` attr, or from the treeview's `expanded` list of item ids,
and toggles in the browser without a round trip. A branch the person toggled stays that way
across patches; when the server changes `expanded` for it, the server wins.

### Events

`on_toggle` runs when the person opens or closes a branch, `on_select` when they click a
leaf (or press Enter on it). See `treeview/1` for the payloads.

### The canvas look

`variant="canvas"` (the default; `variant="lineone"` is the old Ledger UI tree) draws the Signetum canvas tree: rows padded 6px 8px (8px corners, 2px apart; 36px with a boxed icon) in regular weight and the
ink, the top level in 550, a 14px chevron, the selected row tinted with the accent from the row's start (the
depth is a left padding inside the row) and boxed icons:

    <.treeview id="notas" variant="canvas">
      <.tree_item id="2026" label="Notas 2026" expanded>
        <:icon><.icon name="huge-layers-01" boxed box_size="sm" class="size-3.5" /></:icon>
        <.tree_item id="out" label="Outubro" branch />
        <.tree_item id="nfe" label="NF-e 48.211.xml" selected />
      </.tree_item>
    </.treeview>

`branch` draws an item as a closed branch before its children are there (loaded when it opens).
`checked` (`true`, `false` or `"mixed"`) puts a checkbox before the label and sets `aria-checked`; a click on
it pushes the treeview's `on_check`. `chevrons={false}` leaves the chevrons out, for a checklist of categories.

### Streams

    <.treeview id="files" rows={@streams.files}>
      <:row :let={{_dom_id, file}}>
        <.tree_item tag="div" id={"file-#{file.id}"} label={file.name} />
      </:row>
    </.treeview>

### `<.treeview>`

Renders the tree's root list.

`on_toggle` (an event name or a `%JS{}`) is pushed with `%{"id" => item_id, "expanded" => boolean}`
when the person opens or closes a branch. `on_select` is pushed with `%{"id" => item_id}` when a
leaf is clicked or gets Enter. Both go to `target` when given; a `%JS{}` is executed instead.

    <.treeview id="files" expanded={@open_ids} on_toggle="toggled" on_select="opened">
      <.tree_item id="src" label="src">
        <.tree_item id="src/app.ex" label="app.ex" />
      </.tree_item>
    </.treeview>

    def handle_event("toggled", %{"id" => id, "expanded" => open?}, socket), do: ...
    def handle_event("opened", %{"id" => id}, socket), do: ...

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `expanded` | `:list` | `[]` | Ids of the branches that are open, in addition to each item's own `expanded`. |
| `on_toggle` | `:any` | `nil` | Event name or `%JS{}`; pushed with `%{"id" => id, "expanded" => boolean}`. |
| `on_select` | `:any` | `nil` | Event name or `%JS{}`; pushed with `%{"id" => id}` when a leaf is picked. |
| `on_check` | `:any` | `nil` | Event name or `%JS{}`; pushed with `%{"id" => id, "checked" => boolean}` (the new state) when an item's checkbox is clicked. |
| `variant` | `:string` | `"canvas"` | `canvas`, `lineone` — `canvas` (the default) is the Signetum canvas tree (see "The canvas look"); `lineone` is the old Ledger UI tree. |
| `chevrons` | `:boolean` | `true` | `false` leaves out the chevrons and their space (a checklist of categories). |
| `target` | `:any` | `nil` | The `phx-target` the events go to. |
| `rows` | `:list` | `nil` | A list or a stream (`@streams.x`) rendered by `:row`. |
| `row_id` | `:any` | `nil` | A function giving each row's DOM id (streams give it). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`
- `<:row>` — Renders one row; takes the row (`{dom_id, item}` for a stream).

### `<.tree_item>`

Renders one item: a branch when it has children, a leaf when it does not.

`id` names the item in events and in the treeview's `expanded` list. Without one the item
renders no DOM id at all (a generated id would change on every render and the browser would
replace the element, losing what the person opened) and the hook names it by its position in
the tree, such as `tree-item-0.1.2`, in the events and for its own state. Items that appear,
disappear or move among their siblings change that name, so give an `id` to any item whose
state matters to the server (`expanded`, `on_toggle`, `on_check`). `tag="div"` renders it
without its own `<li>`, for a treeview `:row` that already sits in one.

    <.tree_item id="design" label="Design" expanded>
      <:icon><svg class="size-6 text-warning">…</svg></:icon>
      <.tree_item id="web" label="Web Apps" />
    </.tree_item>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | Names the item in events and in `expanded`. |
| `label` | `:string` | `nil` |  |
| `expanded` | `:boolean` | `false` | Whether the branch is open (server state). |
| `selected` | `:boolean` | `false` | Marks the item as the chosen one: `aria-selected` and a tinted header. |
| `branch` | `:boolean` | `false` | Draws the item as a branch (a chevron that opens it) even with no children yet. |
| `checked` | `:any` | `nil` | ``, `true`, `false`, `mixed` — A checkbox before the label (`"mixed"` for a branch partly checked); `nil` shows none. |
| `tag` | `:string` | `"li"` | `li`, `div` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — An icon before the label; switches to Ledger UI's advanced look.
- `<:inner_block>` — The children; makes the item a branch.
