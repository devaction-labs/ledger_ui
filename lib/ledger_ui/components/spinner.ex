defmodule LedgerUI.Components.Spinner do
  @moduledoc """
  Short loading indicator: five designs, five sizes and the system colours.

      <.spinner color="primary" variant="soft" size="md" label="Saving" />

  With a `label` (default `"Loading"`) it is `role="status"` and `aria-label`led; pass
  `label={nil}` for a purely decorative one. `white` and `current` (the surrounding text colour)
  are for spinners inside filled buttons.
  """
  use LedgerUI.Component

  @elastic "animation-timing-function:cubic-bezier(.68,-.55,.27,1.55)"
  @svg ~s(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 3a9 9 0 1 1-9 9"/></svg>)

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white current)

  attr :variant, :string, default: "canvas", values: ~w(canvas border soft grow svg)
  attr :size, :string, default: "sm", values: ~w(xs sm md lg xl)
  attr :elastic, :boolean, default: false
  attr :label, :any, default: "Loading", doc: "Accessible name; `nil` for a decorative spinner."
  attr :class, :any, default: nil
  attr :rest, :global

  def spinner(assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-sp",
          color_class(assigns.color),
          "v-" <> assigns.variant,
          "s-" <> assigns.size,
          assigns.class
        ])
      )
      |> assign(:attrs, attrs(assigns))
      |> assign(:svg, if(assigns.variant == "svg", do: {:safe, @svg}))

    ~H"""
    <span data-part="spinner" class={@classes} {@attrs}>{@svg}</span>
    """
  end

  defp color_class(c) when c in ["white", "current"], do: nil
  defp color_class(c), do: "c-" <> c

  defp attrs(a) do
    style =
      [
        a.color == "white" && "--c:#fff;border-color:#fff;border-right-color:transparent",
        a.color == "current" && "--c:currentColor",
        a.elastic && @elastic,
        a.rest[:style]
      ]
      |> Enum.filter(& &1)
      |> Enum.join(";")

    rest = if style == "", do: a.rest, else: Map.put(a.rest, :style, style)

    if a.label,
      do: Map.merge(rest, %{:role => "status", :"aria-label" => a.label}),
      else: rest
  end
end
