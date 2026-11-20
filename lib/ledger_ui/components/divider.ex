defmodule LedgerUI.Components.Divider do
  @moduledoc """
  A 1px separator in the `line` colour, horizontal or vertical, with optional centred or
  left-aligned text.

      <.divider />
      <.divider>ou continue com</.divider>
      <.divider align="left">Entrega</.divider>
      <div class="lu-row"><span>Day</span><.divider orientation="vertical" /><span>Month</span></div>

  A horizontal divider without text is an `<hr class="lu-sep">`. With text it is a row of two
  lines around the text (`align="center"`) or the text followed by one line (`align="left"`),
  the text being a small uppercase label. A vertical divider is a 1px column, 18px high unless
  you pass `style="height:40px"` (or a class).
  """
  use LedgerUI.Component

  @label_style "letter-spacing:.06em;text-transform:uppercase"
  @vline "width:1px;height:18px;background:var(--line)"
  @vline_free "width:1px;background:var(--line)"

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

  defp render_divider(%{orientation: "vertical", inner_block: []} = assigns) do
    assigns =
      assigns
      |> assign(:rest, with_style(assigns.rest, vline_style(assigns.style)))
      |> assign(:class_s, classes(assigns.class))

    ~H"""
    <span
      data-part="divider"
      class={@class_s}
      role="separator"
      aria-orientation="vertical"
      {@rest}
    ></span>
    """
  end

  defp render_divider(%{orientation: "vertical"} = assigns) do
    assigns =
      assigns
      |> assign(:class_s, classes(["lu-col", assigns.class]))
      |> assign(:label_style, @label_style)
      |> assign(
        :rest,
        with_style(assigns.rest, join_style("align-items:center;gap:10px", assigns.style))
      )

    ~H"""
    <div data-part="divider" class={@class_s} {@rest}>
      <span style="width:1px;flex:1;background:var(--line)"></span>
      <span class="lu-xs lu-muted" style={@label_style}>{render_slot(@inner_block)}</span>
      <span style="width:1px;flex:1;background:var(--line)"></span>
    </div>
    """
  end

  defp render_divider(%{inner_block: []} = assigns) do
    assigns =
      assigns
      |> assign(:class_s, classes(["lu-sep", assigns.class]))
      |> assign(:rest, with_style(assigns.rest, assigns.style))

    ~H|<hr data-part="divider" class={@class_s} {@rest} />|
  end

  defp render_divider(%{align: "left"} = assigns) do
    assigns =
      assigns
      |> assign(:class_s, classes(["lu-row", assigns.class]))
      |> assign(:rest, with_style(assigns.rest, join_style("gap:12px", assigns.style)))
      |> assign(:label_style, @label_style)

    ~H"""
    <div data-part="divider" class={@class_s} {@rest}>
      <span class="lu-xs lu-muted" style={@label_style}>{render_slot(@inner_block)}</span><hr class="lu-sep lu-grow" />
    </div>
    """
  end

  defp render_divider(assigns) do
    assigns =
      assigns
      |> assign(:class_s, classes(["lu-row", assigns.class]))
      |> assign(:rest, with_style(assigns.rest, join_style("gap:12px", assigns.style)))
      |> assign(:label_style, @label_style)

    ~H"""
    <div data-part="divider" class={@class_s} {@rest}>
      <hr class="lu-sep lu-grow" /><span class="lu-xs lu-muted" style={@label_style}>{render_slot(
        @inner_block
      )}</span><hr class="lu-sep lu-grow" />
    </div>
    """
  end

  # The user's own `height` replaces the 18px default.
  defp vline_style(nil), do: @vline

  defp vline_style(extra) do
    if String.contains?(extra, "height"),
      do: join_style(@vline_free, extra),
      else: join_style(@vline, extra)
  end

  defp join_style(base, nil), do: base
  defp join_style(base, extra), do: base <> ";" <> extra

  defp classes(list) do
    case cx(list) do
      "" -> nil
      s -> s
    end
  end
end
