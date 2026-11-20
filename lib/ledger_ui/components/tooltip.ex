defmodule LedgerUI.Components.Tooltip do
  @moduledoc """
  A short hint around a trigger (`<.tooltip>`).

      <.tooltip id="save-tip" text="Save the draft">
        <.button>Save</.button>
      </.tooltip>

      <.tooltip id="top-start" text="Top Start" color="success" placement="top-start">
        <.button variant="outline">Top Start</.button>
      </.tooltip>

      <.tooltip id="profile" trigger="click">
        <.button>Content</.button>
        <:content><div class="p-3">...</div></:content>
      </.tooltip>

  The trigger is the inner block; the hint floats next to it (`placement`, 12 values) in any
  `color`. The `LedgerUI.Float` hook (`priv/static/ledger_ui/hooks/float.js`) shows it on hover/focus,
  click or never (`manual`), after `delay` ms, optionally following the cursor, and flips it when
  there is no room. `LedgerUI.open/close/toggle("id")` show and hide it, `open` drives it from the
  server. `on_open` / `on_close` take an event name (payload `%{"id" => id}`, sent to `target`) or a `%JS{}`.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @colors ~w(neutral light dark primary secondary info success warning error)
  @placements ~w(top top-start top-end right right-start right-end bottom bottom-start bottom-end left left-start left-end)

  attr :id, :string, required: true
  attr :text, :string, default: nil
  attr :color, :string, default: "neutral", values: @colors
  attr :placement, :string, default: "top", values: @placements
  attr :trigger, :string, default: "hover", values: ~w(hover click focus manual)
  attr :delay, :integer, default: 0
  attr :duration, :integer, default: 300

  attr :follow_cursor, :string,
    default: nil,
    values: [nil, "", "both", "horizontal", "vertical", "initial"]

  attr :arrow, :boolean, default: true
  attr :interactive, :boolean, default: nil
  attr :open, :boolean, default: false
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :tip_class, :any, default: nil
  attr :rest, :global

  slot :content
  slot :inner_block, required: true

  def tooltip(assigns) do
    interactive =
      if assigns.interactive == nil, do: assigns.content != [], else: assigns.interactive

    cfg =
      Support.cfg("tooltip",
        trigger: assigns.trigger,
        placement: assigns.placement,
        delay: assigns.delay,
        duration: assigns.duration,
        follow: if(assigns.follow_cursor not in [nil, ""], do: assigns.follow_cursor),
        arrow: Support.flag(assigns.arrow),
        interactive: Support.flag(interactive),
        open: Support.flag(assigns.open),
        "on-open": Support.handler(assigns.on_open),
        "on-close": Support.handler(assigns.on_close),
        target: assigns.target
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:root_class, cx(["lu-anc", assigns.class]))
      |> assign(:fl_class, "fl p-" <> assigns.placement)
      |> assign(:tip_class_s, cx(["lu-tip2", "c-" <> assigns.color, assigns.tip_class]))
      |> assign(:tip_style, if(assigns.content != [], do: "padding:0"))
      |> assign(:hidden, !assigns.open)
      |> assign(:fl_id, assigns.id <> "-tip")
      |> assign(:trigger_aria, %{"aria-describedby": assigns.id <> "-tip"})

    ~H"""
    <span id={@id} class={@root_class} phx-hook="LedgerUI.Float" {@cfg} {@rest}>
      {render_slot(@inner_block, @trigger_aria)}
      <span
        id={@fl_id}
        role="tooltip"
        class={@fl_class}
        hidden={@hidden}
        keep-hidden
        keep-style
        keep-class
      >
        <span class={@tip_class_s} {Support.st(@tip_style)}>
          <%= if @content == [] do %>
            {@text}
          <% else %>
            {render_slot(@content)}
          <% end %>
        </span>
      </span>
    </span>
    """
  end
end
