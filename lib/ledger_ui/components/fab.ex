defmodule LedgerUI.Components.Fab do
  @moduledoc """
  Floating action buttons: `fab/1`, one button (the canvas's solid ink button, or the retracting
  pill) and `fab_dial/1`, a speed-dial that opens a column of actions.

      <.fab id="new" label="Novo pedido" phx-click="new_order">
        <:icon><.icon name="plus" size="md" /></:icon>
      </.fab>
      <.fab id="ask" label="Pergunte ao assistente" variant="pill" phx-click="open_assistant" />
      <.fab id="help" label="Precisa de ajuda?" variant="pill" retract="auto" retract_after={6000} />
      <.fab id="chat" label="Chat" variant="pill" retract="always" color="light" position="bottom-left" badge={3} />

      <.fab_dial id="quick" label="Ações rápidas">
        <:action label="Novo contato" phx-click="new_contact"><.icon name="user-plus" /></:action>
        <:action label="Enviar arquivo" phx-click="upload"><.icon name="upload" /></:action>
      </.fab_dial>

  ## Position

  Both are fixed to the viewport corner (`fixed`, the default; `--ledger-z-fab`, 90, keeps them
  under modals and drawers). `fixed={false}` leaves them `absolute` in the nearest positioned
  ancestor, which is how the showcase demos show them inside a box. `offset` moves a button from
  its corner, in pixels.

  ## Hooks

    * `LedgerUI.Fab` (`priv/static/ledger_ui/hooks/fab.js`), only for `retract="auto"`: expands the
      pill, retracts it after `retract_after` ms or on scroll, expands it again on hover and focus.
      `data-state` is kept across patches (`keep-data-state`).
    * `LedgerUI.FabDial` (`priv/static/ledger_ui/hooks/fab_dial.js`): click toggles, Escape closes and
      returns focus, arrows/Home/End walk the actions, a click outside or focus leaving closes it.
  """
  use LedgerUI.Component

  @positions ~w(bottom-right bottom-left top-right top-left)
  @colors ~w(assistant primary dark light)
  @fixed "position:fixed;z-index:var(--ledger-z-fab,90)"
  @link_attrs ~w(href navigate patch)a

  @pos_class %{
    "bottom-right" => nil,
    "bottom-left" => "pos-bl",
    "top-right" => "pos-tr",
    "top-left" => "pos-tl"
  }

  # Inline offset from the corner, for each corner.
  @pos_props %{
    "bottom-right" => ~w(right bottom),
    "bottom-left" => ~w(left bottom),
    "top-right" => ~w(right top),
    "top-left" => ~w(left top)
  }

  # `style={nil}` would render `style=""`: the style goes in the attribute map instead.
  defp with_style(rest, nil), do: rest
  defp with_style(rest, style), do: Map.put(rest, :style, style)

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "Always rendered, and the `aria-label`."
  attr :position, :string, default: "bottom-right", values: @positions
  attr :color, :string, default: "assistant", values: @colors
  attr :size, :string, default: "md", values: ~w(md lg)
  attr :variant, :string, default: "canvas", values: ~w(canvas pill)
  attr :offset, :integer, default: nil, doc: "Distance from the corner, in pixels."
  attr :retract, :string, default: "hover", values: ~w(hover auto never always)

  attr :retract_after, :integer,
    default: 4000,
    doc: "Milliseconds before `retract=\"auto\"` retracts."

  attr :expanded, :boolean, default: false, doc: "Forces the pill open, whatever `retract` says."
  attr :badge, :any, default: nil, doc: "A count or short text on the bubble's corner."

  attr :fixed, :boolean,
    default: true,
    doc: "Fixed to the viewport (`false`: absolute in its parent)."

  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :style, :string, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download target rel replace form name value)

  slot :icon, doc: "The glyph (a sparkle by default)."
  slot :inner_block, doc: "Replaces the visible label text (`label` stays the `aria-label`)."

  def fab(%{variant: "canvas"} = assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-fabc", assigns.class]))
      |> assign(:rest, with_style(assigns.rest, style(canvas_style(assigns), assigns.style)))
      |> assign(:link?, link?(assigns.rest))
      |> assign(:custom_label?, !empty_slot?(assigns.inner_block))

    ~H"""
    <.link :if={@link?} id={@id} data-part="fab" class={@classes} {@rest}>
      <.fab_icon icon={@icon} />{if @custom_label?, do: render_slot(@inner_block), else: @label}
    </.link>
    <button
      :if={!@link?}
      id={@id}
      data-part="fab"
      type={@type}
      class={@classes}
      disabled={@disabled}
      {@rest}
    >
      <.fab_icon icon={@icon} />{if @custom_label?, do: render_slot(@inner_block), else: @label}
    </button>
    """
  end

  def fab(assigns) do
    # `auto` starts open (the hook retracts it after `retract_after`).
    expanded? = assigns.expanded or assigns.retract in ~w(never auto)
    auto? = assigns.retract == "auto"

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-fab2",
          "k-" <> assigns.color,
          "r-" <> assigns.retract,
          "s-" <> assigns.size,
          @pos_class[assigns.position],
          assigns.class
        ])
      )
      |> assign(:rest, with_style(assigns.rest, style(pill_style(assigns), assigns.style)))
      |> assign(:state, if(expanded?, do: "expanded", else: "collapsed"))
      |> assign(:hook, if(auto?, do: "LedgerUI.Fab"))
      |> assign(:keep, auto?)
      |> assign(:link?, link?(assigns.rest))
      |> assign(:custom_label?, !empty_slot?(assigns.inner_block))

    ~H"""
    <.link
      :if={@link?}
      id={@id}
      data-part="fab"
      class={@classes}
      title={@label}
      aria-label={@label}
      data-state={@state}
      data-after={@retract_after}
      keep-data-state={@keep}
      phx-hook={@hook}
      {@rest}
    >
      <.fab_tile icon={@icon} /><span class="lbl">{if @custom_label?,
        do: render_slot(@inner_block),
        else: @label}</span><span :if={@badge} class="badge">{@badge}</span>
    </.link>
    <button
      :if={!@link?}
      id={@id}
      data-part="fab"
      type={@type}
      class={@classes}
      title={@label}
      aria-label={@label}
      data-state={@state}
      data-after={@retract_after}
      keep-data-state={@keep}
      phx-hook={@hook}
      disabled={@disabled}
      {@rest}
    >
      <.fab_tile icon={@icon} /><span class="lbl">{if @custom_label?,
        do: render_slot(@inner_block),
        else: @label}</span><span :if={@badge} class="badge">{@badge}</span>
    </button>
    """
  end

  attr :icon, :list, required: true

  defp fab_icon(assigns) do
    ~H"""
    <%= if @icon == [] do %>
      <.icon name="sparkles" size="md" />
    <% else %>
      {render_slot(@icon)}
    <% end %>
    """
  end

  attr :icon, :list, required: true

  defp fab_tile(assigns) do
    ~H"""
    <span class="tile"><.fab_icon icon={@icon} /></span>
    """
  end

  # A call with a body but only named slots still gets an (empty) `inner_block`.
  defp empty_slot?(slot) do
    Enum.all?(slot, fn
      %{inner_block: %{static: [text]}} -> String.trim(text) == ""
      _ -> false
    end)
  end

  defp link?(rest), do: Enum.any?(@link_attrs, &Map.has_key?(rest, &1))

  defp canvas_style(a) do
    [a.fixed && @fixed | corner_style(a.position, a.offset, a.position != "bottom-right")]
  end

  defp pill_style(a) do
    [a.fixed && @fixed | corner_style(a.position, a.offset, false)]
  end

  # `all?`: also reset the opposite sides (needed when the CSS default is bottom-right).
  defp corner_style(_position, nil, false), do: []

  defp corner_style(position, offset, all?) do
    [h, v] = @pos_props[position]
    px = "#{offset || 18}px"

    resets =
      if all?,
        do: [
          if(h == "left", do: "right:auto"),
          if(v == "top", do: "bottom:auto")
        ],
        else: []

    ["#{h}:#{px}", "#{v}:#{px}" | resets]
  end

  defp style(decls, extra) do
    case [decls, extra]
         |> List.flatten()
         |> Enum.reject(&(&1 in [nil, false, ""]))
         |> Enum.join(";") do
      "" -> nil
      s -> s
    end
  end

  # ---------------------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :label, :string, required: true, doc: "The button's `aria-label` and the name of the menu."
  attr :position, :string, default: "bottom-right", values: @positions

  attr :color, :string,
    default: "primary",
    values: @colors,
    doc: "Kept for API parity with `fab/1`."

  attr :size, :string, default: "md", values: ~w(md lg), doc: "Kept for API parity with `fab/1`."
  attr :variant, :string, default: "canvas", values: ~w(canvas pill)
  attr :offset, :integer, default: nil
  attr :open, :boolean, default: false, doc: "The initial state; after mount the hook owns it."

  attr :fixed, :boolean,
    default: true,
    doc: "Fixed to the viewport (`false`: absolute in its parent)."

  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global

  slot :icon, doc: "The glyph of the button, a plus by default; it turns while open."

  slot :action, required: true, doc: "A mini action: the icon is its content." do
    attr :label, :string, required: true
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :disabled, :boolean
    attr :class, :any
  end

  def fab_dial(assigns) do
    actions =
      Enum.map(assigns.action, fn a ->
        {a, assigns_to_attributes(a, [:label, :class]), link?(a)}
      end)

    assigns =
      assigns
      |> assign(:classes, cx(["lu-dial", assigns.variant == "pill" && "pill", assigns.class]))
      |> assign(:rest, with_style(assigns.rest, style(dial_style(assigns), assigns.style)))
      |> assign(:state, if(assigns.open, do: "open", else: "closed"))
      |> assign(:actions, actions)

    ~H"""
    <div
      id={@id}
      data-part="fab-dial"
      class={@classes}
      data-state={@state}
      keep-data-state
      phx-hook="LedgerUI.FabDial"
      {@rest}
    >
      <button
        type="button"
        class="lu-dial-btn"
        aria-expanded={to_string(@open)}
        aria-haspopup="menu"
        aria-controls={@id <> "-menu"}
        aria-label={@label}
      >
        <%= if @icon == [] do %>
          <.icon name="plus" />
        <% else %>
          {render_slot(@icon)}
        <% end %>
      </button>
      <div id={@id <> "-menu"} class="menu" role="menu" aria-label={@label}>
        <%= for {a, attrs, link?} <- @actions do %>
          <.link
            :if={link?}
            class={cx(["lu-menu-item", a[:class]])}
            role="menuitem"
            tabindex="-1"
            {attrs}
          >
            {render_slot(a)}<span>{a.label}</span>
          </.link>
          <button
            :if={!link?}
            type="button"
            class={cx(["lu-menu-item", a[:class]])}
            role="menuitem"
            tabindex="-1"
            {attrs}
          >
            {render_slot(a)}<span>{a.label}</span>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  defp dial_style(a) do
    corner = corner_style(a.position, a.offset, a.position != "bottom-right")
    {h, v} = {a.position =~ "left", a.position =~ "top"}

    layout = [
      h && "align-items:flex-start",
      v && "flex-direction:column"
    ]

    [a.fixed && @fixed | corner] ++ layout
  end
end
