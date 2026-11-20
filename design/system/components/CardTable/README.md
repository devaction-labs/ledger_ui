# CardTable

Tabela “em cartão” do segundo exemplo: bandeja arredondada, colunas mono para IDs e badges com contorno.

**Grupo:** 08 · Tabelas  
**Resumo visual:** variant rows · flat · prioridade de colunas p1–p4 · sub-linhas · ordenação

## Uso (Phoenix / HEEx)

```heex
<.card_table id="cases" rows={@cases}>…</.card_table>
```

## Regras

- Avatar `mono` de iniciais nas linhas; meta (idade/sexo) em mono `muted` ao lado do nome.
- Status e risco em badges `outline` com fundo tonal leve; Critical leva ponto.
- A bandeja (`lu-card`) dá a borda dupla arredondada sem pesar a tabela.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: card_table)

Todos os function components, atributos, valores e slots que este componente cobre.

A compact table: one row per record, in a card with a header row and a thin status bar at the left of each row. It is for long lists (orders, invoices, clients)
that must stay readable from a wide screen down to a phone, without a horizontal scroll.

    <.card_table id="orders" rows={@streams.orders} on_select="select" on_select_all="select_all" selected={@selected}
      status={&order_status/1}>
      <:col :let={o} label="Order" role="head" width="max-content">{o.number}</:col>
      <:col :let={o} label="Client" role="title" width="minmax(120px,1.3fr)">{o.client}</:col>
      <:col :let={o} label="Issuer" priority={2}>{o.issuer}</:col>
      <:col :let={o} label="Value" role="value" align="end">{o.total}</:col>
      <:col :let={o} label="Status" role="status"><.badge variant="soft" dot>{o.status}</.badge></:col>
      <:col :let={o} label="Balance" priority={1}>{o.balance}</:col>
      <:action :let={o}><.dropdown id={"actions-" <> o.id}>...</.dropdown></:action>
      <:empty>No orders.</:empty>
    </.card_table>

### Heading

`title`, `description` and `<:actions>` draw a heading above the table, so a list needs no card around it to
say what it is and how to add to it:

    <.card_table id="portal" rows={@users} title="Portal access" description="Who can see the orders." ...>
      <:actions><.button size="sm">Invite</.button></:actions>
      ...
    </.card_table>

    <.card_table id="orders" title="Pedidos" meta="128 no período" rows={@orders} ...>
      <:actions><.link navigate={~p"/orders"}>Ver todos</.link></:actions>
      ...
    </.card_table>

`meta` is a small muted text on the same line as the title, right after it. A plain link (or any `<a>`
with no class) in `<:actions>` is drawn quiet, in the same muted style, pushed to the right: the line reads
`Pedidos  128 no período ........................ Ver todos`. A `<.button>` keeps its own look.

### Footer

`<:foot>` is a line inside the card, under the rows, set off by a hairline: the place for the pager or a
total. Its content is laid out in a wrapping row with the parts spread to the two ends:

    <.card_table id="orders" rows={@orders} ...>
      <:col ...>...</:col>
      <:foot>
        <span>Mostrando 1–6 de 128 · 25 / página</span>
        <.pagination ... />
      </:foot>
    </.card_table>

### Columns leave by priority

The table answers to the width of its own box, not of the window (a container query), so it behaves the same
in a narrow column or beside a sidebar. A column has a `priority`: `0` (default) always stays; `1`, `2` and `3`
leave, in this order, when the box gets narrower than 1180px, 960px and 720px. What left is not lost: hovering a row (or
tabbing to it) opens a panel under it with the label and the value of every column that is hidden.

`breakpoints` changes those widths: one integer (px) per priority level, in descending order, and the width of
the card layout last. The default is `[1180, 960, 720, 520]`. A table with four priority levels, whose
card layout starts under 560px:

    <.card_table id="orders" breakpoints={[1180, 980, 760, 640, 560]} ...>
      <:col :let={o} label="Issuer" priority={4}>{o.issuer}</:col>

gives 1 under 1180px, 2 under 980px, 3 under 760px, 4 under 640px and the cards under 560px. Between 2 and 5 integers
(1 to 4 priority levels), strictly descending; anything else raises `ArgumentError`. Container queries cannot read
CSS variables, so a table with other widths than the default renders a small `<style>` scoped to its own id (the same
every render, so nothing is sent again over the socket). A priority above the levels of the list never leaves.

