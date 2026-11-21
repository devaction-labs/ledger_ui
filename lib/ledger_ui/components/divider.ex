defmodule LedgerUI.Components.Divider do
  @moduledoc """
  A 1px separator in the `line` colour, horizontal or vertical, with optional centred or
  left-aligned text.

      <.divider />
      <.divider>ou continue com</.divider>
      <.divider align="left">Entrega</.divider>
      <div class="flex items-center gap-2.5"><span>Day</span><.divider orientation="vertical" /><span>Month</span></div>

  A horizontal divider without text is an `<hr>` 1px high in the `line` colour. With text it is a
  row of two lines around the text (`align="center"`) or the text followed by one line
  (`align="left"`), the text being a small uppercase label. A vertical divider is a 1px column,
  18px high unless you pass `style="height:40px"` or an `h-*` class. Styled only with Tailwind
  utilities.
  """
  use LedgerUI.Component

  @label_utilities "text-xs text-muted tracking-[.06em] uppercase"

  # `style={nil}` would render `style=""`: the style goes in the attribute map instead.
  defp with_style(rest, nil), do: rest
  defp with_style(rest, style), do: Map.put(rest, :style, style)

  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)

  attr :align, :string,
    default: "center",
    values: ~w(center left),
    doc: "Where a horizontal divider's text sits."

  attr :label, :string, default: nil, doc: "The text, as an attribute instead of the inner block."
  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def divider(%{label: label, inner_block: []} = assigns) when is_binary(label),
    do:
      render_divider(%{
        assigns
        | inner_block: [%{__slot__: :inner_block, inner_block: fn _, _ -> label end}]
      })

  def divider(assigns), do: render_divider(assigns)

  # `rest` carries the caller's `style`; the label utilities are shared by every layout.
  defp render_divider(assigns) do
    assigns
    |> assign(:rest, with_style(assigns.rest, assigns.style))
    |> assign(:label_class, @label_utilities)
    |> layout()
  end

  defp layout(%{orientation: "vertical", inner_block: []} = assigns) do
    assigns = assign(assigns, :height, if(own_height?(assigns), do: nil, else: "h-[18px]"))

    ~H"""
    <span
      data-part="divider"
      class={["w-px bg-line", @height, @class]}
      role="separator"
      aria-orientation="vertical"
      {@rest}
    ></span>
    """
  end

  defp layout(%{orientation: "vertical"} = assigns) do
    ~H"""
    <div data-part="divider" class={["flex flex-col items-center gap-2.5", @class]} {@rest}>
      <span data-part="divider-line" class="w-px flex-1 bg-line"></span>
      <span data-part="divider-label" class={@label_class}>{render_slot(@inner_block)}</span>
      <span data-part="divider-line" class="w-px flex-1 bg-line"></span>
    </div>
    """
  end

  defp layout(%{inner_block: []} = assigns) do
    ~H|<hr data-part="divider" class={["m-0 h-px border-0 bg-line", @class]} {@rest} />|
  end

  defp layout(%{align: "left"} = assigns) do
    ~H"""
    <div data-part="divider" class={["flex flex-wrap items-center gap-3", @class]} {@rest}>
      <span data-part="divider-label" class={@label_class}>{render_slot(@inner_block)}</span><hr
        data-part="divider-line"
        class="m-0 h-px min-w-0 flex-1 border-0 bg-line"
      />
    </div>
    """
  end

  defp layout(assigns) do
    ~H"""
    <div data-part="divider" class={["flex flex-wrap items-center gap-3", @class]} {@rest}>
      <hr data-part="divider-line" class="m-0 h-px min-w-0 flex-1 border-0 bg-line" /><span
        data-part="divider-label"
        class={@label_class}
      >{render_slot(@inner_block)}</span><hr
        data-part="divider-line"
        class="m-0 h-px min-w-0 flex-1 border-0 bg-line"
      />
    </div>
    """
  end

  # The user's own `height` (style or `h-*` class) replaces the 18px default.
  defp own_height?(%{style: style, class: class}) do
    String.contains?(style || "", "height") or Regex.match?(~r/(^|[\s:])h-/, cx([class]))
  end
end
