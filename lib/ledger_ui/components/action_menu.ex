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

  The server renders the ARIA (`aria-haspopup`/`aria-expanded`/`aria-controls` on the button,
  `popover="manual"`, `role="menu"`/`menuitem`/`separator`); the hook only flips `aria-expanded`.
  The menu uses the Dropdown machinery through the hook `LedgerUI.ActionMenu`
  (`priv/static/ledger_ui/hooks/action_menu.js`, the Dropdown hook plus the row marking): top
  layer, flips, follows scrolling, Esc/Tab/click outside, arrows, Home/End and letters.
  While it is open the hook sets `data-am-open` on the nearest `[data-am-row]`, `tr` or
  `.ledger-ctable-row` and tints it.

  `action_button/1` emits the `lu-b` button markup directly.
  """
  use LedgerUI.Component

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
  attr :anchor_class, :any, default: nil, doc: "Extra classes of the `lu-anc` root."
  attr :rest, :global
  slot :inner_block, required: true
  slot :title
  slot :trigger, doc: "What the button shows, in place of the \"⋯\" icon."
  slot :overlay, doc: "Extra content after the menu inside the anchor (a demo cursor)."

  def action_menu(assigns) do
    assigns =
      assigns
      |> assign(:panel_class, "fl p-" <> assigns.placement)
      |> assign(:box_class, cx(["lu-pop", assigns.class]))
      |> assign(:box_attrs, if(assigns.menu_style, do: %{style: assigns.menu_style}, else: %{}))
      |> assign(:root_class, cx(["lu-anc", assigns.anchor_class]))
      |> assign(
        :popover,
        if(!(to_string(assigns.anchor_class) =~ ~r/\bm-(click|loop)\b/), do: "manual")
      )

    ~H"""
    <span id={@id} class={@root_class} phx-hook="LedgerUI.ActionMenu" {@rest}>
      <button
        aria-label={@label}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={@id <> "-menu"}
        class="lu-b c-neutral v-ghost s-md"
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
        class={@panel_class}
        popover={@popover}
        keep-popover
        keep-style
        keep-hidden
      >
        <div class={@box_class} role="menu" {@box_attrs}>
          <div :if={@title != []} class="lu-menu-label" role="presentation">
            {render_slot(@title)}
          </div>
          {render_slot(@inner_block)}
        </div>
      </span>
      {render_slot(@overlay)}
    </span>
    """
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
        cx(["lu-menu-item", assigns.hint && "media", assigns.danger && "danger", assigns.class])
      )
      |> assign(:link?, Enum.any?([:href, :navigate, :patch], &Map.get(assigns.rest, &1)))
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))

    ~H"""
    <.link :if={@link?} class={@classes} role="menuitem" aria-disabled={@aria_disabled} {@rest}>
      <.item_body icon={@icon} kbd={@kbd} hint={@hint}>{render_slot(@inner_block)}</.item_body>
    </.link>
    <button
      :if={!@link?}
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
    ~H"""
    <.icon :if={@icon} name={@icon} />
    <span :if={@hint} class="tx">{render_slot(@inner_block)}<small>{@hint}</small></span>
    <%= if !@hint do %>
      {render_slot(@inner_block)}
    <% end %>
    <span :if={@kbd} class="r"><kbd class="lu-kbd">{@kbd}</kbd></span>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  def action_menu_separator(assigns) do
    ~H"""
    <div class={cx(["lu-menu-sep", @class])} role="separator" {@rest}></div>
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
        cx([
          "lu-b",
          if(assigns.danger, do: "c-error", else: "c-neutral"),
          "v-" <> assigns.variant,
          "s-" <> assigns.size,
          assigns.inner_block == [] && "sh-square",
          assigns.class
        ])
      )
      |> assign(:link?, Enum.any?([:href, :navigate, :patch], &Map.get(assigns.rest, &1)))

    ~H"""
    <.link :if={@link?} aria-label={@label} class={@classes} {@rest}>
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
    </.link>
    <button :if={!@link?} aria-label={@label} class={@classes} type="button" {@rest}>
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
    </button>
    """
  end
end
