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

  The markup is `div.lu-tablewrap > table.lu-table.<variant>`; the look lives in `ledger.css`.
  `variant` is `nil` for the bare `lu-table`; `rounded` (`row`, `top`) rounds the header row.

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

  A `:col` with `priority` 1, 2 or 3 leaves (header, cells and `:foot` cell together) when the
  table's own box gets narrower than 720, 560 and 420px (a container query scoped to the table's
  `id`). `table-narrow-hide` hides what carries it under 420px.

  ## Card layout, details panel, copy columns (used by `card_table/1`)

  Extra attributes `card_below`, `details`, `row_editing`, `row_action` and the column attributes
  `role`, `width`, `truncate`, `card`, `copy*` back the "card" table (see
  `LedgerUI.Components.CardTable`): under `card_below` px each row is a two-line grid placed by the
  `role` of its cells (`head`, `status`, `title`, `value`); `details` adds a panel under the clicked
  row (hook `LedgerUI.CardTable`) with the `:detail` slots and the columns that left by priority;
  `copy` turns a cell into a copy button; `row_editing` swaps a row for the `:edit` slot.

  ## Not implemented

  `peek` / `peek_label` (the panel with the hidden columns) and `bleed` are accepted but draw
  nothing yet. `borderless` only adds the `borderless` class (the stylesheet has no rule for it).
  """
  use LedgerUI.Component

  @variants ~w(basic bordered hoverable zebra grid data data-grid flat)
  @aligns %{"left" => nil, "center" => "c", "right" => "num"}
  @rounded %{"row" => "r-row", "top" => "r-top", "none" => nil}

  @roles %{
    "head" => "lu-r-head",
    "status" => "lu-r-status",
    "title" => "lu-r-title",
    "value" => "lu-r-value",
    "meta" => "lu-r-meta"
  }

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
      "`nil` is the bare `lu-table`. `grid` is the gridjs look; `data`/`data-grid` the lean one of `data_table/1`."

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
      "Width (px) of the table's own box under which rows become two-line cards (needs `role`s)."

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
    doc: "Widths (px) under which priority 1, 2, 3... leave."

  attr :wrapper, :boolean,
    default: true,
    doc: "`false` leaves out the `lu-tablewrap` box (a table inside a `lu-card-b`)."

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
    <style :if={@shell.css}>
      <%= @shell.css %>
    </style>
    <.table_wrap wrapper={@wrapper} shell={@shell} scroll_label={@scroll_label}>
      <table id={@id} class={@shell.class} {@rest}>
        {render_slot(@inner_block)}
      </table>
    </.table_wrap>
    """
  end

  def table(assigns) do
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.rows)

    assigns =
      assigns
      |> assign(:stream?, stream?)
      |> assign(:row_id, assigns.row_id || if(stream?, do: fn {id, _} -> id end))
      |> assign(:shell, shell(assigns, assigns.col))
      |> assign(:cols, Enum.map(assigns.col, &col_info(&1, assigns)))
      |> assign(:expand?, assigns.expand != [])
      |> assign(:select?, assigns.on_select != nil or assigns.on_select_all != nil)
      |> assign(:sticky, if(assigns.sticky_header, do: sticky_style()))
      |> assign(:head_all, head_all(assigns))
      |> assign(:card?, card?(assigns))
      |> assign(:panel?, assigns.details and (assigns.detail != [] or has_priority?(assigns.col)))
      |> assign(:panel_cols, panel_cols(assigns))
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
    <style :if={@shell.css}>
      <%= @shell.css %>
    </style>
    <style :if={@empty != []}>
      <%= empty_css() %>
    </style>
    <.table_wrap wrapper={@wrapper} shell={@shell} scroll_label={@scroll_label}>
      <table id={@id} class={@shell.class} {ra(@card?, "table")} {@rest}>
        <thead :if={!@headless} {ra(@card?, "rowgroup")}>
          <tr {ra(@card?, "row")}>
            <th :if={@select?} class="cb" {st(@sticky)} {ra(@card?, "columnheader")}>
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
              class={c.th_class}
              {st(@sticky)}
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
                <.icon name={sort_icon(c.sort_key, @sort_by, @sort_dir)} size="sm" />
              <% end %>
            </th>
            <th
              :for={a <- @action}
              class={act_class(a, false)}
              {st(@sticky)}
              {ra(@card?, "columnheader")}
            >
            </th>
            <th :if={@expand? and @expand_open == nil} {st(@sticky)}>{@expand_label}</th>
          </tr>
        </thead>
        <tbody
          id={@id <> "-body"}
          class={@body_class}
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
              {tr_attrs(@row_attrs, @row_class, @row_click, row, item, sel)}
              {row_extra(@card?, panel, editing, rid)}
            >
              <td :if={@select?} class="cb" {ra(@card?, "cell")}>
                <.table_checkbox
                  :if={@on_select}
                  checked={sel}
                  label={(@row_label && @row_label.(item)) || @select_label}
                  on_click={@on_select}
                  values={%{"id" => key, "selected" => to_string(!sel)}}
                  target={@target}
                  {(@select_attrs && @select_attrs.(item)) || %{}}
                />
              </td>
              <td :if={editing} colspan={@ncols - if(@select?, do: 1, else: 0)} class="lu-ct-edit">
                {render_slot(@edit, item)}
              </td>
              <%= if !editing do %>
                <td
                  :for={c <- @col}
                  class={td_class(c, @card?)}
                  {st(col_style(c))}
                  {ra(@card?, "cell")}
                >
                  <%= if c[:copy] do %>
                    <.copy_cell col={c} item={item} />
                  <% else %>
                    {render_slot(c, item)}
                  <% end %>
                </td>
                <td
                  :for={a <- @action}
                  class={act_class(a, @card?, "num")}
                  style="width:40px"
                  {ra(@card?, "cell")}
                >
                  {if @row_action == nil or @row_action.(item) != false, do: render_slot(a, item)}
                </td>
                <td :if={@expand? and @expand_open == nil} class="num" style="width:40px">
                  <.table_expand_toggle row_id={rid || @id <> "-row"} />
                </td>
              <% end %>
            </tr>
            <tr
              :if={panel}
              id={rid && rid <> "-panel"}
              class="lu-ct-prow"
              hidden
            >
              <td colspan={@ncols}>
                <div class="lu-ct-panel" role="group" aria-label={@panel_label}>
                  <div :for={d <- @detail} class="lu-ct-pi">
                    <span class="lu-ct-k">{d[:label]}</span>
                    <span class="lu-ct-v">{render_slot(d, item)}</span>
                  </div>
                  <div :for={c <- @panel_cols} class={"lu-ct-pi lu-wh" <> to_string(c.priority)}>
                    <span class="lu-ct-k">{c.label}</span>
                    <span class="lu-ct-v">{render_slot(c.slot, item)}</span>
                  </div>
                </div>
              </td>
            </tr>
            <tr
              :if={@expand? and (@expand_open == nil or @expand_open.(item))}
              id={(rid || @id <> "-row") <> "-detail"}
              class="sub"
              {st(@expand_open == nil && "display:none")}
            >
              <td colspan={@ncols}>
                {render_slot(@expand, %{row: item, toggle: table_toggle_row(rid || @id <> "-row")})}
              </td>
            </tr>
          <% end %>
          <tr :if={@empty != [] and @rows == []} id={@id <> "-empty"} class="lu-t-empty">
            <td colspan={@ncols} class="lu-muted" style="text-align:center">
              {render_slot(@empty)}
            </td>
          </tr>
          <tr :if={@empty != [] and @stream?} id={@id <> "-empty-stream"} class="lu-t-empty">
            <td colspan={@ncols} class="lu-muted" style="text-align:center">
              {render_slot(@empty)}
            </td>
          </tr>
        </tbody>
        <tfoot :if={@foot != []}>
          <tr>
            <td
              :for={f <- @foot}
              colspan={f[:colspan]}
              class={foot_class(f)}
              style="font-weight:600;border-top:1px solid var(--line)"
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
      class={@shell.wrap_class}
      {st(@shell.wrap_style)}
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
  defp tr_attrs(row_attrs, row_class, row_click, row, item, sel) do
    base = if row_attrs, do: Map.new(row_attrs.(item)), else: %{}

    base
    |> Map.put(
      :class,
      cx([sel && "sel", row_click && "clickable", row_class && row_class.(item), base[:class]])
    )
    |> click_attrs(row_click && row_click.(row), nil)
  end

  defp click_attrs(attrs, nil, _target), do: attrs

  defp click_attrs(attrs, click, target) do
    attrs = Map.new(attrs)

    attrs
    |> Map.put(:"phx-click", click)
    |> then(&if target, do: Map.put(&1, :"phx-target", target), else: &1)
    |> Map.update(:style, "cursor:pointer", &("cursor:pointer;" <> &1))
  end

  defp row_key(nil, nil, _row, _item), do: nil
  defp row_key(nil, row_id, row, _item), do: row_id.(row)
  defp row_key(key, _row_id, _row, item), do: key.(item)

  defp td_class(c, card? \\ false) do
    cx([
      @aligns[c[:align]],
      pc(c[:priority]),
      card? && @roles[c[:role]],
      card? && c[:card] && "lu-ckeep",
      flex_col?(c) && "lu-ct-flex",
      card? && c[:truncate] == false && "lu-ct-wrap",
      c[:class]
    ])
  end

  # -- card layout / details panel / copy columns -------------------------------------------------

  # The card layout needs a width and at least one column with a role.
  defp card?(%{card_below: nil}), do: false
  defp card?(%{col: cols}), do: Enum.any?(cols, &(&1[:role] in Map.keys(@roles)))

  defp has_priority?(cols), do: Enum.any?(cols, &(&1[:priority] in 1..4))

  # The columns that may leave, for the panel; a column with the label of a `:detail` is not repeated.
  defp panel_cols(%{details: false}), do: []

  defp panel_cols(%{col: cols, detail: details}) do
    labels = for d <- details, do: d[:label]

    for c <- cols, c[:priority] in 1..4, c[:label] not in labels do
      %{priority: c.priority, label: c[:label], slot: c}
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

  defp act_class(a, card?, base \\ nil) do
    case cx([
           base,
           pc(a[:priority]),
           card? && "lu-ct-act",
           card? && a[:card] == false && "lu-ct-nocard"
         ]) do
      "" -> nil
      class -> class
    end
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
    <span class={cx(["lu-ct-val", @inline && "inline"])}>{render_slot(@col, @item)}</span>
    <button type="button" class="lu-ct-copy" data-lu-ct-copy={@text} aria-label={@copy_label}>
      <.icon name="copy" size="sm" class="lu-ct-ic-idle" />
      <.icon name="check" size="sm" class="lu-ct-ic-done" />
      <span class="lu-ct-tip" role="tooltip">
        <span class="lu-ct-t-idle">
          <%= if @value_label do %>
            <b class="mono">{@text}</b> · {@copy_label}
          <% else %>
            {@text}
          <% end %>
        </span>
        <span class="lu-ct-t-done">
          <%= if @value_label do %>
            <b class="mono">{@text}</b> · {@copied_label}
          <% else %>
            {@copied_label}
          <% end %>
        </span>
      </span>
    </button>
    """
  end

  defp foot_class(c), do: td_class(c)

  defp pc(p) when p in 1..4, do: "lu-p#{p}"
  defp pc(_), do: nil

  # `style={nil}` renders `style=""`, so an optional style goes through a spread.
  defp st(v) when v in [nil, false], do: []
  defp st(v), do: [style: v]

  defp col_info(c, a) do
    sort_key = c[:sort_key]

    %{
      label: c[:label],
      sort_key: sort_key,
      priority: c[:priority] && c.priority > 0 && c.priority,
      th_class:
        cx([
          @aligns[c[:align]],
          pc(c[:priority]),
          sort_key && "sort",
          c[:head_class],
          a.sort_label && nil
        ])
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

  defp sticky_style,
    do: "position:sticky;top:0;z-index:1;background:var(--bg-panel)"

  # -- shell (wrapper, classes, container query css) --------------------------------------------

  defp shell(a, cols) do
    priorities = for c <- cols, p = c[:priority], p in 1..4, do: p
    card? = card?(%{card_below: a.card_below, col: cols})

    container? =
      a.container || (a.container == nil and (priorities != [] or card? or a.details))

    %{
      class: table_class(a),
      wrap_class: cx(["lu-tablewrap", a.wrapper_class]),
      wrap_style: container? && "container-type:inline-size",
      css: container? && priority_css(a.id, a.breakpoints, card? && a.card_below)
    }
  end

  defp table_class(a) do
    hover? = a.hoverable && a.variant != "hoverable"

    cx([
      "lu-table",
      a.variant,
      @rounded[a.rounded],
      hover? && "hoverable",
      a.compact && "dense",
      a.borderless && "borderless",
      a.class
    ])
  end

  defp priority_css(id, bps, card_below) do
    sel = "#" <> safe_id(id)

    rules =
      bps
      |> Enum.with_index(1)
      |> Enum.map_join(fn {w, p} ->
        "#{sel} .lu-wh#{p}{display:none}" <>
          "@container (max-width:#{w}px){#{sel} .lu-p#{p}{display:none}#{sel} .lu-wh#{p}{display:revert}}"
      end)

    rules <>
      "@container (max-width:#{List.last(bps)}px){#{sel} .table-narrow-hide{display:none}}" <>
      card_css(sel, card_below)
  end

  # The two-line card layout: a grid per row placed by the cell roles (see ledger_ui.css for the
  # look). Container queries cannot read variables, so the width goes in here.
  defp card_css(_sel, false), do: ""

  defp card_css(sel, w) do
    "@container (max-width:#{w}px){" <>
      "#{sel} thead{position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%)}" <>
      "#{sel} thead:focus-within{position:static;width:auto;height:auto;overflow:visible;clip-path:none;display:block;padding:8px 14px}" <>
      "#{sel} thead th:not(.cb){display:none}#{sel} thead tr{display:block}" <>
      "#{sel} tbody{display:block}" <>
      "#{sel} tbody tr{display:grid;grid-template-columns:auto minmax(0,1fr) auto auto;grid-template-areas:'cb head status act' 'cb title value act' 'cb keep keep act';align-items:center;padding:10px 14px;border-bottom:1px solid var(--line)}" <>
      "#{sel} tbody tr:last-child{border-bottom:0}" <>
      "#{sel} tbody tr>td{display:none;padding:0;border:0;min-width:0;max-width:none;width:auto}" <>
      "#{sel} tbody tr>td.cb{display:block;grid-area:cb;padding-right:10px}" <>
      "#{sel} tbody tr>td.lu-r-head{display:block;grid-area:head;font-family:var(--font-mono);font-size:13px}" <>
      "#{sel} tbody tr>td.lu-r-status{display:block;grid-area:status;justify-self:end}" <>
      "#{sel} tbody tr>td.lu-r-title{display:-webkit-box;grid-area:title;-webkit-box-orient:vertical;-webkit-line-clamp:2;line-clamp:2;overflow:hidden;white-space:normal;padding-right:10px}" <>
      "#{sel} tbody tr>td.lu-r-title.lu-ct-wrap{display:block}" <>
      "#{sel} tbody tr>td.lu-r-value{display:block;grid-area:value;justify-self:end;text-align:right}" <>
      "#{sel} tbody tr>td.lu-ckeep{display:block;grid-area:keep;padding-top:4px}" <>
      "#{sel} tbody tr>td.lu-ct-act{display:block;grid-area:act;padding-left:10px;width:auto!important}" <>
      "#{sel} tbody tr>td.lu-ct-act.lu-ct-nocard{display:none}" <>
      "#{sel} tbody tr>td.lu-r-head .lu-ct-val,#{sel} tbody tr>td .lu-ct-val{display:inline}" <>
      "#{sel} tbody tr>td.lu-ct-edit{display:block;grid-column:2/-1}" <>
      "#{sel} tbody tr.lu-ct-prow{display:none}" <>
      "#{sel} tbody tr.sub{display:block;padding:0 14px 10px}" <>
      "#{sel} tbody tr.sub>td{display:block;padding:0}" <>
      "}"
  end

  # Only the characters of a DOM id that are safe inside a CSS attribute selector.
  defp safe_id(id), do: String.replace(id, ~r/[^A-Za-z0-9_\-]/u, "")

  defp empty_css,
    do: ".lu-table tr.lu-t-empty:not(:only-child){display:none}"

  defp aria_sort(key, key, "asc"), do: "ascending"
  defp aria_sort(key, key, "desc"), do: "descending"
  defp aria_sort(_, _, _), do: "none"

  defp next_dir(key, key, "asc"), do: "desc"
  defp next_dir(_, _, _), do: "asc"

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
      |> assign(:sticky, if(assigns.sticky_header, do: sticky_style()))
      |> assign(:cols, Enum.map(assigns.col, &head_col(&1, assigns)))

    ~H"""
    <thead {@rest}>
      <tr class={@class}>
        <th :if={@on_select_all} class="cb" {st(@sticky)}>
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
          class={c.class}
          {st(@sticky)}
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
            <.icon name={c.icon} size="sm" />
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
      class: cx([@aligns[c[:align]], pc(c[:priority]), key && "sort", c[:class]]),
      colspan: c[:colspan],
      priority: c[:priority] && c.priority > 0 && c.priority,
      sort_key: key,
      aria_sort: key && a.on_sort && aria_sort(key, a.sort_by, a.sort_dir),
      aria_label: key && a.sort_label && sort_aria_label(a.sort_label, label),
      icon: key && sort_icon(key, a.sort_by, a.sort_dir),
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
    <tbody class={@class} {@rest}>{render_slot(@inner_block)}</tbody>
    """
  end

  # -- table_row --------------------------------------------------------------------------------

  attr :selected, :boolean, default: nil, doc: "`true` checks the box and marks the row (`sel`)."
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
        cx([assigns.selected && "sel", assigns.on_click && "clickable", assigns.class])
      )
      |> assign(:cells, Enum.map(assigns.cell, &cell_info/1))
      |> assign(:tr_rest, click_attrs(assigns.rest, assigns.on_click, assigns.target))

    ~H"""
    <tr class={@classes} {@tr_rest}>
      <td :if={@on_select} class="cb">
        <.table_checkbox
          checked={@selected == true}
          label={@select_label}
          on_click={@on_select}
          values={%{"id" => @select_value, "selected" => to_string(@selected != true)}}
          target={@target}
        />
      </td>
      <td
        :for={{c, i} <- Enum.with_index(@cells)}
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
      class: cx([@aligns[c[:align]], pc(c[:priority]), c[:class]]),
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
      assign(assigns, :classes, cx([@aligns[assigns.align], pc(assigns.priority), assigns.class]))

    ~H"""
    <th
      scope="row"
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
      assign(assigns, :classes, cx([@aligns[assigns.align], pc(assigns.priority), assigns.class]))

    ~H"""
    <td
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
    ~H"""
    <tfoot {@rest}>
      <tr :if={@cell != []} class={@class}>
        <td
          :for={c <- @cell}
          class={foot_class(c)}
          colspan={c[:colspan]}
          style="font-weight:600;border-top:1px solid var(--line)"
        >
          {render_slot(c)}
        </td>
      </tr>
      {render_slot(@inner_block)}
    </tfoot>
    """
  end

  # -- table_empty ------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :class, :any, default: nil, doc: "Classes of the cell."
  attr :rest, :global
  slot :inner_block, required: true

  def table_empty(assigns) do
    assigns = assign(assigns, :css, empty_css())

    ~H"""
    <tr id={@id} class="lu-t-empty" {@rest}>
      <td colspan="1000" class={cx(["lu-muted", @class])} style="text-align:center">
        <style>
          <%= @css %>
        </style>
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
  attr :on_click, :any, default: nil
  attr :values, :map, default: %{}, doc: "Sent as `phx-value-*` with `on_click`."
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, doc: "Attributes of the `<label>`."

  def table_checkbox(assigns) do
    values = for {k, v} <- assigns.values, v != nil, into: %{}, do: {"phx-value-#{k}", v}

    assigns =
      assigns
      |> assign(:classes, cx(["lu-check", assigns.class]))
      |> assign(:values_attrs, values)
      |> assign(:hook, assigns.id && "LedgerUI.TableCheckbox")
      |> assign(:ind, assigns.indeterminate && "1")

    ~H"""
    <label class={@classes} {@rest}><input
      id={@id}
      type="checkbox"
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
    <button
      id={@row_id <> "-toggle"}
      type="button"
      class={cx(["lu-btn icon ghost sm", @class])}
      aria-label={@label}
      aria-expanded={to_string(@open)}
      phx-click={@js}
      {@rest}
    >
      <.icon name="chevron-down" size="sm" />
    </button>
    """
  end

  attr :row_id, :string, required: true
  attr :open, :boolean, default: false
  attr :class, :any, default: nil, doc: "Classes of the detail panel."
  attr :rest, :global
  slot :inner_block, required: true

  def table_detail_row(assigns) do
    ~H"""
    <tr id={@row_id <> "-detail"} class="sub" {st(!@open && "display:none")} {@rest}>
      <td colspan="1000">
        <div class={@class}>{render_slot(@inner_block)}</div>
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

  def table_skeleton(assigns) do
    n = if assigns.columns == [], do: assigns.cols, else: length(assigns.columns)

    assigns =
      assigns
      |> assign(:n, n)
      |> assign(:shape_list, for(i <- 0..(n - 1), do: Enum.at(assigns.shapes, i, "text")))
      |> assign(
        :table_class,
        table_class(%{
          variant: assigns.variant,
          rounded: assigns.rounded,
          hoverable: nil,
          compact: assigns.compact,
          borderless: false,
          class: assigns.class
        })
      )

    ~H"""
    <div class="lu-tablewrap" role="status" aria-busy="true" aria-label={@label}>
      <table id={@id} class={@table_class} {@rest}>
        <thead :if={!@headless}>
          <tr>
            <th :for={i <- 0..(@n - 1)}>
              <%= if @columns != [] do %>
                {Enum.at(@columns, i)}
              <% else %>
                <span class="lu-skel" style="display:block;width:60%"></span>
              <% end %>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={_ <- 1..max(@rows, 1)}>
            <td :for={s <- @shape_list}>
              <%= case s do %>
                <% "avatar" -> %>
                  <div class="lu-row" style="flex-wrap:nowrap">
                    <span class="lu-skel" style="width:28px;height:28px;border-radius:50%;flex:none"></span>
                    <span class="lu-skel" style="width:60%"></span>
                  </div>
                <% "pill" -> %>
                  <span
                    class="lu-skel"
                    style="display:block;width:56px;height:20px;border-radius:999px"
                  ></span>
                <% "number" -> %>
                  <span class="lu-skel" style="display:block;width:40%;margin-left:auto"></span>
                <% _ -> %>
                  <span class="lu-skel" style="display:block;width:70%"></span>
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
