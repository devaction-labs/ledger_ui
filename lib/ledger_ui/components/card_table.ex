defmodule LedgerUI.Components.CardTable do
  @moduledoc """
  The "card" table: one row per record in a rounded tray (styled with utilities only), with an optional heading, a
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

  ## Card layout, panel, copy, edit

    * Under the last breakpoint (`520` by default) rows with a column `role` (`head`, `status`,
      `title`, `value`) become two-line cards; `card` keeps a column in its own line, `truncate`,
      `width` shape the tracks, `<:action card={false}>` leaves the action cell out.
    * With `<:detail>` slots or columns with `priority`, a click on a row (rows variant) opens a
      panel under it (hook `LedgerUI.CardTable`, on the `<tbody>`); `panel_label` names it.
    * `copy` / `copy_label` / `copied_label` / `copy_show` / `copy_tip` on a column draw a copy button
      (same hook).
    * `row_editing` + `<:edit>` swap a row for an inline form; `row_action` drops the action of a
      row.

  `status` paints an inset bar through `box-shadow` on the row (`data-status` carries the colour name).

  The tray, its heading, description and footer are styled here; the table inside (rows, cells,
  breakpoints, details panel) is `LedgerUI.Components.Table`. `ctable_sub` hides itself with the same
  container-query utilities (`Table.Layout`), from the `breakpoints` it is given.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Skeleton, only: [skeleton: 1]

  alias LedgerUI.Components.Table

  @tray "flex min-w-0 flex-col rounded-xl p-1.5"
  @tray_look "border border-line bg-tray"
  @tray_bare "border-0 bg-transparent"
  @head "flex min-h-11 items-center gap-2.5 pt-2 pr-2.5 pb-2.5 pl-3.5"
  @title "inline-flex items-center gap-2 font-display text-xs leading-4 font-medium tracking-[.08em] text-ink-2 uppercase"
  @body "relative min-w-0 flex-1 rounded-lg border border-line bg-panel p-0"
  @toolbar "flex flex-wrap items-center gap-2.5 border-b border-line px-3.5 py-2.5"
  @selection "flex flex-wrap items-center gap-2.5 bg-accent-soft px-3.5 py-2 text-[13px] text-accent-content"
  @selection_badge "inline-flex h-6 items-center rounded-full bg-accent-600 px-2.5 text-xs leading-none font-medium whitespace-nowrap text-accent-foreground tabular-nums"
  @state "flex flex-col items-center justify-center gap-2.5 px-3.5 py-10 text-center text-[13px] text-muted"
  @cell "border-t border-line px-3.5 py-3"
  @foot "flex flex-wrap items-center justify-between gap-2 border-t border-line pt-2.5 pr-3 pb-1.5 pl-3.5 text-[13px] text-muted"

  @status_colors %{
    "success" => "var(--lu-pos)",
    "info" => "var(--lu-info)",
    "warning" => "var(--lu-chart-3)",
    "error" => "var(--lu-neg)",
    "primary" => "var(--lu-accent)"
  }

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
  attr :panel_label, :string, default: "Details", doc: "The accessible name of the details panel."
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

  attr :row_editing, :any,
    default: nil,
    doc: "Function of the row; true shows the `<:edit>` slot in place of the cells."

  attr :row_action, :any,
    default: nil,
    doc: "Function of the row; false leaves out the content of its action cell."

  attr :breakpoints, :list,
    default: [1180, 960, 720, 520],
    doc:
      "Widths (px) under which priority 1, 2, 3... leave, descending; the last is the card layout."

  attr :body_class, :any, default: nil, doc: "Classes of the `<tbody>`."
  attr :variant, :string, default: "rows", values: ~w(rows flat)

  attr :selection_label, :string,
    default: "selected",
    doc: "The text after the count in the `:selection` badge, for one selected."

  attr :selection_label_plural, :string,
    default: nil,
    doc: "Same, for several (`selection_label` when nil)."

  attr :selection_badge, :boolean,
    default: true,
    doc:
      "`false` leaves the count badge out of the `:selection` strip (the slot draws all of it)."

  attr :loading, :boolean,
    default: false,
    doc: "Skeleton lines (`loading_rows`, with the columns) in place of the rows."

  attr :loading_rows, :integer, default: 5
  attr :loading_label, :string, default: "Loading"

  attr :error, :string,
    default: nil,
    doc: "A message: shows the error state in place of the rows (wins over `loading`)."

  attr :on_retry, :any,
    default: nil,
    doc: "Event name or `JS` of the retry button of the error state."

  attr :retry_label, :string, default: "Tentar novamente"
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

  slot :detail, doc: "A line of the details panel that opens when a row is clicked." do
    attr :label, :string
  end

  slot :edit, doc: "Inline form in place of the cells of a row being edited."
  slot :empty, doc: "Shown when there are no rows. Receives `%{id, rows, selected, title}`."
  slot :expand, doc: "A full-width line under a row (see `row_expanded`); receives the row."

  slot :foot,
    doc: "A line inside the card under the rows. Receives `%{id, rows, selected, title}`."

  slot :toolbar,
    doc:
      "A strip inside the card, between the heading and the table (search, filters, export), with a hairline under it."

  slot :selection,
    doc:
      "A strip under the toolbar, only while something is selected, with the `accent-soft` fill and no border. Receives `%{count, selected}`; the count badge is drawn before it."

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
      |> assign(:count, length(assigns.selected))
      |> assign(:toolbar_class, @toolbar)
      |> assign(:selection_class, @selection)
      |> assign(:selection_badge_class, @selection_badge)
      |> assign(:state_class, @state)
      |> assign(:cell_class, @cell)
      |> assign(:flat?, flat?)
      |> assign(:card?, card?)
      |> assign(:head?, assigns.title != nil or assigns.actions != [] or assigns.top != [])
      |> assign(:table_variant, if(flat?, do: "flat"))
      |> assign(:tray_class, [@tray, if(assigns.bordered, do: @tray_look, else: @tray_bare)])
      |> assign(:head_class, @head)
      |> assign(:title_class, @title)
      |> assign(:body_class_tray, @body)
      |> assign(:foot_class, @foot)
      |> assign(:expand_open, expand_open(assigns))
      |> assign(:attrs_fun, attrs_fun(assigns))
      |> assign(:bps, Enum.take(assigns.breakpoints, length(assigns.breakpoints) - 1))
      |> assign(:card_below, if(flat?, do: 520, else: List.last(assigns.breakpoints)))
      |> assign(
        :details?,
        not flat? and (assigns.detail != [] or Enum.any?(assigns.col, &(&1[:priority] in 1..4)))
      )

    ~H"""
    <%= if @card? do %>
      <section
        id={@id <> "-card"}
        class={[@tray_class, @class]}
        data-part="card-table"
        {@rest}
      >
        <div :if={@head?} data-part="card-table-head" class={@head_class}>
          <%= if @top != [] do %>
            {render_slot(@top)}
          <% else %>
            <span :if={@title} data-part="card-table-title" class={@title_class}>{@title}</span>
            <span :if={@meta} data-part="card-table-meta" class="text-xs/4 text-muted">{@meta}</span>
          <% end %>
          <div
            :if={@actions != []}
            data-part="card-table-actions"
            class="ml-auto flex items-center gap-1.5"
          >
            {render_slot(@actions)}
          </div>
        </div>
        <p
          :if={@description}
          data-part="card-table-description"
          class="m-0 px-3.5 pb-2.5 text-xs/4 text-muted"
        >
          {@description}
        </p>
        <%= if @flat? do %>
          <.strips {assigns} />
          <.content {assigns} />
        <% else %>
          <div data-part="card-table-body" class={@body_class_tray}>
            <.strips {assigns} />
            <.content {assigns} />
          </div>
        <% end %>
        <div :if={@foot != []} data-part="card-table-foot" class={@foot_class}>
          {render_slot(@foot, @ctx)}
        </div>
      </section>
    <% else %>
      <.strips {assigns} />
      <.content {assigns} />
    <% end %>
    """
  end

  defp strips(assigns) do
    ~H"""
    <div :if={@toolbar != []} data-part="card-table-toolbar" class={@toolbar_class}>
      {render_slot(@toolbar)}
    </div>
    <div
      :if={@selection != [] and @count > 0}
      id={@id <> "-selection"}
      data-part="card-table-selection"
      aria-live="polite"
      class={[@selection_class, @toolbar == [] && "rounded-t-[inherit]"]}
    >
      <span
        :if={@selection_badge}
        data-part="card-table-selection-count"
        class={@selection_badge_class}
      >
        {@count} {if @count == 1,
          do: @selection_label,
          else: @selection_label_plural || @selection_label}
      </span>
      {render_slot(@selection, %{count: @count, selected: @selected})}
    </div>
    """
  end

  defp content(%{error: error} = assigns) when is_binary(error) do
    ~H"""
    <div data-part="card-table-error" role="alert" class={@state_class}>
      <span data-part="card-table-error-message" class="text-ink-2">{@error}</span>
      <button
        :if={@on_retry}
        type="button"
        data-part="card-table-retry"
        class="inline-flex h-8 cursor-pointer items-center justify-center rounded-lg border border-line-strong bg-panel px-3 text-[13px] font-medium text-ink hover:bg-hover"
        phx-click={@on_retry}
        phx-target={@target}
      >
        {@retry_label}
      </button>
    </div>
    """
  end

  defp content(%{loading: true} = assigns) do
    ~H"""
    <div data-part="card-table-loading" role="status" aria-busy="true" aria-label={@loading_label}>
      <table class="w-full border-collapse">
        <thead>
          <tr>
            <th
              :for={c <- @col}
              class="px-3.5 py-3 text-left text-[11.5px] leading-4 font-medium tracking-[.07em] whitespace-nowrap text-muted uppercase"
            >
              {c[:label]}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={_ <- 1..max(@loading_rows, 1)} data-part="card-table-loading-row">
            <td :for={_ <- @col} class={@cell_class}>
              <.skeleton class="w-3/5" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp content(assigns), do: inner_table(assigns)

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
      card_below={@card_below}
      details={@details?}
      panel_label={@panel_label}
      row_editing={@row_editing}
      row_action={@row_action}
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
        role={c[:role]}
        width={c[:width]}
        truncate={c[:truncate]}
        card={c[:card]}
        copy={c[:copy]}
        copy_label={c[:copy_label]}
        copied_label={c[:copied_label]}
        copy_show={c[:copy_show]}
        copy_tip={c[:copy_tip]}
      >
        {render_slot(c, row)}
      </:col>
      <:action
        :let={row}
        :for={a <- @action}
        priority={a[:priority]}
        card={a[:card]}
      >
        {render_slot(a, row)}
      </:action>
      <:detail :let={row} :for={d <- @detail} label={d[:label]}>{render_slot(d, row)}</:detail>
      <:edit :let={row} :for={e <- @edit}>{render_slot(e, row)}</:edit>
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
      css = @status_colors[color] || "var(--lu-line-strong)"
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

  attr :breakpoints, :list,
    default: [1180, 960, 720],
    doc:
      "The widths of the table's priorities 1, 2, 3...: the `breakpoints` of the `card_table` without its last (card) width."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A second line inside a `card_table` cell (12px, faint) that leaves by its own `priority`; or,
  with `when_hidden="p2"`, shows only once the columns of priority 2 have left.
  """
  def ctable_sub(assigns) do
    width = fn p -> Enum.at(assigns.breakpoints, p - 1) end

    pri =
      (assigns.priority in 1..4 and width.(assigns.priority)) &&
        Table.Layout.hide(width.(assigns.priority))

    wh =
      case assigns.when_hidden do
        "p" <> n ->
          w = width.(String.to_integer(n))
          w && ["hidden", Table.Layout.block(w)]

        _ ->
          nil
      end

    assigns = assign(assigns, :classes, cx(["text-xs/4 text-muted", pri, wh, assigns.class]))

    ~H"""
    <div data-part="card-table-sub" class={@classes} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
