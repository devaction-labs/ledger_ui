defmodule LedgerUI.Components.Fab do
  @moduledoc """
  Floating action buttons: `fab/1`, one button (the canvas's solid ink button, or the retracting
  pill) and `fab_dial/1`, a speed-dial that opens a column of actions. Styled only with Tailwind
  utilities.

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
  its corner, in pixels (18 by default). `loop` plays the canvas demo loop (the pill opens and
  closes, the dial opens and closes), for showcases.

  ## Hooks

    * `LedgerUI.Fab` (`priv/static/ledger_ui/hooks/fab.js`), only for `retract="auto"`: expands the
      pill, retracts it after `retract_after` ms or on scroll, expands it again on hover and focus.
      `data-state` survives a patch (it is set with the sticky `setAttribute` of `this.js()`); the utilities read it
      (`data-[state=expanded]:`).
    * `LedgerUI.FabDial` (`priv/static/ledger_ui/hooks/fab_dial.js`): click toggles, Escape closes and
      returns focus, arrows/Home/End walk the actions, a click outside or focus leaving closes it.
  """
  use LedgerUI.Component

  @positions ~w(bottom-right bottom-left top-right top-left)
  @colors ~w(assistant primary dark light)
  @link_attrs ~w(href navigate patch)a

  # The corner: `--fab-o` is the distance (`offset`, 18px by default); fixed to the viewport or
  # absolute in the parent, always under modals and drawers (`--ledger-z-fab`).
  @fixed "fixed z-[var(--ledger-z-fab,90)]"
  @absolute "absolute z-[2]"

  @corners %{
    "bottom-right" => "right-[var(--fab-o,18px)] bottom-[var(--fab-o,18px)]",
    "bottom-left" => "left-[var(--fab-o,18px)] bottom-[var(--fab-o,18px)]",
    "top-right" => "right-[var(--fab-o,18px)] top-[var(--fab-o,18px)]",
    "top-left" => "left-[var(--fab-o,18px)] top-[var(--fab-o,18px)]"
  }

  # Canvas button: the solid ink square.
  @canvas "inline-flex h-12 cursor-pointer items-center gap-2 rounded-xl border-0 bg-inverse pr-[18px] pl-3.5 " <>
            "text-[15px] font-medium text-on-inverse shadow-[var(--lu-shadow-btn),var(--lu-shadow-lg)]"

  # Pill: the bubble (`tile`) plus a label that grows out of it.
  @pill "group/fab inline-flex cursor-pointer items-center gap-0 rounded-full border-0 p-1.5 " <>
          "font-medium whitespace-nowrap [transition:gap_.25s,padding_.25s,box-shadow_.2s] " <>
          "data-[state=expanded]:gap-2.5 data-[state=expanded]:pr-[18px]"

  # Open on hover (and on keyboard focus, `hover` only); `auto`, `never` and `always` leave it to the state.
  @reveal %{
    "hover" => "hover:gap-2.5 hover:pr-[18px] focus-visible:gap-2.5 focus-visible:pr-[18px]",
    "auto" => "hover:gap-2.5 hover:pr-[18px]"
  }
  @reveal_label %{
    "hover" =>
      "group-hover/fab:max-w-[220px] group-hover/fab:opacity-100 group-focus-visible/fab:max-w-[220px] group-focus-visible/fab:opacity-100",
    "auto" => "group-hover/fab:max-w-[220px] group-hover/fab:opacity-100"
  }

  # background + text + shadow of the pill and the background of its tile, by `color`
  @pill_colors %{
    "assistant" =>
      {"bg-navy text-white shadow-lg",
       "bg-[linear-gradient(135deg,var(--lu-assistant-a),var(--lu-assistant-b))] text-white"},
    "primary" => {"bg-accent-600 text-(--lu-on-accent) shadow-lg", "bg-[rgba(255,255,255,.18)]"},
    "dark" => {"bg-[#141514] text-white shadow-lg", "bg-[rgba(255,255,255,.12)]"},
    "light" =>
      {"bg-white text-[#141514] shadow-[var(--lu-shadow-lg),0_0_0_1px_var(--lu-line)]",
       "bg-sunken"}
  }

  # height + font size of the pill, size of the tile
  @pill_sizes %{
    "md" => {"h-[52px] text-[14.5px]", "size-10"},
    "lg" => {"h-[60px] text-[15.5px]", "size-12"}
  }

  # `static`: part of the flow (relative, no corner), for showing a button inside a page or a box.
  defp placement(%{static: true}), do: "relative"
  defp placement(%{fixed: true, position: pos}), do: [@fixed, @corners[pos]]
  defp placement(%{position: pos}), do: [@absolute, @corners[pos]]

  # `style={nil}` would render `style=""`: the style goes in the attribute map instead.
  defp with_style(rest, nil), do: rest
  defp with_style(rest, style), do: Map.put(rest, :style, style)

  # The offset reaches the corner utilities as `--fab-o`.
  defp style(offset, extra) do
    case Enum.reject([offset && "--fab-o:#{offset}px", extra], &(&1 in [nil, false, ""])) do
      [] -> nil
      parts -> Enum.join(parts, ";")
    end
  end

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

  attr :static, :boolean,
    default: false,
    doc: "In the flow (`relative`, no corner, no offset): a sample inside a page or a box."

  attr :fixed, :boolean,
    default: true,
    doc: "Fixed to the viewport (`false`: absolute in its parent)."

  attr :loop, :boolean,
    default: false,
    doc: "`variant=\"pill\"`: plays the open/close loop of the canvas demo."

  attr :type, :string, default: "button", values: ~w(button submit reset)
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :style, :string, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download target rel replace form name value)

  slot :icon, doc: "The glyph (a sparkle by default)."
  slot :inner_block, doc: "Replaces the visible label text (`label` stays the `aria-label`)."

  def fab(%{variant: "canvas"} = assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:classes, [
        @canvas,
        placement(assigns)
      ])
      |> assign(:rest, with_style(assigns.rest, style(assigns.offset, assigns.style)))
      |> assign(:link?, link?(assigns.rest))
      |> assign(:custom_label?, !empty_slot?(assigns.inner_block))

    # A new label must not send the classes again (`rest` goes first: it only counts as changed
    # when the caller changed it or the offset or style did).
    assigns =
      settle(assigns, changed0,
        rest: [:offset, :style],
        classes: [:static, :fixed, :position],
        link?: [:rest],
        custom_label?: [:inner_block]
      )

    ~H"""
    <.link :if={@link?} id={@id} data-part="fab" class={[@classes, @class]} {@rest}>
      <.fab_icon icon={@icon} />{if @custom_label?, do: render_slot(@inner_block), else: @label}
    </.link>
    <button
      :if={!@link?}
      id={@id}
      data-part="fab"
      type={@type}
      class={[@classes, @class]}
      disabled={@disabled}
      {@rest}
    >
      <.fab_icon icon={@icon} />{if @custom_label?, do: render_slot(@inner_block), else: @label}
    </button>
    """
  end

  def fab(assigns) do
    changed0 = assigns.__changed__
    # `auto` starts open (the hook retracts it after `retract_after`).
    expanded? = assigns.expanded or assigns.retract in ~w(never auto)
    auto? = assigns.retract == "auto"
    {look, tile} = @pill_colors[assigns.color]
    {size, tile_size} = @pill_sizes[assigns.size]

    assigns =
      assigns
      |> assign(:classes, [
        @pill,
        look,
        size,
        @reveal[assigns.retract],
        placement(assigns),
        assigns.loop && "animate-[lu-fabpad_4.5s_cubic-bezier(.3,.7,.4,1)_infinite]"
      ])
      |> assign(:tile_class, [
        "grid flex-none place-items-center rounded-full",
        tile,
        tile_size
      ])
      |> assign(:label_class, [
        "max-w-0 overflow-hidden opacity-0 [transition:max-width_.3s_cubic-bezier(.3,.7,.4,1),opacity_.2s,margin_.3s]",
        "group-data-[state=expanded]/fab:max-w-[220px] group-data-[state=expanded]/fab:opacity-100",
        @reveal_label[assigns.retract],
        assigns.loop && "animate-[lu-fablbl_4.5s_cubic-bezier(.3,.7,.4,1)_infinite]"
      ])
      |> assign(:rest, with_style(assigns.rest, style(assigns.offset, assigns.style)))
      |> assign(:state, if(expanded?, do: "expanded", else: "collapsed"))
      |> assign(:hook, if(auto?, do: "LedgerUI.Fab"))
      |> assign(:link?, link?(assigns.rest))
      |> assign(:custom_label?, !empty_slot?(assigns.inner_block))

    assigns =
      settle(assigns, changed0,
        classes: [:color, :size, :retract, :static, :fixed, :position, :loop],
        tile_class: [:color, :size],
        label_class: [:retract, :loop],
        rest: [:offset, :style],
        state: [:expanded, :retract],
        hook: [:retract],
        link?: [:rest],
        custom_label?: [:inner_block]
      )

    ~H"""
    <.link
      :if={@link?}
      id={@id}
      data-part="fab"
      class={[@classes, @class]}
      title={@label}
      aria-label={@label}
      data-state={@state}
      data-after={@retract_after}
      phx-hook={@hook}
      {@rest}
    >
      <.fab_tile icon={@icon} class={@tile_class} /><span data-part="fab-label" class={@label_class}>{if @custom_label?,
        do: render_slot(@inner_block),
        else: @label}</span><span
        :if={@badge}
        data-part="fab-badge"
        class="absolute -top-0.5 left-[34px] grid h-[18px] min-w-[18px] place-items-center rounded-full bg-neg px-[5px] text-[11px] font-semibold text-white shadow-[0_0_0_2px_var(--lu-bg-tray)]"
      >{@badge}</span>
    </.link>
    <button
      :if={!@link?}
      id={@id}
      data-part="fab"
      type={@type}
      class={[@classes, @class]}
      title={@label}
      aria-label={@label}
      data-state={@state}
      data-after={@retract_after}
      phx-hook={@hook}
      disabled={@disabled}
      {@rest}
    >
      <.fab_tile icon={@icon} class={@tile_class} /><span data-part="fab-label" class={@label_class}>{if @custom_label?,
        do: render_slot(@inner_block),
        else: @label}</span><span
        :if={@badge}
        data-part="fab-badge"
        class="absolute -top-0.5 left-[34px] grid h-[18px] min-w-[18px] place-items-center rounded-full bg-neg px-[5px] text-[11px] font-semibold text-white shadow-[0_0_0_2px_var(--lu-bg-tray)]"
      >{@badge}</span>
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
  attr :class, :any, default: nil

  defp fab_tile(assigns) do
    ~H"""
    <span data-part="fab-tile" class={@class}><.fab_icon icon={@icon} /></span>
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

  attr :static, :boolean,
    default: false,
    doc: "In the flow (`relative`, no corner, no offset): a sample inside a page or a box."

  attr :fixed, :boolean,
    default: true,
    doc: "Fixed to the viewport (`false`: absolute in its parent)."

  attr :loop, :boolean, default: false, doc: "Plays the open/close loop of the canvas demo."
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

  @dial_motion "[transition:opacity_.18s,transform_.22s_cubic-bezier(.3,.7,.4,1)]"

  def fab_dial(assigns) do
    changed0 = assigns.__changed__

    actions =
      Enum.map(assigns.action, fn a ->
        {a, assigns_to_attributes(a, [:label, :class]), link?(a)}
      end)

    pill? = assigns.variant == "pill"
    top? = assigns.position =~ "top"
    left? = assigns.position =~ "left"

    assigns =
      assigns
      |> assign(:classes, [
        "flex gap-2.5",
        placement(assigns),
        if(top?, do: "flex-col", else: "flex-col-reverse"),
        if(left?, do: "items-start", else: "items-end"),
        "group/dial"
      ])
      |> assign(:button_class, [
        "grid size-14 cursor-pointer place-items-center border-0 bg-inverse text-on-inverse shadow-[var(--lu-shadow-btn),var(--lu-shadow-lg)]",
        "[&_svg]:size-6 [&_svg]:[transition:rotate_.25s_cubic-bezier(.3,.7,.4,1)] group-data-[state=open]/dial:[&_svg]:rotate-45",
        if(pill?, do: "rounded-full", else: "rounded-xl"),
        assigns.loop && "[&_svg]:animate-[lu-dialrot_4s_cubic-bezier(.3,.7,.4,1)_infinite]"
      ])
      |> assign(:menu_class, [
        "flex flex-col",
        if(left?, do: "origin-bottom-left", else: "origin-bottom-right"),
        @dial_motion,
        "group-data-[state=closed]/dial:pointer-events-none group-data-[state=closed]/dial:opacity-0 group-data-[state=closed]/dial:[transform:translateY(8px)_scale(.96)]",
        if(pill?,
          do: "items-end gap-2 border-0 bg-transparent p-0 shadow-none",
          else: "gap-0.5 rounded-lg border border-line bg-panel p-[5px] shadow-md"
        ),
        assigns.loop &&
          "animate-[lu-dialmenu_4s_cubic-bezier(.3,.7,.4,1)_infinite] [&>*]:animate-[lu-dialitem_4s_cubic-bezier(.3,.7,.4,1)_infinite] [&>*:nth-child(2)]:[animation-delay:.05s] [&>*:nth-child(3)]:[animation-delay:.1s]"
      ])
      |> assign(:item_class, dial_item(pill?))
      |> assign(:rest, with_style(assigns.rest, style(assigns.offset, assigns.style)))
      |> assign(:state, if(assigns.open, do: "open", else: "closed"))
      |> assign(:actions, actions)

    assigns =
      settle(assigns, changed0,
        classes: [:static, :fixed, :position],
        button_class: [:variant, :loop],
        menu_class: [:position, :variant, :loop],
        item_class: [:variant],
        rest: [:offset, :style],
        state: [:open],
        actions: [:action]
      )

    ~H"""
    <div
      id={@id}
      data-part="fab-dial"
      class={[@classes, @class]}
      data-state={@state}
      phx-hook="LedgerUI.FabDial"
      {@rest}
    >
      <button
        type="button"
        data-part="fab-dial-button"
        class={@button_class}
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
      <div
        id={@id <> "-menu"}
        data-part="fab-dial-menu"
        class={@menu_class}
        role="menu"
        aria-label={@label}
      >
        <%= for {a, attrs, link?} <- @actions do %>
          <.link
            :if={link?}
            data-part="fab-dial-item"
            class={[@item_class, a[:class]]}
            role="menuitem"
            tabindex="-1"
            {attrs}
          >
            {render_slot(a)}<span data-part="fab-dial-label" class={label_class(@variant)}>{a.label}</span>
          </.link>
          <button
            :if={!link?}
            type="button"
            data-part="fab-dial-item"
            class={[@item_class, a[:class]]}
            role="menuitem"
            tabindex="-1"
            {attrs}
          >
            {render_slot(a)}<span data-part="fab-dial-label" class={label_class(@variant)}>{a.label}</span>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  # The action rows: a menu row (`canvas`) or the round icon with a dark tag (`pill`).
  @item "flex cursor-pointer items-center border-0 text-left text-[14px] focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none " <>
          "aria-disabled:cursor-not-allowed aria-disabled:opacity-45"
  @item_menu "h-[34px] w-full gap-2.5 rounded-[8px] bg-transparent px-2.5 text-ink-2 hover:bg-hover hover:text-ink [&_svg]:size-4 [&_svg]:text-ink"
  @item_pill "h-auto w-auto flex-row-reverse gap-2.5 bg-transparent p-0 text-ink [&_svg]:size-[38px] [&_svg]:rounded-full [&_svg]:bg-panel [&_svg]:p-2.5 [&_svg]:text-ink [&_svg]:shadow-md"

  defp dial_item(true), do: [@item, @item_pill]
  defp dial_item(false), do: [@item, @item_menu]

  defp label_class("pill"),
    do: "rounded-sm bg-inverse px-2 py-1 text-[12.5px] text-on-inverse"

  defp label_class(_variant), do: nil
end
