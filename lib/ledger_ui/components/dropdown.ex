defmodule LedgerUI.Components.Dropdown do
  @moduledoc """
  Dropdown menu: a button (or any trigger) that opens a floating menu of links and actions.

      <.dropdown id="actions" label="Ações">
        <.dropdown_item phx-click="edit"><:icon><.icon name="edit" /></:icon>Editar</.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item danger phx-click="delete">Excluir</.dropdown_item>
      </.dropdown>

      <.dropdown id="row" toggle_icon="dots" toggle_label="Mais ações" placement="bottom-end">
        <.dropdown_item href="#">Abrir</.dropdown_item>
      </.dropdown>

  ## Markup

  The root is the `lu-anc` anchor; the menu is `span.fl.p-<placement>` holding the `lu-pop`
  box. Everything dynamic (open state, ARIA, positioning, keys, click outside, scroll
  following, flipping) is done by the hook `LedgerUI.Dropdown`
  (`priv/static/ledger_ui/hooks/dropdown.js`), which puts the menu in the top layer
  (`popover="manual"`, `position: fixed`) under the trigger. The server only renders the
  static markup, so the hook adds `aria-haspopup`, `aria-expanded`, `role="menu"` and the
  like at mount. Options that differ from the defaults reach the hook as `data-*`
  attributes on the root (`data-offset`, `data-hover`, `data-keep-submenus`,
  `data-close-on-select`, `data-on-open`, `data-on-close`).

  `LedgerUI.open/close/toggle` work with the dropdown `id`.

  ## Additions to the design README

    * `menu_style` - inline style of the menu box (`width:220px`); `anchor_class` - extra
      classes of the root.
    * `:overlay` slot - extra content after the menu inside the anchor (a demo cursor).
    * `dropdown_item` accepts `danger`, `selected` and a `:trailing` slot.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary info success warning error mono)
  @placements ~w(bottom-start bottom bottom-end top-start top top-end left-start left left-end right-start right right-end)
  @shapes %{
    nil => "rounded",
    "" => "rounded",
    "rounded" => "rounded",
    "pill" => "pill",
    "square" => "square"
  }
  @item_colors %{"neutral" => nil, "primary" => "c-primary", "error" => "c-error"}

  @doc false
  def placements, do: @placements

  # ---------------------------------------------------------------------------------------
  # dropdown

  attr :id, :string, required: true
  attr :label, :string, default: nil
  attr :color, :string, default: "neutral", values: @colors
  attr :toggle_icon, :string, default: nil, values: [nil, "", "dots", "dots-vertical"]
  attr :toggle_class, :any, default: nil
  attr :toggle_label, :string, default: "Menu"
  attr :shape, :string, default: nil, values: [nil, "", "rounded", "pill", "square"]
  attr :control, :boolean, default: false
  attr :open, :boolean, default: false
  attr :hover, :boolean, default: false
  attr :placement, :string, default: "bottom-start", values: @placements
  attr :offset, :integer, default: 4
  attr :close_on_select, :boolean, default: true
  attr :keep_submenus, :boolean, default: false
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Merged into the menu box."
  attr :menu_style, :string, default: nil
  attr :anchor_class, :any, default: nil, doc: "Extra classes of the `lu-anc` root."
  attr :rest, :global

  slot :action do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :type, :string
    attr :disabled, :boolean
    attr :class, :any
    attr :id, :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-value-id", :any
  end

  slot :inner_block, required: true
  slot :toggle
  slot :overlay

  def dropdown(assigns) do
    assigns =
      assigns
      |> assign(:root_class, cx(["lu-anc", assigns.anchor_class, assigns.open && "open"]))
      |> assign(:root_attrs, root_attrs(assigns))
      |> assign(:panel_class, "fl p-" <> assigns.placement)
      |> assign(:btn_class, button_class(assigns))
      |> assign(
        :icon_name,
        if(assigns.toggle_icon == "dots-vertical", do: "more-v", else: "more-h")
      )
      |> assign(:kebab_class, cx(["lu-kebab", assigns.toggle_class]))
      |> assign(:box_class, cx(["lu-pop", assigns.class]))
      |> assign(:box_attrs, if(assigns.menu_style, do: %{style: assigns.menu_style}, else: %{}))

    ~H"""
    <span id={@id} class={@root_class} phx-hook="LedgerUI.Dropdown" {@root_attrs}>
      <%= cond do %>
        <% @toggle != [] -> %>
          {render_slot(@toggle)}
        <% @action != [] -> %>
          <span class={"lu-split c-" <> @color}>
            <.action_part :for={action <- @action} action={action} class={@btn_class} />
            <button class={@btn_class} type="button" aria-label={@toggle_label}>
              <.icon name="chevron-down" />
            </button>
          </span>
        <% @toggle_icon in ["dots", "dots-vertical"] and is_nil(@label) -> %>
          <button aria-label={@toggle_label} class={@kebab_class} type="button">
            <.icon name={@icon_name} />
          </button>
        <% true -> %>
          <button class={@btn_class} type="button">{@label}<.icon name="chevron-down" /></button>
      <% end %>
      <span id={@id <> "-menu"} class={@panel_class} keep-popover keep-style keep-hidden>
        <div class={@box_class} {@box_attrs}>
          {render_slot(@inner_block)}
        </div>
      </span>
      {render_slot(@overlay)}
    </span>
    """
  end

  attr :action, :map, required: true
  attr :class, :string, required: true

  defp action_part(%{action: action} = assigns) do
    rest = Map.drop(action, [:__slot__, :inner_block, :class, :href, :navigate, :patch, :type])
    assigns = assign(assigns, rest: rest, extra: action[:class], type: action[:type] || "button")

    cond do
      action[:href] || action[:navigate] || action[:patch] ->
        assigns =
          assign(assigns, link: Map.take(action, [:href, :navigate, :patch]))

        ~H"""
        <.link class={cx([@class, @extra])} {@link} {@rest}>{render_slot(@action)}</.link>
        """

      true ->
        ~H"""
        <button class={cx([@class, @extra])} type={@type} {@rest}>{render_slot(@action)}</button>
        """
    end
  end

  defp button_class(a) do
    cx([
      "lu-b",
      "c-" <> a.color,
      if(a.color == "neutral", do: "v-outline", else: "v-solid"),
      "s-md",
      "sh-" <> Map.fetch!(@shapes, a.shape)
    ])
  end

  defp root_attrs(a) do
    %{}
    |> put_if(a.offset != 4, :"data-offset", a.offset)
    |> put_if(a.hover, :"data-hover", "")
    |> put_if(a.keep_submenus, :"data-keep-submenus", "")
    |> put_if(!a.close_on_select, :"data-close-on-select", "false")
    |> put_if(a.on_open, :"data-on-open", to_js(a.on_open, a.id, a.target))
    |> put_if(a.on_close, :"data-on-close", to_js(a.on_close, a.id, a.target))
    |> Map.merge(a.rest)
    |> then(fn attrs -> if a.control, do: Map.put(attrs, :"data-control", ""), else: attrs end)
  end

  defp put_if(map, cond, key, value), do: if(cond, do: Map.put(map, key, value), else: map)

  @doc false
  def to_js(nil, _id, _target), do: nil
  def to_js(%JS{} = js, _id, _target), do: js

  def to_js(event, id, target) when is_binary(event) do
    opts = [value: %{id: id}]
    opts = if target, do: Keyword.put(opts, :target, target), else: opts
    JS.push(event, opts)
  end

  # ---------------------------------------------------------------------------------------
  # dropdown_item

  attr :color, :string, default: "neutral", values: ~w(neutral primary error)
  attr :variant, :string, default: "default", values: ~w(default media)
  attr :disabled, :boolean, default: false
  attr :shortcut, :string, default: nil
  attr :type, :string, default: "button"
  attr :danger, :boolean, default: false
  attr :selected, :boolean, default: false, doc: "Check mark at the end."
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(href navigate patch method replace download target rel hreflang referrerpolicy form name value)

  slot :icon
  slot :trailing
  slot :inner_block, required: true

  def dropdown_item(assigns) do
    assigns =
      assigns
      |> assign(:classes, item_class(assigns))
      |> assign(:keys, keys(assigns.shortcut))
      |> assign(:link?, link?(assigns.rest))
      |> assign(:role, if(assigns.variant == "media", do: nil, else: "menuitem"))
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))

    ~H"""
    <.link :if={@link?} class={@classes} role={@role} aria-disabled={@aria_disabled} {@rest}>
      <.item_body keys={@keys} selected={@selected} icons={@icon} trailing={@trailing}>
        {render_slot(@inner_block)}
      </.item_body>
    </.link>
    <button
      :if={!@link?}
      class={@classes}
      role={@role}
      type={@type}
      aria-disabled={@aria_disabled}
      {@rest}
    >
      <.item_body keys={@keys} selected={@selected} icons={@icon} trailing={@trailing}>
        {render_slot(@inner_block)}
      </.item_body>
    </button>
    """
  end

  attr :keys, :list, required: true
  attr :selected, :boolean, required: true
  attr :icons, :list, required: true
  attr :trailing, :list, required: true
  slot :inner_block, required: true

  defp item_body(assigns) do
    ~H"""
    {render_slot(@icons)}{render_slot(@inner_block)}<span
      :if={@keys != [] or @trailing != [] or @selected}
      class="r"
    ><kbd :for={key <- @keys} class="lu-kbd">{key}</kbd>{render_slot(@trailing)}<.icon
      :if={@selected}
      name="check"
      class="sm ck"
    /></span>
    """
  end

  defp item_class(a) do
    cx([
      "lu-menu-item",
      @item_colors[a.color],
      a.variant == "media" && "media",
      a.danger && "danger",
      a.selected && "sel",
      a.class
    ])
  end

  defp keys(nil), do: []
  defp keys(shortcut), do: String.split(shortcut, " ", trim: true)

  defp link?(rest), do: Enum.any?([:href, :navigate, :patch], &Map.get(rest, &1))

  # ---------------------------------------------------------------------------------------
  # dropdown_separator / label / header / search

  attr :class, :any, default: nil
  attr :rest, :global

  def dropdown_separator(assigns) do
    ~H"""
    <div class={cx(["lu-menu-sep", @class])} {@rest}></div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_label(assigns) do
    ~H"""
    <div class={cx(["lu-menu-label", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_header(assigns) do
    ~H"""
    <div class={cx(["lu-menu-head", @class])} style="padding:8px 10px 6px" {@rest}>
      <div style="font-weight:500;color:var(--ink)">{render_slot(@inner_block)}</div>
      <div :if={@subtitle} class="lu-muted" style="font-size:12px">{@subtitle}</div>
    </div>
    """
  end

  attr :placeholder, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-debounce phx-throttle autocomplete form)

  def dropdown_search(assigns) do
    ~H"""
    <div class={cx(["lu-menu-search", @class])}>
      <.icon name="search" />
      <input type="text" name={@name} value={@value} placeholder={@placeholder} {@rest} />
    </div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # checkbox / radio

  attr :checked, :boolean, default: false
  attr :name, :string, default: nil
  attr :value, :string, default: "true"
  attr :id, :string, default: nil
  attr :count, :any, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)
  slot :inner_block, required: true

  def dropdown_checkbox(assigns), do: choice(assigns, "menuitemcheckbox", "checkbox")

  attr :checked, :boolean, default: false
  attr :name, :string, default: nil
  attr :value, :string, default: "true"
  attr :id, :string, default: nil
  attr :count, :any, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(form)
  slot :inner_block, required: true

  def dropdown_radio(assigns), do: choice(assigns, "menuitemradio", "radio")

  defp choice(assigns, role, type) do
    input_id = assigns.id || derive_id(assigns.name, assigns.value)

    assigns =
      assigns
      |> assign(:role, role)
      |> assign(:type, type)
      |> assign(:input_id, input_id)
      |> assign(:classes, cx(["lu-menu-item", assigns.checked && "sel", assigns.class]))
      |> assign(:ck_style, if(!assigns.checked, do: "visibility:hidden"))
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))

    ~H"""
    <button
      class={@classes}
      role={@role}
      type="button"
      aria-checked={bool_attr(@checked)}
      aria-disabled={@aria_disabled}
      id={@input_id && @input_id <> "-item"}
      {@rest}
    >
      <input
        :if={@name}
        type={@type}
        id={@input_id}
        name={@name}
        value={@value}
        checked={@checked}
        tabindex="-1"
        hidden
      />{render_slot(@inner_block)}<span class="r"><span :if={@count != nil}>{@count}</span><.icon
        name="check"
        class="sm ck"
        style={@ck_style}
      /></span>
    </button>
    """
  end

  defp derive_id(nil, _), do: nil

  defp derive_id(name, value) do
    "dd-" <> String.replace("#{name}-#{value}", ~r/[^A-Za-z0-9_-]+/, "-")
  end

  # ---------------------------------------------------------------------------------------
  # submenu

  attr :id, :string, default: nil
  attr :label, :string, required: true
  attr :placement, :string, default: "right", values: ~w(right left)
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :trigger_class, :any, default: nil
  attr :count, :integer, default: nil
  attr :rest, :global
  slot :icon
  slot :inner_block, required: true

  def dropdown_submenu(assigns) do
    assigns =
      assigns
      |> assign(:box_class, cx(["lu-pop", assigns.class]))
      |> assign(:trigger_classes, cx(["lu-menu-item", assigns.trigger_class]))
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))
      |> assign(:left?, assigns.placement == "left")

    ~H"""
    <div
      id={@id}
      data-dd="sub"
      data-placement={@left? && "left"}
      style="position:relative"
      {@rest}
    >
      <button
        class={@trigger_classes}
        role="menuitem"
        type="button"
        aria-haspopup="menu"
        aria-expanded="false"
        aria-disabled={@aria_disabled}
      >
        {render_slot(@icon)}{@label}<span class="r"><span
          :if={@count != nil}
          class="lu-badge acc sm"
          data-dd="count"
          hidden={@count == 0}
        >{@count}</span><.icon name="chevron-right" class="sm" /></span>
      </button>
      <div
        class={@box_class}
        data-dd="subpop"
        role="menu"
        hidden
        style="position:absolute;top:-6px;z-index:2;width:max-content;min-width:180px"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # footer

  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :clear_label, :string, default: nil
  attr :apply_label, :string, default: nil
  attr :apply_count, :integer, default: nil
  attr :on_clear, :any, default: nil
  attr :on_apply, :any, default: nil
  attr :close_on_apply, :boolean, default: true
  attr :apply_color, :string, default: "primary", values: @colors
  attr :show_apply, :boolean, default: true
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def dropdown_footer(assigns) do
    pt? = assigns.locale == "pt_BR"
    clear = assigns.clear_label || if(pt?, do: "Limpar", else: "Clear")
    apply = assigns.apply_label || if(pt?, do: "Aplicar", else: "Apply")
    apply = if assigns.apply_count, do: "#{apply} (#{assigns.apply_count})", else: apply

    assigns =
      assigns
      |> assign(:clear, clear)
      |> assign(:apply, apply)
      |> assign(:on_clear_js, to_js(assigns.on_clear, nil, assigns.target))
      |> assign(:on_apply_js, to_js(assigns.on_apply, nil, assigns.target))
      |> assign(:apply_type, if(assigns.on_apply, do: "button", else: "submit"))
      |> assign(:apply_class, "lu-b c-#{assigns.apply_color} v-solid s-sm sh-rounded")

    ~H"""
    <div
      class={cx(["lu-menu-foot", @class])}
      style="display:flex;gap:6px;justify-content:flex-end;padding:6px 0 0;margin-top:5px;border-top:1px solid var(--line)"
      {@rest}
    >
      <button
        class="lu-b c-neutral v-ghost s-sm sh-rounded"
        role="menuitem"
        type="button"
        data-dd="clear"
        phx-click={@on_clear_js}
      >
        {@clear}
      </button>
      <button
        :if={@show_apply}
        class={@apply_class}
        role="menuitem"
        type={@apply_type}
        data-dd="apply"
        data-close={to_string(@close_on_apply)}
        phx-click={@on_apply_js}
      >
        {@apply}
      </button>
    </div>
    """
  end
end