Below 520px (the last of `breakpoints`) the table is one card with a compact two-line grid per row, a hairline
between rows, and the `role` of a column says where it goes: `head` (first line, left; drawn in mono), `status`
(first line, right), `title` (second line, left, up to two lines: a name and a sub line) and `value` (second
line, right). The checkbox, if any, sits at the left of both lines. A column with no `role` and `meta`
are not drawn in the card (the board has no third line) unless it asks to stay (`card`, see below). The action
column stays: it is drawn at the right of both lines, spanning them, so a row can still be edited or deleted on a
phone (`<:action card={false}>` hides it). The header row and the panel are not
drawn; "select all" is kept for screen readers and the keyboard only (a visually hidden checkbox that shows when
it has focus).

### Staying in the card

`card` on a column keeps it in the card when it has no role (or has `meta`): it is drawn in a line of its own under
the two lines, so a copyable address does not vanish. `<:action card={false}>` removes the action column from the card.

    <:col :let={a} label="Address" role="meta" card copy={& &1.address}>{a.address}</:col>

### Expanded and edited rows

`<:expand :let={row}>` is a full-width line under a row (lots of an item, the items of a contract), drawn inside the
row's `<li>` under the cells. `row_expanded` is a function of the row that says which rows show it (default: all,
when the slot is given). A click inside it also toggles the details panel of the row, so a table that uses
`expand` usually has no hidden columns (no `priority`) and no `detail`.

`row_editing` is a function of the row; when it returns true the row carries `data-editing="true"` and the `<:edit :let={row}>`
slot (an inline form) takes the place of its cells, across the full width. The checkbox stays; the action cell and the
panel are not drawn.

    <.card_table id="tasks" rows={@tasks} row_editing={&(&1.id == @editing)} row_expanded={&(&1.id in @open)}>
      <:col :let={t} label="Task" role="title">{t.name}</:col>
      <:edit :let={t}><.form for={@form} phx-submit="save">...</.form></:edit>
      <:expand :let={t}>{t.notes}</:expand>
    </.card_table>

`row_action` is a function of the row; a row for which it returns false has no action cell at all (the track stays
empty, the layout does not move).

### The details panel

