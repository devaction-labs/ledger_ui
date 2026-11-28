defmodule LedgerUI.Components.Table do
  @moduledoc """
  Ledger UI's tables: basic, bordered, hoverable, zebra, the grid and the lean `data` looks, with
  `:col` slots the way Phoenix's generated `CoreComponents.table/1` takes them.

      <.table id="users" rows={@users}>
        <:col :let={user} label="Name">{user.name}</:col>
        <:col :let={user} label="Job" align="right">{user.job}</:col>
      </.table>

      <.table id="users" rows={@streams.users} variant="hoverable"
        row_click={fn {_id, user} -> JS.navigate(~p"/users/\#{user.id}") end}>
        <:col :let={{_id, user}} label="Name" sort_key="name">{user.name}</:col>
        <:action :let={{_id, user}}><.button size="sm">Edit</.button></:action>
      </.table>

  The markup is `div[data-part=table-wrap] > table[data-part=table]`, styled only with Tailwind
  utilities: the look of the table (`variant`, `compact`, `rounded`) is a set of local variables on
  the `<table>` (`--tpx`, `--td-py`, ...) that every cell reads, so the same cell classes serve the
  rows mode and the hand-written tables. `variant` is `nil` for the bare table; `rounded` (`row`,
  `top`) rounds the rows or the header row.

  A cell takes its text colour, weight and size from the utilities of its `class`
  (`<:col class="font-medium text-ink">`, `class="font-mono text-[13px]"`).

  In the rows mode the classes every cell shares (padding, borders, header type, background) are
  set once on the `<table>` with descendant selectors; a cell only carries what varies (alignment,
  `class`, priority, card role). The hand-written table keeps them on each cell.

  ## Events

  Every event attr takes an event name or a `%JS{}`; `target` sets `phx-target`.

    * `on_sort`: `%{"column" => sort_key, "direction" => "asc" | "desc"}` (the direction to sort
      by next). A column with `sort_key` gets `class="sort"` and the arrows; `sort_by`/`sort_dir`
      mark the current order.
    * `on_select`: `%{"id" => key, "selected" => "true" | "false"}` (the new state of that row).
      `on_select_all`: `%{"selected" => "true" | "false"}`. `selected` lists the checked keys; the
      key is `row_key.(row)` or the row's DOM id. With a stream, `stream_insert` the rows whose
      selection changed and give `all_selected`, or set `select_sync="client"` (see "Selection of a stream").

  ## Optimistic selection

  With `on_select` or `on_select_all` the `<table>` carries `data-lu-select` and the
  `LedgerUI.TableSelect` hook (the `CardTable` hook with `row_groups` and details). A click on a
  row checkbox updates, in the browser and at once, the row (`aria-selected` and the selected
  tint, which the server renders too), the header checkbox (checked or indeterminate, from the
  rows of the page) and sends a `lu:selection` DOM event (`detail: {id, count, delta, ids}`) that a
  `<.bulk_bar for="table-id">` listens to. The events to the server are the same as before.
  The server prevails: its markup is the baseline (the `checked` attribute of each box), a patch
  that changes a box replaces what the browser showed, and when the server answered and left a
  box as it was (a refusal, the minimal diff of #70) the boxes return to the server's state.
  The header's "select all" is assumed to act on the rows of the page; ids the server selects
  off the page show up with its patch. A table without selection is unchanged.

  ## Selection of a stream

  A row of a stream is sent once, so it cannot be re-rendered just to tick its box. With
  `select_sync="client"` (also on `data_table/1` and `card_table/1`; the default is `"server"`, the
  behavior above) the rows are rendered unticked and the `<table>` carries `data-lu-selected`, the
  JSON list of `selected` (as strings). The hook paints `checked`, `aria-selected` and the selected
  classes of every row from that list: on mount, when it changes, for a row that is inserted, and
  once the server answered a click (a refusal puts the box back). The app then only assigns
  `selected`; a new selection sends the list and not the rows, and the header box still follows
  `all_selected`.

      <.table id="t" rows={@streams.items} on_select="sel" selected={@selected} select_sync="client">

  ## Performance

  Give the table a unique `row_id`: LiveView then tracks each row by it (`:key`) and sends only the
  row that changed. Without `row_id`, or with a repeated id, rows are tracked by position, and
  inserting at the top resends the rows below it.

      <.table id="users" rows={@users} row_id={&"user-\#{&1.id}"}>
        <:col :let={user} label="Name">{user.name}</:col>
      </.table>

  With `row_id`, sorting (100 rows reversed: ~1.4 KB instead of 46 KB) and the other changes of
  `sort_by`/`sort_dir` send the new order and the header, not the rows. Density (`compact`) sends
  the table's class string once (~2 KB: the `class` attribute is a single value to LiveView), not
  a class per cell. A new page sends the new rows, which is their content.

  For long lists, or lists that grow, use a stream with `limit:`:

      stream(socket, :users, users, limit: -100)

  Also turn on websocket compression in the endpoint (diffs compress 30 to 70 times):

      socket "/live", Phoenix.LiveView.Socket,
        websocket: [compress: true, connect_info: [session: @session_options]]

  ## Hand-written tables

  Without `rows`, the table renders its inner block: `table_head/1`, `table_body/1`,
  `table_row/1`, `table_cell/1`, `table_foot/1` and `table_empty/1` (see each).

  When the app builds the rows with a `:for`, add `:key`: without it, inserting a row at the top
  resends all the rows after it (63% of the payload on a 500-row table). The kit cannot do this
  for you.

      <.table id="users">
        <.table_body>
          <.table_row :for={user <- @users} :key={user.id}>
            <:cell>{user.name}</:cell>
          </.table_row>
        </.table_body>
      </.table>

  ## Columns that leave by priority

  A `:col` with `priority` 1, 2 or 3 (up to 4) leaves (header, cells and `:foot` cell together) when
  the table's own box (a container, `@container`) gets narrower than the matching `breakpoints`
  entry (720, 560 and 420px by default). Tailwind only sees literal class names, so the widths are
  a fixed list (the `hide_widths` list of the internal Table.Layout module); another width raises
  `ArgumentError`.

  ## Column sizing: `grow`, `wrap`, `min`

  The table is an auto-layout `<table>` (`w-full`) and every cell is one line (`whitespace-nowrap`),
  so with room to spare each column gets a share of it in proportion to its content. To give the
  free width to one column (a name, a description) put `grow` on its `:col`:

      <:col :let={o} label="Cliente" grow={1}>{o.cliente}</:col>

  The other columns stay at the width of their content, the grown one takes the rest, stays on a
  single line while it fits and wraps when the table (or its wrapper) gets narrower. `grow` is a
  weight: with `grow={2}` and `grow={1}` the first takes twice the second's share of the table.

    * `wrap="auto"`: the text may wrap (the default of a `grow` column; on a column without `grow`
      it only lets the text wrap). `wrap="never"`: always one line, the wrapper scrolls instead
      (the default of a column without `grow`). `wrap="truncate"`: one line cut with an ellipsis,
      never wider than the room the table gives it.
    * `min`: minimum width (`"12rem"`, `"200px"`), so a growing column does not wrap into a
      sliver before the table scrolls.
    * `width` wins: a column with `width` keeps its own track treatment and ignores `grow`, `wrap`
      and `min`. Without any of the three the markup is unchanged (`role="title"` does not grow by
      itself: say `grow` where you want it).
    * In the card layout (`card_below`) the column goes back to `w-auto` and drops `min`.

  ## Card layout, details panel, copy columns (used by `card_table/1`)

  Extra attributes `card_below`, `details`, `row_editing`, `row_action` and the column attributes
  `role`, `width`, `truncate`, `card`, `copy*` back the "card" table (see
  `LedgerUI.Components.CardTable`): under `card_below` px each row is a two-line grid placed by the
  `role` of its cells (`head`, `status`, `title`, `value`); `card_below` is one of
  the `card_widths` list of the internal Table.Layout module. `details` adds a panel under the clicked row
  (hook `LedgerUI.CardTable`) with the `:detail` slots and the columns that left by priority;
  `copy` turns a cell into a copy button; `row_editing` swaps a row for the `:edit` slot.

  ## Streams with `:expand` / `:detail`: `row_groups`

  The detail row (`:expand`) and the panel row (`:detail`) are siblings of the row's `<tr>`. In a
  stream the client only moves the element that carries the stream id, so a reset, a `stream_insert`
  at `at: 0` or a `stream_delete` would leave those rows behind. With `row_groups` each item is a
  `<tbody id={dom_id}>` holding its `<tr>` and the rows that belong to it, and `phx-update="stream"`
  goes on the `<table>` (its `<thead>`, `<tfoot>` and the empty `<tbody>` keep their own ids). It is
  on by itself when `rows` is a stream and there is an `:expand` or a panel (`details` with `:detail`
  or `priority` columns); `row_groups={false}` keeps the single `<tbody>` and `row_groups={true}`
  forces the layout for lists too. In that layout the `<tr>` id is `"<dom_id>-row"`, `body_class` is
  applied to every item's `<tbody>`, the hook of the panel sits on the `<table>` and the zebra
  stripes count items, not `<tr>`s. Without `row_groups` (and without the stream + expand/panel
  case) the markup is the one it always was.

  ## Infinite scroll with a stream

  `on_viewport_top` / `on_viewport_bottom` (an event name or a `%JS{}`; also on `data_table/1` and
  `card_table/1`) are rendered as `phx-viewport-top` / `phx-viewport-bottom` on the element that holds
  the stream (the `<tbody>`, or the `<table>` with `row_groups`): the LiveView looks at the first and
  the last child of that element, so they must be the rows. With the wrapper, its `id` (`<id>-wrap`)
  is the `phx-viewport-overrun-target`. The LiveView throttles the events itself (500 ms); there is no
  attribute to change it. Without them the HTML does not change.

      <.table id="items" rows={@streams.items} on_viewport_bottom="next-page">
        <:col :let={{_id, item}} label="Name">{item.name}</:col>
      </.table>

      # handle_event("next-page", _, socket): the next page at the end, the oldest rows out
      stream(socket, :items, next, at: -1, limit: -200)
      # handle_event("prev-page", _, socket) (with `on_viewport_top`): the previous page at the top
      stream(socket, :items, prev, at: 0, limit: 200)

  ## Not implemented

  `peek` / `peek_label` (the panel with the hidden columns) are accepted but draw
  nothing yet. `borderless` is accepted: the design has no style for it.
  """
  use LedgerUI.Component

  # `settle/3` here is the table's own (rows and selection, #70), not `LedgerUI.Helpers.settle/3`.
  import LedgerUI.Helpers, except: [settle: 3]

  alias LedgerUI.Color
  alias LedgerUI.Components.Button
  alias LedgerUI.Components.Checkbox
  alias LedgerUI.Components.Table.Layout

  @variants ~w(basic bordered hoverable zebra grid data data-grid flat)
  @aligns %{"left" => nil, "center" => "c", "right" => "num"}
  @roles ~w(head status title value meta)

  # The assigns no derived value of the rows mode reads: the rows and the selection (what the
  # rows and the header checkbox are made of), the sort (the header reads it straight from the
  # assigns), the density, the classes and the labels of the shell, the foot. A call that changed
  # only these leaves `ctx`, `cols`, `cells`... as they were.
  @struct_ignore ~w(on_viewport_top on_viewport_bottom rows selected all_selected empty sort_by sort_dir on_sort compact class wrapper_class variant rounded bleed container scroll_label sort_label select_all_label expand_label headless foot hoverable borderless peek peek_label wrapper rest)a
  # `shell` (the table's classes) is the one that reads the density, the variant, the classes...
  @shell_ignore @struct_ignore -- ~w(compact class wrapper_class variant rounded bleed container)a
  # the entries and the header checkbox are made of the rows and the selection
  @entries_ignore @struct_ignore -- ~w(rows selected all_selected)a

  # -- classes -------------------------------------------------------------------------------------
  # The look is set by variables on the <table> (so rows mode and hand-written tables share it):
  #   --tpx  horizontal padding            --td-py / --th-py  vertical padding of a cell
  #   --td-fs / --th-fs  font size         --tff  font family
  #   --tbr  right border of a cell        --tbr-last  that of the last cell of a row
  #   --tbb  bottom border of a cell       --z / --h / --s  background of a cell: zebra, hover, selected
  @table_base "w-full border-separate border-spacing-0 text-[14px]"

  @variant_classes %{
    "basic" => nil,
    "hoverable" => nil,
    "bordered" => "overflow-hidden rounded-lg border border-line",
    "zebra" =>
      "[&_tbody_tr:nth-child(even)]:[--z:color-mix(in_oklab,var(--lu-bg-sunken)_60%,transparent)]",
    "grid" => "[--tbr:1px_solid_var(--lu-line)]",
    "data" => "[--td-py:7px] [--td-fs:13px] [--th-fs:12px]",
    "data-grid" =>
      "[--td-py:6px] [--th-py:6px] [--td-fs:13px] [--th-fs:13px] [--tff:var(--lu-font-mono)] [--tbr:1px_solid_var(--lu-line)] [--tbr-last:1px_solid_var(--lu-line)]",
    "flat" => "[--tbb:0_none]"
  }

  @rounded %{
    "row" => "[&_tbody_td:first-child]:rounded-l-md [&_tbody_td:last-child]:rounded-r-md",
    "top" =>
      "[&_thead_th]:bg-sunken [&_thead_th:first-child]:rounded-tl-md [&_thead_th:last-child]:rounded-tr-md",
    "none" => nil
  }

  @th "py-[var(--th-py,12px)] border-b border-line text-[length:var(--th-fs,12.5px)] leading-4 font-medium text-muted [font-family:var(--tff)] whitespace-nowrap [border-right:var(--tbr,0_none)] last:[border-right:var(--tbr-last,0_none)]"
  @td "py-[var(--td-py,12px)] [border-bottom:var(--tbb,1px_solid_var(--lu-line))] [tr:last-child>&]:[border-bottom:0_none] [border-right:var(--tbr,0_none)] last:[border-right:var(--tbr-last,0_none)] [:where(&)]:text-[length:var(--td-fs)] [:where(&)]:text-[color:var(--td-c,var(--lu-ink-2))] [:where(&)]:[font-family:var(--tff)] bg-[var(--z,var(--h,var(--s,transparent)))]"
  # -- the cells of the rows mode -------------------------------------------------------------------
  # The classes every body cell (`@td` + `@px`) and header cell (`@th` + `@px`) of the rows mode share
  # live once on the <table>, as descendant selectors (#25): 10 000 cells no longer repeat ~500
  # characters each. Under `:where()` (specificity 0) they lose to any class on the cell, as the
  # `@td` classes did to the cell's own utilities; the ones that had `last:` / `tr:last-child>&` keep
  # a real selector. The panel row's cell is left out (it has its own `border-0 p-0`), the <tfoot>
  # keeps `@td`.
  @lean_cells Enum.join(
                [
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:py-[var(--td-py,12px)]",
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:px-[var(--tpx,14px)]",
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:[border-bottom:var(--tbb,1px_solid_var(--lu-line))]",
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:[border-right:var(--tbr,0_none)]",
                  "[&>tbody>tr:not([data-part=table-panel-row])>td:last-child]:[border-right:var(--tbr-last,0_none)]",
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:text-[length:var(--td-fs)]",
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:text-[color:var(--td-c,var(--lu-ink-2))]",
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:[font-family:var(--tff)]",
                  "[:where(&>tbody>tr:not([data-part=table-panel-row])>td)]:bg-[var(--z,var(--h,var(--s,transparent)))]",
                  "[:where(&>thead>tr>th)]:py-[var(--th-py,12px)]",
                  "[:where(&>thead>tr>th)]:px-[var(--tpx,14px)]",
                  "[:where(&>thead>tr>th)]:border-b",
                  "[:where(&>thead>tr>th)]:border-line",
                  "[:where(&>thead>tr>th)]:text-[length:var(--th-fs,12.5px)]",
                  "[:where(&>thead>tr>th)]:leading-4",
                  "[:where(&>thead>tr>th)]:font-medium",
                  "[:where(&>thead>tr>th)]:text-muted",
                  "[:where(&>thead>tr>th)]:[font-family:var(--tff)]",
                  "[:where(&>thead>tr>th)]:whitespace-nowrap",
                  "[:where(&>thead>tr>th)]:[border-right:var(--tbr,0_none)]",
                  "[&>thead>tr>th:last-child]:[border-right:var(--tbr-last,0_none)]"
                ],
                " "
              )
  @lean_last "[&>tbody>tr:last-child>td]:[border-bottom:0_none]"
  # `row_groups`: every row is the `:last-child` of its own <tbody>, so only the last group drops it
  @group_last "[&>tbody:last-of-type>tr:last-child>td]:[border-bottom:0_none]"
  @zebra_group "[&_tbody:nth-of-type(even)>tr:first-child]:[--z:color-mix(in_oklab,var(--lu-bg-sunken)_60%,transparent)]"
  # `bleed`: the cells at the ends of a row are padded like the card around the table
  @bleed_edges "[&>thead>tr>th:first-child]:pl-[var(--card-p,16px)] [&>thead>tr>th:last-child]:pr-[var(--card-p,16px)] [&>tbody>tr:not([data-part=table-panel-row])>td:first-child]:pl-[var(--card-p,16px)] [&>tbody>tr:not([data-part=table-panel-row])>td:last-child]:pr-[var(--card-p,16px)]"
  @px "px-[var(--tpx,14px)]"
  # `@td` without its vertical padding: the cell of `padded={false}` (no `@px` either)
  @td_flush String.replace_prefix(@td, "py-[var(--td-py,12px)] ", "")
  @cb "w-9 pl-[var(--tpx,14px)] pr-0"

  @th_aligns %{
    "left" => "text-left",
    "center" => "text-center",
    "right" => "text-right tabular-nums",
    nil => "text-left"
  }
  @td_aligns %{"center" => "text-center", "right" => "text-right tabular-nums"}

  # a row: selected tint (--s), the detail row, the row that opens a panel
  @row_sel "[--s:color-mix(in_oklab,var(--lu-accent-soft)_70%,var(--lu-bg-panel))]"
  @row_sub "[--s:var(--lu-bg-tray)] [--td-fs:12.5px] [--td-c:var(--lu-muted)] [&>td:first-child]:pl-11"
  @row_panel "data-[ct-row]:cursor-pointer focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-accent-500 data-[open]:[--h:var(--lu-bg-hover)]"

  @check_label "inline-flex cursor-pointer items-start gap-2.5 text-[14px] text-ink"

  # -- rows mode ---------------------------------------------------------------------------------

  attr :id, :string, required: true

  attr :rows, :any,
    default: nil,
    doc: "A list or a `@streams.x` stream. Leave it out to write the table by hand."

  attr :row_id, :any,
    default: nil,
    doc:
      "Function giving each row's DOM id (streams: the stream id). With a list it is also the key LiveView follows (`:key`), so a change, an insertion or a new order sends only the rows that moved (#86); without it the rows are followed by position and an insertion at the top sends the rows below it again. Repeated ids make the whole list follow by position."

  attr :row_click, :any, default: nil, doc: "Function of the row returning a `JS` or an event."

  attr :row_class, :any,
    default: nil,
    doc: "Function of the row returning extra classes of its `<tr>`."

  attr :row_attrs, :any,
    default: nil,
    doc: "Function of the row returning a map of extra `<tr>` attributes."

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "Maps each row before the slots get it."

  attr :row_key, :any,
    default: nil,
    doc: "Function giving the selection key of a row (default: DOM id)."

  attr :variant, :string,
    default: nil,
    values: [nil | @variants],
    doc:
      "`nil` is the bare table (rows light up on hover; `basic` does not). `grid` is the gridjs look; `data`/`data-grid` the lean one of `data_table/1`."

  attr :rounded, :string, default: nil, values: [nil, "row", "top", "none"]
  attr :sort_by, :string, default: nil
  attr :sort_dir, :string, default: "asc", values: ~w(asc desc)
  attr :on_sort, :any, default: nil
  attr :on_select, :any, default: nil
  attr :on_select_all, :any, default: nil
  attr :selected, :list, default: []
  attr :all_selected, :boolean, default: nil

  attr :select_sync, :string,
    default: "server",
    values: ~w(server client),
    doc:
      "`\"client\"`: the browser paints the selection from `selected` (`data-lu-selected` on the `<table>`) and the rows are rendered unticked, so with a stream there is no `stream_insert` to tick a box. See \"Selection of a stream\"."

  attr :hoverable, :boolean, default: nil
  attr :compact, :boolean, default: false
  attr :headless, :boolean, default: false
  attr :sticky_header, :boolean, default: false
  attr :borderless, :boolean, default: false

  attr :bleed, :boolean,
    default: false,
    doc:
      "For a table inside a `card` body with `padded={false}`: no box of its own (no border, radius or background) and the first and last cells are padded by the card's `--card-p` (16px outside a card), so rows run edge to edge while the content stays aligned with the card's padding."

  attr :card_below, :integer,
    default: nil,
    doc:
      "Width (px) of the table's own box under which rows become two-line cards (needs `role`s); one of `Table.Layout.card_widths/0`."

  attr :details, :boolean,
    default: false,
    doc: "A click on a row opens a panel under it (hook `LedgerUI.CardTable`)."

  attr :panel_label, :string, default: nil

  attr :row_editing, :any,
    default: nil,
    doc: "Function of the row; true swaps its cells for the `:edit` slot."

  attr :row_action, :any,
    default: nil,
    doc: "Function of the row; false leaves the content of its `:action` cells out."

  attr :body_class, :any,
    default: nil,
    doc: "Classes of the `<tbody>` (of each item's, with `row_groups`)."

  attr :copy_toast, :boolean,
    default: false,
    doc:
      "A toast (`ledger:toast`, the contract of `clipboard`) after a `copy` column copies. A column's own `copy_toast` wins."

  attr :copy_toast_message, :string,
    default: nil,
    doc:
      "The toast text; `%s` is the copied value, shown in bold. Default: `\"%s · <copied_label>\"`."

  attr :row_groups, :boolean,
    default: nil,
    doc:
      "One `<tbody>` per row, holding its `<tr>`, panel and detail rows, so a stream moves them together. `nil` turns it on for a stream with `:expand` or a details panel."

  attr :select_attrs, :any,
    default: nil,
    doc:
      "Function of the row returning extra attributes (`class`, `style`) of its checkbox label."

  attr :expand_open, :any,
    default: nil,
    doc:
      "Function of the row: with `:expand`, shows its detail row always open (no toggle column), for rows it returns true for."

  attr :breakpoints, :list,
    default: [720, 560, 420],
    doc:
      "Widths (px) under which priority 1, 2, 3... leave; each is one of `Table.Layout.hide_widths/0`."

  attr :wrapper, :boolean,
    default: true,
    doc: "`false` leaves out the bordered box (a table inside a card body)."

  attr :container, :boolean, default: nil
  attr :peek, :boolean, default: false, doc: "Not implemented yet."
  attr :peek_label, :string, default: nil
  attr :target, :any, default: nil
  attr :expand_label, :string, default: nil

  attr :scroll_label, :string,
    default: nil,
    doc:
      "The accessible name that makes the scrolling box of the table (`wrapper`) a focusable `region` (`role=\"region\"`, `tabindex=\"0\"`), so the keyboard can scroll it. Off by default: give it to a table that can be wider or taller than its box (without it a scrolling box cannot be reached with the keyboard, and axe reports `scrollable-region-focusable`)."

  attr :on_viewport_top, :any,
    default: nil,
    doc:
      "A stream only: event name or `%JS{}` for the infinite scroll upwards (`phx-viewport-top`), put on the element that holds the stream (the `<tbody>`; the `<table>` with `row_groups`). See \"Infinite scroll\"."

  attr :on_viewport_bottom, :any,
    default: nil,
    doc: "A stream only: as `on_viewport_top`, downwards (`phx-viewport-bottom`)."

  attr :sort_label, :string, default: nil
  attr :row_label, :any, default: nil
  attr :select_all_label, :string, default: nil
  attr :select_label, :string, default: nil
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil, doc: "Classes of the `<table>`."
  attr :rest, :global, doc: "Attributes of the `<table>`."

  slot :action, doc: "Cells appended to every row, after the columns." do
    attr :priority, :integer, doc: "Leaves with the columns of that priority."
    attr :card, :boolean, doc: "`false` leaves the cell out of the card layout."
  end

  slot :col, doc: "A column; receives the row (after `row_item`)." do
    attr :label, :string
    attr :class, :any
    attr :head_class, :any

    attr :dim, :boolean,
      doc: "Header and cells at 32% (marks the column that leaves, in a `priority` demo)."

    attr :align, :string, values: ~w(left center right)
    attr :sort_key, :string
    attr :priority, :integer
    attr :style, :string, doc: "Inline style of the cell (`<td>`)."
    attr :role, :string, values: ~w(head status title value meta)
    attr :width, :string, doc: "CSS track: `max-content` (default) or `minmax(120px,1.3fr)`."
    attr :truncate, :boolean

    attr :grow, :integer,
      doc:
        "Share of the free width this column takes (weight: `grow={2}` takes twice a `grow={1}`); the others stay at their content. Ignored with `width`."

    attr :wrap, :string,
      values: ~w(auto never truncate),
      doc:
        "`auto`: one line while there is room, wraps when the table is narrow (the default of a `grow` column); `never`: one line (the default otherwise); `truncate`: one line with an ellipsis. Ignored with `width`."

    attr :min, :string,
      doc:
        "Minimum width of the column (`\"12rem\"`, `\"200px\"`); the card layout drops it. Ignored with `width`."

    attr :card, :boolean, doc: "Keeps the cell in the card layout, in a line of its own."
    attr :copy, :any, doc: "Function of the row returning the text a copy button copies."
    attr :copy_label, :string
    attr :copied_label, :string
    attr :copy_show, :string, values: ~w(inline)
    attr :copy_tip, :string, values: ~w(value_label)
    attr :copy_toast, :boolean, doc: "Overrides the table's `copy_toast` for this column."
    attr :copy_toast_message, :string, doc: "Overrides the table's `copy_toast_message`."
  end

  slot :detail, doc: "A `label: value` line of the details panel; receives the row." do
    attr :label, :string
  end

  slot :edit, doc: "Inline form in place of the cells of a row for which `row_editing` is true."

  slot :empty, doc: "Shown in a full-width row when there are no rows."
  slot :expand, doc: "Detail shown under a row; receives `%{row: row, toggle: js}`."

  slot :foot, doc: "A cell of the `<tfoot>` row, for totals." do
    attr :class, :any
    attr :align, :string, values: ~w(left center right)
    attr :colspan, :any
    attr :priority, :integer
  end

  slot :inner_block, doc: "The hand-written table when `rows` is not given."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def table(%{rows: nil} = assigns) do
    assigns =
      I18n.texts(assigns,
        panel_label: "table.details",
        peek_label: "data_table.peek",
        select_all_label: "table.select_all",
        select_label: "table.select_row"
      )

    assigns = assign(assigns, :shell, shell(assigns, assigns.col))

    ~H"""
    <.table_wrap wrapper={@wrapper} shell={@shell} scroll_label={@scroll_label} wrap_id={nil}>
      <table id={@id} data-part="table" class={@shell.class} {@rest}>
        {render_slot(@inner_block)}
      </table>
    </.table_wrap>
    """
  end

  def table(assigns) do
    assigns =
      I18n.texts(assigns,
        panel_label: "table.details",
        peek_label: "data_table.peek",
        select_all_label: "table.select_all",
        select_label: "table.select_row"
      )

    changed0 = Map.get(assigns, :__changed__)
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.rows)
    # `selected` is a list in the API; a set makes the test per row (and in `head_all/2`) O(1).
    selected_set = MapSet.new(assigns.selected)

    # `select_sync="client"`: the rows are rendered unticked, the browser paints them from the list
    client_sync? = assigns.select_sync == "client" and assigns.on_select != nil
    group? = row_groups?(assigns, stream?)
    assigns = assign(assigns, :row_groups, group?)
    shell = shell(assigns, assigns.col)

    assigns =
      assigns
      |> assign(:stream?, stream?)
      |> assign(:group?, group?)
      |> assign(:vp_top, stream? && assigns.on_viewport_top)
      |> assign(:vp_bottom, stream? && assigns.on_viewport_bottom)
      |> assign(
        :wrap_id,
        stream? && assigns.wrapper && (assigns.on_viewport_top || assigns.on_viewport_bottom) &&
          assigns.id <> "-wrap"
      )
      |> assign(:selected_set, if(client_sync?, do: MapSet.new(), else: selected_set))
      |> assign(:sel_json, client_sync? && selected_json(assigns.selected))
      |> assign(:row_id, assigns.row_id || if(stream?, do: fn {id, _} -> id end))
      |> assign(:shell, shell)
      |> assign(:rshell, Map.drop(shell, [:class, :wrap_class]))
      |> assign(:cols, Enum.map(assigns.col, &col_info(&1, assigns, shell)))
      |> assign(:cells, Enum.map(assigns.col, &cell_info(&1, shell)))
      |> assign(:action_cells, Enum.map(assigns.action, &action_cell_info(&1, shell)))
      |> assign(:td, td_classes(shell))
      |> assign(:expand?, assigns.expand != [])
      |> assign(:select?, assigns.on_select != nil or assigns.on_select_all != nil)
      |> assign(:sel_class, @row_sel)
      |> assign(:head_all, head_all(assigns, selected_set))
      |> assign(:card?, shell.card != nil)
      |> assign(:panel?, assigns.details and (assigns.detail != [] or has_priority?(assigns.col)))
      |> assign(:panel_cols, panel_cols(assigns, shell))
      |> assign(:hooked, assigns.details or Enum.any?(assigns.col, & &1[:copy]))
      |> assign(:edit?, assigns.row_editing != nil and assigns.edit != [])

    assigns =
      assign(
        assigns,
        :ncols,
        length(assigns.col) + length(assigns.action) + if(assigns.select?, do: 1, else: 0) +
          if(assigns.expand? and assigns.expand_open == nil, do: 1, else: 0)
      )

    assigns =
      assigns
      |> assign(:ctx, row_ctx(assigns))
      |> assign(:entries, if(stream?, do: nil, else: row_entries(assigns)))

    # Which assigns each derived value is read from, as a list of what it does NOT depend on: when
    # a call changed only those, the value is the same as last time and goes out of `__changed__`.
    # Sorting, a new page, the search and the density change `rows`, `sort_by`... but not the
    # classes, the columns or the `ctx` every row reads, so those rows are not sent again (#86).
    assigns =
      settle_table(assigns, changed0, [
        {[
           :ctx,
           :row_groups,
           :stream?,
           :group?,
           :row_id,
           :rshell,
           :cols,
           :cells,
           :action_cells,
           :td,
           :expand?,
           :select?,
           :sel_class,
           :card?,
           :panel?,
           :panel_cols,
           :hooked,
           :edit?,
           :ncols
         ], @struct_ignore},
        {[:shell], @shell_ignore},
        {[:vp_top, :vp_bottom, :wrap_id],
         @struct_ignore -- ~w(on_viewport_top on_viewport_bottom wrapper)a}
        | entry_groups(client_sync?)
      ])

    ~H"""
    <.table_wrap wrapper={@wrapper} shell={@shell} scroll_label={@scroll_label} wrap_id={@wrap_id}>
      <table
        id={@id}
        data-part="table"
        class={@shell.class}
        phx-update={(@group? and @stream?) && "stream"}
        phx-viewport-top={@group? && @vp_top}
        phx-viewport-bottom={@group? && @vp_bottom}
        phx-viewport-overrun-target={@group? && @wrap_id}
        phx-hook={table_hook(@group?, @hooked, @select?)}
        data-lu-select={@select?}
        data-lu-sel-class={@select? && @sel_class}
        data-lu-selected={@sel_json}
        {ra(@card?, "table")}
        {@rest}
      >
        <thead
          :if={!@headless}
          id={@group? && @id <> "-head"}
          data-part="table-head"
          class={@card? && @shell.card.thead}
          {ra(@card?, "rowgroup")}
        >
          <tr data-part="table-head-row" class={@card? && @shell.card.thead_tr} {ra(@card?, "row")}>
            <th
              :if={@select?}
              data-part="table-cell"
              class={th_class(:cb, nil, @shell, @sticky_header)}
              {ra(@card?, "columnheader")}
            >
              <.table_checkbox
                :if={@on_select_all}
                id={@id <> "-select-all"}
                label={@select_all_label}
                checked={@head_all == true}
                indeterminate={@head_all == :some}
                on_click={@on_select_all}
                values={%{"selected" => to_string(@head_all != true)}}
                target={@target}
              />
            </th>
            <th
              :for={c <- @cols}
              data-part="table-head-cell"
              class={c.th_class}
              {ra(@card?, "columnheader")}
              aria-sort={@on_sort && c.sort_key && aria_sort(c.sort_key, @sort_by, @sort_dir)}
              tabindex={@on_sort && c.sort_key && "0"}
              phx-click={@on_sort && c.sort_key && @on_sort}
              phx-keydown={@on_sort && c.sort_key && @on_sort}
              phx-key={@on_sort && c.sort_key && "Enter"}
              phx-target={@on_sort && c.sort_key && @target}
              phx-value-column={@on_sort && c.sort_key && c.sort_key}
              phx-value-direction={
                @on_sort && c.sort_key && next_dir(c.sort_key, @sort_by, @sort_dir)
              }
            >
              {c.label}
              <%= if c.sort_key do %>
                <.icon
                  name={sort_icon(c.sort_key, @sort_by, @sort_dir)}
                  size="sm"
                  class={sort_icon_class(c.sort_key, @sort_by)}
                />
              <% end %>
            </th>
            <th
              :for={a <- @action}
              data-part="table-head-cell"
              class={th_class(:action, a, @shell, @sticky_header, @card?)}
              {ra(@card?, "columnheader")}
            >
            </th>
            <th
              :if={@expand? and @expand_open == nil}
              data-part="table-head-cell"
              class={th_class(:plain, nil, @shell, @sticky_header, @card?)}
            >
              {@expand_label}
            </th>
          </tr>
        </thead>
        <.rows_body
          group?={@group?}
          id={@id <> "-body"}
          class={[@card? && @shell.card.tbody, @body_class]}
          stream?={@stream?}
          hooked={@hooked}
          card?={@card?}
          vp_top={@vp_top}
          vp_bottom={@vp_bottom}
          wrap_id={@wrap_id}
        >
          <%!-- Stream: `rows` is consumed by the stream itself (it sends only the inserts). --%>
          <%= if @stream? do %>
            <.trow
              :for={row <- @rows}
              ctx={@ctx}
              row={row}
              item={@row_item.(row)}
              rid={@row_id.(row)}
              sel_key={row_key(@row_key, @row_id, row, @row_item.(row))}
              sel={row_sel?(@selected_set, @row_key, @row_id, row, @row_item.(row))}
              editing={@edit? and @row_editing.(@row_item.(row)) == true}
            />
          <% else %>
            <%!-- List: one keyed component per row (#86), see `trow/1` and `row_entries/1`. --%>
            <.trow
              :for={{k, rid, sel_key, sel, editing, item, row} <- @entries}
              :key={k}
              ctx={@ctx}
              row={row}
              item={item}
              rid={rid}
              sel_key={sel_key}
              sel={sel}
              editing={editing}
            />
          <% end %>
          <.row_group
            :if={@empty != [] and @rows == []}
            group?={@group?}
            id={@id <> "-empty"}
            class="not-only-of-type:hidden"
            card?={false}
          >
            <tr
              id={tr_id(@group?, @id <> "-empty")}
              data-part="table-empty"
              class={!@group? && "not-only:hidden"}
            >
              <td
                data-part="table-cell"
                colspan={@ncols}
                class={td_class(:plain, nil, @shell, false)}
                style="text-align:center"
              >
                {render_slot(@empty)}
              </td>
            </tr>
          </.row_group>
          <.row_group
            :if={@empty != [] and @stream?}
            group?={@group?}
            id={@id <> "-empty-stream"}
            class="not-only-of-type:hidden"
            card?={false}
          >
            <tr
              id={tr_id(@group?, @id <> "-empty-stream")}
              data-part="table-empty"
              class={!@group? && "not-only:hidden"}
            >
              <td
                data-part="table-cell"
                colspan={@ncols}
                class={td_class(:plain, nil, @shell, false)}
                style="text-align:center"
              >
                {render_slot(@empty)}
              </td>
            </tr>
          </.row_group>
        </.rows_body>
        <tfoot :if={@foot != []} id={@group? && @id <> "-foot"}>
          <tr>
            <td
              :for={f <- @foot}
              data-part="table-cell"
              colspan={f[:colspan]}
              class={td_class(:foot, f, @shell, false)}
            >
              {render_slot(f)}
            </td>
          </tr>
        </tfoot>
      </table>
    </.table_wrap>
    """
  end

  # The `<tbody>` of the rows; with `row_groups` there is none (each row has its own, see `row_group/1`).
  defp rows_body(%{group?: true} = assigns), do: ~H"{render_slot(@inner_block)}"

  defp rows_body(assigns) do
    ~H"""
    <tbody
      data-part="table-body"
      id={@id}
      class={@class}
      phx-update={@stream? && "stream"}
      phx-hook={@hooked && "LedgerUI.CardTable"}
      phx-viewport-top={@vp_top}
      phx-viewport-bottom={@vp_bottom}
      phx-viewport-overrun-target={@wrap_id}
      {ra(@card?, "rowgroup")}
    >
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  # One row of the rows mode (#86). Each row is a component, so that the `:for` of `rows_body` can
  # follow it by `:key` and send only the rows that changed: with the markup of a row inline, and
  # the `item`, `key`, `sel`... it computes as locals of the `for` block, LiveView lost track of
  # the items and sent every row again when one changed (310 KB of 341 KB for 100 rows).
  #
  #   * `ctx`: what is the same for every row (classes, columns, slots, the functions of the
  #     table), made once in `table/1`; it is `settle`d there, so it is not "changed" when only
  #     the rows or the selection changed.
  #   * `row`, `item`, `rid`, `sel_key`, `sel`, `editing`: what is about this row. For a list they
  #     are the variables of the `:for` (`row_entries/1`), and LiveView compares them one by one:
  #     a row only renders when one of them changed (`sel` included, so toggling the selection
  #     of a row renders that row only). For a stream they come from the row itself.
  #   * `panel`, `tr`, `extra` are derived here and `settle`d on their sources.
  defp trow(assigns) do
    changed0 = Map.get(assigns, :__changed__)
    ctx = assigns.ctx
    panel = ctx.panel? and not assigns.editing

    assigns =
      assigns
      |> assign(:panel, panel)
      |> assign(
        :tr,
        tr_attrs(
          ctx.row_attrs,
          ctx.row_class,
          ctx.row_click,
          assigns.row,
          assigns.item,
          assigns.sel,
          ctx.shell,
          panel,
          ctx.on_select
        )
      )
      |> assign(:extra, row_extra(ctx.card?, panel, assigns.editing, assigns.rid))

    assigns =
      LedgerUI.Helpers.settle(assigns, changed0,
        panel: [:ctx, :editing],
        tr: [:ctx, :row, :item, :sel, :panel],
        extra: [:ctx, :panel, :editing, :rid]
      )

    cond do
      # The common cases have ONE static root tag (the `<tr>`, or the `<tbody>` of `row_groups`),
      # so the client skips the rows that did not change instead of building and morphing every
      # one of them (#127). Only a row with a panel or a detail row, outside `row_groups`, is
      # several `<tr>` side by side and has no single root.
      ctx.group? -> trow_group(assigns)
      panel or ctx.expand? -> trow_rows(assigns)
      true -> trow_single(assigns)
    end
  end

  defp trow_single(assigns) do
    ~H"""
    <tr
      id={tr_id(@ctx.group?, @rid)}
      data-part="table-row"
      {@tr}
      {@extra}
    >
      <.trow_cells
        ctx={@ctx}
        item={@item}
        sel={@sel}
        sel_key={@sel_key}
        editing={@editing}
        rid={@rid}
      />
    </tr>
    """
  end

  defp trow_group(assigns) do
    ~H"""
    <tbody
      id={@rid}
      data-part="table-row-group"
      class={[@ctx.card? && @ctx.shell.card.tbody, @ctx.body_class]}
      {ra(@ctx.card?, "rowgroup")}
    >
      <tr
        id={tr_id(@ctx.group?, @rid)}
        data-part="table-row"
        {@tr}
        {@extra}
      >
        <.trow_cells
          ctx={@ctx}
          item={@item}
          sel={@sel}
          sel_key={@sel_key}
          editing={@editing}
          rid={@rid}
        />
      </tr>
      <.trow_panel :if={@panel} ctx={@ctx} item={@item} rid={@rid} />
      <.trow_detail
        :if={@ctx.expand? and (@ctx.expand_open == nil or @ctx.expand_open.(@item))}
        ctx={@ctx}
        item={@item}
        rid={@rid}
      />
    </tbody>
    """
  end

  defp trow_rows(assigns) do
    ~H"""
    <tr
      id={tr_id(@ctx.group?, @rid)}
      data-part="table-row"
      {@tr}
      {@extra}
    >
      <.trow_cells
        ctx={@ctx}
        item={@item}
        sel={@sel}
        sel_key={@sel_key}
        editing={@editing}
        rid={@rid}
      />
    </tr>
    <.trow_panel :if={@panel} ctx={@ctx} item={@item} rid={@rid} />
    <.trow_detail
      :if={@ctx.expand? and (@ctx.expand_open == nil or @ctx.expand_open.(@item))}
      ctx={@ctx}
      item={@item}
      rid={@rid}
    />
    """
  end

  # The cells of a row (the content of its `<tr>`).
  defp trow_cells(assigns) do
    ~H"""
    <td
      :if={@ctx.select?}
      data-part="table-cell"
      class={@ctx.td.cb}
      {ra(@ctx.card?, "cell")}
    >
      <%!-- two calls: a call with `{...}` is not change-tracked, so only the one that needs it has it --%>
      <%= if @ctx.on_select do %>
        <%= if @ctx.select_attrs do %>
          <.table_checkbox
            middle
            checked={@sel}
            label={(@ctx.row_label && @ctx.row_label.(@item)) || @ctx.select_label}
            on_click={@ctx.on_select}
            values={%{"id" => @sel_key, "selected" => to_string(!@sel)}}
            target={@ctx.target}
            {@ctx.select_attrs.(@item) || %{}}
          />
        <% else %>
          <.table_checkbox
            middle
            checked={@sel}
            label={(@ctx.row_label && @ctx.row_label.(@item)) || @ctx.select_label}
            on_click={@ctx.on_select}
            values={%{"id" => @sel_key, "selected" => to_string(!@sel)}}
            target={@ctx.target}
          />
        <% end %>
      <% end %>
    </td>
    <td
      :if={@editing}
      data-part="table-cell"
      colspan={@ctx.ncols - if(@ctx.select?, do: 1, else: 0)}
      class={@ctx.td.edit}
    >
      {LedgerUI.Helpers.render_slot_full(@ctx.edit, @item)}
    </td>
    <%= if !@editing do %>
      <td
        :for={cell <- @ctx.cells}
        data-part="table-cell"
        class={cell.class}
        {cell.style}
        {ra(@ctx.card?, "cell")}
      >
        <%= if cell.col[:copy] do %>
          <.copy_cell
            col={cell.col}
            item={@item}
            shell={@ctx.shell}
            toast={@ctx.copy_toast}
            toast_message={@ctx.copy_toast_message}
            locale={@ctx.locale}
          />
        <% else %>
          {LedgerUI.Helpers.render_slot_full(cell.col, @item)}
        <% end %>
      </td>
      <td
        :for={cell <- @ctx.action_cells}
        data-part="table-cell"
        class={cell.class}
        style="width:40px"
        {ra(@ctx.card?, "cell")}
      >
        {if @ctx.row_action == nil or @ctx.row_action.(@item) != false,
          do: LedgerUI.Helpers.render_slot_full(cell.col, @item)}
      </td>
      <td
        :if={@ctx.expand? and @ctx.expand_open == nil}
        data-part="table-cell"
        class={@ctx.td.plain_num}
        style="width:40px"
      >
        <.table_expand_toggle row_id={@rid || @ctx.id <> "-row"} locale={@ctx.locale} />
      </td>
    <% end %>
    """
  end

  defp trow_panel(assigns) do
    ~H"""
    <tr
      id={@rid && @rid <> "-panel"}
      data-part="table-panel-row"
      class={@ctx.card? && @ctx.shell.card.prow}
      hidden
    >
      <td data-part="table-cell" colspan={@ctx.ncols} class="relative h-0 border-0 p-0">
        <div
          data-part="table-panel"
          class="absolute top-(--ct-top,2px) bottom-(--ct-bottom,auto) left-(--ct-x,96px) z-5 w-max max-w-[calc(100%-16px)] min-w-[220px] cursor-text rounded-lg border border-line bg-panel px-3 py-2.5 text-left text-[13px] leading-5 whitespace-normal text-ink-2 shadow-md select-text"
          role="group"
          aria-label={@ctx.panel_label}
        >
          <div
            :for={d <- @ctx.detail}
            data-part="table-panel-item"
            class="flex justify-between gap-3.5 py-[3px]"
          >
            <span data-part="table-panel-key" class="text-muted">{d[:label]}</span>
            <span data-part="table-panel-value" class="text-right text-ink">{LedgerUI.Helpers.render_slot_full(
              d,
              @item
            )}</span>
          </div>
          <div
            :for={c <- @ctx.panel_cols}
            data-part="table-panel-item"
            class={["hidden justify-between gap-3.5 py-[3px]", c.show]}
          >
            <span data-part="table-panel-key" class="text-muted">{c.label}</span>
            <span data-part="table-panel-value" class="text-right text-ink">{LedgerUI.Helpers.render_slot_full(
              c.slot,
              @item
            )}</span>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  defp trow_detail(assigns) do
    ~H"""
    <tr
      id={(@rid || @ctx.id <> "-row") <> "-detail"}
      data-part="table-detail-row"
      class={@ctx.td.sub_row}
      {st(@ctx.expand_open == nil && "display:none")}
    >
      <td
        data-part="table-cell"
        colspan={@ctx.ncols}
        class={@ctx.td.plain_sub}
      >
        {LedgerUI.Helpers.render_slot_full(@ctx.expand, %{
          row: @item,
          toggle: table_toggle_row(@rid || @ctx.id <> "-row")
        })}
      </td>
    </tr>
    """
  end

  # With `row_groups`, the `<tbody>` of one item: its `<tr>` and the rows that belong to it.
  defp row_group(%{group?: true} = assigns) do
    ~H"""
    <tbody id={@id} data-part="table-row-group" class={@class} {ra(@card?, "rowgroup")}>
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  defp row_group(assigns), do: ~H"{render_slot(@inner_block)}"

  defp tr_id(true, id), do: id && id <> "-row"
  defp tr_id(_, id), do: id

  # `row_groups` unset: on for a stream with a detail row or a panel (they would be left behind).
  defp row_groups?(%{row_groups: nil} = a, stream?) do
    stream? and
      (a.expand != [] or (a.details and (a.detail != [] or has_priority?(a.col))))
  end

  defp row_groups?(%{row_groups: v}, _stream?), do: v == true

  defp table_wrap(%{wrapper: true} = assigns) do
    ~H"""
    <div
      data-part="table-wrap"
      id={@wrap_id}
      class={@shell.wrap_class}
      role={@scroll_label && "region"}
      aria-label={@scroll_label}
      tabindex={@scroll_label && "0"}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp table_wrap(assigns) do
    ~H"{render_slot(@inner_block)}"
  end

  # Stream and list rows both land in one `<tbody>`; the plain empty row is only kept for lists.
  @doc false
  def aligns, do: @aligns

  # The `<tr>` attributes of a row: the user's `row_attrs`, `row_class` and `row_click`, merged so
  # `class`, `style` and `phx-click` never come out twice.
  # The table's own hook: the details/copy one (`row_groups`, on the `<table>`; it also runs the
  # optimistic selection), else the selection one. See `priv/static/ledger_ui/lib/table_select.js`.
  defp table_hook(true, true, _select?), do: "LedgerUI.CardTable"
  defp table_hook(_group?, _hooked, true), do: "LedgerUI.TableSelect"
  defp table_hook(_group?, _hooked, _select?), do: nil

  defp tr_attrs(row_attrs, row_class, row_click, row, item, sel, shell, panel, on_select) do
    base = if row_attrs, do: Map.new(row_attrs.(item)), else: %{}
    base = if on_select, do: Map.put(base, :"aria-selected", to_string(sel)), else: base

    base
    |> Map.put(
      :class,
      cx([
        sel && @row_sel,
        row_click && "cursor-pointer",
        panel && @row_panel,
        shell.card && ((shell.group && shell.card.tr_group) || shell.card.tr),
        row_class && row_class.(item),
        base[:class]
      ])
    )
    |> click_attrs(row_click && row_click.(row), nil)
  end

  defp click_attrs(attrs, nil, _target), do: attrs

  defp click_attrs(attrs, click, target) do
    attrs = Map.new(attrs)

    attrs
    |> Map.put(:"phx-click", click)
    |> then(&if target, do: Map.put(&1, :"phx-target", target), else: &1)
  end

  # What every row of the table shares (`trow/1`). It holds no row, no selection and no `rows`, so
  # `settle/3` can drop it when only those changed.
  defp row_ctx(a) do
    %{
      id: a.id,
      group?: a.group?,
      card?: a.card?,
      shell: a.rshell,
      body_class: a.body_class,
      td: a.td,
      cells: a.cells,
      action_cells: a.action_cells,
      select?: a.select?,
      on_select: a.on_select,
      target: a.target,
      select_label: a.select_label,
      row_label: a.row_label,
      select_attrs: a.select_attrs,
      row_attrs: a.row_attrs,
      row_class: a.row_class,
      row_click: a.row_click,
      row_action: a.row_action,
      edit: a.edit,
      edit?: a.edit?,
      panel?: a.panel?,
      panel_label: a.panel_label,
      detail: a.detail,
      panel_cols: a.panel_cols,
      expand: a.expand,
      expand?: a.expand?,
      expand_open: a.expand_open,
      ncols: a.ncols,
      copy_toast: a.copy_toast,
      copy_toast_message: a.copy_toast_message,
      locale: a.locale
    }
  end

  # The rows of a list as `{k, rid, sel_key, sel, editing, item, row}`: the variables of the `:for`
  # in `table/1`, which LiveView compares one by one between renders. `k` is the `:key`: the id
  # the table already uses for the row (`row_id`, the DOM id). Without `row_id` there is no id to
  # follow, and `k` is the position, which is what a `:for` without `:key` does (inserting at the
  # top sends the rows below it again); so it is when an id is repeated.
  defp row_entries(a) do
    entries =
      a.rows
      |> Enum.with_index()
      |> Enum.map(fn {row, i} ->
        item = a.row_item.(row)
        rid = a.row_id && a.row_id.(row)
        key = row_key(a.row_key, a.row_id, row, item)
        sel = key != nil and MapSet.member?(a.selected_set, key)
        editing = a.edit? and a.row_editing.(item) == true
        {i, rid, key, sel, editing, item, row}
      end)

    # A repeated `row_id` would make LiveView raise ("duplicate key"): the DOM already had a
    # duplicated id, but it rendered. In that case the whole render is followed by position.
    by_id? = unique_ids?(entries)

    for {i, rid, key, sel, editing, item, row} <- entries do
      {if(by_id? and rid, do: {:id, rid}, else: {:pos, i}), rid, key, sel, editing, item, row}
    end
  end

  defp unique_ids?(entries) do
    entries
    |> Enum.reduce_while(MapSet.new(), fn {_, rid, _, _, _, _, _}, seen ->
      cond do
        rid == nil -> {:cont, seen}
        MapSet.member?(seen, rid) -> {:halt, :dup}
        true -> {:cont, MapSet.put(seen, rid)}
      end
    end)
    |> then(&(&1 != :dup))
  end

  # What the selection feeds. In `select_sync="client"` the rows do not read it (they are rendered
  # unticked): `selected` only goes to `data-lu-selected` and the header box.
  defp entry_groups(true) do
    [
      {[:selected_set, :entries], @entries_ignore ++ ~w(selected all_selected)a},
      {[:head_all], @entries_ignore},
      {[:sel_json], @struct_ignore -- ~w(selected)a}
    ]
  end

  defp entry_groups(false) do
    [
      {[:selected_set, :head_all, :entries], @entries_ignore},
      {[:sel_json], @struct_ignore}
    ]
  end

  defp selected_json(selected),
    do: selected |> Enum.map(&to_string/1) |> Phoenix.json_library().encode!()

  defp row_sel?(selected_set, row_key, row_id, row, item) do
    key = row_key(row_key, row_id, row, item)
    key != nil and MapSet.member?(selected_set, key)
  end

  defp row_key(nil, nil, _row, _item), do: nil
  defp row_key(nil, row_id, row, _item), do: row_id.(row)
  defp row_key(key, _row_id, _row, item), do: key.(item)

  # -- cell classes --------------------------------------------------------------------------------
  # `shell` carries what the table decided: the hide class of each priority and the card layout.

  # A header cell. `kind`: `:cb` (the select-all box), `:col` (`c` is its attrs), `:action`, `:plain`.
  defp th_class(kind, c, shell, sticky, card? \\ false)

  defp th_class(:cb, _c, shell, sticky, _card?) do
    [
      @cb,
      @th_aligns[nil],
      sticky && "sticky top-0 z-1 bg-panel"
    ]
    |> with_card(shell, :th_cb)
  end

  defp th_class(:col, c, shell, sticky, _card?) do
    key = c[:sort_key]

    [
      @th_aligns[c[:align]],
      key && "group/th cursor-pointer [&_svg]:ml-0.5 [&_svg]:size-3",
      pc(shell, c[:priority]),
      c[:dim] && "opacity-[.32]",
      c[:head_class],
      sticky && "sticky top-0 z-1 bg-panel"
    ]
    |> with_card(shell, :th)
  end

  defp th_class(kind, c, shell, sticky, _card?) when kind in [:action, :plain] do
    [
      @th_aligns[nil],
      kind == :action && pc(shell, c && c[:priority]),
      sticky && "sticky top-0 z-1 bg-panel"
    ]
    |> with_card(shell, :th)
  end

  defp with_card(classes, %{card: nil}, _), do: classes
  defp with_card(classes, %{card: card}, :th), do: [classes, card.th]
  defp with_card(classes, _shell, :th_cb), do: classes

  # A body cell. `kind`: `:cb`, `:col`, `:action`, `:edit`, `:foot`, `:plain`, `:plain_num`.
  defp td_class(kind, c, shell, card?, sub? \\ false)

  defp td_class(:cb, _c, shell, card?, _sub?) do
    [@cb, card? && card_cell(shell, :cb)]
  end

  defp td_class(:col, c, shell, card?, _sub?) do
    flex? = flex_col?(c)
    wrap? = card? && c[:truncate] == false
    keep? = card? && c[:card]

    [
      @td_aligns[c[:align]],
      pc(shell, c[:priority]),
      c[:dim] && "opacity-[.32]",
      if(flex? and not wrap?, do: "w-full max-w-0 overflow-hidden text-ellipsis"),
      if(flex? and wrap?,
        do: "w-full max-w-none overflow-hidden text-ellipsis whitespace-normal",
        else: sizing_wrap(c)
      ),
      sizing_class(c, shell),
      card? && card_role(shell, c[:role], keep?, wrap?),
      c[:class]
    ]
  end

  defp td_class(:action, a, shell, card?, _sub?) do
    [
      "text-right tabular-nums whitespace-nowrap",
      pc(shell, a && a[:priority]),
      card? && card_cell(shell, if(a[:card] == false, do: :nocard, else: :act))
    ]
  end

  defp td_class(:edit, _c, shell, card?, _sub?) do
    ["whitespace-normal", card? && card_cell(shell, :edit)]
  end

  defp td_class(:foot, f, shell, _card?, _sub?) do
    [
      @td,
      @px,
      @td_aligns[f[:align]],
      pc(shell, f[:priority]),
      "border-t border-line font-semibold whitespace-nowrap",
      f[:class]
    ]
  end

  defp td_class(:plain_num, _c, shell, card?, _sub?) do
    ["text-right tabular-nums whitespace-nowrap", card? && shell.card.td_hidden]
  end

  defp td_class(:plain, _c, shell, _card?, sub?) do
    ["whitespace-nowrap", sub? && shell.card && shell.card.sub_td]
  end

  defp card_cell(%{card: nil}, _), do: nil
  defp card_cell(%{card: card}, :nocard), do: [card.td_base, card.td_hidden]
  defp card_cell(%{card: card}, role), do: [card.td_base, card[role]]

  defp card_role(shell, role, keep?, wrap?) do
    cond do
      keep? -> card_cell(shell, :keep)
      role in ~w(head status value) -> card_cell(shell, String.to_existing_atom(role))
      role == "title" -> card_cell(shell, if(wrap?, do: :title_wrap, else: :title))
      true -> [shell.card.td_base, shell.card.td_hidden]
    end
  end

  defp sub_row_class(shell, card?), do: [@row_sub, card? && shell.card.sub_tr]

  defp pc(_shell, p) when p not in 1..4, do: nil
  defp pc(shell, p), do: shell.hide[p]

  # -- card layout / details panel / copy columns -------------------------------------------------

  # The card layout needs a width and at least one column with a role.
  defp card?(%{card_below: nil}), do: false
  defp card?(%{col: cols}), do: Enum.any?(cols, &(&1[:role] in @roles))

  defp has_priority?(cols), do: Enum.any?(cols, &(&1[:priority] in 1..4))

  # The columns that may leave, for the panel; a column with the label of a `:detail` is not repeated.
  defp panel_cols(%{details: false}, _shell), do: []

  defp panel_cols(%{col: cols, detail: details}, shell) do
    labels = for d <- details, do: d[:label]

    for c <- cols, c[:priority] in 1..4, c[:label] not in labels do
      %{
        priority: c.priority,
        label: c[:label],
        slot: c,
        show: shell.widths[c.priority] && Layout.show(shell.widths[c.priority])
      }
    end
  end

  # `role` attributes only when the layout turns table parts into grid boxes (which drops their
  # native table semantics in some browsers).
  defp ra(true, role), do: [role: role]
  defp ra(_, _), do: []

  defp row_extra(card?, panel, editing, rid) do
    []
    |> Kernel.++(if editing, do: [{:"data-editing", "true"}], else: [])
    |> Kernel.++(
      if panel,
        do: [
          {:tabindex, "0"},
          {:"aria-expanded", "false"},
          {:"data-ct-row", ""}
          | if(rid, do: [{:"aria-controls", rid <> "-panel"}], else: [])
        ],
        else: []
    )
    |> Kernel.++(ra(card?, "row"))
  end

  # Only a flexible track (`minmax(...)`, `fr`) gets the ellipsis treatment; `max-content` is the
  # table's natural width.
  defp flex_col?(c) do
    w = c[:width]

    c[:truncate] != false and is_binary(w) and
      (String.contains?(w, "fr") or String.contains?(w, "minmax"))
  end

  # -- column sizing: `grow`, `wrap`, `min` -----------------------------------------------------
  # A `width` always wins: the column keeps its CSS track and `grow`/`wrap`/`min` are ignored.
  # Without them nothing changes (every class and style below is nil).

  # the weight of a growing column: 0 when it does not grow
  defp grow_of(%{width: w}) when is_binary(w), do: 0
  defp grow_of(%{grow: g}) when is_integer(g) and g > 0, do: g
  defp grow_of(_), do: 0

  defp grow_total(cols), do: cols |> Enum.map(&grow_of/1) |> Enum.sum()

  # `whitespace-nowrap` stays the default; `auto` lets the text wrap (a growing column does so by
  # itself); `truncate` is one line cut with an ellipsis that never widens the table.
  defp sizing_wrap(c), do: wrap_class(sizing_mode(c))

  # the class of a `wrap` value; shared by the `:col` and by the cells of the composed API
  defp wrap_class("auto"), do: "whitespace-normal"
  defp wrap_class("truncate"), do: "max-w-0 overflow-hidden text-ellipsis whitespace-nowrap"
  defp wrap_class(_), do: "whitespace-nowrap"

  # `@td` (+ `@px`) of a composed-API cell; `padded={false}` takes the padding out
  defp td_pad(false), do: [@td_flush]
  defp td_pad(_), do: [@td, @px]

  defp sizing_mode(%{width: w}) when is_binary(w), do: "never"
  defp sizing_mode(%{wrap: w}) when w in ~w(auto never truncate), do: w
  defp sizing_mode(c), do: if(grow_of(c) > 0, do: "auto", else: "never")

  # `w-full` for the only growing column; with several, each takes `weight / total` of the table
  # (the variables are on the cell). The card layout puts `w-auto` after them (a later variant).
  defp sizing_class(c, shell) do
    g = grow_of(c)

    cond do
      g == 0 -> sizing_min(c)
      g == shell.grow_total -> ["w-full", sizing_min(c)]
      true -> ["w-[calc(100%*var(--g)/var(--gt))]", sizing_min(c)]
    end
  end

  defp sizing_min(%{width: w}) when is_binary(w), do: nil
  defp sizing_min(%{min: m}) when is_binary(m), do: "min-w-[var(--cmin)]"
  defp sizing_min(_), do: nil

  defp sizing_style(c, shell) do
    g = grow_of(c)

    [
      (g > 0 and g != shell.grow_total) && "--g:#{g};--gt:#{shell.grow_total}",
      sizing_min(c) && "--cmin:#{c.min}"
    ]
    |> Enum.filter(& &1)
  end

  defp col_style(c, shell) do
    min =
      case c[:width] && Regex.run(~r/minmax\(\s*(\d+)px/, c[:width]) do
        [_, px] -> "min-width:" <> px <> "px"
        _ -> nil
      end

    case Enum.reject(sizing_style(c, shell) ++ [min, c[:style]], &(&1 in [nil, false])) do
      [] -> nil
      parts -> Enum.join(parts, ";")
    end
  end

  attr :col, :any, required: true
  attr :item, :any, required: true
  attr :shell, :map, required: true
  attr :toast, :boolean, default: false
  attr :toast_message, :string, default: nil

  attr :locale, :string, default: nil

  defp copy_cell(assigns) do
    c = assigns.col
    text = to_string(c.copy.(assigns.item))
    copy_label = c[:copy_label] || I18n.t("table.copy", assigns[:locale])
    copied_label = c[:copied_label] || I18n.t("table.copied", assigns[:locale])

    assigns =
      assign(assigns,
        text: text,
        copy_label: copy_label,
        copied_label: copied_label,
        toast: copy_toast(c, assigns, text, copied_label),
        inline: c[:copy_show] == "inline",
        value_label: c[:copy_tip] == "value_label"
      )

    ~H"""
    <span
      data-part="table-copy-value"
      class={[(@inline && "mr-2 inline") || "hidden", @shell.card && @shell.card.val]}
    >{LedgerUI.Helpers.render_slot_full(@col, @item)}</span>
    <button
      type="button"
      data-part="table-copy"
      class="group/copy relative inline-grid size-[26px] cursor-pointer place-items-center rounded-md border-0 bg-transparent p-0 align-middle text-muted hover:bg-hover hover:text-ink focus-visible:bg-hover focus-visible:text-ink"
      data-lu-ct-copy={@text}
      data-lu-ct-toast={@toast}
      aria-label={@copy_label}
    >
      <.icon name="copy" size="sm" class="pointer-events-none group-data-[copied]/copy:hidden" />
      <.icon
        name="check"
        size="sm"
        class="pointer-events-none text-pos group-not-data-[copied]/copy:hidden"
      />
      <span
        data-part="table-copy-tip"
        class="pointer-events-none absolute bottom-[calc(100%+6px)] left-1/2 z-6 hidden -translate-x-1/2 rounded-md bg-ink px-2 py-[5px] text-xs leading-4 whitespace-nowrap text-on-inverse shadow-sm group-hover/copy:block group-focus-visible/copy:block [&_b]:font-semibold"
        role="tooltip"
      >
        <span data-part="table-copy-idle" class="group-data-[copied]/copy:hidden">
          <%= if @value_label do %>
            <b data-part="table-copy-text" class="font-mono">{@text}</b> · {@copy_label}
          <% else %>
            {@text}
          <% end %>
        </span>
        <span data-part="table-copy-done" class="hidden group-data-[copied]/copy:inline">
          <%= if @value_label do %>
            <b data-part="table-copy-text" class="font-mono">{@text}</b> · {@copied_label}
          <% else %>
            {@copied_label}
          <% end %>
        </span>
      </span>
    </button>
    """
  end

  # The message of the toast a copy shows (`**value**` is bold in the toaster), or nil for none.
  defp copy_toast(c, assigns, text, copied_label) do
    on? = Map.get(c, :copy_toast, assigns.toast)

    if on? do
      template = c[:copy_toast_message] || assigns.toast_message || "%s · " <> copied_label
      String.replace(template, "%s", "**" <> String.replace(text, "**", "") <> "**")
    end
  end

  # `style={nil}` renders `style=""`, so an optional style goes through a spread.
  defp st(v) when v in [nil, false], do: []
  defp st(v), do: [style: v]

  defp col_info(c, a, shell) do
    sort_key = c[:sort_key]

    %{
      label: c[:label],
      sort_key: sort_key,
      priority: c[:priority] && c.priority > 0 && c.priority,
      th_class: th_class(:col, c, shell, a.sticky_header)
    }
  end

  # The classes of a body cell are the same on every row, so they are worked out once per table
  # (per column for `:col` and `:action`), not in the loop over the rows.
  defp cell_info(c, shell) do
    %{col: c, class: td_class(:col, c, shell, shell.card != nil), style: st(col_style(c, shell))}
  end

  defp action_cell_info(a, shell) do
    %{col: a, class: td_class(:action, a, shell, shell.card != nil)}
  end

  defp td_classes(shell) do
    card? = shell.card != nil

    %{
      cb: td_class(:cb, nil, shell, card?),
      edit: td_class(:edit, nil, shell, card?),
      plain_num: td_class(:plain_num, nil, shell, card?),
      plain_sub: td_class(:plain, nil, shell, card?, true),
      sub_row: sub_row_class(shell, card?)
    }
  end

  @doc false
  # The values a component derives in its function body are assigned from scratch on every call,
  # so `assign/3` marks them all as changed, even when they came out the same (the previous
  # assigns are not kept). Called at the end of the derivation with the `__changed__` the
  # component came in with: when the call changed only the selection (the rows and the `:empty` slot, which gets the selection), the `keys`
  # (which do not depend on them) are taken back out of `__changed__`, and the LiveView does not
  # send the header, the classes and the structure again (#70).
  def settle(assigns, %{} = changed0, keys) do
    if Map.keys(changed0) -- [:selected, :all_selected, :rows, :empty] == [] do
      # Not even the selection or the rows changed (a new description, say): the checked state
      # (`selected_set`, `head_all`) did not change either, and the rows are not sent again.
      keys =
        if Map.has_key?(changed0, :selected) or Map.has_key?(changed0, :all_selected) or
             Map.has_key?(changed0, :rows),
           do: keys,
           else: [:selected_set, :head_all, :entries | keys]

      %{assigns | __changed__: Map.drop(assigns.__changed__, keys)}
    else
      assigns
    end
  end

  def settle(assigns, _changed0, _keys), do: assigns

  @doc false
  # Like `settle/3`, but for `groups` of `{keys, ignore}`: the `keys` leave `__changed__` when
  # everything the call changed is in `ignore`.
  def settle_table(assigns, %{} = changed0, groups) do
    changed = Map.keys(changed0)

    drop =
      for {keys, ignore} <- groups, changed -- ignore == [], key <- keys, do: key

    %{assigns | __changed__: Map.drop(assigns.__changed__, drop)}
  end

  def settle_table(assigns, _changed0, _groups), do: assigns

  defp head_all(%{all_selected: nil, selected: [], rows: rows}, _set) when is_list(rows),
    do: false

  defp head_all(%{all_selected: nil, rows: rows} = a, set) when is_list(rows) do
    keys = Enum.map(rows, fn row -> row_key(a.row_key, a.row_id, row, a.row_item.(row)) end)
    sel = Enum.count(keys, &MapSet.member?(set, &1))

    cond do
      keys != [] and sel == length(keys) -> true
      sel > 0 -> :some
      true -> false
    end
  end

  defp head_all(%{all_selected: nil}, _set), do: false
  defp head_all(%{all_selected: v}, _set), do: v

  # -- shell (wrapper, classes, container query classes) -------------------------------------------

  defp shell(a, cols) do
    priorities = for c <- cols, p = c[:priority], p in 1..4, do: p
    card? = card?(%{card_below: a.card_below, col: cols})

    container? =
      a.container || (a.container == nil and (priorities != [] or card? or a.details))

    widths =
      for {w, p} <- Enum.with_index(a.breakpoints, 1), into: %{}, do: {p, w}

    %{
      class: table_class(a),
      wrap_class: [
        if(Map.get(a, :bleed),
          do: "overflow-auto",
          else: "overflow-auto rounded-lg border border-line bg-panel"
        ),
        container? && "@container",
        a.wrapper_class
      ],
      group: a.row_groups == true,
      grow_total: grow_total(cols),
      widths: widths,
      hide: for({p, w} <- widths, into: %{}, do: {p, Layout.hide(w)}),
      card: if(card?, do: Map.new(Layout.card(a.card_below)))
    }
  end

  defp table_class(a) do
    hover? = a.variant != "basic"
    group? = Map.get(a, :row_groups) == true

    # the rows mode: `rows` given (the hand-written table and the skeleton keep their cell classes)
    lean? = Map.get(a, :rows) != nil

    cx([
      @table_base,
      if(group? and a.variant == "zebra", do: @zebra_group, else: @variant_classes[a.variant]),
      lean? && @lean_cells,
      lean? && if(group?, do: @group_last, else: @lean_last),
      hover? && "[&_tbody_tr:hover]:[--h:var(--lu-bg-hover)]",
      @rounded[a.rounded],
      Map.get(a, :bleed) && @bleed_edges,
      a.compact && "[--tpx:12px] [--th-py:9px]",
      a.compact && a.variant not in ["data", "data-grid"] && "[--td-py:8px]",
      a.class
    ])
  end

  defp aria_sort(key, key, "asc"), do: "ascending"
  defp aria_sort(key, key, "desc"), do: "descending"
  defp aria_sort(_, _, _), do: "none"

  defp next_dir(key, key, "asc"), do: "desc"
  defp next_dir(_, _, _), do: "asc"

  # the arrows of the columns that are not the sorted one show on hover/focus only (no layout shift)
  defp sort_icon_class(key, key), do: nil

  defp sort_icon_class(_, _),
    do:
      "opacity-0 transition-opacity group-hover/th:opacity-100 group-focus-visible/th:opacity-100"

  defp sort_icon(key, key, "asc"), do: "arrow-up"
  defp sort_icon(key, key, "desc"), do: "arrow-down"
  defp sort_icon(_, _, _), do: "updown"

  @doc false
  def sort_icon_name(key, by, dir), do: sort_icon(key, by, dir)
  @doc false
  def next_direction(key, by, dir), do: next_dir(key, by, dir)
  @doc false
  def aria_sort_value(key, by, dir), do: aria_sort(key, by, dir)

  # -- table_head -------------------------------------------------------------------------------

  attr :sort_by, :string, default: nil
  attr :sort_dir, :string, default: "asc", values: ~w(asc desc)
  attr :on_sort, :any, default: nil

  attr :on_select_all, :any,
    default: nil,
    doc: "Adds a select-all checkbox cell first; the event it sends."

  attr :all_selected, :boolean, default: false
  attr :some_selected, :boolean, default: false
  attr :select_all_id, :string, default: nil
  attr :select_all_label, :string, default: nil
  attr :sort_label, :string, default: nil
  attr :target, :any, default: nil
  attr :sticky_header, :boolean, default: false
  attr :class, :any, default: nil, doc: "Classes of the `<tr>`."
  attr :rest, :global, doc: "Attributes of the `<thead>`."

  slot :col, doc: "A header cell; its content is the label (or give `label`)." do
    attr :label, :string
    attr :class, :any
    attr :align, :string, values: ~w(left center right)
    attr :colspan, :any
    attr :priority, :integer
    attr :sort_key, :string
    attr :title, :string
    attr :id, :string
  end

  slot :inner_block, doc: "Extra `<th>` cells after the columns, or further header rows."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def table_head(assigns) do
    assigns = I18n.texts(assigns, select_all_label: "table.select_all")

    assigns =
      assigns
      |> assign(
        :sel_id,
        assigns.select_all_id || (assigns.rest[:id] && assigns.rest[:id] <> "-select-all")
      )
      |> assign(:cb_class, [
        @th,
        @cb,
        @th_aligns[nil],
        assigns.sticky_header && "sticky top-0 z-1 bg-panel"
      ])
      |> assign(:cols, Enum.map(assigns.col, &head_col(&1, assigns)))

    ~H"""
    <thead {@rest}>
      <tr data-part="table-head-row" class={@class}>
        <th :if={@on_select_all} data-part="table-head-cell" class={@cb_class}>
          <.table_checkbox
            id={@sel_id}
            label={@select_all_label}
            checked={@all_selected}
            indeterminate={@some_selected and not @all_selected}
            on_click={@on_select_all}
            values={%{"selected" => to_string(!@all_selected)}}
            target={@target}
          />
        </th>
        <th
          :for={c <- @cols}
          data-part="table-head-cell"
          class={c.class}
          colspan={c.colspan}
          aria-sort={c.aria_sort}
          aria-label={c.aria_label}
          tabindex={c.sort_key && @on_sort && "0"}
          phx-click={c.sort_key && @on_sort && @on_sort}
          phx-keydown={c.sort_key && @on_sort && @on_sort}
          phx-key={c.sort_key && @on_sort && "Enter"}
          phx-target={c.sort_key && @on_sort && @target}
          phx-value-column={c.sort_key && @on_sort && c.sort_key}
          phx-value-direction={c.sort_key && @on_sort && c.next}
          {c.rest}
        >
          {c.label || render_slot(c.slot)}
          <%= if c.sort_key do %>
            <.icon name={c.icon} size="sm" class={c.icon_class} />
          <% end %>
        </th>
        {render_slot(@inner_block)}
      </tr>
    </thead>
    """
  end

  defp head_col(c, a) do
    key = c[:sort_key]
    label = c[:label]

    %{
      class: [
        @th,
        @px,
        @th_aligns[c[:align]],
        key && "group/th cursor-pointer [&_svg]:ml-0.5 [&_svg]:size-3",
        c[:class],
        a.sticky_header && "sticky top-0 z-1 bg-panel"
      ],
      colspan: c[:colspan],
      priority: c[:priority] && c.priority > 0 && c.priority,
      sort_key: key,
      aria_sort: key && a.on_sort && aria_sort(key, a.sort_by, a.sort_dir),
      aria_label: key && a.sort_label && sort_aria_label(a.sort_label, label),
      icon: key && sort_icon(key, a.sort_by, a.sort_dir),
      icon_class: key && sort_icon_class(key, a.sort_by),
      next: key && next_dir(key, a.sort_by, a.sort_dir),
      rest:
        Map.drop(c, [
          :__slot__,
          :inner_block,
          :label,
          :class,
          :align,
          :colspan,
          :priority,
          :sort_key
        ]),
      label: label,
      slot: c
    }
  end

  defp sort_aria_label(template, label) do
    if String.contains?(template, "%{label}"),
      do: String.replace(template, "%{label}", label || ""),
      else: template <> " " <> (label || "")
  end

  # -- table_body -------------------------------------------------------------------------------

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def table_body(assigns) do
    ~H"""
    <tbody data-part="table-body" class={@class} {@rest}>{render_slot(@inner_block)}</tbody>
    """
  end

  # -- table_row --------------------------------------------------------------------------------

  attr :selected, :boolean, default: nil, doc: "`true` checks the box and tints the row."
  attr :on_click, :any, default: nil

  attr :on_select, :any,
    default: nil,
    doc: "Adds a selection checkbox cell first; the event it sends."

  attr :select_value, :any, default: nil, doc: "Sent as `\"id\"` by the checkbox."
  attr :select_label, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :cell, doc: "A `<td>` of the row." do
    attr :class, :any
    attr :align, :string, values: ~w(left center right)
    attr :colspan, :any
    attr :rowspan, :any
    attr :priority, :integer
    attr :title, :string
    attr :id, :string

    attr :wrap, :string,
      values: ~w(auto never truncate),
      doc:
        "`never` (default): one line; `auto`: the text may wrap; `truncate`: one line with an ellipsis."

    attr :padded, :boolean, doc: "`false` takes the cell padding out (default `true`)."
  end

  slot :inner_block, doc: "Free cells after the `:cell` ones."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def table_row(assigns) do
    assigns = I18n.texts(assigns, select_label: "table.select_row")

    assigns =
      assigns
      |> assign(
        :classes,
        cx([assigns.selected && @row_sel, assigns.on_click && "cursor-pointer", assigns.class])
      )
      |> assign(:cells, Enum.map(assigns.cell, &cell_info/1))
      |> assign(:cb_class, [@td, @cb])
      |> assign(:tr_rest, click_attrs(assigns.rest, assigns.on_click, assigns.target))

    ~H"""
    <tr data-part="table-row" class={@classes} {@tr_rest}>
      <td :if={@on_select} data-part="table-cell" class={@cb_class}>
        <.table_checkbox
          middle
          checked={@selected == true}
          label={@select_label}
          on_click={@on_select}
          values={%{"id" => @select_value, "selected" => to_string(@selected != true)}}
          target={@target}
        />
      </td>
      <td
        :for={{c, i} <- Enum.with_index(@cells)}
        data-part="table-cell"
        class={c.class}
        colspan={c.colspan}
        rowspan={c.rowspan}
        {c.rest}
      >
        {render_slot(Enum.at(@cell, i))}
      </td>
      {render_slot(@inner_block)}
    </tr>
    """
  end

  defp cell_info(c) do
    %{
      class: [
        td_pad(c[:padded]),
        @td_aligns[c[:align]],
        wrap_class(c[:wrap]),
        c[:class]
      ],
      colspan: c[:colspan],
      rowspan: c[:rowspan],
      priority: c[:priority] && c.priority > 0 && c.priority,
      rest:
        Map.drop(c, [
          :__slot__,
          :inner_block,
          :class,
          :align,
          :colspan,
          :rowspan,
          :priority,
          :wrap,
          :padded
        ])
    }
  end

  # -- table_cell -------------------------------------------------------------------------------

  attr :header, :boolean, default: false, doc: "Renders a `<th scope=\"row\">`."
  attr :align, :string, default: nil, values: [nil, "left", "center", "right"]
  attr :colspan, :any, default: nil
  attr :rowspan, :any, default: nil
  attr :priority, :integer, default: nil

  attr :wrap, :string,
    default: "never",
    values: ~w(auto never truncate),
    doc:
      "`never`: one line; `auto`: the text may wrap; `truncate`: one line with an ellipsis. Ignored with `header`."

  attr :padded, :boolean,
    default: true,
    doc: "`false` takes the cell padding out (for edge to edge content). Ignored with `header`."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def table_cell(%{header: true} = assigns) do
    assigns =
      assign(assigns, :classes, [@th, @px, @th_aligns[assigns.align], assigns.class])

    ~H"""
    <th
      scope="row"
      data-part="table-head-cell"
      class={@classes}
      colspan={@colspan}
      rowspan={@rowspan}
      {@rest}
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  def table_cell(assigns) do
    assigns =
      assign(assigns, :classes, [
        td_pad(assigns.padded),
        @td_aligns[assigns.align],
        wrap_class(assigns.wrap),
        assigns.class
      ])

    ~H"""
    <td
      data-part="table-cell"
      class={@classes}
      colspan={@colspan}
      rowspan={@rowspan}
      {@rest}
    >
      {render_slot(@inner_block)}
    </td>
    """
  end

  # -- table_foot -------------------------------------------------------------------------------

  attr :class, :any, default: nil, doc: "Classes of the `:cell` row."
  attr :rest, :global

  slot :cell, doc: "A `<td>` of the totals row." do
    attr :class, :any
    attr :align, :string, values: ~w(left center right)
    attr :colspan, :any
    attr :priority, :integer

    attr :wrap, :string,
      values: ~w(auto never truncate),
      doc: "`never` (default), `auto` or `truncate`."

    attr :padded, :boolean, doc: "`false` takes the cell padding out (default `true`)."
  end

  slot :inner_block, doc: "Free `<tr>` rows after the `:cell` row."

  def table_foot(assigns) do
    assigns = assign(assigns, :cells, Enum.map(assigns.cell, &foot_cell_class/1))

    ~H"""
    <tfoot {@rest}>
      <tr :if={@cell != []} data-part="table-foot-row" class={@class}>
        <td
          :for={{c, class} <- Enum.zip(@cell, @cells)}
          data-part="table-cell"
          class={class}
          colspan={c[:colspan]}
        >
          {render_slot(c)}
        </td>
      </tr>
      {render_slot(@inner_block)}
    </tfoot>
    """
  end

  defp foot_cell_class(c) do
    [
      td_pad(c[:padded]),
      "border-t border-line font-semibold",
      wrap_class(c[:wrap]),
      align_class(c[:align]),
      c[:class]
    ]
  end

  defp align_class(align), do: @td_aligns[align]

  # -- table_empty ------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :class, :any, default: nil, doc: "Classes of the cell."

  attr :wrap, :string,
    default: "never",
    values: ~w(auto never truncate),
    doc:
      "`never` (default, as before): one line; `auto`: a long message wraps instead of widening the table."

  attr :rest, :global
  slot :inner_block, required: true

  def table_empty(assigns) do
    assigns = assign(assigns, :td, [@td, @px, wrap_class(assigns.wrap)])

    ~H"""
    <tr id={@id} data-part="table-empty" class="not-only:hidden" {@rest}>
      <td
        data-part="table-cell"
        colspan="1000"
        class={[@td, @class]}
        style="text-align:center"
      >
        {render_slot(@inner_block)}
      </td>
    </tr>
    """
  end

  # -- table_checkbox ---------------------------------------------------------------------------

  attr :id, :string, default: nil
  attr :checked, :boolean, default: false

  attr :indeterminate, :boolean,
    default: false,
    doc: "Draws the dash of a partial selection (needs an `id`, for its hook)."

  attr :label, :string, required: true, doc: "The `aria-label` of the box."

  attr :middle, :boolean,
    default: false,
    doc: "`vertical-align: middle` (the box of a body row; the header's sits on the baseline)."

  attr :on_click, :any, default: nil
  attr :values, :map, default: %{}, doc: "Sent as `phx-value-*` with `on_click`."
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, doc: "Attributes of the `<label>`."

  def table_checkbox(assigns) do
    changed0 = Map.get(assigns, :__changed__)
    values = for {k, v} <- assigns.values, v != nil, into: %{}, do: {"phx-value-#{k}", v}

    assigns =
      assigns
      |> assign(:classes, [
        @check_label,
        assigns.middle && "align-middle",
        Color.vars("primary"),
        assigns.class
      ])
      |> assign(:input_class, Checkbox.input_class("checkbox", "md", "square", false, false))
      |> assign(:values_attrs, values)
      |> assign(:hook, assigns.id && "LedgerUI.TableCheckbox")
      |> assign(:ind, assigns.indeterminate && "1")

    # A row that changes sends its box again: without this, with the classes (#86).
    assigns =
      LedgerUI.Helpers.settle(assigns, changed0,
        classes: [:middle, :class],
        input_class: [],
        values_attrs: [:values],
        hook: [:id],
        ind: [:indeterminate]
      )

    ~H"""
    <label
      :if={@middle and is_nil(@class)}
      data-part="table-checkbox"
      class="inline-flex cursor-pointer items-start gap-2.5 text-[14px] text-ink align-middle [--c:var(--color-accent)] [--c-on:var(--color-accent-foreground)] [--c-soft:var(--lu-accent-soft)] [--c-ink:var(--color-accent-content)]"
      {@rest}
    ><input
      id={@id}
      data-part="table-checkbox-input"
      type="checkbox"
      class="m-0 mt-px grid shrink-0 appearance-none place-items-center border-[1.5px] transition-[background-color,border-color] duration-[120ms] focus-visible:border-accent-500 focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none size-[18px] rounded-[4px] cursor-pointer border-[color-mix(in_oklab,var(--lu-line-strong),var(--lu-muted)_30%)] bg-panel hover:border-muted checked:border-(--c) checked:bg-(--c) checked:after:content-[''] checked:after:border-2 checked:after:border-t-0 checked:after:border-r-0 checked:after:border-(--c-on) checked:after:[transform:rotate(-45deg)_translate(1px,-1px)] checked:after:h-[7px] checked:after:w-[11px] indeterminate:relative indeterminate:border-(--c) indeterminate:bg-(--c) indeterminate:after:absolute indeterminate:after:top-1/2 indeterminate:after:left-1/2 indeterminate:after:h-0.5 indeterminate:after:w-2 indeterminate:after:-translate-1/2 indeterminate:after:rounded-[1px] indeterminate:after:bg-(--c-on) indeterminate:after:content-[''] aria-[checked=mixed]:relative aria-[checked=mixed]:border-(--c) aria-[checked=mixed]:bg-(--c) aria-[checked=mixed]:after:absolute aria-[checked=mixed]:after:top-1/2 aria-[checked=mixed]:after:left-1/2 aria-[checked=mixed]:after:h-0.5 aria-[checked=mixed]:after:w-2 aria-[checked=mixed]:after:-translate-1/2 aria-[checked=mixed]:after:rounded-[1px] aria-[checked=mixed]:after:bg-(--c-on) aria-[checked=mixed]:after:content-['']"
      aria-label={@label}
      checked={@checked}
      data-ind={@ind}
      phx-hook={@hook}
      phx-click={@on_click}
      phx-target={@on_click && @target}
      {@values_attrs}
    /></label>
    <label :if={!(@middle and is_nil(@class))} data-part="table-checkbox" class={@classes} {@rest}><input
      id={@id}
      data-part="table-checkbox-input"
      type="checkbox"
      class={@input_class}
      aria-label={@label}
      checked={@checked}
      data-ind={@ind}
      phx-hook={@hook}
      phx-click={@on_click}
      phx-target={@on_click && @target}
      {@values_attrs}
    /></label>
    """
  end

  # -- expandable rows --------------------------------------------------------------------------

  @doc """
  The `JS` that opens or closes the detail row of the row with DOM id `row_id`
  (`table_expand_toggle/1` and `table_detail_row/1`).
  """
  def table_toggle_row(row_id, js \\ %JS{}) do
    js
    |> JS.toggle(to: "#" <> row_id <> "-detail", display: "table-row")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "#" <> row_id <> "-toggle")
  end

  attr :row_id, :string, required: true
  attr :open, :boolean, default: false
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def table_expand_toggle(assigns) do
    assigns = I18n.texts(assigns, label: "table.toggle_details")

    assigns = assign(assigns, :js, table_toggle_row(assigns.row_id))

    ~H"""
    <Button.button
      id={@row_id <> "-toggle"}
      canvas
      appearance="ghost"
      size="sm"
      icon
      class={@class}
      aria-label={@label}
      aria-expanded={to_string(@open)}
      phx-click={@js}
      {@rest}
    >
      <.icon name="chevron-down" size="sm" />
    </Button.button>
    """
  end

  attr :row_id, :string, required: true
  attr :open, :boolean, default: false
  attr :class, :any, default: nil, doc: "Classes of the detail panel."

  attr :wrap, :string,
    default: "never",
    values: ~w(auto never truncate),
    doc:
      "`never` (default, as before): one line; `auto`: the content may wrap (free text, paragraphs)."

  attr :rest, :global
  slot :inner_block, required: true

  def table_detail_row(assigns) do
    assigns =
      assigns
      |> assign(:row_class, @row_sub)
      |> assign(:td, [@td, @px, wrap_class(assigns.wrap)])

    ~H"""
    <tr
      id={@row_id <> "-detail"}
      data-part="table-detail-row"
      class={@row_class}
      {st(!@open && "display:none")}
      {@rest}
    >
      <td data-part="table-cell" colspan="1000" class={@td}>
        <div data-part="table-detail" class={@class}>{render_slot(@inner_block)}</div>
      </td>
    </tr>
    """
  end

  # -- table_skeleton ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :rows, :integer, default: 5
  attr :columns, :list, default: [], doc: "Header labels; one column each."
  attr :cols, :integer, default: 4, doc: "How many columns when `columns` is empty."
  attr :variant, :string, default: nil, values: [nil | @variants]
  attr :rounded, :string, default: nil, values: [nil, "row", "top", "none"]
  attr :compact, :boolean, default: false
  attr :headless, :boolean, default: false

  attr :shapes, :list,
    default: [],
    doc: "Per column: `text` (a bar), `avatar`, `pill` or `number`."

  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @skel "block bg-[linear-gradient(90deg,var(--lu-bg-sunken)_25%,var(--lu-bg-hover)_50%,var(--lu-bg-sunken)_75%)] bg-[length:200%_100%] animate-[lu-shim_1.4s_linear_infinite]"

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def table_skeleton(assigns) do
    assigns = I18n.texts(assigns, label: "common.loading")

    n = if assigns.columns == [], do: assigns.cols, else: length(assigns.columns)

    assigns =
      assigns
      |> assign(:n, n)
      |> assign(:skel, @skel)
      |> assign(:th, [@th, @px, @th_aligns[nil]])
      |> assign(:td, [@td, @px, "whitespace-nowrap"])
      |> assign(:shape_list, for(i <- 0..(n - 1), do: Enum.at(assigns.shapes, i, "text")))
      |> assign(
        :table_class,
        table_class(%{
          variant: assigns.variant,
          rounded: assigns.rounded,
          compact: assigns.compact,
          class: assigns.class
        })
      )
      |> assign(:wrap_class, "overflow-auto rounded-lg border border-line bg-panel")

    ~H"""
    <div
      data-part="table-wrap"
      class={@wrap_class}
      role="status"
      aria-busy="true"
      aria-label={@label}
    >
      <table id={@id} data-part="table" class={@table_class} {@rest}>
        <thead :if={!@headless}>
          <tr>
            <th :for={i <- 0..(@n - 1)} data-part="table-head-cell" class={@th}>
              <%= if @columns != [] do %>
                {Enum.at(@columns, i)}
              <% else %>
                <span data-part="table-skeleton" class={[@skel, "h-3 w-3/5 rounded-[6px]"]}></span>
              <% end %>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={_ <- 1..max(@rows, 1)} data-part="table-row">
            <td :for={s <- @shape_list} data-part="table-cell" class={@td}>
              <%= case s do %>
                <% "avatar" -> %>
                  <div data-part="table-skeleton-avatar" class="flex flex-nowrap items-center gap-2.5">
                    <span data-part="table-skeleton" class={[@skel, "size-7 flex-none rounded-full"]}></span>
                    <span data-part="table-skeleton" class={[@skel, "h-3 w-3/5 rounded-[6px]"]}></span>
                  </div>
                <% "pill" -> %>
                  <span data-part="table-skeleton" class={[@skel, "h-5 w-14 rounded-full"]}></span>
                <% "number" -> %>
                  <span data-part="table-skeleton" class={[@skel, "ml-auto h-3 w-2/5 rounded-[6px]"]}></span>
                <% _ -> %>
                  <span data-part="table-skeleton" class={[@skel, "h-3 w-[70%] rounded-[6px]"]}></span>
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
