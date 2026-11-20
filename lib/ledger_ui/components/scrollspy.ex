defmodule LedgerUI.Components.Scrollspy do
  @moduledoc """
  A list of links to the sections of the page that marks the section in view.

      <.scrollspy id="settings-nav" offset={96}>
        <:item href="#profile">Profile</:item>
        <:item href="#security">Security</:item>
      </.scrollspy>

  The hook `LedgerUI.Scrollspy` (`priv/static/ledger_ui/hooks/scrollspy.js`) watches the elements
  the links point at and moves `aria-current="true"` (and the class `on`) to the link of the
  section at the top of the view (`offset` pixels from the top, 120 by default). A click scrolls
  to the section smoothly (instantly with `prefers-reduced-motion`).

  The server renders `aria-current="true"` on an item whose `class` includes `on` (the initial
  state); the hook only updates it as the page scrolls.

  The root is a `<nav>` (the design's `lu-spy nav`); wrap it in a `lu-spy` grid yourself.
  `label: nil` omits the `aria-label`.
  """
  use LedgerUI.Component

  attr :id, :string, required: true
  attr :label, :any, default: "On this page"
  attr :offset, :integer, default: 120
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :href, :string
    attr :class, :any
    attr :style, :string
    attr :id, :string
  end

  def scrollspy(assigns) do
    assigns = assign(assigns, :offset_attr, if(assigns.offset != 120, do: assigns.offset))

    ~H"""
    <nav
      id={@id}
      class={@class}
      aria-label={@label}
      phx-hook="LedgerUI.Scrollspy"
      data-offset={@offset_attr}
      {@rest}
    >
      <a :for={item <- @item} {item_attrs(item)}>{render_slot(item)}</a>
    </nav>
    """
  end

  defp item_attrs(item) do
    attrs = Map.drop(item, [:__slot__, :inner_block])

    if on?(attrs[:class]), do: Map.put_new(attrs, :"aria-current", "true"), else: attrs
  end

  defp on?(class) when is_binary(class), do: "on" in String.split(class)
  defp on?(_), do: false
end
