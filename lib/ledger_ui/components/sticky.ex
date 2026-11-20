defmodule LedgerUI.Components.Sticky do
  @moduledoc """
  A block that sticks to the top of the page and takes classes while the page is scrolled: a header
  that gets an edge, a bar that gets a shadow.

      <.sticky id="page-bar" stuck_class="shadow-md">...</.sticky>

  The hook `LedgerUI.Sticky` (`priv/static/ledger_ui/hooks/sticky.js`) adds `stuck_class` and sets
  `data-stuck` once the page is scrolled past `offset` pixels, and takes them off when it is back.
  The block is `position: sticky; top: 0`.

  ## Preview

  `preview` draws the canvas picture of the behavior: a frame (`lu-sticky`) with the `:header` slot on a
  translucent bar and the content scrolling under it (`body_class` / `body_style` go to the content, for
  the scrolling animation). No hook. For the documentation and the showcase only.

      <.sticky id="demo" preview body_class="mo-scroll" body_style="--sy:-160px">
        <:header>Orders today</:header>
        <i style="width:90%"></i>
      </.sticky>
  """
  use LedgerUI.Component

  attr :id, :string, required: true

  attr :offset, :integer,
    default: 0,
    doc: "Pixels the page scrolls before the block counts as stuck."

  attr :stuck_class, :string,
    default: nil,
    doc: "Classes added while stuck. Without it the hook draws a 1px bottom line."

  attr :preview, :boolean, default: false, doc: "The canvas picture of a sticky header."
  attr :body_class, :string, default: nil, doc: "With `preview`: extra classes of the content."
  attr :body_style, :string, default: nil, doc: "With `preview`: the style of the content."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :header, doc: "With `preview`: the content of the bar."

  def sticky(%{preview: true} = assigns) do
    ~H"""
    <div id={@id} data-part="sticky" class={cx(["lu-sticky", @class])} {@rest}>
      <div class="hd">{render_slot(@header)}</div>
      <div class={cx(["body", @body_class])} style={@body_style}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  def sticky(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="LedgerUI.Sticky"
      data-part="sticky"
      data-offset={@offset}
      data-stuck-class={@stuck_class}
      class={cx(["lu-sticky-bar", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
