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

  **Deprecated aliases.** `action_menu/1`, `action_menu_item/1` and `action_menu_separator/1` are thin
  wrappers of `LedgerUI.Components.Dropdown.dropdown/1` (`part="action-menu"`, `trigger_style="ghost"`,
  the `:title` slot), `dropdown_item/1` (`kbd`, `description`, `two_line`) and `dropdown_separator/1`,
  with the same HTML as before. Prefer the dropdown API in new code:

      <.dropdown id="actions-1" label="Actions" part="action-menu" trigger_style="ghost" row_mark
        placement="bottom-end">...</.dropdown>

  The server renders the ARIA (`aria-haspopup`/`aria-expanded`/`aria-controls` on the button,
  `popover="manual"`, `role="menu"`/`menuitem`/`separator`); the hook only flips `aria-expanded`.
  The menu uses the Dropdown machinery through the hook `LedgerUI.ActionMenu`
  (`priv/static/ledger_ui/hooks/action_menu.js`, now just the Dropdown hook with `rowMark: true`,
  kept so apps that registered it keep working): top layer, flips, follows scrolling,
  Esc/Tab/click outside, arrows, Home/End and letters. While it is open the hook sets
  `data-am-open` on the nearest `[data-am-row]`, `tr` or `.ledger-ctable-row` and tints it; the
  plain Dropdown hook does the same for a `dropdown` with `row_mark`.

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
  # action_menu (deprecated: a thin alias of `dropdown/1`)

  @doc deprecated:
         "Use `dropdown/1` with `part=\"action-menu\"` `trigger_style=\"ghost\"` `row_mark`."
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
    ~H"""
    <Dropdown.dropdown
      id={@id}
      label={@label}
      placement={@placement}
      class={@class}
      menu_style={@menu_style}
      anchor_class={@anchor_class}
      demo={@demo}
      highlight={@highlight}
      part="action-menu"
      trigger_style="ghost"
      hook="LedgerUI.ActionMenu"
      {@rest}
    >
      <:title :if={@title != []}>{render_slot(@title)}</:title>
      <:trigger :if={@trigger != []}>{render_slot(@trigger)}</:trigger>
      <:overlay :if={@overlay != []}>{render_slot(@overlay)}</:overlay>
      {render_slot(@inner_block)}
    </Dropdown.dropdown>
    """
  end

  # ---------------------------------------------------------------------------------------
  # action_menu_item (deprecated: `dropdown_item/1`)

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
    ~H"""
    <Dropdown.dropdown_item
      danger={@danger}
      disabled={@disabled}
      type={@type}
      class={@class}
      kbd={@kbd}
      description={@hint}
      two_line={@hint != nil}
      {@rest}
    >
      <:icon :if={@icon}><.icon name={@icon} /></:icon>
      {render_slot(@inner_block)}
    </Dropdown.dropdown_item>
    """
  end

  # ---------------------------------------------------------------------------------------
  # action_menu_separator (deprecated: `dropdown_separator/1`)

  attr :class, :any, default: nil
  attr :rest, :global

  def action_menu_separator(assigns) do
    ~H"""
    <Dropdown.dropdown_separator class={@class} {@rest} />
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
