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

  Styled only with Tailwind utilities. The marker look (`solid`, `outline`, `icon`, `avatar`, `dot`)
  belongs to the whole line, so it is set on the timeline with `marker` (the root carries
  `data-lu-marker` and the items read it through `group-data-[lu-marker=...]/tl:`); the item's
  `variant` only decides what its point holds. `loop` plays the canvas loop (`mo-stg`): each item
  fades in, stays and leaves, staggered by its own `--dl` delay (`style="--dl:0.6s"`).
  """
  use LedgerUI.Component

  alias LedgerUI.Color

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

  # the boxed icon of a `timeline_event`
  @tones %{
    "default" => "bg-sunken text-ink-2",
    "acc" => "bg-accent-soft text-accent-content",
    "pos" => "bg-pos-soft text-pos",
    "neg" => "bg-neg-soft text-neg",
    "warn" => "bg-warn-soft text-warn",
    "info" => "bg-info-soft text-info"
  }

  @sizes %{
    "md" => "[--mk:28px]",
    "lg" => "[--mk:34px]",
    "xl" => "[--mk:40px]",
    "2xl" => "[--mk:48px]"
  }

  # `stagger`: the loop of the canvas (every direct child, delayed by its own `--dl`)
  @loop "*:animate-[mo-stg_var(--dur,6s)_cubic-bezier(.2,.8,.2,1)_var(--dl,0s)_infinite]"

  attr :line_space, :boolean, default: false, doc: "Leaves a gap between the points and the line."
  attr :size, :string, default: "md", values: ~w(md lg xl 2xl)
  attr :density, :string, default: "default", values: ~w(default compact)
  attr :variant, :string, default: "line", values: ~w(line canvas)

  attr :marker, :string,
    default: "solid",
    values: ~w(solid outline icon avatar dot),
    doc: "The look of the points of a `line` timeline."

  attr :loop, :boolean,
    default: false,
    doc: "The canvas loop (`mo-stg`): the items fade in one after the other, forever."

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
    changed0 = assigns.__changed__
    stream? = match?(%Phoenix.LiveView.LiveStream{}, assigns.rows)

    assigns =
      assigns
      |> assign(:classes, classes(assigns))
      |> assign(:stream?, stream?)
      |> assign(:rows, rows(assigns.rows, assigns.row_id, stream?))

    assigns =
      settle(assigns, changed0,
        classes: [:variant, :loop, :class, :marker, :size, :line_space, :density],
        stream?: [:rows],
        rows: [:rows, :row_id, :stream?]
      )

    ~H"""
    <div
      id={@id}
      data-part="timeline"
      data-lu-marker={@variant == "line" && @marker}
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

  defp classes(%{variant: "canvas"} = a),
    do: cx(["flex flex-col", a.loop && @loop, a.class])

  # `--mk` is the size of a point; the line leaves from under it (`--ln-*`: left, top, bottom).
  defp classes(a) do
    dot? = a.marker == "dot"

    cx([
      "group/tl flex flex-col",
      if(dot?, do: "[--mk:10px]", else: @sizes[a.size]),
      a.marker == "icon" && "[--mk-r:9px]",
      dot? && "[--mk-m:6px_9px_0] [--ln-l:13.5px]",
      dot? && !a.line_space && "[--ln-t:18px]",
      dot? && a.line_space && "[--ln-t:22px]",
      !dot? && a.line_space && "[--ln-t:calc(var(--mk)+4px)]",
      a.line_space && "[--ln-b:4px]",
      a.density == "compact" && "[--pb:8px]",
      a.loop && @loop,
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
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:classes, [
        "relative flex gap-3 pb-(--pb,18px)",
        "before:absolute before:top-(--ln-t,var(--mk,28px)) before:bottom-(--ln-b,0px) before:left-(--ln-l,calc(var(--mk,28px)/2-.5px)) before:w-px before:bg-line-strong before:content-[''] last:before:hidden",
        Color.vars(@colors[assigns.color]),
        assigns.class
      ])
      |> assign(:mk_class, [
        "z-[1] m-(--mk-m,0px) grid size-(--mk,28px) flex-none place-items-center rounded-[var(--mk-r,50%)] bg-(--c) text-(--c-on)",
        "group-data-[lu-marker=outline]/tl:bg-panel group-data-[lu-marker=outline]/tl:text-(--c) group-data-[lu-marker=outline]/tl:shadow-[inset_0_0_0_1.5px_var(--c)]",
        "group-data-[lu-marker=icon]/tl:bg-(--c-soft) group-data-[lu-marker=icon]/tl:text-(--c-ink)",
        assigns.ping && "animate-[mo-pulse_2s_ease-in-out_infinite]",
        assigns.point_class
      ])

    assigns =
      settle(assigns, changed0,
        classes: [:color, :class],
        mk_class: [:ping, :point_class]
      )

    ~H"""
    <div data-part="timeline-item" class={@classes} {@rest}>
      <span data-part="timeline-point" class={@mk_class}>{render_slot(@point)}</span>
      <div data-part="timeline-text" class="flex flex-col gap-0.5 pt-[3px] text-[13.5px]">
        <b :if={@title} data-part="timeline-title" class="font-medium">{@title}</b>
        <small :if={@details != []} data-part="timeline-description" class="text-[12.5px] text-muted">{render_slot(
          @details
        )}</small>
        <small
          :if={@details == [] and @description}
          data-part="timeline-description"
          class="text-[12.5px] text-muted"
        >{@description}</small>
        <time :if={@time} data-part="timeline-time" class="font-mono text-[11.5px] text-subtle">{@time}</time>
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
    changed0 = assigns.__changed__
    assigns = assign(assigns, :tone_class, @tones[assigns.tone])
    assigns = settle(assigns, changed0, tone_class: [:tone])

    ~H"""
    <div
      data-part="timeline-event"
      class={[
        "relative flex gap-3.5 pb-[18px]",
        "before:absolute before:top-[34px] before:bottom-0.5 before:left-[15px] before:w-px before:bg-line-strong before:content-[''] last:before:hidden",
        @class
      ]}
      {@rest}
    >
      <span
        data-part="timeline-icon"
        class={["inline-grid size-8 flex-none place-items-center rounded-md", @tone_class]}
      >{render_slot(@icon)}</span>
      <div data-part="timeline-text" class="min-w-0 flex-1 pt-[5px] text-sm">
        <b :if={@title} data-part="timeline-title" class="font-medium">{@title}</b>
        <span :if={@time} data-part="timeline-time" class="ml-1.5 text-[12.5px] text-muted">{@time}</span>
        <div
          :if={@subtitle}
          data-part="timeline-subtitle"
          class="text-[13px] leading-[18px] text-muted"
        >
          {@subtitle}
        </div>
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
      class={["pt-0.5 pr-0 pb-2.5 pl-10 font-mono text-xs leading-4 text-muted", @class]}
      {@rest}
    >
      {@label}
    </div>
    """
  end
end
