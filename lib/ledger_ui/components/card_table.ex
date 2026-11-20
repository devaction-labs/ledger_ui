defmodule LedgerUI.Components.CardTable do
  @moduledoc """
  The "card" table: one row per record in a rounded tray (`lu-card`), with an optional heading, a
  footer line and sub-lines. For long lists (orders, invoices, clients).

      <.card_table id="orders" rows={@streams.orders} on_select="select" selected={@selected}
        status={&order_status/1}>
        <:col :let={{_id, o}} label="Pedido" class="mono">{o.number}</:col>
        <:col :let={{_id, o}} label="Cliente">
          {o.client}
          <.ctable_sub priority={2}>{o.issuer}</.ctable_sub>
        </:col>
        <:col :let={{_id, o}} label="Total" align="right">{o.total}</:col>
        <:foot><span>Mostrando 1–6 de 128</span></:foot>
      </.card_table>

  It renders `LedgerUI.Components.Table.table/1` inside the tray, so rows (list or stream), sorting,
  selection and the other `row_*` attrs work as there. `variant="flat"` is the plain table of the
  canvas dashboards (`lu-table flat`), in a card only when it has a `title`, `:top`, `:actions` or
  `:foot`.

  Columns leave by `priority` (1 to 4) when the table's own box is narrower than `breakpoints`
  (`[1180, 960, 720, 520]` by default; between 2 and 5 strictly descending integers, else
  `ArgumentError`). A `<.ctable_sub>` is a second line inside a cell that leaves by its own
  `priority`, or shows only once the columns of `when_hidden` (`p1`..`p4`) have left.
  `<:expand :let={row}>` is a full-width line under each row for which `row_expanded` is true.

  ## Not implemented

  The details panel (`<:detail>`, hook `LedgerUI.CardTable`), the copy button columns (`copy*`), the
  compact two-line card layout under the last breakpoint (`role`, `card`, `width`, `truncate`),
  `<:edit>`/`row_editing` and `row_action`/`panel_label` are accepted but draw nothing yet. `status`
  paints an inset bar through `box-shadow` on the row (`data-status` carries the colour name).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Table

  @status_colors %{
    "success" => "var(--pos)",
    "info" => "var(--info)",
    "warning" => "var(--chart-3)",
    "error" => "var(--neg)",
    "primary" => "var(--accent)"
  }

  # `style={nil}` renders `style=""`, so an optional style goes through a spread.
  defp st(v) when v in [nil, false], do: []
  defp st(v), do: [style: v]

  attr :id, :string, required: true
  attr :rows, :any, required: true, doc: "A list or a `@streams.x` stream."
  attr :row_id, :any, default: nil
  attr :row_item, :any, default: &Function.identity/1
  attr :row_key, :any, default: nil

  attr :row_attrs, :any,
    default: nil,
    doc: "Function of the row returning extra `<tr>` attributes."

  attr :status, :any,
    default: nil,
    doc: "Function of the row returning a colour for the bar at its left, or `nil`."

  attr :on_select, :any, default: nil
  attr :on_select_all, :any, default: nil
  attr :selected, :list, default: []
  attr :all_selected, :boolean, default: nil
  attr :select_all_label, :string, default: "Select all rows"
  attr :select_label, :string, default: "Select row"
  attr :panel_label, :string, default: "Details", doc: "Not implemented yet."
  attr :on_sort, :any, default: nil
  attr :sort_by, :string, default: nil
  attr :sort_dir, :string, default: "asc", values: ~w(asc desc)
  attr :target, :any, default: nil
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :meta, :string, default: nil, doc: "A small muted text right after the title."

  attr :bordered, :boolean,
    default: true,
    doc: "`false` drops the tray's own border, shadow and background."

  attr :row_expanded, :any, default: nil
  attr :row_editing, :any, default: nil, doc: "Not implemented yet."
  attr :row_action, :any, default: nil, doc: "Not implemented yet."

  attr :breakpoints, :list,
    default: [1180, 960, 720, 520],
    doc:
      "Widths (px) under which priority 1, 2, 3... leave, descending; the last is the card layout."

  attr :body_class, :any, default: nil, doc: "Classes of the `<tbody>`."
  attr :variant, :string, default: "rows", values: ~w(rows flat)
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "The last cell of every row (a menu button); receives the row." do
    attr :priority, :integer
    attr :card, :boolean
  end

  slot :actions, doc: "Buttons at the right of the heading."

  slot :col, required: true, doc: "A column; receives the row (after `row_item`)." do
    attr :label, :string
    attr :width, :string
    attr :priority, :integer
    attr :role, :string
    attr :align, :string, values: ~w(start end left center right)
    attr :truncate, :boolean
    attr :class, :any
    attr :sort_key, :string
    attr :copy, :any
    attr :copy_label, :string
    attr :copied_label, :string
    attr :copy_show, :string
    attr :card, :boolean
    attr :copy_tip, :string
    attr :style, :string
  end

  slot :detail, doc: "A line of the details panel (not implemented yet)." do
    attr :label, :string
  end

  slot :edit, doc: "Inline form in place of a row's cells (not implemented yet)."
  slot :empty, doc: "Shown when there are no rows. Receives `%{id, rows, selected, title}`."
  slot :expand, doc: "A full-width line under a row (see `row_expanded`); receives the row."

  slot :foot,
    doc: "A line inside the card under the rows. Receives `%{id, rows, selected, title}`."

  slot :top, doc: "With `variant=\"flat\"`, what heads the card instead of the title (tabs)."

  def card_table(assigns) do
    validate_breakpoints!(assigns.breakpoints)

    ctx = %{id: assigns.id, rows: assigns.rows, selected: assigns.selected, title: assigns.title}
    flat? = assigns.variant == "flat"

    card? =
      not flat? or assigns.title != nil or assigns.top != [] or assigns.actions != [] or
        assigns.foot != []

    assigns =
      assigns
      |> assign(:ctx, ctx)
      |> assign(:flat?, flat?)
      |> assign(:card?, card?)
      |> assign(:head?, assigns.title != nil or assigns.actions != [] or assigns.top != [])
      |> assign(:table_variant, if(flat?, do: "flat"))
      |> assign(:expand_open, expand_open(assigns))
      |> assign(:attrs_fun, attrs_fun(assigns))
      |> assign(
        :tray_style,
        if(!assigns.bordered, do: "border:0;box-shadow:none;background:none")
      )
      |> assign(:bps, Enum.take(assigns.breakpoints, length(assigns.breakpoints) - 1))

    ~H"""
    <%= if @card? do %>
      <section
        id={@id <> "-card"}
        class={cx(["lu-card", @class])}
        {st(@tray_style)}
        data-part="card-table"
        {@rest}
      >
        <div :if={@head?} class="lu-card-h">
          <%= if @top != [] do %>
            {render_slot(@top)}
          <% else %>
            <span :if={@title} class="lu-card-t">{@title}</span>
            <span :if={@meta} class="lu-xs lu-muted">{@meta}</span>
          <% end %>
          <div :if={@actions != []} class="act">{render_slot(@actions)}</div>
        </div>
        <p :if={@description} class="lu-xs lu-muted" style="margin:0;padding:0 14px 10px">
          {@description}
        </p>
        <%= if @flat? do %>
          <.inner_table {assigns} />
        <% else %>
          <div class="lu-card-b" style="padding:0">
            <.inner_table {assigns} />
          </div>
        <% end %>
        <div
          :if={@foot != []}
          class="lu-card-f"
          style="flex-wrap:wrap;justify-content:space-between;border-top:1px solid var(--line)"
        >
          {render_slot(@foot, @ctx)}
        </div>
      </section>
    <% else %>
      <.inner_table {assigns} />
    <% end %>
    """
  end

  defp inner_table(assigns) do
    ~H"""
    <Table.table
      id={@id}
      rows={@rows}
      row_id={@row_id}
      row_item={@row_item}
      row_key={@row_key}
      row_attrs={@attrs_fun}
      variant={@table_variant}
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort={@on_sort}
      selected={@selected}
      all_selected={@all_selected}
      on_select={@on_select}
      on_select_all={@on_select_all}
      select_all_label={@select_all_label}
      select_label={@select_label}
      target={@target}
      breakpoints={@bps}
      expand_open={@expand_open}
      body_class={@body_class}
    >
      <:col
        :let={row}
        :for={c <- @col}
        label={c[:label]}
        class={col_class(c)}
        align={table_align(c[:align])}
        sort_key={c[:sort_key]}
        priority={c[:priority]}
        style={c[:style]}
      >
        {render_slot(c, row)}
      </:col>
      <:action :let={row} :for={a <- @action}>{render_slot(a, row)}</:action>
      <:empty :if={@empty != []}>{render_slot(@empty, @ctx)}</:empty>
      <:expand :let={ctx} :for={e <- @expand}>{render_slot(e, ctx.row)}</:expand>
    </Table.table>
    """
  end

  defp col_class(c), do: c[:class]

  defp table_align("start"), do: "left"
  defp table_align("end"), do: "right"
  defp table_align(other), do: other

  defp expand_open(%{expand: []}), do: nil
  defp expand_open(%{row_expanded: nil}), do: fn _ -> true end
  defp expand_open(%{row_expanded: f}), do: f

  # Composes the user's row attributes with the status colour.
  defp attrs_fun(%{status: nil, row_attrs: attrs}), do: attrs

  defp attrs_fun(%{status: status, row_attrs: attrs}) do
    fn item ->
      base = if attrs, do: attrs.(item), else: %{}
      color = status.(item)
      css = @status_colors[color] || "var(--line-strong, var(--line))"
      bar = "box-shadow:inset 3px 0 0 " <> css

      base
      |> Map.new()
      |> Map.update(:style, bar, &(bar <> ";" <> &1))
      |> Map.put(:"data-status", color || "none")
    end
  end

  defp validate_breakpoints!(bps) do
    ok? =
      is_list(bps) and length(bps) in 2..5 and Enum.all?(bps, &is_integer/1) and
        bps == Enum.sort(Enum.uniq(bps), :desc)

    unless ok?,
      do:
        raise(
          ArgumentError,
          "card_table breakpoints must be 2 to 5 strictly descending integers, got: #{inspect(bps)}"
        )
  end

  # -- sub line ---------------------------------------------------------------------------------

  attr :priority, :integer,
    default: nil,
    doc: "1 to 4: leaves where the columns of that priority leave."

  attr :when_hidden, :string, default: nil, values: [nil, "p1", "p2", "p3", "p4"]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A second line inside a `card_table` cell (12px, faint) that leaves by its own `priority`; or,
  with `when_hidden="p2"`, shows only once the columns of priority 2 have left.
  """
  def ctable_sub(assigns) do
    pri = assigns.priority && assigns.priority in 1..4 && "lu-p#{assigns.priority}"

    wh =
      case assigns.when_hidden do
        "p" <> n -> "lu-wh" <> n
        _ -> nil
      end

    assigns = assign(assigns, :classes, cx(["lu-xs lu-muted", pri, wh, assigns.class]))

    ~H"""
    <div class={@classes} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
