defmodule LedgerUI.Components.Kanban do
  @moduledoc """
  Kanban board: a row of tinted columns holding cards that are dragged between them.

      <.kanban id="funnel" event="move" aria-label="Sales funnel" style="--cols:3">
        <.kanban_column id="col-open" list="open" label="Open" count={length(@open)} color="primary">
          <.kanban_card :for={card <- @open} id={"card-\#{card.id}"} item={card.id}>
            <b>{card.title}</b>
          </.kanban_card>
          <:empty>Drop here</:empty>
        </.kanban_column>
        <.kanban_lost label="Lost" count={3} list="lost" />
      </.kanban>

  Styled only with Tailwind utilities. The board is one `LedgerUI.Sortable` hook
  (`priv/static/ledger_ui/hooks/sortable.js`): columns (`data-part="kanban-column"`) are lists,
  cards (`data-part="kanban-card"`) are items, and a drop pushes `event` (to `target` when given) with
  `%{"id" => item, "from" => list, "to" => list, "index" => position}`. Nothing is moved in the
  browser: the server's render is the new order. `data-list`/`data-id` are only rendered when
  `list`/`item` are given; the hook falls back to the element ids.

  A column with a `limit` turns its pill and bar red (`data-wip="exceeded"`) when `count` goes over
  it. The board is `role="group"` when it has an `aria-label`. `--cols` in `style` sets the grid
  columns; without it the columns are 272px wide in a row that scrolls sideways (`fluid` shares
  the width instead).

  The same hook sorts any list: put `phx-hook="LedgerUI.Sortable"` on it with `data-list`,
  `data-event`, `data-group`, `data-handle`, `data-axis`, `data-target`, `data-disabled`; items
  carry `data-id`.
  """
  use LedgerUI.Component

  @colors ~w(neutral info warning primary accent success)

  # the colour of the bar at the top of a column (`--kc`)
  @column_colors %{
    "neutral" => "[--kc:var(--lu-muted)]",
    "info" => "[--kc:var(--lu-info)]",
    "warning" => "[--kc:var(--lu-warn)]",
    "primary" => "[--kc:var(--lu-accent-600)]",
    "accent" => "[--kc:var(--lu-accent-400)]",
    "success" => "[--kc:var(--lu-pos)]"
  }

  @column "flex flex-col gap-1.5 rounded-xl border border-line bg-tray p-1.5 data-[disabled=true]:pointer-events-none data-[over]:-outline-offset-2 data-[over]:outline-2 data-[over]:outline-dashed data-[over]:outline-accent-500"

  # ---------------------------------------------------------------------------
  # kanban
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :event, :string, default: nil
  attr :target, :any, default: nil
  attr :group, :string, default: nil
  attr :disabled, :boolean, default: false

  attr :local, :boolean,
    default: false,
    doc: "The board moves the dropped card itself (and the counters), besides pushing `event`."

  attr :fluid, :boolean, default: false
  attr :active, :string, default: nil, doc: "Phone mode: the column shown below 640px."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def kanban(assigns) do
    assigns =
      assigns
      |> assign(:classes, board_classes(assigns))
      |> assign(:attrs, board_attrs(assigns))

    ~H"""
    <div
      id={@id}
      data-part="kanban"
      class={@classes}
      phx-hook="LedgerUI.Sortable"
      phx-target={@target}
      {@attrs}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp board_attrs(a) do
    a.rest
    |> put_attr(:"data-event", a.event)
    |> put_attr(:"data-group", a.group)
    |> put_attr(:"data-disabled", a.disabled && "true")
    |> put_attr(:"data-lu-local", a.local && "true")
    |> put_attr(:"data-phone", a.active)
    |> put_attr(:role, if(a.rest[:"aria-label"], do: "group"))
  end

  # With `--cols` in `style` the columns are a grid of that many tracks; without it they are a row
  # of fixed width cards that scrolls sideways.
  defp board_classes(a) do
    style = a.rest[:style]
    cols? = is_binary(style) and String.contains?(style, "--cols")

    cx([
      "grid gap-3 overflow-auto",
      if(cols?,
        do: "grid-cols-[repeat(var(--cols,3),minmax(220px,1fr))]",
        else: [
          "grid-cols-none grid-flow-col",
          if(a.fluid, do: "auto-cols-[minmax(0,1fr)]", else: "auto-cols-[272px]")
        ]
      ),
      "data-[phone]:snap-x data-[phone]:snap-mandatory data-[phone]:*:snap-start",
      "max-[639px]:data-[phone]:block max-[639px]:data-[phone]:overflow-visible max-[639px]:data-[phone]:*:not-data-[phone-active=true]:hidden max-[639px]:data-[phone]:*:data-[phone-active=true]:w-full",
      a.class
    ])
  end

  defp put_attr(map, _key, nil), do: map
  defp put_attr(map, _key, false), do: map
  defp put_attr(map, key, value), do: Map.put_new(map, key, value)

  # ---------------------------------------------------------------------------
  # kanban_column
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :list, :string, default: nil
  attr :label, :string, required: true
  attr :count, :any, default: nil
  attr :count_label, :string, default: nil
  attr :over_limit, :boolean, default: false
  attr :hint, :string, default: "empty", values: ~w(empty always)
  attr :active, :boolean, default: false
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :limit, :integer, default: nil
  attr :meta, :string, default: nil
  attr :total, :string, default: nil
  attr :progress, :integer, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :icon
  slot :footer
  slot :inner_block

  slot :empty do
    attr :title, :string
    attr :icon, :string
  end

  def kanban_column(assigns) do
    exceeded? =
      assigns.over_limit or
        (is_integer(assigns.limit) and is_integer(assigns.count) and assigns.count > assigns.limit)

    pill = assigns.count_label || assigns.count

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          @column,
          assigns.color && ["shadow-[inset_0_3px_0_var(--kc)]", @column_colors[assigns.color]],
          assigns.disabled && "opacity-60",
          assigns.class
        ])
      )
      |> assign(:attrs, column_attrs(assigns, exceeded?))
      |> assign(:pill, pill)
      |> assign(:exceeded?, exceeded?)
      |> assign(
        :show_empty?,
        assigns.empty != [] and (assigns.count == 0 or assigns.hint == "always")
      )
      |> assign(
        :bar_class,
        if(exceeded?, do: "[--c:var(--lu-neg)]", else: "[--c:var(--kc,var(--lu-accent-500))]")
      )

    ~H"""
    <div id={@id} data-part="kanban-column" class={@classes} {@attrs}>
      <div
        data-part="kanban-column-header"
        class="flex items-center gap-2 px-2 pt-2 pb-1.5 text-[13px] font-medium"
      >
        {render_slot(@icon)}{@label}<span
          :if={@pill != nil}
          data-part="kanban-column-count"
          class={["tabular-nums", (@exceeded? && "text-neg") || "text-muted"]}
        >{@pill}</span><span data-part="kanban-column-spacer" class="min-w-0 flex-1"></span>{render_slot(
          @actions
        )}
      </div>
      <div
        :if={@meta || @total}
        data-part="kanban-column-meta"
        class="flex flex-wrap items-center justify-between gap-2.5 px-2 text-xs text-muted"
      >
        <span data-part="kanban-column-total">{@meta}</span><b class="font-bold">{@total}</b>
      </div>
      <div
        :if={@progress}
        data-part="kanban-column-progress"
        class={["mx-2 h-1 w-full overflow-hidden rounded-full bg-sunken", @bar_class]}
      >
        <i
          data-part="kanban-column-bar"
          class="block h-full rounded-full bg-(--c)"
          style={"width:#{@progress}%"}
        ></i>
      </div>
      {render_slot(@inner_block)}
      <%= if @show_empty? do %>
        <%= for e <- @empty do %>
          <div
            :if={e[:title]}
            data-part="kanban-column-empty"
            class="flex flex-col items-center gap-1.5 px-6 py-8 text-center"
          >
            <span
              :if={e[:icon]}
              data-part="kanban-column-empty-icon"
              class="relative mb-2 grid size-14 place-items-center rounded-xl border border-line bg-sunken text-muted before:absolute before:-inset-2 before:rounded-2xl before:border before:border-dashed before:border-line-strong before:content-[''] after:absolute after:-inset-[18px] after:rounded-[30px] after:border after:border-dashed after:border-line-strong after:opacity-55 after:content-['']"
            ><.icon name={e[:icon]} size="lg" /></span>
            <b data-part="kanban-column-empty-title" class="text-[16px] font-semibold">{e[:title]}</b>
            <p
              data-part="kanban-column-empty-text"
              class="m-0 mb-2.5 max-w-[340px] text-sm text-muted"
            >
              {render_slot(e)}
            </p>
          </div>
          <div
            :if={!e[:title]}
            data-part="kanban-column-hint"
            class="grid h-16 place-items-center rounded-[12px] border-[1.5px] border-dashed border-line-strong text-[12.5px] text-muted"
          >
            {render_slot(e)}
          </div>
        <% end %>
      <% end %>
      {render_slot(@footer)}
    </div>
    """
  end

  defp column_attrs(a, exceeded?) do
    a.rest
    |> put_attr(:"data-list", a.list)
    |> put_attr(:"data-wip", exceeded? && "exceeded")
    |> put_attr(:"data-disabled", a.disabled && "true")
    |> put_attr(:"data-phone-active", a.active && "true")
  end

  # ---------------------------------------------------------------------------
  # kanban_card
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :item, :any, default: nil
  attr :risk, :boolean, default: false
  attr :dense, :boolean, default: false
  attr :grip, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :inner_block, required: true

  def kanban_card(assigns) do
    assigns =
      assigns
      |> assign(:classes, card_classes(assigns))
      |> assign(:attrs, put_attr(assigns.rest, :"data-id", assigns.item))

    ~H"""
    <div id={@id} data-part="kanban-card" class={@classes} {@attrs}>
      {render_slot(@inner_block)}
      <span
        :if={@grip}
        data-part="kanban-card-grip"
        aria-hidden="true"
        data-grip
        class="absolute top-2 right-2 text-xs leading-none tracking-[-2px] opacity-45"
      >
        ⋮⋮
      </span>
      <span
        :if={@actions != []}
        data-part="kanban-card-actions"
        data-card-actions
        class="absolute top-1.5 right-1.5"
      >
        {render_slot(@actions)}
      </span>
    </div>
    """
  end

  defp card_classes(a) do
    cx([
      "flex cursor-grab flex-col rounded-lg border border-line bg-panel",
      if(a.dense, do: "gap-2 p-2", else: "gap-2.5 p-3"),
      if(a.risk, do: "shadow-[0_0_0_2px_var(--lu-warn)]", else: "shadow-xs"),
      (a.grip or a.actions != []) && "relative",
      "data-[dragging]:opacity-35 data-[dragging]:outline-[1.5px] data-[dragging]:outline-dashed data-[dragging]:outline-line-strong",
      "[&_b]:text-sm [&_b]:leading-[19px] [&_b]:font-medium",
      a.class
    ])
  end

  # ---------------------------------------------------------------------------
  # kanban_lost
  # ---------------------------------------------------------------------------

  attr :label, :string, required: true
  attr :count, :integer, default: nil
  attr :meta, :string, default: nil
  attr :list, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon

  def kanban_lost(assigns) do
    assigns =
      assigns
      |> assign(:attrs, put_attr(assigns.rest, :"data-list", assigns.list))
      |> assign(
        :text,
        if(assigns.meta, do: assigns.label <> " · " <> assigns.meta, else: assigns.label)
      )

    ~H"""
    <aside
      data-part="kanban-lost"
      class={[
        "flex w-[52px] flex-col items-center gap-2.5 rounded-xl border border-line bg-tray px-1.5 py-3 data-[over]:-outline-offset-2 data-[over]:outline-2 data-[over]:outline-dashed data-[over]:outline-accent-500",
        @class
      ]}
      aria-label={@label}
      {@attrs}
    >
      <span data-part="kanban-lost-icon" class="text-neg">
        {if @icon == [], do: icon_tag("x-circle"), else: render_slot(@icon)}
      </span>
      <span :if={@count} data-part="kanban-lost-count" class="text-xs tabular-nums text-muted">{@count}</span>
      <span
        data-part="kanban-lost-label"
        class="text-[13px] leading-[18px] text-muted [writing-mode:vertical-rl]"
      >{@text}</span>
    </aside>
    """
  end

  defp icon_tag(name) do
    assigns = %{name: name}
    ~H|<.icon name={@name} size="md" />|
  end
end
