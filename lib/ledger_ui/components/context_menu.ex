defmodule LedgerUI.Components.ContextMenu do
  @moduledoc """
  A menu that opens under the pointer on a right click.

      <.context_menu id="file-menu">
        <div class="lu-panel">Right click here</div>
        <:item phx-click="rename" icon="edit" kbd="F2">Rename</:item>
        <:item phx-click="copy">Copy</:item>
        <:item phx-click="delete" tone="danger" divider icon="trash">Delete</:item>
      </.context_menu>

  The hook `LedgerUI.ContextMenu` (`priv/static/ledger_ui/hooks/context_menu.js`) opens the menu
  at the pointer (kept inside the window, in the top layer), moves the focus to the first item
  and closes it on a click outside, `Escape`, a scroll and when an item is chosen. The arrows,
  `Home`, `End` and letters move between the items.

  Besides the README attrs the `:item` slot takes `icon` (a name) and `kbd` (a shortcut shown
  as text).
  """
  use LedgerUI.Component

  attr :id, :string, required: true
  attr :label, :string, default: "Actions", doc: "Accessible name of the menu."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true, doc: "The area that answers to the right click."

  slot :item do
    attr :tone, :string
    attr :divider, :boolean
    attr :disabled, :boolean
    attr :icon, :string
    attr :kbd, :string
    attr :"phx-click", :any
    attr :"phx-value-id", :any
    attr :"phx-target", :any
  end

  def context_menu(assigns) do
    assigns = assign(assigns, :items, Enum.map(assigns.item, &prepare/1))

    ~H"""
    <div id={@id} class={@class} phx-hook="LedgerUI.ContextMenu" {@rest}>
      {render_slot(@inner_block)}
      <div
        id={@id <> "-menu"}
        class="lu-pop"
        role="menu"
        aria-label={@label}
        popover="manual"
        keep-popover
        keep-style
        keep-hidden
      >
        <%= for item <- @items do %>
          <div :if={item.divider} class="lu-menu-sep" role="separator"></div>
          <button
            class={item.class}
            role="menuitem"
            type="button"
            aria-disabled={item.disabled && "true"}
            {item.rest}
          >
            <.icon :if={item.icon} name={item.icon} />
            {render_slot(item)}<span :if={item.kbd} class="r"><kbd class="lu-kbd">{item.kbd}</kbd></span>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  defp prepare(item) do
    rest = Map.drop(item, [:__slot__, :inner_block, :tone, :divider, :disabled, :icon, :kbd])

    %{
      divider: item[:divider] == true,
      disabled: item[:disabled] == true,
      icon: item[:icon],
      kbd: item[:kbd],
      class: cx(["lu-menu-item", item[:tone] == "danger" && "danger"]),
      rest: rest,
      __slot__: item.__slot__,
      inner_block: item.inner_block
    }
  end
end
