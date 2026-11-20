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

  The board is one `LedgerUI.Sortable` hook (`priv/static/ledger_ui/hooks/sortable.js`): columns are
  lists, cards are items, and a drop pushes `event` (to `target` when given) with
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

  @colors ~w(neutral info warning primary teal success)

  # ---------------------------------------------------------------------------
  # kanban
  # ---------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :event, :string, default: nil
  attr :target, :any, default: nil
  attr :group, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :fluid, :boolean, default: false
  attr :active, :string, default: nil, doc: "Phone mode: the column shown below 640px."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def kanban(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-kanban", assigns.class]))
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
    rest = a.rest

    rest =
      case grid_style(a, rest[:style]) do
        nil -> rest
        style -> Map.put(rest, :style, style)
      end

    rest
    |> put_attr(:"data-event", a.event)
    |> put_attr(:"data-group", a.group)
    |> put_attr(:"data-disabled", a.disabled && "true")
    |> put_attr(:"data-phone", a.active)
    |> put_attr(:role, if(rest[:"aria-label"], do: "group"))
  end

  # Without `--cols` the columns are a row of fixed width cards that scrolls sideways.
  defp grid_style(a, style) do
    if is_binary(style) and String.contains?(style, "--cols") do
      nil
    else
      cols = if a.fluid, do: "minmax(0,1fr)", else: "272px"

      base = "grid-template-columns:none;grid-auto-flow:column;grid-auto-columns:#{cols}"
      if style in [nil, ""], do: base, else: base <> ";" <> style
    end
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
      |> assign(:classes, cx(["lu-kcol", assigns.color && "k-" <> assigns.color, assigns.class]))
      |> assign(:attrs, column_attrs(assigns, exceeded?))
      |> assign(:pill, pill)
      |> assign(:pill_attrs, if(exceeded?, do: %{style: "color:var(--neg)"}, else: %{}))
      |> assign(
        :show_empty?,
        assigns.empty != [] and (assigns.count == 0 or assigns.hint == "always")
      )
      |> assign(
        :bar_style,
        if(exceeded?, do: "--c:var(--neg)", else: "--c:var(--kc,var(--teal-500))")
      )

    ~H"""
    <div id={@id} data-part="kanban-column" class={@classes} {@attrs}>
      <div class="h">
        {render_slot(@icon)}{@label}<span :if={@pill != nil} class="n" {@pill_attrs}>{@pill}</span><span class="lu-grow"></span>{render_slot(
          @actions
        )}
      </div>
      <div
        :if={@meta || @total}
        class="lu-row lu-xs lu-muted"
        style="justify-content:space-between;padding:0 8px"
      >
        <span>{@meta}</span><b>{@total}</b>
      </div>
      <div :if={@progress} class="lu-pb2" style={"height:4px;margin:0 8px;" <> @bar_style}>
        <i style={"width:#{@progress}%"}></i>
      </div>
      {render_slot(@inner_block)}
      <%= if @show_empty? do %>
        <%= for e <- @empty do %>
          <div :if={e[:title]} class="lu-empty">
            <span :if={e[:icon]} class="art"><.icon name={e[:icon]} size="lg" /></span>
            <b>{e[:title]}</b>
            <p>{render_slot(e)}</p>
          </div>
          <div :if={!e[:title]} class="hint">{render_slot(e)}</div>
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
    |> then(fn attrs ->
      if a.disabled,
        do: Map.update(attrs, :style, "opacity:.6", &("opacity:.6;" <> &1)),
        else: attrs
    end)
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
      |> assign(:classes, cx(["lu-kcard", assigns.class]))
      |> assign(:attrs, card_attrs(assigns))

    ~H"""
    <div id={@id} data-part="kanban-card" class={@classes} {@attrs}>
      {render_slot(@inner_block)}
      <span
        :if={@grip}
        aria-hidden="true"
        data-grip
        style="position:absolute;top:8px;right:8px;opacity:.45;letter-spacing:-2px;font-size:12px;line-height:1"
      >
        ⋮⋮
      </span>
      <span :if={@actions != []} data-card-actions style="position:absolute;top:6px;right:6px">
        {render_slot(@actions)}
      </span>
    </div>
    """
  end

  defp card_attrs(a) do
    extra =
      [
        (a.grip or a.actions != []) && "position:relative",
        a.risk && "box-shadow:0 0 0 2px var(--warn)",
        a.dense && "padding:8px;gap:8px"
      ]
      |> Enum.filter(& &1)

    rest = a.rest

    rest =
      case extra do
        [] ->
          rest

        _ ->
          Map.update(rest, :style, Enum.join(extra, ";"), &(Enum.join(extra, ";") <> ";" <> &1))
      end

    put_attr(rest, :"data-id", a.item)
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
      |> assign(:classes, cx(["lu-kcol", assigns.class]))
      |> assign(:attrs, put_attr(assigns.rest, :"data-list", assigns.list))
      |> assign(
        :text,
        if(assigns.meta, do: assigns.label <> " · " <> assigns.meta, else: assigns.label)
      )

    ~H"""
    <aside
      data-part="kanban-lost"
      class={@classes}
      aria-label={@label}
      style="width:52px;align-items:center;padding:12px 6px;gap:10px"
      {@attrs}
    >
      <span style="color:var(--neg)">
        {if @icon == [], do: icon_tag("x-circle"), else: render_slot(@icon)}
      </span>
      <span :if={@count} class="n lu-xs lu-muted">{@count}</span>
      <span class="lu-small lu-muted" style="writing-mode:vertical-rl">{@text}</span>
    </aside>
    """
  end

  defp icon_tag(name) do
    assigns = %{name: name}
    ~H|<.icon name={@name} size="md" />|
  end
end
