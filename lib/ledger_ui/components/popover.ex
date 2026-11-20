defmodule LedgerUI.Components.Popover do
  @moduledoc """
  A card with an arrow next to its trigger (`<.popover>`), for more than a tooltip holds.

      <.popover id="lesson">
        <:trigger><.button variant="primary">Lessons</.button></:trigger>
        <:title>Group Lesson</:title>
        <p class="mt-2">Lorem ipsum dolor sit amet.</p>
      </.popover>

      <.popover id="john" trigger_on="hover" placement="top" width="192px">...</.popover>

  Opens and closes from the browser (`LedgerUI.toggle("lesson")`), from the server
  (`LedgerUI.close(socket, "lesson")`) or from `open`; a click outside and Esc close it. The
  `LedgerUI.Float` hook (`priv/static/ledger_ui/hooks/float.js`) places it (`placement`, `fallbacks` when there
  is no room, `offset`), draws the arrow and runs `on_open` / `on_close` (an event name with payload
  `%{"id" => id}` to `target`, or a `%JS{}`).

  The panel is a `role="dialog"` named by its `:title` or by `label`. `width` is the card's width
  (272px by default; `nil` leaves it to its content).
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @placements ~w(bottom-start bottom bottom-end top-start top top-end left-start left left-end right-start right right-end)

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :placement, :string, default: "right-start", values: @placements
  attr :fallbacks, :list, default: ["bottom", "top"]
  attr :offset, :integer, default: 12
  attr :trigger_on, :string, default: "click", values: ~w(click hover)
  attr :arrow, :boolean, default: true
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :label, :string, default: nil
  attr :class, :any, default: nil, doc: "Merged into the card."
  attr :width, :string, default: "272px", doc: "The card's width; `nil` for its content's."
  attr :rest, :global

  slot :inner_block
  slot :title
  slot :trigger, required: true

  def popover(assigns) do
    cfg =
      Support.cfg("popover",
        trigger: assigns.trigger_on,
        placement: assigns.placement,
        fallbacks: Enum.join(assigns.fallbacks, ","),
        offset: assigns.offset,
        arrow: Support.flag(assigns.arrow),
        open: Support.flag(assigns.open),
        "on-open": Support.handler(assigns.on_open),
        "on-close": Support.handler(assigns.on_close),
        target: assigns.target
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:fl_class, "fl p-" <> assigns.placement)
      |> assign(:card_class, cx(["lu-pop pad", assigns.class]))
      |> assign(
        :card_style,
        Support.style([
          "white-space:normal",
          assigns.width && "width:#{assigns.width}",
          assigns.width && "max-width:90vw"
        ])
      )
      |> assign(:title_id, if(assigns.title != [], do: assigns.id <> "-title"))
      |> assign(:aria_label, if(assigns.title == [], do: assigns.label))
      |> assign(:hidden, !assigns.open)

    ~H"""
    <span id={@id} class="lu-anc" phx-hook="LedgerUI.Float" {@cfg} {@rest}>
      {render_slot(@trigger)}
      <span class={@fl_class} hidden={@hidden} keep-hidden keep-style keep-class>
        <div
          class={@card_class}
          {Support.st(@card_style)}
          role="dialog"
          aria-labelledby={@title_id}
          aria-label={@aria_label}
        >
          <b :if={@title != []} id={@title_id}>{render_slot(@title)}</b>
          {render_slot(@inner_block)}
        </div>
      </span>
    </span>
    """
  end
end
