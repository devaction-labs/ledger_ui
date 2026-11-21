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

  The trigger is the inner block (or, with a `<:trigger>` slot, the slot, and the inner block is
  the hint: `<.tooltip id="t"><:trigger><.button>Save</.button></:trigger>Save the draft</.tooltip>`); the hint floats next to it (`placement`, 12 values) in any
  `color`. The `LedgerUI.Float` hook (`priv/static/ledger_ui/hooks/float.js`) shows it on hover/focus,
  click or never (`manual`), after `delay` ms, optionally following the cursor, and flips it when
  there is no room. `LedgerUI.open/close/toggle("id")` show and hide it, `open` drives it from the
  server. `on_open` / `on_close` take an event name (payload `%{"id" => id}`, sent to `target`) or a `%JS{}`.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @colors ~w(neutral light dark primary secondary info success warning error)

  # one utility per property; the colour is `--c` / `--c-on` (see `LedgerUI.Color`) except the three fixed looks
  @tips %{
    "neutral" => "bg-ink text-on-inverse",
    "dark" => "bg-[#171717] text-white",
    "light" => "bg-panel text-ink"
  }
  @tip_base "inline-flex items-center rounded-[8px]"
  @tip_kbd "[&_kbd]:font-mono [&_kbd]:text-[10.5px] [&_kbd]:opacity-70"
  @arrow_pos %{
    "bottom" => "bottom-[-4px] left-1/2 -ml-1",
    "top" => "top-[-4px] left-1/2 -ml-1",
    "left" => "left-[-4px] top-1/2 -mt-1",
    "right" => "right-[-4px] top-1/2 -mt-1"
  }
  @placements ~w(top top-start top-end right right-start right-end bottom bottom-start bottom-end left left-start left-end)

  attr :id, :string, required: true
  attr :text, :string, default: nil
  attr :color, :string, default: "neutral", values: @colors
  attr :placement, :string, default: "top", values: @placements
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

  attr :rest, :global,
    include: ~w(trigger content),
    doc:
      "`trigger` is how it opens: `hover` (the default), `click`, `focus` or `manual`. `content=\"...\"` is the text, like `text`."

  slot :content
  slot :trigger, doc: "The element the hint hangs from; the inner block is then the hint."
  slot :inner_block, required: true

  def tooltip(assigns) do
    # `trigger` and `content` are slots; the string forms (`trigger="click"`, `content="Hint"`) are
    # global attributes that Phoenix leaves in the assigns (and in `rest`)
    {mode_rest, rest} = Map.pop(assigns.rest, :trigger)
    {content_rest, rest} = Map.pop(rest, :content)
    {mode, trigger} = string_or_slot(assigns.trigger, mode_rest || "hover")
    {content_text, content} = string_or_slot(assigns.content, content_rest)
    slot_trigger? = trigger != []

    assigns =
      assign(assigns,
        rest: rest,
        text: assigns.text || content_text,
        trigger: trigger,
        content: content,
        trigger_mode: mode
      )

    interactive =
      if assigns.interactive == nil, do: assigns.content != [], else: assigns.interactive

    cfg =
      Support.cfg("tooltip",
        trigger: assigns.trigger_mode,
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
      |> assign(:root_class, cx(["relative inline-flex", assigns.class]))
      |> assign(:fl_class, Support.float_class())
      |> assign(:tip_class_s, tip_class(assigns))
      |> assign(:hidden, !assigns.open)
      |> assign(:fl_id, assigns.id <> "-tip")
      |> assign(:trigger_aria, %{"aria-describedby": assigns.id <> "-tip"})
      |> assign(:slot_trigger?, slot_trigger?)

    ~H"""
    <span id={@id} data-part="tooltip" class={@root_class} phx-hook="LedgerUI.Float" {@cfg} {@rest}>
      <%= if @slot_trigger? do %>
        {render_slot(@trigger, @trigger_aria)}
      <% else %>
        {render_slot(@inner_block, @trigger_aria)}
      <% end %>
      <span
        id={@fl_id}
        data-part="tooltip-float"
        data-lu-fl=""
        data-lu-placement={@placement}
        role="tooltip"
        class={@fl_class}
        hidden={@hidden}
        keep-hidden
        keep-style
        keep-class
      >
        <span data-part="tooltip-tip" class={@tip_class_s}>
          <%= cond do %>
            <% @slot_trigger? -> %>
              {render_slot(@inner_block)}
            <% @content == [] -> %>
              {@text}
            <% true -> %>
              {render_slot(@content)}
          <% end %>
        </span>
      </span>
    </span>
    """
  end

  defp tip_class(assigns) do
    cx([
      @tip_base,
      @tip_kbd,
      "gap-1.5 text-xs/4",
      look(assigns.color, "shadow-sm"),
      assigns.color not in ~w(neutral dark light) && LedgerUI.Color.vars(assigns.color),
      if(assigns.content != [], do: "p-0", else: "px-2 py-[5px]"),
      assigns.tip_class
    ])
  end

  defp arrow_pos(side), do: @arrow_pos[side]

  defp look(color, shadow),
    do: [
      Map.get(@tips, color, "bg-(--c) text-(--c-on)"),
      if(color == "light",
        do: "shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-md)]",
        else: shadow
      )
    ]

  attr :color, :string, default: "neutral", values: @colors

  attr :size, :string,
    default: "sm",
    values: ~w(sm md),
    doc:
      "`sm` is the 12px hint of `tooltip/1`; `md` the larger 12.5px one (more padding, a deeper shadow)."

  attr :arrow, :string,
    default: nil,
    values: [nil, "top", "bottom", "left", "right"],
    doc: "The side the arrow is drawn on (it points away from the bubble); no arrow by default."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  Only the bubble of a tooltip, in the page flow: no trigger, no hook, no floating. For previews
  and for hints you place yourself.

      <.tooltip_tip arrow="bottom">Search <.kbd variant="dark">⌘K</.kbd></.tooltip_tip>
  """
  def tooltip_tip(assigns) do
    assigns =
      assign(
        assigns,
        :gap,
        if(assigns.size == "md", do: "gap-2", else: "gap-1.5")
      )

    assigns =
      assign(
        assigns,
        :tip_cls,
        cx([
          @tip_base,
          "relative",
          if(assigns.size == "md",
            do: "px-[9px] py-1.5 text-[12.5px]/4 whitespace-nowrap",
            else: "px-2 py-[5px] text-xs/4"
          ),
          look(assigns.color, if(assigns.size == "md", do: "shadow-md", else: "shadow-sm")),
          assigns.color not in ~w(neutral dark light) && LedgerUI.Color.vars(assigns.color),
          assigns.class
        ])
      )

    ~H"""
    <span data-part="tooltip-tip" class={@tip_cls} {@rest}>
      <span class={["inline-flex items-center", @gap]}>{render_slot(@inner_block)}</span><i
        :if={@arrow}
        data-part="tooltip-arrow"
        aria-hidden="true"
        class={[
          "pointer-events-none absolute size-2 rotate-45 rounded-[1px] bg-inherit",
          arrow_pos(@arrow)
        ]}
      ></i>
    </span>
    """
  end

  defp string_or_slot(list, string) when is_list(list), do: {string, list}
  defp string_or_slot(text, _string) when is_binary(text), do: {text, []}
  defp string_or_slot(_, string), do: {string, []}
end
