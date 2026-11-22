defmodule LedgerUI.Components.ContextMenu do
  @moduledoc """
  A menu that opens under the pointer on a right click.

      <.context_menu id="file-menu">
        <.card variant="panel">Right click here</.card>
        <:item phx-click="rename" icon="edit" kbd="F2">Rename</:item>
        <:item phx-click="copy">Copy</:item>
        <:item phx-click="delete" tone="danger" divider icon="trash">Delete</:item>
      </.context_menu>

  The hook `LedgerUI.ContextMenu` (`priv/static/ledger_ui/hooks/context_menu.js`) opens the menu
  at the pointer (kept inside the window, in the top layer), moves the focus to the first item
  and closes it on a click outside, `Escape`, a scroll and when an item is chosen. The arrows,
  `Home`, `End` and letters move between the items.

  Styled only with Tailwind utilities (the popup parts are those of
  `LedgerUI.Components.Dropdown`); every element carries `data-part` (`context-menu`, `pop`,
  `pop-item`, `pop-separator`, `pop-end`, `pop-kbd`).

  Besides the README attrs the `:item` slot takes `icon` (a name) and `kbd` (a shortcut shown
  as text).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Dropdown

  attr :id, :string, required: true
  attr :label, :string, default: nil, doc: "Accessible name of the menu."
  attr :class, :any, default: nil

  attr :placement, :string,
    default: "bottom-start",
    values: ~w(bottom-start bottom-end top-start top-end),
    doc:
      "Where the menu sits against the pointer (`bottom-start`: below, from the pointer to the right)."

  attr :rest, :global

  slot :inner_block, required: true, doc: "The area that answers to the right click."

  slot :trigger,
    doc:
      "The area that answers to the right click, in place of the inner block (the vitrine's form)."

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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def context_menu(assigns) do
    assigns = I18n.texts(assigns, label: "context_menu.actions")

    assigns =
      assigns
      |> assign(:items, Enum.map(assigns.item, &prepare/1))
      |> assign(:box_class, Dropdown.pop_classes())
      |> assign(:sep_class, Dropdown.separator_classes())
      |> assign(:end_cls, Dropdown.item_end_classes())
      |> assign(:kbd_cls, Dropdown.kbd_classes())

    ~H"""
    <div
      id={@id}
      data-part="context-menu"
      class={@class}
      phx-hook="LedgerUI.ContextMenu"
      data-placement={@placement != "bottom-start" && @placement}
      {@rest}
    >
      <%= if @trigger != [] do %>
        {render_slot(@trigger)}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
      <div
        id={@id <> "-menu"}
        data-part="pop"
        class={@box_class}
        role="menu"
        aria-label={@label}
        popover="manual"
        keep-popover
        keep-style
        keep-hidden
      >
        <%= for item <- @items do %>
          <div :if={item.divider} data-part="pop-separator" class={@sep_class} role="separator"></div>
          <button
            data-part="pop-item"
            class={item.class}
            role="menuitem"
            type="button"
            aria-disabled={item.disabled && "true"}
            {item.rest}
          >
            <.icon :if={item.icon} name={item.icon} />
            {render_slot(item)}<span :if={item.kbd} data-part="pop-end" class={@end_cls}><kbd
              data-part="pop-kbd"
              class={@kbd_cls}
            >{item.kbd}</kbd></span>
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
      class: Dropdown.item_classes(tone: if(item[:tone] == "danger", do: "danger")),
      rest: rest,
      __slot__: item.__slot__,
      inner_block: item.inner_block
    }
  end
end
