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

  ## Events

  Every event attr takes an event name or a `%JS{}`; `target` sets `phx-target`.

    * `on_sort`: `%{"column" => sort_key, "direction" => "asc" | "desc"}` (the direction to sort
      by next). A column with `sort_key` gets `class="sort"` and the arrows; `sort_by`/`sort_dir`
      mark the current order.
    * `on_select`: `%{"id" => key, "selected" => "true" | "false"}` (the new state of that row).
      `on_select_all`: `%{"selected" => "true" | "false"}`. `selected` lists the checked keys; the
      key is `row_key.(row)` or the row's DOM id. With a stream, `stream_insert` the rows whose
      selection changed and give `all_selected`.

  ## Hand-written tables

  Without `rows`, the table renders its inner block: `table_head/1`, `table_body/1`,
  `table_row/1`, `table_cell/1`, `table_foot/1` and `table_empty/1` (see each).

  ## Columns that leave by priority

  A `:col` with `priority` 1, 2 or 3 (up to 4) leaves (header, cells and `:foot` cell together) when
  the table's own box (a container, `@container`) gets narrower than the matching `breakpoints`
  entry (720, 560 and 420px by default). Tailwind only sees literal class names, so the widths are
  a fixed list (the `hide_widths` list of the internal Table.Layout module); another width raises
  `ArgumentError`.

  ## Card layout, details panel, copy columns (used by `card_table/1`)

  Extra attributes `card_below`, `details`, `row_editing`, `row_action` and the column attributes
  `role`, `width`, `truncate`, `card`, `copy*` back the "card" table (see
  `LedgerUI.Components.CardTable`): under `card_below` px each row is a two-line grid placed by the
  `role` of its cells (`head`, `status`, `title`, `value`); `card_below` is one of
  the `card_widths` list of the internal Table.Layout module. `details` adds a panel under the clicked row
  (hook `LedgerUI.CardTable`) with the `:detail` slots and the columns that left by priority;
  `copy` turns a cell into a copy button; `row_editing` swaps a row for the `:edit` slot.

  ## Not implemented

  `peek` / `peek_label` (the panel with the hidden columns) and `bleed` are accepted but draw
  nothing yet. `borderless` is accepted: the design has no style for it.
  """
  use LedgerUI.Component

  alias LedgerUI.Color
  alias LedgerUI.Components.Button
  alias LedgerUI.Components.Checkbox
  alias LedgerUI.Components.Table.Layout

  @variants ~w(basic bordered hoverable zebra grid data data-grid flat)
  @aligns %{"left" => nil, "center" => "c", "right" => "num"}
  @roles ~w(head status title value meta)

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
    "bordered" => "overflow-hidden rounded-[12px] border border-line",
    "zebra" =>
      "[&_tbody_tr:nth-child(even)]:[--z:color-mix(in_oklab,var(--lu-bg-sunken)_60%,transparent)]",
    "grid" => "[--tbr:1px_solid_var(--lu-line)]",
    "data" => "[--td-py:7px] [--td-fs:13px] [--th-fs:11px]",
    "data-grid" =>
      "[--td-py:6px] [--th-py:6px] [--td-fs:13px] [--th-fs:13px] [--tff:var(--lu-font-mono)] [--tbr:1px_solid_var(--lu-line)] [--tbr-last:1px_solid_var(--lu-line)]",
    "flat" => "[--tbb:0_none]"
  }

  @rounded %{
    "row" => "[&_tbody_td:first-child]:rounded-l-[10px] [&_tbody_td:last-child]:rounded-r-[10px]",
    "top" =>
      "[&_thead_th]:bg-sunken [&_thead_th:first-child]:rounded-tl-[10px] [&_thead_th:last-child]:rounded-tr-[10px]",
    "none" => nil
  }

  @th "py-[var(--th-py,12px)] border-b border-line text-[length:var(--th-fs,11.5px)] leading-4 font-medium tracking-[.07em] text-muted uppercase [font-family:var(--tff)] whitespace-nowrap [border-right:var(--tbr,0_none)] last:[border-right:var(--tbr-last,0_none)]"
  @td "py-[var(--td-py,12px)] [border-bottom:var(--tbb,1px_solid_var(--lu-line))] [tr:last-child>&]:[border-bottom:0_none] [border-right:var(--tbr,0_none)] last:[border-right:var(--tbr-last,0_none)] [:where(&)]:text-[length:var(--td-fs)] [:where(&)]:text-[color:var(--td-c,var(--lu-ink-2))] [:where(&)]:[font-family:var(--tff)] bg-[var(--z,var(--h,var(--s,transparent)))]"
  @px "px-[var(--tpx,14px)]"
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
  @row_sub "[--s:color-mix(in_oklab,var(--lu-bg-sunken)_50%,transparent)] [--td-fs:12.5px] [--td-c:var(--lu-muted)] [&>td:first-child]:pl-11"
  @row_panel "data-[ct-row]:cursor-pointer focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-accent-500 data-[open]:[--h:var(--lu-bg-hover)]"

  @check_label "inline-flex cursor-pointer items-start gap-2.5 text-[14px] text-ink"

  # -- rows mode ---------------------------------------------------------------------------------

  attr :id, :string, required: true

  attr :rows, :any,
    default: nil,
    doc: "A list or a `@streams.x` stream. Leave it out to write the table by hand."

  attr :row_id, :any,
    default: nil,
    doc: "Function giving each row's DOM id (streams: the stream id)."

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
  attr :hoverable, :boolean, default: nil
  attr :compact, :boolean, default: false
  attr :headless, :boolean, default: false
  attr :sticky_header, :boolean, default: false
  attr :borderless, :boolean, default: false
  attr :bleed, :boolean, default: false, doc: "Not implemented yet."

  attr :card_below, :integer,
    default: nil,
    doc:
      "Width (px) of the table's own box under which rows become two-line cards (needs `role`s); one of `Table.Layout.card_widths/0`."

  attr :details, :boolean,
    default: false,
    doc: "A click on a row opens a panel under it (hook `LedgerUI.CardTable`)."

  attr :panel_label, :string, default: "Details"

  attr :row_editing, :any,
    default: nil,
    doc: "Function of the row; true swaps its cells for the `:edit` slot."

  attr :row_action, :any,
    default: nil,
    doc: "Function of the row; false leaves the content of its `:action` cells out."

  attr :body_class, :any, default: nil, doc: "Classes of the `<tbody>`."

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
  attr :peek_label, :string, default: "Hidden columns"
  attr :target, :any, default: nil
  attr :expand_label, :string, default: nil
  attr :scroll_label, :string, default: nil
  attr :sort_label, :string, default: nil
  attr :row_label, :any, default: nil
  attr :select_all_label, :string, default: "Select all rows"
  attr :select_label, :string, default: "Select row"
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
    attr :card, :boolean, doc: "Keeps the cell in the card layout, in a line of its own."
    attr :copy, :any, doc: "Function of the row returning the text a copy button copies."
    attr :copy_label, :string
    attr :copied_label, :string
    attr :copy_show, :string, values: ~w(inline)
    attr :copy_tip, :string, values: ~w(value_label)
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

  def table(%{rows: nil} = assigns) do
    assigns = assign(assigns, :shell, shell(assigns, assigns.col))

    ~H"""
    <.table_wrap wrapper={@wrapper} shell={@shell} scroll_label={@scroll_label}>
      <table id={@id} data-part="table" class={@shell.class} {@rest}>
        {render_slot(@inner_block)}
      </table>
    </.table_wrap>
    """
  end

  def table(assigns) do
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.rows)
    shell = shell(assigns, assigns.col)

    assigns =
      assigns
      |> assign(:stream?, stream?)
      |> assign(:row_id, assigns.row_id || if(stream?, do: fn {id, _} -> id end))
      |> assign(:shell, shell)
      |> assign(:cols, Enum.map(assigns.col, &col_info(&1, assigns, shell)))
      |> assign(:expand?, assigns.expand != [])
      |> assign(:select?, assigns.on_select != nil or assigns.on_select_all != nil)
      |> assign(:head_all, head_all(assigns))
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

    ~H"""
    <.table_wrap wrapper={@wrapper} shell={@shell} scroll_label={@scroll_label}>
      <table id={@id} data-part="table" class={@shell.class} {ra(@card?, "table")} {@rest}>
        <thead
          :if={!@headless}
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
        <tbody
          data-part="table-body"
          id={@id <> "-body"}
          class={[@card? && @shell.card.tbody, @body_class]}
          phx-update={@stream? && "stream"}
          phx-hook={@hooked && "LedgerUI.CardTable"}
          {ra(@card?, "rowgroup")}
        >
          <%= for row <- @rows do %>
            <% item = @row_item.(row) %>
            <% key = row_key(@row_key, @row_id, row, item) %>
            <% sel = key != nil and key in @selected %>
            <% rid = @row_id && @row_id.(row) %>
            <% editing = @edit? and @row_editing.(item) == true %>
            <% panel = @panel? and not editing %>
            <tr
              id={rid}
              data-part="table-row"
              {tr_attrs(@row_attrs, @row_class, @row_click, row, item, sel, @shell, panel)}
              {row_extra(@card?, panel, editing, rid)}
            >
              <td
                :if={@select?}
                data-part="table-cell"
                class={td_class(:cb, nil, @shell, @card?)}
                {ra(@card?, "cell")}
              >
                <.table_checkbox
                  :if={@on_select}
                  middle
                  checked={sel}
                  label={(@row_label && @row_label.(item)) || @select_label}
                  on_click={@on_select}
                  values={%{"id" => key, "selected" => to_string(!sel)}}
                  target={@target}
                  {(@select_attrs && @select_attrs.(item)) || %{}}
                />
              </td>
              <td
                :if={editing}
                data-part="table-cell"
                colspan={@ncols - if(@select?, do: 1, else: 0)}
                class={td_class(:edit, nil, @shell, @card?)}
              >
                {render_slot(@edit, item)}
              </td>
              <%= if !editing do %>
                <td
                  :for={c <- @col}
                  data-part="table-cell"
                  class={td_class(:col, c, @shell, @card?)}
                  {st(col_style(c))}
                  {ra(@card?, "cell")}
                >
                  <%= if c[:copy] do %>
                    <.copy_cell col={c} item={item} shell={@shell} />
                  <% else %>
                    {render_slot(c, item)}
                  <% end %>
                </td>
                <td
                  :for={a <- @action}
                  data-part="table-cell"
                  class={td_class(:action, a, @shell, @card?)}
                  style="width:40px"
                  {ra(@card?, "cell")}
                >
                  {if @row_action == nil or @row_action.(item) != false, do: render_slot(a, item)}
                </td>
                <td
                  :if={@expand? and @expand_open == nil}
                  data-part="table-cell"
                  class={td_class(:plain_num, nil, @shell, @card?)}
                  style="width:40px"
                >
                  <.table_expand_toggle row_id={rid || @id <> "-row"} />
                </td>
              <% end %>
            </tr>
            <tr
              :if={panel}
              id={rid && rid <> "-panel"}
              data-part="table-panel-row"
              class={@card? && @shell.card.prow}
              hidden
            >
              <td data-part="table-cell" colspan={@ncols} class="relative h-0 border-0 p-0">
                <div
                  data-part="table-panel"
                  class="absolute top-(--ct-top,2px) bottom-(--ct-bottom,auto) left-(--ct-x,96px) z-5 w-max max-w-[calc(100%-16px)] min-w-[220px] cursor-text rounded-[12px] border border-line bg-panel px-3 py-2.5 text-left text-[13px] leading-5 whitespace-normal text-ink-2 shadow-md select-text"
                  role="group"
                  aria-label={@panel_label}
                >
                  <div
                    :for={d <- @detail}
                    data-part="table-panel-item"
                    class="flex justify-between gap-3.5 py-[3px]"
                  >
                    <span data-part="table-panel-key" class="text-muted">{d[:label]}</span>
                    <span data-part="table-panel-value" class="text-right text-ink">{render_slot(
                      d,
                      item
                    )}</span>
                  </div>
                  <div
                    :for={c <- @panel_cols}
                    data-part="table-panel-item"
                    class={["hidden justify-between gap-3.5 py-[3px]", c.show]}
                  >
                    <span data-part="table-panel-key" class="text-muted">{c.label}</span>
                    <span data-part="table-panel-value" class="text-right text-ink">{render_slot(
                      c.slot,
                      item
                    )}</span>
                  </div>
                </div>
              </td>
            </tr>
            <tr
              :if={@expand? and (@expand_open == nil or @expand_open.(item))}
              id={(rid || @id <> "-row") <> "-detail"}
              data-part="table-detail-row"
              class={sub_row_class(@shell, @card?)}
              {st(@expand_open == nil && "display:none")}
            >
              <td
                data-part="table-cell"
                colspan={@ncols}
                class={td_class(:plain, nil, @shell, @card?, true)}
              >
                {render_slot(@expand, %{row: item, toggle: table_toggle_row(rid || @id <> "-row")})}
              </td>
            </tr>
          <% end %>
          <tr
            :if={@empty != [] and @rows == []}
            id={@id <> "-empty"}
            data-part="table-empty"
            class="not-only:hidden"
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
          <tr
            :if={@empty != [] and @stream?}
            id={@id <> "-empty-stream"}
            data-part="table-empty"
            class="not-only:hidden"
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
        </tbody>
        <tfoot :if={@foot != []}>
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

  defp table_wrap(%{wrapper: true} = assigns) do
    ~H"""
    <div
      data-part="table-wrap"
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
  defp tr_attrs(row_attrs, row_class, row_click, row, item, sel, shell, panel) do
    base = if row_attrs, do: Map.new(row_attrs.(item)), else: %{}

    base
    |> Map.put(
      :class,
      cx([
        sel && @row_sel,
        row_click && "cursor-pointer",
        panel && @row_panel,
        shell.card && shell.card.tr,
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

  defp row_key(nil, nil, _row, _item), do: nil
  defp row_key(nil, row_id, row, _item), do: row_id.(row)
  defp row_key(key, _row_id, _row, item), do: key.(item)

  # -- cell classes --------------------------------------------------------------------------------
  # `shell` carries what the table decided: the hide class of each priority and the card layout.

  # A header cell. `kind`: `:cb` (the select-all box), `:col` (`c` is its attrs), `:action`, `:plain`.
  defp th_class(kind, c, shell, sticky, card? \\ false)

  defp th_class(:cb, _c, shell, sticky, _card?) do
    [
      @th,
      @cb,
      @th_aligns[nil],
      sticky && "sticky top-0 z-1 bg-panel"
    ]
    |> with_card(shell, :th_cb)
  end

  defp th_class(:col, c, shell, sticky, _card?) do
    key = c[:sort_key]

    [
      @th,
      @px,
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
      @th,
      @px,
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
    [@td, @cb, card? && card_cell(shell, :cb)]
  end

  defp td_class(:col, c, shell, card?, _sub?) do
    flex? = flex_col?(c)
    wrap? = card? && c[:truncate] == false
    keep? = card? && c[:card]

    [
      @td,
      @px,
      @td_aligns[c[:align]],
      pc(shell, c[:priority]),
      c[:dim] && "opacity-[.32]",
      if(flex? and not wrap?, do: "w-full max-w-0 overflow-hidden text-ellipsis"),
      if(flex? and wrap?,
        do: "w-full max-w-none overflow-hidden text-ellipsis whitespace-normal",
        else: "whitespace-nowrap"
      ),
      card? && card_role(shell, c[:role], keep?, wrap?),
      c[:class]
    ]
  end

  defp td_class(:action, a, shell, card?, _sub?) do
    [
      @td,
      @px,
      "text-right tabular-nums whitespace-nowrap",
      pc(shell, a && a[:priority]),
      card? && card_cell(shell, if(a[:card] == false, do: :nocard, else: :act))
    ]
  end

  defp td_class(:edit, _c, shell, card?, _sub?) do
    [@td, @px, "whitespace-normal", card? && card_cell(shell, :edit)]
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
    [@td, @px, "text-right tabular-nums whitespace-nowrap", card? && shell.card.td_hidden]
  end

  defp td_class(:plain, _c, shell, _card?, sub?) do
    [@td, @px, "whitespace-nowrap", sub? && shell.card && shell.card.sub_td]
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

  defp col_style(c) do
    min =
      case c[:width] && Regex.run(~r/minmax\(\s*(\d+)px/, c[:width]) do
        [_, px] -> "min-width:" <> px <> "px"
        _ -> nil
      end

    case Enum.reject([min, c[:style]], &is_nil/1) do
      [] -> nil
      parts -> Enum.join(parts, ";")
    end
  end

  attr :col, :any, required: true
  attr :item, :any, required: true
  attr :shell, :map, required: true

  defp copy_cell(assigns) do
    c = assigns.col
    text = to_string(c.copy.(assigns.item))
    copy_label = c[:copy_label] || "Copy"
    copied_label = c[:copied_label] || "Copied"

    assigns =
      assign(assigns,
        text: text,
        copy_label: copy_label,
        copied_label: copied_label,
        inline: c[:copy_show] == "inline",
        value_label: c[:copy_tip] == "value_label"
      )

    ~H"""
    <span
      data-part="table-copy-value"
      class={[(@inline && "mr-2 inline") || "hidden", @shell.card && @shell.card.val]}
    >{render_slot(@col, @item)}</span>
    <button
      type="button"
      data-part="table-copy"
      class="group/copy relative inline-grid size-[26px] cursor-pointer place-items-center rounded-[8px] border-0 bg-transparent p-0 align-middle text-muted hover:bg-hover hover:text-ink focus-visible:bg-hover focus-visible:text-ink"
      data-lu-ct-copy={@text}
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
        class="pointer-events-none absolute bottom-[calc(100%+6px)] left-1/2 z-6 hidden -translate-x-1/2 rounded-[8px] bg-ink px-2 py-[5px] text-xs leading-4 whitespace-nowrap text-on-inverse shadow-sm group-hover/copy:block group-focus-visible/copy:block [&_b]:font-semibold"
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

  defp head_all(%{all_selected: nil, selected: [], rows: rows}) when is_list(rows), do: false

  defp head_all(%{all_selected: nil, rows: rows} = a) when is_list(rows) do
    keys = Enum.map(rows, fn row -> row_key(a.row_key, a.row_id, row, a.row_item.(row)) end)
    sel = Enum.count(keys, &(&1 in a.selected))

    cond do
      keys != [] and sel == length(keys) -> true
      sel > 0 -> :some
      true -> false
    end
  end

  defp head_all(%{all_selected: nil}), do: false
  defp head_all(%{all_selected: v}), do: v

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
        "overflow-auto rounded-lg border border-line bg-panel",
        container? && "@container",
        a.wrapper_class
      ],
      widths: widths,
      hide: for({p, w} <- widths, into: %{}, do: {p, Layout.hide(w)}),
      card: if(card?, do: Map.new(Layout.card(a.card_below)))
    }
  end

  defp table_class(a) do
    hover? = a.variant != "basic"

    cx([
      @table_base,
      @variant_classes[a.variant],
      hover? && "[&_tbody_tr:hover]:[--h:var(--lu-bg-hover)]",
      @rounded[a.rounded],
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
  attr :select_all_label, :string, default: "Select all rows"
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

  def table_head(assigns) do
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
  attr :select_label, :string, default: "Select row"
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
  end

  slot :inner_block, doc: "Free cells after the `:cell` ones."

  def table_row(assigns) do
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
      class: [@td, @px, @td_aligns[c[:align]], "whitespace-nowrap", c[:class]],
      colspan: c[:colspan],
      rowspan: c[:rowspan],
      priority: c[:priority] && c.priority > 0 && c.priority,
      rest: Map.drop(c, [:__slot__, :inner_block, :class, :align, :colspan, :rowspan, :priority])
    }
  end

  # -- table_cell -------------------------------------------------------------------------------

  attr :header, :boolean, default: false, doc: "Renders a `<th scope=\"row\">`."
  attr :align, :string, default: nil, values: [nil, "left", "center", "right"]
  attr :colspan, :any, default: nil
  attr :rowspan, :any, default: nil
  attr :priority, :integer, default: nil
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
        @td,
        @px,
        @td_aligns[assigns.align],
        "whitespace-nowrap",
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
  end

  slot :inner_block, doc: "Free `<tr>` rows after the `:cell` row."

  def table_foot(assigns) do
    assigns =
      assign(assigns, :td, [@td, @px, "border-t border-line font-semibold whitespace-nowrap"])

    ~H"""
    <tfoot {@rest}>
      <tr :if={@cell != []} data-part="table-foot-row" class={@class}>
        <td
          :for={c <- @cell}
          data-part="table-cell"
          class={[@td, align_class(c[:align]), c[:class]]}
          colspan={c[:colspan]}
        >
          {render_slot(c)}
        </td>
      </tr>
      {render_slot(@inner_block)}
    </tfoot>
    """
  end

  defp align_class(align), do: @td_aligns[align]

  # -- table_empty ------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :class, :any, default: nil, doc: "Classes of the cell."
  attr :rest, :global
  slot :inner_block, required: true

  def table_empty(assigns) do
    assigns = assign(assigns, :td, [@td, @px, "whitespace-nowrap"])

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

    ~H"""
    <label data-part="table-checkbox" class={@classes} {@rest}><input
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
  attr :label, :string, default: "Toggle details"
  attr :class, :any, default: nil
  attr :rest, :global

  def table_expand_toggle(assigns) do
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
  attr :rest, :global
  slot :inner_block, required: true

  def table_detail_row(assigns) do
    assigns =
      assigns
      |> assign(:row_class, @row_sub)
      |> assign(:td, [@td, @px, "whitespace-nowrap"])

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

  attr :label, :string, default: "Loading"
  attr :class, :any, default: nil
  attr :rest, :global

  @skel "block bg-[linear-gradient(90deg,var(--lu-bg-sunken)_25%,var(--lu-bg-hover)_50%,var(--lu-bg-sunken)_75%)] bg-[length:200%_100%] animate-[lu-shim_1.4s_linear_infinite]"

  def table_skeleton(assigns) do
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
