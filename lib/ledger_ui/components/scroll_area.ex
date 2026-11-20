defmodule LedgerUI.Components.ScrollArea do
  @moduledoc """
  A box that scrolls with a thin scrollbar (6px, transparent track). For long menus, lists in a
  card, the body of a panel. The height comes from `class` or an inline `style`.

      <.scroll_area style="max-height:16rem">...</.scroll_area>
      <.scroll_area focusable label="Release notes" style="max-height:16rem">...</.scroll_area>

  `stick_bottom` keeps a list that grows at its end (a chat) scrolled to its last item, unless the
  reader scrolled up: it mounts the `LedgerUI.ScrollBottom` hook (needs a stable `id`).

  ## `variant`

    * `"plain"` (default): the bare scrolling box (`lu-scroll-area`).
    * `"panel"`: the canvas card (`lu-panel`) that scrolls: border, background and radius of a panel.
    * `"preview"`: the canvas picture of a scroll area (`lu-sa`): a frame that clips the content and
      draws the scrollbar thumb (`bar` for vertical, `barx` for horizontal, animated) according to
      `orientation`; `scrollbar` `hover` / `hidden` add the class of the same name. The content is
      whatever the slot holds (the canvas wraps it in an animated `mo-scroll` / `mo-scrollx`). For the
      documentation and the showcase only.
  """
  use LedgerUI.Component

  @overflow %{
    "vertical" => "overflow-y:auto;overflow-x:hidden",
    "horizontal" => "overflow-x:auto;overflow-y:hidden",
    "both" => "overflow:auto"
  }
  @bars %{
    "hover" => "scrollbar-width:thin;scrollbar-color:var(--line-strong) transparent",
    "always" => "scrollbar-width:thin;scrollbar-color:var(--line-strong) transparent",
    "hidden" => "scrollbar-width:none"
  }

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
        classes:
          cx([
            "lu-sa",
            assigns.scrollbar in ["hover", "hidden"] && assigns.scrollbar,
            assigns.class
          ]),
        bar?: assigns.orientation in ["vertical", "both"],
        barx?: assigns.orientation in ["horizontal", "both"]
      )

    ~H"""
    <div id={@id} data-part="scroll-area" class={@classes} {@rest}>
      {render_slot(@inner_block)}
      <span :if={@bar?} class="bar mo"></span><span :if={@barx?} class="barx mo"></span>
    </div>
    """
  end

  def scroll_area(assigns) do
    if assigns.stick_bottom and is_nil(assigns.id),
      do: raise(ArgumentError, "scroll_area with stick_bottom needs a stable id")

    assigns =
      assigns
      |> assign(:style, style(assigns))
      |> assign(:plain?, assigns.variant == "plain")
      |> assign(:hook, if(assigns.stick_bottom, do: "LedgerUI.ScrollBottom"))
      |> assign(:tabindex, if(assigns.focusable, do: "0"))
      |> assign(:role, if(assigns.focusable && assigns.label, do: "region"))
      |> assign(:aria_label, if(assigns.focusable, do: assigns.label))

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
      class={cx([@variant == "panel" && "lu-panel", @variant == "plain" && "lu-scroll-area", @class])}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # The plain variant is styled by the stylesheet (`lu-scroll-area`, `data-orientation`,
  # `data-scrollbar`); the panel carries the canvas inline style.
  defp style(%{variant: "panel"} = a) do
    base = @overflow[a.orientation] <> ";" <> @bars[a.scrollbar]

    case a.rest do
      %{style: s} when is_binary(s) and s != "" -> base <> ";" <> s
      _ -> base
    end
  end

  defp style(a), do: a.rest[:style]

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
