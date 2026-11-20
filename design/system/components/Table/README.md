# Table

Tabela base: cabeçalho em caixa-alta `muted`, linhas com divisor de 1px e números alinhados à direita.

**Grupo:** 08 · Tabelas  
**Resumo visual:** variant basic · bordered · hoverable · zebra · grid · data · data-grid · rounded row/top/none · sort asc/desc · align

## Uso (Phoenix / HEEx)

```heex
<.table id="accounts" rows={@accounts}>
  <:col :let={a} label="Conta">{a.name}</:col>
</.table>
```

## Regras

- Números e moeda à direita em tabulares; texto à esquerda.
- Hover em `bg-hover`; selecionada em `accent-soft`.
- Densidade `dense` (8px) para listas longas.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: table)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's tables: basic, bordered, hoverable, zebra and the grid look, with `:col` slots
the way Phoenix's generated `CoreComponents.table/1` takes them.

    <.table id="users" rows={@users}>
      <:col :let={user} label="Name">{user.name}</:col>
      <:col :let={user} label="Job">{user.job}</:col>
    </.table>

    <.table id="users" rows={@streams.users} variant="hoverable" row_click={&JS.navigate(~p"/users/#{elem(&1, 1)}")}>
      <:col :let={{_id, user}} label="Name">{user.name}</:col>
      <:action :let={{_id, user}}><.button size="xs">Edit</.button></:action>
    </.table>

`variant="hoverable"` and `"zebra"` draw the filled header; `rounded` picks its corners:
`row` rounds both ends of the header row (a table inside a padded card), `top` only the
top corners (a table that is the top of a card) and `none` keeps it square (full width).

Sortable headers: give a column `sort_key` and the table `on_sort`; the header becomes a
button that sends `on_sort` with `%{"column" => sort_key, "direction" => "asc" | "desc"}`,
the direction being the one to sort by next. `sort_by` and `sort_dir` mark the current order.

    <.table id="t" rows={@rows} on_sort="sort" sort_by={@sort_by} sort_dir={@sort_dir}>
      <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
    </.table>

Row selection: `on_select` adds a checkbox column. Each checkbox sends `on_select` with
`%{"id" => key, "selected" => "true" | "false"}` (the new state of that row); the header one
sends `on_select_all` with `%{"selected" => "true" | "false"}`. `selected` is the list of keys
checked. The key is `row_key.(row)`, or the row's DOM id when `row_key` is not given; keys
are compared as given, so pass strings or convert the `"id"` back.

Density and chrome: `compact` tightens the cell padding, `borderless` drops the row rules (and
the cell borders of `bordered`), `headless` leaves out the `<thead>` altogether. A column's
`align` (`left`, `center`, `right`) aligns its header and cells.

    <.table id="stats" rows={@rows} compact borderless headless>
      <:col :let={row}>{row.label}</:col>
      <:col :let={row} align="right">{row.count}</:col>
    </.table>

Every event attr takes an event name or a `%JS{}`; `target` sets `phx-target`.

Expandable rows: an `:expand` slot adds a last column with a chevron that shows a detail
row under each row (`expand_label` names that column). The slot receives
`%{row: row, toggle: js}`, `toggle` being the `JS` that opens and closes it. Expandable
rows render one `<tbody>` per row, so they take a list, not a stream.

Per-row markup: `row_class` and `row_attrs` are functions of the row giving extra classes
and attributes (`phx-click`, `data-*`) of its `<tr>`; `:foot` cells make a totals row in a
`<tfoot>`; `sticky_header` pins the header inside a height-bound wrapper.

### Columns leave by priority