Clicking a row (or tapping it) opens a panel under it with more than the row shows: a list of label and value, one
line each. Hovering never opens it. The panel's left edge sits at the click (16px to its left), kept 8px inside
both sides of the row, and it does not follow the pointer afterwards. The text of the panel can be selected and
copied, and a click inside it keeps it open. It closes on a second click on the row, on `Esc` (the focus goes back to the
row), on a click outside the table, and on a click on any control of the row (link, button, check box, copy button,
action menu), which does its own thing. A click on another row moves the panel there. From the keyboard, `Enter` or
`Space` on a focused row toggles it, at a fixed anchor (96px from the left of the row, 72px under 720px) since there is no pointer.
The row carries `aria-expanded` and `data-open` (which the CSS uses). The last two rows open it upwards. The
`CardTable` hook (`LedgerUI.CardTable`, on the rows' list) does this; without it the panel never opens.
Give `detail` slots (`<:detail :let={o} label="Due date">{o.due}</:detail>`) and the panel lists them first, in
the order given, at every width above 520px, then the columns that left at the current width (each shows only
once its priority has left; a column with the same label as a `detail` is not listed again). With no `detail`, the panel only has the columns that left. Below 520px there is no panel: the card shows what the roles place.

A column may have an empty `label` (a number or copy column with no header text), and `<:action priority={3}>`
makes the action column leave like a column of that priority.

### Copy button

`copy` on a column (a function of the row that returns the text) turns its cell into a copy button, as in the
order number of the design. Its tooltip shows the text it copies and, for two seconds after a copy, `copied_label`
(`copy_label` is the button's accessible name). The column's own content stays visible only in the card, where
there is no tooltip. The button shows a check while it says `copied_label` (two seconds).

`copy_show="inline"` keeps the column's own content visible before the button at every width, 8px apart
(`ORD-2041 [copy]`), instead of only in the card:

    <:col :let={o} label="Pedido" role="head" copy={& &1.number} copy_show="inline"
      copy_label="Copiar número">{o.number}</:col>

`copy_tip="value_label"` changes the tooltip to the value in bold mono, a dot, and the label in the text font:
`ORD-2041 · Copiar número`, and after the copy `ORD-2041 · Número copiado`:

    <:col :let={o} label="Pedido" role="head" copy={& &1.number} copy_tip="value_label"
      copy_label="Copiar número" copied_label="Número copiado">{o.number}</:col>

### Sub lines

`<.ctable_sub>` is a second line inside a cell (12px, faint) that leaves by its own `priority`, with the same
widths as the columns (default or custom `breakpoints`), while the cell stays. No priority: always shown. The
panel of a row lists whole columns, so a sub line inside a column that left is shown there.

    <:col :let={o} label="Cliente" role="title" width="minmax(120px,1.3fr)">
      {o.client}
      <.ctable_sub priority={2}>{o.issuer}</.ctable_sub>
    </:col>
    <:col :let={o} label="Valor" role="value" align="end">
      {o.total}
      <.ctable_sub priority={1}>saldo {o.balance} · {o.pending} pend.</.ctable_sub>
    </:col>

`when_hidden="p2"` is the inverse: the sub line shows only once the columns of priority 2 have left, so the data is not
shown twice on a wide screen (`p1` to `p4`). A `ctable_sub` inside a `role="head"` column is not drawn in mono in the card.

    <:col :let={o} label="Cliente" role="title">
      {o.client}
      <.ctable_sub when_hidden="p2">{o.issuer}</.ctable_sub>
    </:col>
    <:col :let={o} label="Emissor" priority={2}>{o.issuer}</:col>

### Columns

`width` is the CSS track of the column (`max-content` by default; `minmax(120px,1.3fr)` to let it take what is
left). `align` is `start` (default) or `end` (numbers). Text is cut with an ellipsis; `truncate={false}` lets
it wrap (in the card too: a `role="title"` is not cut at two lines then; with the default, even a `lu-cellx` of avatar and text ends in an ellipsis). `sort_key` with the table's `on_sort` makes the header a button, as in `table/1`.

### Rows

`rows` is a list or a stream. `status` is a function of the row that returns a color (`success`, `info`,
`warning`, `error`, `primary`...) for the thin bar at the left of the row, or `nil` for the neutral (input border) bar. `on_select`
adds a checkbox column (the events and keys work as in `table/1`: `selected`, `row_key`, `on_select_all`).
`row_attrs` gives extra attributes of a row (`phx-click`, `data-*`).

`<:foot>` and `<:empty>` receive a map (`:let={ctx}`) with `id`, `rows`, `selected` and `title` of the table, so
they can show a total or a message that depends on it: `<:foot :let={ctx}>{length(ctx.rows)} rows</:foot>` (the rows of
a stream are not enumerable; use your own assign there). Without `:let` the argument is ignored.

`bordered={false}` draws the table with no border, shadow or background of its own, to nest it in a card that has
other blocks (a chart and a table) without a double border.

### Flat

`variant="flat"` is the canvas card table: a plain table in a card (a kit CSS `card` and `table`), for
short lists on a dashboard ("Últimos pedidos", "Maiores clientes"). The `title` and `<:actions>` (a "Ver
todos" link, drawn quiet) head the card; `<:top>` takes the place of the heading (tabs that filter the
table). Columns keep `label`, `align` and `class`, and also take `priority`, `role` and `card`: a column leaves
at the default widths (1180, 960 and 720px, `breakpoints` is not read), and under 520px, when some column has a `role`,
each row becomes a card as in the default variant (`meta` too, and the action cell stays). The panel, the selection,
`expand` and `edit` belong to the default variant. `description` goes under the title and `<:foot>` under the table
(a "Total" line), as in the default variant.

    <.card_table id="last" variant="flat" title="Últimos pedidos" rows={@orders}>
      <:actions><.link navigate={~p"/orders"}>Ver todos</.link></:actions>
      <:col :let={o} label="Pedido">{o.number}</:col>
      <:col :let={o} label="Total" align="end">{o.total}</:col>
    </.card_table>

The filters above the table and the pager under it are not part of it: build them with `input`, `select`,
`button` and `pagination`, inside the same `card`.

### `<.card_table>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `rows` (required) | `:any` |  | A list or a `@streams.x` stream. |
| `row_id` | `:any` | `nil` | A function giving each row's DOM id. Streams default to the stream id. |
| `row_item` | `:any` | `&Function.identity/1` | Maps each row before it is given to the slots. |
| `row_key` | `:any` | `nil` | A function giving the selection key of a row. Defaults to the row's DOM id. |
| `row_attrs` | `:any` | `nil` | A function of the row returning a map of extra attributes of its `<li>`. |
| `status` | `:any` | `nil` | A function of the row returning a color for the bar at the row's left, or `nil`. |
| `on_select` | `:any` | `nil` | Event sent when a row checkbox is clicked. |
| `on_select_all` | `:any` | `nil` | Event sent by the header checkbox. |
| `selected` | `:list` | `[]` | The keys of the selected rows. |
| `all_selected` | `:boolean` | `nil` | Whether the header checkbox is checked. Computed for lists; give it for streams. |
| `select_all_label` | `:string` | `"Select all rows"` |  |
| `select_label` | `:string` | `"Select row"` |  |
| `panel_label` | `:string` | `"Details"` | The accessible name of the details panel. |
| `on_sort` | `:any` | `nil` | Event sent when a sortable header is clicked. |
| `sort_by` | `:string` | `nil` |  |
| `sort_dir` | `:string` | `"asc"` | `asc`, `desc` |
| `target` | `:any` | `nil` | `phx-target` of the events. |
| `title` | `:string` | `nil` | A heading drawn above the table, with `description` and `<:actions>`. |
| `description` | `:string` | `nil` | A line under the `title`. |
| `meta` | `:string` | `nil` | A small muted text on the same line as the `title`, right after it ("128 no período"). Default variant only. |
| `bordered` | `:boolean` | `true` | `false` draws the table with no border, shadow or background of its own, to nest it in a card that has other blocks. |
| `row_expanded` | `:any` | `nil` | A function of the row that says whether its `<:expand>` slot shows. Default: every row. Default variant only. |
| `row_editing` | `:any` | `nil` | A function of the row; true shows the `<:edit>` slot in place of the cells and sets `data-editing`. Default variant only. |
| `row_action` | `:any` | `nil` | A function of the row; false leaves the action cell of that row out. Default: every row has it. |
| `breakpoints` | `:list` | `[1180, 960, 720, 520]` | The widths (px) at which each priority level leaves, descending, and the width of the card layout last. 2 to 5 integers; `[1180, 980, 760, 640, 560]` gives priorities 1 to 4 and cards under 560px. Default variant only. |
| `variant` | `:string` | `"rows"` | `rows`, `flat` — `rows` (default) draws one row per record in a card; `flat` a plain table in a card, as the canvas. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — attrs: `priority`, `card` — The last cell of every row (a menu button); receives the row.
- `<:actions>` — Buttons at the right of the heading (`title`, `description`).
- `<:col>` (required) — attrs: `label`, `width`, `priority`, `role`, `align`, `truncate`, `class`, `sort_key`, `copy`, `copy_label`, `copied_label`, `copy_show`, `card`, `copy_tip` — A column; receives the row (after `row_item`).
- `<:detail>` — attrs: `label` — A line of the panel that opens when a row is clicked; receives the row. When given, the panel lists these and not the hidden columns.
- `<:edit>` — An inline form in place of the cells of a row for which `row_editing` is true; receives the row. Default variant only.
- `<:empty>` — Shown when there are no rows. Receives a map with `id`, `rows`, `selected` and `title`.
- `<:expand>` — A full-width line under a row (see `row_expanded`); receives the row. Default variant only.
- `<:foot>` — A line inside the card, under the rows, set off by a hairline (pagination, a total). Wraps, with its parts spread to both ends. Receives a map with `id`, `rows`, `selected` and `title`.
- `<:top>` — With `variant="flat"`, what heads the card instead of the title (tabs).

### `<.ctable_sub>`

A second line inside a `card_table` cell that leaves by `priority`. See the moduledoc.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `priority` | `:integer` | `nil` | 1 to 4: the sub line leaves at the width where the columns of that priority leave. |
| `when_hidden` | `:string` | `nil` | ``, `p1`, `p2`, `p3`, `p4` — The inverse of `priority`: the sub line shows only once the columns of that priority have left (`p2`: under 960px by default). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
