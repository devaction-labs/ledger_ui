defmodule LedgerUI.Components.Sticky do
  @moduledoc """
  A block that sticks to the top of the page and takes classes while the page is scrolled: a header
  that gets an edge, a bar that gets a shadow.

      <.sticky id="page-bar" stuck_class="shadow-md">...</.sticky>

  The hook `LedgerUI.Sticky` (`priv/static/ledger_ui/hooks/sticky.js`) adds `stuck_class` and sets
  `data-stuck` once the page is scrolled past `offset` pixels, and takes them off when it is back.
  The block is `position: sticky; top: 0`.
  """
  use LedgerUI.Component

  attr :id, :string, required: true

  attr :offset, :integer,
    default: 0,
    doc: "Pixels the page scrolls before the block counts as stuck."

  attr :stuck_class, :string,
    default: nil,
    doc: "Classes added while stuck. Without it the hook draws a 1px bottom line."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sticky(assigns) do
    assigns = assign(assigns, :style, sticky_style(assigns.rest))

    ~H"""
    <div
      id={@id}
      phx-hook="LedgerUI.Sticky"
      data-part="sticky"
      data-offset={@offset}
      data-stuck-class={@stuck_class}
      class={cx(["lu-sticky-bar", @class])}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @base "position:sticky;top:0;z-index:20;background:var(--bg-page)"
  defp sticky_style(%{style: s}) when is_binary(s) and s != "", do: @base <> ";" <> s
  defp sticky_style(_), do: @base

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