A `:col` takes a `priority`: `0` (default) always stays; `1`, `2` and `3` leave, in this order, when the
table's own box (a container query, not the window) gets narrower than 720px, 560px and 420px. The header, the
cells and the `:foot` cell of the same priority go together, so a wide table fits a narrow column without a
horizontal scroll. Mark the `:foot` cells like the columns they sit under (a `colspan` is the app's own, so
give it the span of what stays). Tables without a priority are not touched.

    <.table id="people" rows={@people}>
      <:col :let={p} label="Name">{p.name}</:col>
      <:col :let={p} label="Owner" priority={2}>{p.owner}</:col>
      <:col :let={p} label="Status" priority={1}>{p.status}</:col>
      <:col :let={p} label="Team"><.avatar src={p.photo} class="table-narrow-hide" /> {p.team}</:col>
    </.table>

The class `table-narrow-hide` hides what carries it (an avatar, an icon) when the box is narrower than 420px.
The wrapper becomes the container only when some column has a priority; a hand-written table sets
`container` and marks its `:col` and `:cell` entries (and `table_cell/1`) with `priority` itself.
What left is not shown anywhere else: use `expand` or a `row_click` to open the record, or turn on `peek`.

### Peek at what left

`peek` makes a row show a small panel with `label: value` of each column the box has hidden, while the row is
hovered or has the keyboard focus (the row gets `tabindex="0"`; on touch, the first tap focuses it). The values
come from the same `:col` render, so custom cell content works, and the `label` is the caption. The panel is
in the DOM next to the first column that always stays, is a `role="group"` named by `peek_label`, and is drawn
only while some column is actually hidden, so a wide table shows none. It opens upward for the last rows.
Nothing changes without `peek`, or when no `:col` has a priority. Hand-written tables have no `peek`.

    <.table id="people" rows={@people} peek peek_label="More about this person">
      <:col :let={p} label="Name">{p.name}</:col>
      <:col :let={p} label="Owner" priority={2}>{p.owner}</:col>
    </.table>

### Hand-written tables

Without `rows`, the table renders its inner block and its cells take the look of `variant`,
`rounded`, `compact`, `borderless` and `sticky_header` from it, so rows can carry any markup:
per-row attributes, colspans, detail rows, a totals footer.

    <.table id="orders" variant="hoverable" rounded="top" class="min-w-[760px]">
      <.table_head on_sort="sort" sort_by={@sort_by} sort_dir={@sort_dir}
        on_select_all="select_all" all_selected={@all?} some_selected={@some?}>
        <:col sort_key="number">Number</:col>
        <:col align="right">Total</:col>
      </.table_head>
      <.table_body id="orders-body" phx-update="stream">
        <.table_row :for={{id, o} <- @streams.orders} id={id} on_click="open" phx-value-id={o.id}
          selected={o.id in @selected} on_select="select" select_value={o.id}>
          <:cell>{o.number}</:cell>
          <:cell align="right">{o.total}</:cell>
        </.table_row>
        <.table_empty id="orders-empty">No orders.</.table_empty>
      </.table_body>
      <.table_foot><:cell>Total</:cell><:cell align="right">{@sum}</:cell></.table_foot>
    </.table>

`table_cell/1`, `table_checkbox/1`, `table_expand_toggle/1` and `table_detail_row/1` cover
free cells, custom checkboxes and expandable rows; `table_skeleton/1` is the loading state.
A class given to a cell always wins over the table's look (the look lives in the CSS
`components` layer).

Inside a card, `bleed` runs the table edge to edge: the wrapper cancels the padding of the
card's body (or of the card) as a negative margin and the first and last cells get it back as
their own padding, so the rows (hover, zebra, rules) reach the card's sides while the content
stays aligned with the rest of the card. As the only thing in a body it also reaches the
body's top and bottom and follows its rounded corners. The `bordered` frame is dropped.

    <.card>
      <.card_header><.card_heading>Team</.card_heading></.card_header>
      <.table id="team" rows={@team} bleed>
        <:col :let={person} label="Name">{person.name}</:col>
      </.table>
    </.card>

### `<.table>`

