defmodule LedgerUI.Components.ScrollArea do
  @moduledoc """
  A box that scrolls with a thin scrollbar (6px, transparent track). For long menus, lists in a
  card, the body of a panel. The height comes from `class` or an inline `style`.

      <.scroll_area style="max-height:16rem">...</.scroll_area>
      <.scroll_area focusable label="Release notes" style="max-height:16rem">...</.scroll_area>

  `stick_bottom` keeps a list that grows at its end (a chat) scrolled to its last item, unless the
  reader scrolled up: it mounts the `LedgerUI.ScrollBottom` hook (needs a stable `id`).

  ## `variant`

    * `"plain"` (default): the bare scrolling box.
    * `"panel"`: the canvas card that scrolls: border, background and radius of a panel.
    * `"preview"`: the canvas picture of a scroll area: a frame that clips the content and
      draws the scrollbar thumb (vertical or horizontal, animated) according to `orientation`;
      `scrollbar` `hover` fades the thumb out and `hidden` takes it away. The content is
      whatever the slot holds (the canvas wraps it in an animated `animate-[mo-scroll_…]` /
      `animate-[mo-scrollx_…]`). For the documentation and the showcase only.
  """
  use LedgerUI.Component

  @overflow %{
    "vertical" => "overflow-y-auto overflow-x-hidden",
    "horizontal" => "overflow-x-auto overflow-y-hidden",
    "both" => "overflow-auto"
  }
  @bars %{
    "hover" => "[scrollbar-width:thin] [scrollbar-color:var(--lu-line-strong)_transparent]",
    "always" => "[scrollbar-width:thin] [scrollbar-color:var(--lu-line-strong)_transparent]",
    "hidden" => "[scrollbar-width:none]"
  }
  @frame "relative overflow-hidden rounded-[12px] border border-line bg-panel"
  @thumb "absolute rounded-[3px] bg-line-strong"

  attr :variant, :string, default: "plain", values: ~w(plain panel preview)
  attr :orientation, :string, default: "vertical", values: ~w(both horizontal vertical)
  attr :scrollbar, :string, default: "hover", values: ~w(always hidden hover)
  attr :focusable, :boolean, default: false
  attr :label, :string, default: nil
  attr :id, :string, default: nil
  attr :stick_bottom, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def scroll_area(%{variant: "preview"} = assigns) do
    assigns =
      assign(assigns,
        classes: cx([@frame, assigns.class]),
        thumb_base: @thumb,
        thumb:
          cx([
            assigns.scrollbar == "hover" && "opacity-0",
            assigns.scrollbar == "hidden" && "hidden"
          ]),
        bar?: assigns.orientation in ["vertical", "both"],
        barx?: assigns.orientation in ["horizontal", "both"]
      )

    ~H"""
    <div id={@id} data-part="scroll-area" class={@classes} {@rest}>
      {render_slot(@inner_block)}
      <span
        :if={@bar?}
        data-part="scroll-area-bar"
        class={[
          @thumb_base,
          "right-[3px] top-1.5 h-[40%] w-[5px] animate-[mo-sabar_8s_ease-in-out_infinite]",
          @thumb
        ]}
      ></span><span
        :if={@barx?}
        data-part="scroll-area-bar-x"
        class={[
          @thumb_base,
          "bottom-[3px] left-1.5 h-[5px] w-[40%] animate-[mo-sabarx_8s_ease-in-out_infinite]",
          @thumb
        ]}
      ></span>
    </div>
    """
  end

  def scroll_area(assigns) do
    if assigns.stick_bottom and is_nil(assigns.id),
      do: raise(ArgumentError, "scroll_area with stick_bottom needs a stable id")

    assigns =
      assigns
      |> assign(:plain?, assigns.variant == "plain")
      |> assign(:hook, if(assigns.stick_bottom, do: "LedgerUI.ScrollBottom"))
      |> assign(:tabindex, if(assigns.focusable, do: "0"))
      |> assign(:role, if(assigns.focusable && assigns.label, do: "region"))
      |> assign(:aria_label, if(assigns.focusable, do: assigns.label))
      |> assign(
        :classes,
        cx([
          assigns.variant == "panel" && "rounded-lg border border-line bg-panel",
          @overflow[assigns.orientation],
          @bars[assigns.scrollbar],
          assigns.class
        ])
      )

    ~H"""
    <div
      id={@id}
      data-part="scroll-area"
      data-scrollbar={@plain? && @scrollbar}
      data-orientation={@plain? && @orientation}
      phx-hook={@hook}
      tabindex={@tabindex}
      role={@role}
      aria-label={@aria_label}
      class={@classes}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
