defmodule LedgerUI.Components.Timeline do
  @moduledoc """
  Events down a line, each marked by a filled, outlined, icon or avatar point.

      <.timeline marker="icon" size="lg">
        <.timeline_item title="NF-e autorizada" description="Protocolo 129 2611" time="14:02" color="success">
          <:point><.icon name="check" size="sm" /></:point>
        </.timeline_item>
      </.timeline>

  The items can come from a list or a stream through `rows` and the `:item` slot, which gets
  `{dom_id, row}` (given a stream, the list renders with `phx-update="stream"` and needs an `id`):

      <.timeline id="events" rows={@streams.events}>
        <:item :let={{id, event}}>
          <.timeline_item id={id} title={event.title} time={event.ago} color={event.color} />
        </:item>
      </.timeline>

  `variant="canvas"` is a list of `timeline_event`s, each with a boxed icon tile, a title over a
  subtitle and the time at the right.

  Styling note: the marker look (`solid`, `outline`, `icon`, `avatar`, `dot`) is a class of the
  whole line in the stylesheet, so it is set on the timeline with `marker`; the item's `variant`
  only decides what its point holds.
  """
  use LedgerUI.Component

  @colors %{
    "neutral" => "neutral",
    "primary" => "primary",
    "secondary" => "secondary",
    "accent" => "primary",
    "info" => "info",
    "success" => "success",
    "warning" => "warning",
    "error" => "error",
    "dark" => "dark"
  }
  @tones %{
    "default" => nil,
    "acc" => "acc",
    "pos" => "pos",
    "neg" => "neg",
    "warn" => "warn",
    "info" => "info"
  }

  attr :line_space, :boolean, default: false, doc: "Leaves a gap between the points and the line."
  attr :size, :string, default: "md", values: ~w(md lg xl 2xl)
  attr :density, :string, default: "default", values: ~w(default compact)
  attr :variant, :string, default: "line", values: ~w(line canvas)

  attr :marker, :string,
    default: "solid",
    values: ~w(solid outline icon avatar dot),
    doc: "The look of the points of a `line` timeline."

  attr :items, :list,
    default: [],
    doc:
      "Points as data, before the inner block: maps with `:title` and optionally `:time`, `:description`, `:color`, `:variant` (`solid`, `outline`, `icon`, `avatar`) and `:ping`, one `timeline_item/1` each."

  attr :id, :string, default: nil, doc: "Required with a stream."
  attr :rows, :any, default: nil, doc: "A list or a stream of rows rendered by the `:item` slot."
  attr :row_id, :any, default: nil, doc: "A function from a row to its DOM id, for a plain list."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block
  slot :item, doc: "Renders one row; gets `{dom_id, row}`."

  def timeline(assigns) do
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.rows)

    assigns =
      assigns
      |> assign(:classes, classes(assigns))
      |> assign(:stream?, stream?)
      |> assign(:rows, rows(assigns.rows, assigns.row_id, stream?))

    ~H"""
    <div
      id={@id}
      data-part="timeline"
      class={@classes}
      phx-update={@stream? && "stream"}
      {@rest}
    >
      <.timeline_item
        :for={i <- @items}
        title={i[:title]}
        time={i[:time]}
        description={i[:description]}
        color={i[:color] || "neutral"}
        variant={i[:variant] || "solid"}
        ping={i[:ping] == true}
      />
      {render_slot(@inner_block)}
      <%= if @rows do %>
        <%= for {dom_id, row} <- @rows do %>
          <%= for item <- @item do %>
            {render_slot(item, {dom_id, row})}
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp rows(nil, _fun, _stream?), do: nil
  defp rows(rows, _fun, true), do: rows
  defp rows(rows, nil, false), do: Enum.map(rows, &{nil, &1})
  defp rows(rows, fun, false), do: Enum.map(rows, &{fun.(&1), &1})

  defp classes(%{variant: "canvas"} = a), do: cx(["lu-tl", a.class])

  defp classes(a) do
    cx([
      "lu-tl2",
      a.marker != "solid" && a.marker,
      a.size != "md" && "s-#{a.size}",
      a.density == "compact" && "compact",
      a.line_space && "gap",
      a.class
    ])
  end

  attr :title, :string, default: nil
  attr :time, :string, default: nil
  attr :description, :string, default: nil
  attr :color, :string, default: "neutral", values: Map.keys(@colors)
  attr :variant, :string, default: "solid", values: ~w(solid outline icon avatar)
  attr :point_class, :any, default: nil
  attr :ping, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :details, doc: "The description with markup; replaces `description`."
  slot :inner_block
  slot :point, doc: "What the point shows, usually an icon."

  def timeline_item(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["e", "c-#{@colors[assigns.color]}", assigns.class]))
      |> assign(:mk_class, cx(["mk", assigns.ping && "mo-pulse", assigns.point_class]))

    ~H"""
    <div data-part="timeline-item" class={@classes} {@rest}>
      <span class={@mk_class}>{render_slot(@point)}</span>
      <div class="tx">
        <b :if={@title}>{@title}</b>
        <small :if={@details != []}>{render_slot(@details)}</small>
        <small :if={@details == [] and @description}>{@description}</small>
        <time :if={@time}>{@time}</time>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :time, :string, default: nil
  attr :tone, :string, default: "default", values: Map.keys(@tones)
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "The icon inside the tile."
  slot :inner_block, doc: "Free content after the title and the subtitle."

  def timeline_event(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-tl-i", assigns.class]))
      |> assign(:ic_class, cx(["lu-ic", @tones[assigns.tone]]))

    ~H"""
    <div data-part="timeline-event" class={@classes} {@rest}>
      <span class={@ic_class}>{render_slot(@icon)}</span>
      <div class="t">
        <b :if={@title} style="font-weight:500">{@title}</b>
        <span :if={@time} class="when">{@time}</span>
        <div :if={@subtitle} class="lu-small lu-muted">{@subtitle}</div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def timeline_day(assigns) do
    ~H"""
    <div
      data-part="timeline-day"
      class={cx(["day lu-xs lu-muted mono", @class])}
      style="padding:2px 0 10px 40px"
      {@rest}
    >
      {@label}
    </div>
    """
  end
end