Renders a table of `rows` (a list or a stream), one column per `:col` slot.

    <.table id="people" rows={@streams.people} variant="zebra">
      <:col :let={{_id, person}} label="Name">{person.name}</:col>
      <:col :let={{_id, person}} label="Job">{person.job}</:col>
      <:action :let={{_id, person}}>
        <.button size="xs" phx-click="edit" phx-value-id={person.id}>Edit</.button>
      </:action>
    </.table>

Events (each an event name or a `%JS{}`, sent to `target` when given):

* `on_sort` — a sortable header was clicked:
  `%{"column" => sort_key, "direction" => "asc" | "desc"}` (the direction to sort by next).
* `on_select` — a row checkbox: `%{"id" => key, "selected" => "true" | "false"}`.
* `on_select_all` — the header checkbox: `%{"selected" => "true" | "false"}`.

With a stream, `selected` only reaches the rows the server re-renders: `stream_insert` the
rows whose selection changed, and give `all_selected` for the header checkbox.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `rows` | `:any` | `nil` | A list or a `@streams.x` stream. Leave it out to write the table by hand with `table_head/1`, `table_body/1` and `table_row/1`. |
| `row_id` | `:any` | `nil` | A function giving each row's DOM id. Streams default to the stream id. |
| `row_click` | `:any` | `nil` | A function of the row returning a `JS` or an event; `nil` for a row that does nothing. |
| `row_class` | `:any` | `nil` | A function of the row returning extra classes of its `<tr>`. |
| `row_attrs` | `:any` | `nil` | A function of the row returning a map of extra attributes of its `<tr>` (`phx-click`, `data-*`...). |
| `row_item` | `:any` | `&Function.identity/1` | Maps each row before it is given to the slots. |
| `row_key` | `:any` | `nil` | A function giving the selection key of a row. Defaults to the row's DOM id. |
| `variant` | `:string` | `"basic"` | `basic`, `bordered`, `hoverable`, `zebra`, `grid`, `data`, `data-grid` — `grid` is the gridjs look of Ledger UI's Grid Table page; `data` and `data-grid` are the lean look of `data_table/1` (40px headers, 48px rows, 13.5px text). |
| `rounded` | `:string` | `"row"` | `row`, `top`, `none` — Corners of the filled header of `hoverable` and `zebra`. |
| `sort_by` | `:string` | `nil` | The `sort_key` of the sorted column. |
| `sort_dir` | `:string` | `"asc"` | `asc`, `desc` — Direction of `sort_by`. |
| `on_sort` | `:any` | `nil` | Event sent when a sortable header is clicked. |
| `on_select` | `:any` | `nil` | Event sent when a row checkbox is clicked. |
| `on_select_all` | `:any` | `nil` | Event sent by the header checkbox. |
| `selected` | `:list` | `[]` | The keys of the selected rows. |
| `all_selected` | `:boolean` | `nil` | Whether the header checkbox is checked. Computed for lists; give it for streams. |
| `hoverable` | `:boolean` | `nil` | Highlights the hovered row. Defaults to the variant's own behavior. |
| `compact` | `:boolean` | `false` | Tighter cells: `px-3 py-2` instead of the variant's padding. |
| `headless` | `:boolean` | `false` | Renders no `<thead>` at all (not hidden columns), for list-like tables. |
| `sticky_header` | `:boolean` | `false` | Keeps the header row at the top while the body scrolls. The wrapper is the scroll container, so bound its height with `wrapper_class` (`max-h-96`). |
| `borderless` | `:boolean` | `false` | Removes the rules between rows, and the cell borders of the `bordered` variant. |
| `bleed` | `:boolean` | `false` | Runs the table edge to edge of the card it sits in (the body's padding as a negative margin, given back to the first and last cells), and to the top and bottom of the body when it is the only thing in it. |
| `container` | `:boolean` | `nil` | Makes the wrapper a container for columns that leave by priority. Automatic when a `:col` has a `priority`; set it on a hand-written table. |
| `peek` | `:boolean` | `false` | Rows show a panel with the label and value of the columns hidden by `priority`, on hover and keyboard focus. See "Peek at what left". |
| `peek_label` | `:string` | `"Hidden columns"` | `aria-label` of the `peek` panel. |
| `target` | `:any` | `nil` | `phx-target` of the events. |
| `expand_label` | `:string` | `nil` | Header of the expand column. |
| `scroll_label` | `:string` | `nil` | Names the scrolling wrapper (`role="region"` and `aria-label`) and makes it focusable, so a keyboard can scroll a height-bound or wide table. |
| `sort_label` | `:string` | `nil` | `aria-label` of the sort buttons: a prefix ("Sort by" gives "Sort by Order") or a template with `%{label}` for the column's label; without it the button is named by its text. |
| `row_label` | `:any` | `nil` | A function of the row (after `row_item`) returning the `aria-label` of its selection checkbox ("Select order #2481"); "Select row" when not given. |
| `select_all_label` | `:string` | `"Select all rows"` | `aria-label` of the header checkbox. |
| `select_label` | `:string` | `"Select row"` | `aria-label` of each row checkbox, unless `row_label` is given. |
| `wrapper_class` | `:any` | `nil` | Classes of the scrolling wrapper. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — Cells appended to every row, after the columns.
- `<:col>` — attrs: `label`, `class`, `head_class`, `align`, `sort_key`, `priority` — A column; receives the row (after `row_item`).
- `<:empty>` — Shown in a full-width row when there are no rows (a stream shows it whenever its body is empty).
- `<:expand>` — Detail shown under a row; receives `%{row: row, toggle: js}`.
- `<:foot>` — attrs: `class`, `align`, `colspan`, `priority` — A cell of the `<tfoot>` row, for totals; one entry per cell.
- `<:inner_block>` — The hand-written table (`table_head/1`, `table_body/1`, `table_foot/1`) when `rows` is not given.

### `<.table_head>`

The `<thead>` of a hand-written table: one header cell per `:col`, after an optional
select-all checkbox. Takes the look (`variant`, `compact`, `sticky_header`) from the
`table/1` around it.

    <.table id="orders" variant="hoverable" rounded="top">
      <.table_head on_sort="sort" sort_by={@sort_by} sort_dir={@sort_dir}>
        <:col sort_key="number">Number</:col>
        <:col>Customer</:col>
        <:col align="right" class="w-32">Total</:col>
      </.table_head>
      <.table_body id="orders-body" phx-update="stream">
        ...
      </.table_body>
    </.table>

Events (each an event name or a `%JS{}`, sent to `target` when given):

* `on_sort` — a header with `sort_key` was clicked:
  `%{"column" => sort_key, "direction" => "asc" | "desc"}` (the direction to sort by next).
  The header cell carries `aria-sort` (`ascending`, `descending` or `none`).
* `on_select_all` — the header checkbox: `%{"selected" => "true" | "false"}`, the state to
  move every row to. `all_selected` checks it and `some_selected` draws it indeterminate.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `sort_by` | `:string` | `nil` | The `sort_key` of the sorted column. |
| `sort_dir` | `:string` | `"asc"` | `asc`, `desc` — Direction of `sort_by`. |
| `on_sort` | `:any` | `nil` | Event sent when a sortable header is clicked. |
| `on_select_all` | `:any` | `nil` | Adds a select-all checkbox cell first; the event it sends. |
| `all_selected` | `:boolean` | `false` | Whether every row is selected. |
| `some_selected` | `:boolean` | `false` | Whether some rows are selected; with `all_selected` false the box is indeterminate. |
| `select_all_id` | `:string` | `nil` | Id of the select-all checkbox (its hook needs one). Defaults to the `<thead>` `id` + `-select-all`; a random one is generated when neither is given (it then changes on every render, so give an `id`). |
| `select_all_label` | `:string` | `"Select all rows"` |  |
| `sort_label` | `:string` | `nil` | `aria-label` of a sortable header, `%{label}` being its `label`; none by default. |
| `target` | `:any` | `nil` | `phx-target` of the events. |
| `class` | `:any` | `nil` | Classes of the `<tr>`. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:col>` — A header cell; its content is the label (or give `label`). Takes `label` (text when the slot has no content), `class`, `align` (`left center right`), `colspan`, `priority` and `sort_key` (makes it sortable; sent as `"column"` in `on_sort`). Any other attribute (`id`, `data-*`, `phx-*`, `title`, `aria-*`) lands on the `<th>`.
- `<:inner_block>` — Extra `<th>` cells after the columns, or further header rows.

### `<.table_body>`

The `<tbody>` of a hand-written table. Attributes pass through, so a stream is
`id` plus `phx-update="stream"`, each row taking its stream DOM id.

    <.table_body id="orders-body" phx-update="stream">
      <.table_row :for={{dom_id, order} <- @streams.orders} id={dom_id}>
        <:cell>{order.number}</:cell>
      </.table_row>
      <.table_empty id="orders-empty">No orders yet.</.table_empty>
    </.table_body>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.table_row>`

A row of a hand-written table: one `<td>` per `:cell`, then the inner content (free `<td>`s
or `table_cell/1`). Any attribute (`id`, `phx-click`, `phx-value-*`, `data-*`) lands on the
`<tr>`.

    <.table_row
      :for={{dom_id, order} <- @streams.orders}
      id={dom_id}
      selected={order.id in @selected}
      on_select="select"
      select_value={order.id}
      on_click={JS.patch(~p"/orders/#{order.id}")}
      class={order.canceled && "opacity-60"}
    >
      <:cell class="font-medium">{order.number}</:cell>
      <:cell colspan="2">{order.customer}</:cell>
      <:cell align="right">{order.total}</:cell>
    </.table_row>

Events (each an event name or a `%JS{}`, sent to `target` when given):

* `on_click` — the row was clicked; `phx-value-*` attributes ride along.
* `on_select` — adds a checkbox cell first; clicking it sends
  `%{"id" => select_value, "selected" => "true" | "false"}` (the row's new state).

`selected` checks the box and marks the row (`data-selected`, a tinted background with a
primary bar on its first cell).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `selected` | `:boolean` | `nil` | Whether the row is selected. `nil` leaves the row unmarked. |
| `on_click` | `:any` | `nil` | Event or `%JS{}` run when the row is clicked. |
| `on_select` | `:any` | `nil` | Adds a selection checkbox cell first; the event it sends. |
| `select_value` | `:any` | `nil` | Sent as `"id"` by the checkbox. |
| `select_label` | `:string` | `"Select row"` |  |
| `target` | `:any` | `nil` | `phx-target` of the events. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:cell>` — A `<td>` of the row. Takes `class`, `align` (`left center right`), `colspan`, `rowspan` and `priority`; any other attribute (`id`, `data-*`, `phx-*`, `title`, `aria-*`) lands on the `<td>`.
- `<:inner_block>` — Free cells after the `:cell` ones.

### `<.table_cell>`

A cell of a hand-written table, for rows written with free markup: `<td>`, or `<th>` with
`header` (a row header, `scope="row"`).

    <.table_row id="total">
      <.table_cell colspan="3" align="right">Total</.table_cell>
      <.table_cell align="right">{@total}</.table_cell>
    </.table_row>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `header` | `:boolean` | `false` | Renders a `<th scope="row">`. |
| `align` | `:string` | `nil` | ``, `left`, `center`, `right` |
| `colspan` | `:any` | `nil` |  |
| `rowspan` | `:any` | `nil` |  |
| `priority` | `:integer` | `nil` | See "Columns leave by priority" in `table/1`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`

### `<.table_foot>`

The `<tfoot>` of a hand-written table, for totals: one row of `:cell`s in bold over a rule,
then any free rows.

    <.table_foot>
      <:cell colspan="3">Total</:cell>
      <:cell align="right">{@total}</:cell>
    </.table_foot>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` | Classes of the `:cell` row. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:cell>` — A `<td>` of the totals row. Takes `class`, `align` (`left center right`), `colspan` and `priority`; any other attribute (`id`, `data-*`, `phx-*`, `title`, `aria-*`) lands on the `<td>`.
- `<:inner_block>` — Free `<tr>` rows after the `:cell` row.

### `<.table_empty>`

The empty state of a hand-written table: a full-width row shown only when it is the only
row of its `<tbody>`, so it works for lists and streams alike (put it last in the body;
a stream needs its `id`).

    <.table_body id="orders-body" phx-update="stream">
      <.table_row :for={{id, order} <- @streams.orders} id={id}>...</.table_row>
      <.table_empty id="orders-empty">No orders in this filter.</.table_empty>
    </.table_body>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `class` | `:any` | `nil` | Classes of the cell. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.table_checkbox>`

The selection checkbox the table draws, for a header or row written by hand.
`indeterminate` draws the dash of a partial selection (it needs an `id`, for its hook).

    <.table_checkbox
      checked={row.id in @selected}
      on_click="select"
      values={%{"id" => row.id, "selected" => to_string(row.id not in @selected)}}
    />

`on_click` (an event name or a `%JS{}`) is sent with `values` as `phx-value-*`, to
`target` when given.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` |  |
| `checked` | `:boolean` | `false` |  |
| `indeterminate` | `:boolean` | `false` |  |
| `label` (required) | `:string` |  | The `aria-label` of the box. |
| `on_click` | `:any` | `nil` |  |
| `values` | `:map` | `%{}` | Sent as `phx-value-*` with `on_click`. |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.table_expand_toggle>`

The chevron button that opens and closes the detail row of the row with DOM id `row_id`,
for hand-written expandable rows (pair it with `table_detail_row/1`).

    <.table_row id={"order-#{order.id}"}>
      <:cell>{order.number}</:cell>
      <:cell><.table_expand_toggle row_id={"order-#{order.id}"} /></:cell>
    </.table_row>
    <.table_detail_row row_id={"order-#{order.id}"}>{order.notes}</.table_detail_row>

The toggle runs on the client (`table_toggle_row/2`); `open` sets the starting state.
Rows that come in pairs need a list, not a stream.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `row_id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` |  |
| `label` | `:string` | `"Toggle details"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.table_detail_row>`

The detail row under the row with DOM id `row_id`: one cell spanning every column,
hidden until `table_expand_toggle/1` (or `table_toggle_row/2`) opens it.

    <.table_detail_row row_id="order-1" class="bg-base-200">Notes...</.table_detail_row>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `row_id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` | Classes of the detail panel. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.table_skeleton>`

A table of placeholder rows shown while the real one loads, in the same look.

    <.table_skeleton id="orders-loading" columns={["Number", "Customer", "Total"]} rows={8} variant="hoverable" />
    <.table_skeleton id="loading" cols={4} compact />

`columns` gives the header labels; without them `cols` header cells are placeholders too.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `rows` | `:integer` | `5` | How many placeholder rows. |
| `columns` | `:list` | `[]` | Header labels; one column each. |
| `cols` | `:integer` | `4` | How many columns when `columns` is empty. |
| `variant` | `:string` | `"basic"` | `basic`, `bordered`, `hoverable`, `zebra`, `grid`, `data`, `data-grid` |
| `rounded` | `:string` | `"row"` | `row`, `top`, `none` |
| `compact` | `:boolean` | `false` |  |
| `headless` | `:boolean` | `false` |  |
| `shapes` | `:list` | `[]` | What each column's placeholders look like: `text` (a bar, the default), `avatar` (a disc and a bar), `pill` (a rounded tag) or `number` (a short bar at the right edge), one per column. |
| `label` | `:string` | `"Loading"` | The table's `aria-label`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
