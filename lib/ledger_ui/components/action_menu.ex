defmodule LedgerUI.Components.ActionMenu do
  @moduledoc """
  The actions of one item (a table row, a card), opened by a "⋯" button, and `action_button/1`,
  the direct button for an item with a single action.

      <.action_menu id={"actions-" <> c.id} label={"Actions of " <> c.name}>
        <:title>{c.name}</:title>
        <.action_menu_item navigate={~p"/companies/\#{c.id}"} icon="huge-view" kbd="↵">Open</.action_menu_item>
        <.action_menu_separator />
        <.action_menu_item phx-click="delete" phx-value-id={c.id} icon="huge-delete-02" danger>
          Delete
        </.action_menu_item>
      </.action_menu>

      <.action_button label="Delete" icon="huge-delete-02" danger phx-click="delete" />

  Styled only with Tailwind utilities (the popup parts are those of `LedgerUI.Components.Dropdown`);
  every element carries `data-part` (`action-menu`, `action-menu-trigger`, `action-menu-panel`,
  `pop`, `pop-item`, `pop-label`, `pop-separator`, `pop-end`, `pop-kbd`).

  The server renders the ARIA (`aria-haspopup`/`aria-expanded`/`aria-controls` on the button,
  `popover="manual"`, `role="menu"`/`menuitem`/`separator`); the hook only flips `aria-expanded`.
  The menu uses the Dropdown machinery through the hook `LedgerUI.ActionMenu`
  (`priv/static/ledger_ui/hooks/action_menu.js`, the Dropdown hook plus the row marking): top
  layer, flips, follows scrolling, Esc/Tab/click outside, arrows, Home/End and letters.
  While it is open the hook sets `data-am-open` on the nearest `[data-am-row]`, `tr` or
  `.ledger-ctable-row` and tints it.

  `action_button/1` is a `button/1`-looking icon button (`danger` makes it the `error` colour).

  `demo="click"`/`"loop"` draws the menu open, animated, with no top layer (see
  `LedgerUI.Components.Dropdown`); `highlight` walks a highlight over the items.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Button
  alias LedgerUI.Components.Dropdown

  @placements ~w(bottom-start bottom-end top-start top-end)
  @variants ~w(solid glow outline soft bordered flat glass ghost dim)
  @sizes ~w(xs sm md lg xl)

  # ---------------------------------------------------------------------------------------
  # action_menu

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "Accessible name of the button."
  attr :placement, :string, default: "bottom-end", values: @placements
  attr :class, :any, default: nil, doc: "Merged into the menu box."
  attr :menu_style, :string, default: nil, doc: "Inline style of the menu box."
  attr :anchor_class, :any, default: nil, doc: "Extra classes of the root."

  attr :demo, :string,
    default: nil,
    values: [nil, "click", "loop"],
    doc: "The animated demo: the menu is drawn open under the button, no top layer."

  attr :highlight, :boolean,
    default: false,
    doc: "Walks a highlight over the items (set `style=\"--dl:1s\"` on each for the stagger)."

  attr :rest, :global
  slot :inner_block, required: true
  slot :title
  slot :trigger, doc: "What the button shows, in place of the \"⋯\" icon."
  slot :overlay, doc: "Extra content after the menu inside the anchor (a demo cursor)."

  def action_menu(assigns) do
    assigns =
      assigns
      |> assign(
        :root_class,
        cx([
          "relative inline-flex",
          assigns.demo == "click" && "[&>button]:animate-[lu-presso_4s_infinite]",
          assigns.anchor_class
        ])
      )
      |> assign(:trigger_class, Button.classes("neutral", "ghost", "md", "rounded"))
      |> assign(:panel_class, panel_class(assigns))
      |> assign(
        :box_class,
        cx([Dropdown.pop_classes(highlight: assigns.highlight), assigns.class])
      )
      |> assign(:box_attrs, if(assigns.menu_style, do: %{style: assigns.menu_style}, else: %{}))
      |> assign(:label_class, Dropdown.label_classes())
      |> assign(:popover, if(!assigns.demo, do: "manual"))

    ~H"""
    <span
      id={@id}
      data-part="action-menu"
      data-lu-demo={@demo}
      class={@root_class}
      phx-hook="LedgerUI.ActionMenu"
      {@rest}
    >
      <button
        data-part="action-menu-trigger"
        aria-label={@label}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={@id <> "-menu"}
        class={@trigger_class}
        type="button"
      >
        <%= if @trigger != [] do %>
          {render_slot(@trigger)}
        <% else %>
          <.icon name="more-h" size="md" />
        <% end %>
      </button>
      <span
        id={@id <> "-menu"}
        data-part="action-menu-panel"
        data-lu-placement={@placement}
        class={@panel_class}
        popover={@popover}
        keep-popover
        keep-style
        keep-hidden
      >
        <div data-part="pop" class={@box_class} role="menu" {@box_attrs}>
          <div :if={@title != []} data-part="pop-label" class={@label_class} role="presentation">
            {render_slot(@title)}
          </div>
          {render_slot(@inner_block)}
        </div>
      </span>
      {render_slot(@overlay)}
    </span>
    """
  end

  # the demo menu is placed by the stylesheet, the real one by the hook (inline styles)
  @demo_place %{
    "bottom-start" => "top-[calc(100%+8px)] left-0",
    "bottom-end" => "top-[calc(100%+8px)] right-0",
    "top-start" => "bottom-[calc(100%+8px)] left-0",
    "top-end" => "bottom-[calc(100%+8px)] right-0"
  }

  defp panel_class(a) do
    case a.demo do
      "click" ->
        [
          "absolute z-[4] whitespace-nowrap animate-[lu-flin2_4s_ease-out_infinite]",
          @demo_place[a.placement]
        ]

      "loop" ->
        [
          "absolute z-[4] whitespace-nowrap animate-[lu-flin_4s_ease-out_infinite]",
          @demo_place[a.placement]
        ]

      _ ->
        "whitespace-nowrap"
    end
  end

  # ---------------------------------------------------------------------------------------
  # action_menu_item

  attr :icon, :string, default: nil
  attr :kbd, :string, default: nil
  attr :hint, :string, default: nil
  attr :danger, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :type, :string, default: "button"
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(href navigate patch method replace download target rel hreflang referrerpolicy form name value)

  slot :inner_block, required: true

  def action_menu_item(assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        Dropdown.item_classes(
          tone: if(assigns.danger, do: "danger"),
          media: assigns.hint != nil,
          class: assigns.class
        )
      )
      |> assign(:link?, Dropdown.link?(assigns.rest))
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))

    ~H"""
    <.link
      :if={@link?}
      data-part="pop-item"
      class={@classes}
      role="menuitem"
      aria-disabled={@aria_disabled}
      {@rest}
    >
      <.item_body icon={@icon} kbd={@kbd} hint={@hint}>{render_slot(@inner_block)}</.item_body>
    </.link>
    <button
      :if={!@link?}
      data-part="pop-item"
      class={@classes}
      role="menuitem"
      type={@type}
      aria-disabled={@aria_disabled}
      {@rest}
    >
      <.item_body icon={@icon} kbd={@kbd} hint={@hint}>{render_slot(@inner_block)}</.item_body>
    </button>
    """
  end

  attr :icon, :string, default: nil
  attr :kbd, :string, default: nil
  attr :hint, :string, default: nil
  slot :inner_block, required: true

  defp item_body(assigns) do
    assigns =
      assign(assigns, end_cls: Dropdown.item_end_classes(), kbd_cls: Dropdown.kbd_classes())

    ~H"""
    <.icon :if={@icon} name={@icon} />
    <span :if={@hint} data-part="pop-item-text" class="flex flex-col leading-[17px]">{render_slot(
      @inner_block
    )}<small data-part="pop-item-hint" class="text-[12px] text-muted">{@hint}</small></span>
    <%= if !@hint do %>
      {render_slot(@inner_block)}
    <% end %>
    <span :if={@kbd} data-part="pop-end" class={@end_cls}><kbd data-part="pop-kbd" class={@kbd_cls}>{@kbd}</kbd></span>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  def action_menu_separator(assigns) do
    assigns = assign(assigns, :classes, [Dropdown.separator_classes(), assigns.class])

    ~H"""
    <div data-part="pop-separator" class={@classes} role="separator" {@rest}></div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # action_button

  attr :label, :string, required: true, doc: "Accessible name (`aria-label`)."
  attr :icon, :string, default: nil
  attr :danger, :boolean, default: false
  attr :variant, :string, default: "outline", values: @variants
  attr :size, :string, default: "sm", values: @sizes
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download target rel form name value disabled type)

  slot :inner_block

  def action_button(assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        [
          Button.classes(
            if(assigns.danger, do: "error", else: "neutral"),
            assigns.variant,
            assigns.size,
            if(assigns.inner_block == [], do: "square", else: "rounded")
          ),
          assigns.class
        ]
      )
      |> assign(:link?, Enum.any?([:href, :navigate, :patch], &Map.get(assigns.rest, &1)))

    ~H"""
    <.link :if={@link?} data-part="action-button" aria-label={@label} class={@classes} {@rest}>
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
    </.link>
    <button
      :if={!@link?}
      data-part="action-button"
      aria-label={@label}
      class={@classes}
      type="button"
      {@rest}
    >
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
    </button>
    """
  end
end
