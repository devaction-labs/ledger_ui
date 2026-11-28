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

  Styled only with Tailwind utilities; every element carries `data-part` (`dropdown`,
  `dropdown-menu`, `pop`, `pop-item`, `pop-separator`, `pop-label`, `pop-head`, `pop-search`,
  `pop-foot`, `pop-end`, `pop-kbd`, `dropdown-split`, `dropdown-kebab`...). The `pop-*` parts and the
  helpers `pop_classes/1`, `item_classes/1`... are shared with `LedgerUI.Components.ContextMenu`. `action_button/1`, the direct button of an item with
  a single action, lives here too.

  ## Markup

  The root is the anchor (`relative inline-flex`); the menu is a `span` (`data-part="dropdown-menu"`,
  `data-lu-placement`) holding the `pop` box. Everything dynamic (open state, ARIA, positioning, keys, click outside, scroll
  following, flipping) is done by the hook `LedgerUI.Dropdown`
  (`priv/static/ledger_ui/hooks/dropdown.js`), which puts the menu in the top layer
  (`popover="manual"`, `position: fixed`) under the trigger. The server renders the ARIA and the
  initial state: `popover="manual"` on the menu, `role="menu"` on the box, `role="menuitem"`
  (`menuitemcheckbox`/`menuitemradio`, `separator`) on the parts and, on the built-in triggers,
  `aria-haspopup="menu"`, `aria-expanded` and `aria-controls`; the hook only flips
  `aria-expanded` and the open state. A custom `:toggle` slot receives those trigger attributes
  as its argument (`<:toggle :let={t}><button {t}>...</button></:toggle>`); when it does not
  spread them the hook falls back to setting `aria-haspopup`/`aria-controls` on that trigger.
  Options that differ from the defaults reach the hook as `data-*`
  attributes on the root (`data-offset`, `data-hover`, `data-keep-submenus`,
  `data-close-on-select`, `data-on-open`, `data-on-close`).

  `LedgerUI.open/close/toggle` work with the dropdown `id`.

  ## Additions to the design README

    * `menu_style` - inline style of the menu box (`width:220px`); `anchor_class` - extra
      classes of the root.
    * `demo` (`"click"`/`"loop"`) - the animated demo: the menu is drawn open under the trigger
      (no top layer) and fades in and out; `highlight` walks a highlight over the items
      (stagger them with `style="--dl:1s"`).
    * `:overlay` slot - extra content after the menu inside the anchor (a demo cursor).
    * `dropdown_item` accepts `danger`, `selected` and a `:trailing` slot, `kbd` (one key cap, verbatim) and
      `two_line` (the taller height for a `description`).
    * Row actions (the "⋯" menu of a row): `trigger_style="ghost"` (a ghost "⋯" button named by `label`, or
      the `:trigger` slot), a `:title` slot (muted heading line), `row_mark` (tints the table row while open),
      `part` (the `data-part` prefix: `"action-menu"` gives `action-menu`/`action-menu-trigger`/`action-menu-panel`)
      and `hook` (the `phx-hook` name).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Button
  import LedgerUI.Components.Badge, only: [badge: 1]

  @colors ~w(neutral primary secondary info success warning error mono)
  @placements ~w(bottom-start bottom bottom-end top-start top top-end left-start left left-end right-start right right-end)
  @shapes %{
    nil => "rounded",
    "" => "rounded",
    "rounded" => "rounded",
    "pill" => "pill",
    "square" => "square"
  }

  # --- shared by the three popup menus ---------------------------------------------------

  @box "bg-panel border border-line rounded-lg shadow-popover p-[5px]"
  @item "flex w-full cursor-pointer items-center gap-2.5 rounded-md border-0 bg-transparent text-left text-[14px] " <>
          "hover:bg-hover focus-visible:outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] " <>
          "aria-disabled:cursor-not-allowed aria-disabled:opacity-45 [&_svg]:size-4"
  @item_tone %{
    nil => "text-ink-2 hover:text-ink [&_svg]:text-ink",
    :selected => "font-medium text-ink [&_svg]:text-ink",
    "primary" => "text-accent-content [&_svg]:text-accent-content",
    "danger" => "text-neg [&_svg]:text-neg"
  }
  @item_check "[&_[data-part=pop-check]]:text-accent-content"
  @item_end "ml-auto flex items-center gap-1 text-[12px] text-muted"
  @kbd "inline-flex h-[22px] min-w-[22px] items-center justify-center rounded-sm border border-line-strong bg-panel px-1.5 font-mono text-[11.5px] leading-none text-ink-2 shadow-[inset_0_-1px_0_var(--lu-line)]"
  @highlight "[&_[role^=menuitem]]:animate-[lu-hl_4s_infinite] [&_[role^=menuitem]]:[animation-delay:var(--dl,0s)]"

  # the demo menu is placed by the stylesheet, the real one by the hook (inline styles)
  @demo_place %{
    "top" => "bottom-[calc(100%+8px)] left-1/2 [transform:translateX(-50%)]",
    "top-start" => "bottom-[calc(100%+8px)] left-0",
    "top-end" => "bottom-[calc(100%+8px)] right-0",
    "bottom" => "top-[calc(100%+8px)] left-1/2 [transform:translateX(-50%)]",
    "bottom-start" => "top-[calc(100%+8px)] left-0",
    "bottom-end" => "top-[calc(100%+8px)] right-0",
    "left" => "right-[calc(100%+8px)] top-1/2 [transform:translateY(-50%)]",
    "left-start" => "right-[calc(100%+8px)] top-0",
    "left-end" => "right-[calc(100%+8px)] bottom-0",
    "right" => "left-[calc(100%+8px)] top-1/2 [transform:translateY(-50%)]",
    "right-start" => "left-[calc(100%+8px)] top-0",
    "right-end" => "left-[calc(100%+8px)] bottom-0"
  }

  @doc false
  def placements, do: @placements

  @doc false
  # The popup box. `min` is the min-width utility (`min-w-[220px]` by default).
  def pop_classes(opts \\ []) do
    [
      @box,
      opts[:min] || "min-w-[220px]",
      opts[:highlight] && @highlight
    ]
  end

  @doc false
  # `tone`: nil, `"primary"` or `"danger"`; `media`: the two-line item with a picture.
  def item_classes(opts \\ []) do
    [
      @item,
      @item_tone[if(opts[:selected] && !opts[:tone], do: :selected, else: opts[:tone])],
      if(opts[:media], do: "h-auto px-2 py-[7px]", else: "h-[34px] px-2.5"),
      opts[:check] && @item_check,
      opts[:checkable] && "aria-checked:text-ink aria-checked:font-medium",
      opts[:class]
    ]
  end

  @doc false
  def item_end_classes, do: @item_end

  @doc false
  def kbd_classes, do: @kbd

  @doc false
  def separator_classes, do: "-mx-[5px] my-[5px] h-px bg-line"

  @doc false
  def label_classes,
    do: "px-2.5 pt-2 pb-1 text-[11.5px] font-medium uppercase tracking-[.06em] text-muted"

  @doc false
  # The destination attrs of a menu item (`href`, `navigate`, `patch`).
  def link?(rest), do: Enum.any?([:href, :navigate, :patch], &Map.get(rest, &1))

  # ---------------------------------------------------------------------------------------
  # dropdown

  attr :id, :string, required: true
  attr :label, :string, default: nil
  attr :color, :string, default: "neutral", values: @colors
  attr :toggle_icon, :string, default: nil, values: [nil, "", "dots", "dots-vertical"]
  attr :toggle_class, :any, default: nil
  attr :toggle_label, :string, default: nil
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

  attr :demo, :string,
    default: nil,
    values: [nil, "click", "loop"],
    doc:
      "The animated demo: the menu is drawn open (no top layer); `click` presses the trigger and drops the menu, `loop` fades it in and out."

  attr :highlight, :boolean,
    default: false,
    doc: "Walks a highlight over the items (set `style=\"--dl:1s\"` on each for the stagger)."

  attr :class, :any, default: nil, doc: "Merged into the menu box."
  attr :menu_style, :string, default: nil
  attr :anchor_class, :any, default: nil, doc: "Extra classes of the root."

  attr :part, :string,
    default: "dropdown",
    doc:
      ~s[The `data-part` prefix. `"dropdown"` gives `dropdown`/`dropdown-toggle`/`dropdown-menu`; any other value gives `<part>`/`<part>-trigger`/`<part>-panel` (`"action-menu"` is the row-actions menu).]

  attr :trigger_style, :string,
    default: "default",
    values: ~w(default ghost),
    doc:
      "`ghost` is the row-actions trigger: a ghost icon button (the \"⋯\" icon, or the `:trigger` slot) whose accessible name is `label`, with no chevron."

  attr :row_mark, :boolean,
    default: false,
    doc:
      "While open, the hook marks the nearest `[data-am-row]`, `tr` or `.ledger-ctable-row` with `data-am-open` and tints it (`data-row-mark` on the root)."

  attr :hook, :string,
    default: "LedgerUI.Dropdown",
    doc: "The `phx-hook` name (the `row_mark` attribute turns the row marking on)."

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

  slot :trigger,
    doc: "The label of the button that opens the menu, as markup (instead of `label`)."

  slot :overlay

  slot :title,
    doc: "A muted heading line at the top of the menu (`data-part=\"pop-label\"`)."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def dropdown(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, toggle_label: "dropdown.toggle")

    assigns =
      assigns
      |> assign(
        :root_class,
        cx([
          "relative inline-flex",
          assigns.demo == "click" && "[&>button]:animate-[lu-presso_4s_infinite]",
          assigns.anchor_class,
          assigns.open && "open"
        ])
      )
      |> assign(:root_attrs, root_attrs(assigns))
      |> assign(:panel_class, panel_class(assigns))
      |> assign(:btn_class, button_class(assigns))
      |> assign(:split_last, split_last_class(assigns))
      |> assign(:split_first, [button_class(assigns), "rounded-r-none"])
      |> assign(
        :icon_name,
        if(assigns.toggle_icon == "dots-vertical", do: "more-v", else: "more-h")
      )
      |> assign(:kebab_class, [
        "inline-grid size-8 cursor-pointer place-items-center rounded-md border-0 bg-transparent text-ink-2 hover:bg-hover aria-expanded:bg-hover",
        assigns.toggle_class
      ])
      |> assign(
        :box_class,
        cx([pop_classes(highlight: assigns.highlight), assigns.class])
      )
      |> assign(:box_attrs, if(assigns.menu_style, do: %{style: assigns.menu_style}, else: %{}))
      |> assign(:trig, trigger_aria(assigns.id, assigns.open))
      |> assign(:popover, if(!assigns.demo, do: "manual"))
      |> assign(:parts, parts(assigns.part))
      |> assign(:ghost_class, Button.classes("neutral", "ghost", "md", "rounded"))
      |> assign(:label_class, label_classes())

    assigns =
      settle(assigns, changed0,
        root_class: [:demo, :anchor_class, :open],
        root_attrs: [
          :row_mark,
          :offset,
          :hover,
          :keep_submenus,
          :close_on_select,
          :on_open,
          :on_close,
          :id,
          :target,
          :demo,
          :rest,
          :control
        ],
        panel_class: [:demo, :placement],
        btn_class: [:color, :shape],
        split_last: [:color],
        split_first: [:color, :shape],
        icon_name: [:toggle_icon],
        kebab_class: [:toggle_class],
        box_class: [:highlight, :class],
        box_attrs: [:menu_style],
        trig: [:id, :open],
        popover: [:demo],
        parts: [:part],
        ghost_class: [],
        label_class: []
      )

    ~H"""
    <span id={@id} data-part={@parts.root} class={@root_class} phx-hook={@hook} {@root_attrs}>
      <%= cond do %>
        <% @toggle != [] -> %>
          {render_slot(@toggle, @trig)}
        <% @action != [] -> %>
          <span data-part="dropdown-split" class="inline-flex">
            <.action_part :for={action <- @action} action={action} class={@split_first} />
            <button
              data-part={@parts.trigger}
              class={@split_last}
              type="button"
              aria-label={@toggle_label}
              {@trig}
            >
              <.icon name="chevron-down" />
            </button>
          </span>
        <% @trigger_style == "ghost" -> %>
          <button
            data-part={@parts.trigger}
            aria-label={@label}
            aria-haspopup="menu"
            aria-expanded={@trig[:"aria-expanded"]}
            aria-controls={@trig[:"aria-controls"]}
            class={@ghost_class}
            type="button"
          >
            <%= if @trigger != [] do %>
              {render_slot(@trigger)}
            <% else %>
              <.icon name="more-h" size="md" />
            <% end %>
          </button>
        <% @toggle_icon in ["dots", "dots-vertical"] and is_nil(@label) and @trigger == [] -> %>
          <button
            data-part="dropdown-kebab"
            aria-label={@toggle_label}
            class={@kebab_class}
            type="button"
            {@trig}
          >
            <.icon name={@icon_name} />
          </button>
        <% true -> %>
          <button data-part={@parts.trigger} class={@btn_class} type="button" {@trig}>
            <%= if @trigger != [] do %>
              {render_slot(@trigger)}
            <% else %>
              {@label}
            <% end %>
            <.icon name="chevron-down" />
          </button>
      <% end %>
      <span
        id={@id <> "-menu"}
        data-part={@parts.panel}
        data-lu-placement={@placement}
        class={@panel_class}
        popover={@popover}
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

  defp panel_class(a) do
    cond do
      a.demo == "click" ->
        [
          "absolute z-[4] whitespace-nowrap animate-[lu-flin2_4s_ease-out_infinite]",
          @demo_place[a.placement]
        ]

      a.demo == "loop" ->
        [
          "absolute z-[4] whitespace-nowrap animate-[lu-flin_4s_ease-out_infinite]",
          @demo_place[a.placement]
        ]

      true ->
        "whitespace-nowrap"
    end
  end

  attr :action, :map, required: true
  attr :class, :any, required: true

  defp action_part(%{action: action} = assigns) do
    changed0 = assigns.__changed__
    rest = Map.drop(action, [:__slot__, :inner_block, :class, :href, :navigate, :patch, :type])
    assigns = assign(assigns, rest: rest, extra: action[:class], type: action[:type] || "button")
    assigns = settle(assigns, changed0, rest: [:action], extra: [:action], type: [:action])

    cond do
      action[:href] || action[:navigate] || action[:patch] ->
        assigns =
          assign(
            assigns,
            link:
              LedgerUI.LinkAttrs.resolve(
                Map.merge(rest, Map.take(action, [:href, :navigate, :patch])),
                ["data-part", "class"]
              )
          )
          |> settle(changed0, link: [:action])

        ~H"""
        <a data-part="dropdown-action" class={cx([@class, @extra])} {@link}>{render_slot(@action)}</a>
        """

      true ->
        ~H"""
        <button data-part="dropdown-action" class={cx([@class, @extra])} type={@type} {@rest}>{render_slot(
          @action
        )}</button>
        """
    end
  end

  @doc false
  # ARIA of the trigger button (initial state; the hook flips `aria-expanded`).
  def trigger_aria(id, open?) do
    %{
      "aria-haspopup": "menu",
      "aria-expanded": to_string(open? == true),
      "aria-controls": id <> "-menu"
    }
  end

  defp button_class(a) do
    Button.classes(
      a.color,
      if(a.color == "neutral", do: "outline", else: "solid"),
      "md",
      Map.fetch!(@shapes, a.shape)
    )
  end

  # the arrow half of a split button: square, joined to the action, with a faint divider
  defp split_last_class(a) do
    [
      Button.classes(
        a.color,
        if(a.color == "neutral", do: "outline", else: "solid"),
        "md",
        "square"
      ),
      "rounded-l-none border-l-[color-mix(in_oklab,var(--c-on)_25%,transparent)]"
    ]
  end

  defp parts("dropdown"),
    do: %{root: "dropdown", trigger: "dropdown-toggle", panel: "dropdown-menu"}

  defp parts(p), do: %{root: p, trigger: p <> "-trigger", panel: p <> "-panel"}

  defp root_attrs(a) do
    %{}
    |> put_if(a.row_mark, :"data-row-mark", "")
    |> put_if(a.offset != 4, :"data-offset", a.offset)
    |> put_if(a.hover, :"data-hover", "")
    |> put_if(a.keep_submenus, :"data-keep-submenus", "")
    |> put_if(!a.close_on_select, :"data-close-on-select", "false")
    |> put_if(a.on_open, :"data-on-open", to_js(a.on_open, a.id, a.target))
    |> put_if(a.on_close, :"data-on-close", to_js(a.on_close, a.id, a.target))
    |> put_if(a.demo, :"data-lu-demo", a.demo)
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

  attr :kbd, :string,
    default: nil,
    doc:
      "One key cap shown verbatim at the end (`shortcut` splits on spaces into one cap per key). `shortcut` wins when both are given."

  attr :icon_name, :string,
    default: nil,
    doc:
      "An icon name before the label: the same as an `:icon` slot with `<.icon name=... />`. " <>
        "(Not called `icon`: Phoenix does not allow an attr and a slot with the same name.)"

  attr :two_line, :any,
    default: false,
    values: [false, true, "auto"],
    doc:
      "The taller item height of `variant=\"media\"` for a `description`, keeping the plain `menuitem` role. " <>
        "`\"auto\"`: two-line only when there is a `description` (set it for the whole app with " <>
        "`config :ledger_ui, :defaults, dropdown_item: [two_line: \"auto\"]`)."

  attr :description, :string,
    default: nil,
    doc:
      "A second, muted line under the label. With `variant=\"media\"` the label is always wrapped in its two-line block."

  attr :type, :string, default: "button", values: ~w(button submit reset)
  attr :danger, :boolean, default: false
  attr :selected, :boolean, default: false, doc: "Check mark at the end."

  attr :auto_loading, :boolean,
    default: true,
    doc:
      "An item with `phx-click` shows a spinner at the end, dims and ignores clicks while LiveView waits " <>
        "for the server (`phx-click-loading`). `false` opts out; links are unchanged."

  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(href navigate patch method replace download target rel hreflang referrerpolicy form name value)

  slot :icon
  slot :trailing
  slot :inner_block, required: true

  def dropdown_item(assigns) do
    changed0 = assigns.__changed__

    tone =
      cond do
        assigns.danger or assigns.color == "error" -> "danger"
        assigns.color == "primary" -> "primary"
        true -> nil
      end

    assigns =
      assigns
      |> assign(
        :classes,
        item_classes(
          tone: tone,
          media: assigns.variant == "media" or two_line?(assigns),
          selected: assigns.selected,
          check: assigns.selected,
          class: assigns.class
        )
      )
      |> assign(:keys, keys(assigns.shortcut || assigns.kbd, assigns.shortcut))
      |> assign(:link?, link?(assigns.rest))
      |> assign(
        :link_rest,
        if(link?(assigns.rest),
          do:
            LedgerUI.LinkAttrs.resolve(assigns.rest, [
              "data-part",
              "class",
              "role",
              "aria-disabled"
            ]),
          else: %{}
        )
      )
      |> assign(:role, if(assigns.variant == "media", do: nil, else: "menuitem"))
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))
      |> assign(:auto?, assigns.auto_loading and Button.auto_loading?(assigns.rest))
      |> assign(:auto_spin, Button.auto_spinner_classes())

    assigns =
      settle(assigns, changed0,
        classes:
          [:danger, :color, :variant, :two_line, :selected, :class] ++
            if(assigns.two_line == "auto", do: [:description], else: []),
        keys: [:shortcut, :kbd],
        link?: [:rest],
        link_rest: [:rest],
        role: [:variant],
        aria_disabled: [:disabled],
        auto?: [:auto_loading, :rest],
        auto_spin: []
      )

    ~H"""
    <a
      :if={@link?}
      data-part="pop-item"
      class={@classes}
      role={@role}
      aria-disabled={@aria_disabled}
      {@link_rest}
    >
      <.item_body
        keys={@keys}
        selected={@selected}
        icons={@icon}
        icon_name={@icon_name}
        trailing={@trailing}
        description={@description}
        media={@variant == "media"}
      >
        {render_slot(@inner_block)}
      </.item_body>
    </a>
    <button
      :if={!@link?}
      data-part="pop-item"
      class={[
        @classes,
        @auto? &&
          "relative [&.phx-click-loading]:pointer-events-none [&.phx-click-loading]:cursor-progress [&.phx-click-loading]:opacity-60"
      ]}
      role={@role}
      type={@type}
      aria-disabled={@aria_disabled}
      {@rest}
    >
      <.item_body
        keys={@keys}
        selected={@selected}
        icons={@icon}
        icon_name={@icon_name}
        trailing={@trailing}
        description={@description}
        media={@variant == "media"}
      >
        {render_slot(@inner_block)}
      </.item_body><span
        :if={@auto?}
        data-part="pop-item-spinner"
        aria-hidden="true"
        class={[@auto_spin, "top-1/2 right-2 -mt-2 text-muted"]}
      ></span>
    </button>
    """
  end

  attr :keys, :list, required: true
  attr :selected, :boolean, required: true
  attr :icons, :list, required: true
  attr :icon_name, :string, default: nil
  attr :trailing, :list, required: true
  attr :description, :string, default: nil
  attr :media, :boolean, default: false
  slot :inner_block, required: true

  defp item_body(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, end_cls: item_end_classes(), kbd: kbd_classes())
    assigns = settle(assigns, changed0, end_cls: [], kbd: [])

    ~H"""
    {LedgerUI.Helpers.render_slot_full(@icons)}<.icon :if={@icon_name} name={@icon_name} /><span
      :if={@description || @media}
      data-part="pop-item-text"
      class="flex flex-col leading-[17px]"
    >{render_slot(@inner_block)}<small
      :if={@description}
      data-part="pop-item-hint"
      class="text-[12px] text-muted"
    >{@description}</small></span>
    <%= if !(@description || @media) do %>
      {render_slot(@inner_block)}
    <% end %>
    <span
      :if={@keys != [] or @trailing != [] or @selected}
      data-part="pop-end"
      class={@end_cls}
    ><kbd :for={key <- @keys} data-part="pop-kbd" class={@kbd}>{key}</kbd>{render_slot(@trailing)}<.icon
      :if={@selected}
      data-part="pop-check"
      name="check"
      size="sm"
    /></span>
    """
  end

  defp two_line?(%{two_line: true}), do: true
  defp two_line?(%{two_line: "auto", description: d}), do: d not in [nil, ""]
  defp two_line?(_), do: false

  defp keys(nil, _shortcut), do: []
  defp keys(kbd, nil), do: [kbd]
  defp keys(shortcut, _shortcut), do: String.split(shortcut, " ", trim: true)

  # ---------------------------------------------------------------------------------------
  # dropdown_separator / label / header / search

  attr :class, :any, default: nil
  attr :rest, :global

  def dropdown_separator(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :classes, [separator_classes(), assigns.class])
    assigns = settle(assigns, changed0, classes: [:class])

    ~H"""
    <div data-part="pop-separator" class={@classes} role="separator" {@rest}></div>
    """
  end

  attr :width, :string,
    default: nil,
    doc: "A width utility of the box (`\"w-[230px]\"`); by default `min-w-[220px]`."

  attr :highlight, :boolean,
    default: false,
    doc: "Walks a highlight over the items (set `style=\"--dl:1s\"` on each for the stagger)."

  attr :class, :any, default: nil, doc: "Layout only (`mt-4`)."
  attr :rest, :global
  slot :inner_block, required: true, doc: "`dropdown_item`s, separators and labels."

  @doc """
  The menu box on its own, always visible and in the flow of the page (no trigger, no top layer, no hook):
  the same surface as the open menu of `dropdown/1` and `context_menu/1`. For a menu shown
  in the page (docs, previews, a static list of actions).

      <.menu_panel width="w-[230px]">
        <.dropdown_item><:icon><.icon name="edit" /></:icon>Rename</.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item danger>Delete</.dropdown_item>
      </.menu_panel>
  """
  def menu_panel(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(assigns, :box, [
        pop_classes(min: assigns.width || "min-w-[220px]", highlight: assigns.highlight),
        assigns.class
      ])

    assigns = settle(assigns, changed0, box: [:width, :highlight, :class])

    ~H"""
    <div data-part="pop" class={@box} role="menu" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_label(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :classes, [label_classes(), assigns.class])
    assigns = settle(assigns, changed0, classes: [:class])

    ~H"""
    <div data-part="pop-label" class={@classes} role="presentation" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_header(assigns) do
    ~H"""
    <div data-part="pop-head" class={["px-2.5 pt-2 pb-1.5", @class]} {@rest}>
      <div data-part="pop-head-title" class="font-medium text-ink">{render_slot(@inner_block)}</div>
      <div :if={@subtitle} data-part="pop-head-subtitle" class="text-[12px] text-muted">
        {@subtitle}
      </div>
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
    <div
      data-part="pop-search"
      class={[
        "-mx-[5px] -mt-[5px] mb-[5px] flex h-9 items-center gap-2 border-b border-line px-2.5 text-muted",
        @class
      ]}
    >
      <.icon name="search" />
      <input
        data-part="pop-search-input"
        type="text"
        name={@name}
        value={@value}
        placeholder={@placeholder}
        class="flex-1 border-0 bg-transparent px-0.5 py-px text-[14px] outline-0"
        {@rest}
      />
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
    changed0 = assigns.__changed__
    input_id = assigns.id || derive_id(assigns.name, assigns.value)

    assigns =
      assigns
      |> assign(:role, role)
      |> assign(:type, type)
      |> assign(:input_id, input_id)
      |> assign(
        :classes,
        item_classes(
          check: true,
          checkable: true,
          class: assigns.class
        )
      )
      |> assign(:ck_style, if(!assigns.checked, do: "visibility:hidden"))
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))
      |> assign(:end_cls, item_end_classes())

    assigns =
      settle(assigns, changed0,
        role: [],
        type: [],
        input_id: [:id, :name, :value],
        classes: [:class],
        ck_style: [:checked],
        aria_disabled: [:disabled],
        end_cls: []
      )

    ~H"""
    <button
      data-part="pop-item"
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
      />{render_slot(@inner_block)}<span data-part="pop-end" class={@end_cls}><span :if={
        @count != nil
      }>{@count}</span><.icon
        data-part="pop-check"
        name="check"
        size="sm"
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
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(
        :box_class,
        cx([
          pop_classes(min: "min-w-[180px]"),
          "absolute -top-1.5 z-[2] w-max",
          assigns.class
        ])
      )
      |> assign(
        :trigger_classes,
        item_classes(
          class: ["relative aria-expanded:bg-hover aria-expanded:text-ink", assigns.trigger_class]
        )
      )
      |> assign(:aria_disabled, if(assigns.disabled, do: "true"))
      |> assign(:left?, assigns.placement == "left")
      |> assign(:end_cls, item_end_classes())

    assigns =
      settle(assigns, changed0,
        box_class: [:class],
        trigger_classes: [:trigger_class],
        aria_disabled: [:disabled],
        left?: [:placement],
        end_cls: []
      )

    ~H"""
    <div
      id={@id}
      data-part="dropdown-submenu"
      data-dd="sub"
      data-placement={@left? && "left"}
      class="relative"
      {@rest}
    >
      <button
        data-part="pop-item"
        class={@trigger_classes}
        role="menuitem"
        type="button"
        aria-haspopup="menu"
        aria-expanded="false"
        aria-disabled={@aria_disabled}
      >
        {render_slot(@icon)}{@label}<span data-part="pop-end" class={@end_cls}><.badge
          :if={@count != nil}
          canvas
          color="primary"
          size="sm"
          data-dd="count"
          hidden={@count == 0}
        >
          {@count}
        </.badge><.icon name="chevron-right" size="sm" /></span>
      </button>
      <div
        data-part="pop"
        class={@box_class}
        data-dd="subpop"
        role="menu"
        hidden
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # footer

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

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
    changed0 = assigns.__changed__
    clear = assigns.clear_label || I18n.t("dropdown.clear", assigns.locale)
    apply = assigns.apply_label || I18n.t("dropdown.apply", assigns.locale)
    apply = if assigns.apply_count, do: "#{apply} (#{assigns.apply_count})", else: apply

    assigns =
      assigns
      |> assign(:clear, clear)
      |> assign(:apply, apply)
      |> assign(:on_clear_js, to_js(assigns.on_clear, nil, assigns.target))
      |> assign(:on_apply_js, to_js(assigns.on_apply, nil, assigns.target))
      |> assign(:apply_type, if(assigns.on_apply, do: "button", else: "submit"))
      |> assign(:clear_class, Button.classes("neutral", "ghost", "sm", "rounded"))
      |> assign(:apply_class, Button.classes(assigns.apply_color, "solid", "sm", "rounded"))

    # `clear` and `apply` read the process locale when neither the text nor `locale` is given.
    assigns =
      settle(
        assigns,
        changed0,
        [
          on_clear_js: [:on_clear, :target],
          on_apply_js: [:on_apply, :target],
          apply_type: [:on_apply],
          clear_class: [],
          apply_class: [:apply_color]
        ] ++
          if(assigns.clear_label || assigns.locale,
            do: [clear: [:clear_label, :locale]],
            else: []
          ) ++
          if(assigns.apply_label || assigns.locale,
            do: [apply: [:apply_label, :apply_count, :locale]],
            else: []
          )
      )

    ~H"""
    <div
      data-part="pop-foot"
      class={["mt-[5px] flex justify-end gap-1.5 border-t border-line pt-1.5", @class]}
      {@rest}
    >
      <button
        data-part="button"
        class={@clear_class}
        role="menuitem"
        type="button"
        data-dd="clear"
        phx-click={@on_clear_js}
      >
        {@clear}
      </button>
      <button
        :if={@show_apply}
        data-part="button"
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

  # ---------------------------------------------------------------------------------------
  # action_button: the direct button of an item with a single action

  @action_variants ~w(solid glow outline soft bordered flat glass ghost dim)
  @action_sizes ~w(xs sm md lg xl)

  @doc """
  A `button/1`-looking icon button for an item with a single action (`danger` makes it the `error`
  colour). `data-part="action-button"`.

      <.action_button label="Delete" icon="huge-delete-02" danger phx-click="delete" />
  """
  attr :label, :string, required: true, doc: "Accessible name (`aria-label`)."
  attr :icon, :string, default: nil
  attr :danger, :boolean, default: false
  attr :variant, :string, default: "outline", values: @action_variants
  attr :size, :string, default: "sm", values: @action_sizes
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download target rel form name value disabled type)

  slot :inner_block

  def action_button(assigns) do
    changed0 = assigns.__changed__

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

    assigns =
      assign(
        assigns,
        :link_attrs,
        assigns.link? &&
          LedgerUI.LinkAttrs.resolve(assigns.rest, ["data-part", "aria-label", "class"])
      )

    # `inner_block` is not a source: whether the button has content is fixed by the call site.
    assigns =
      settle(assigns, changed0,
        classes: [:danger, :variant, :size, :class],
        link?: [:rest],
        link_attrs: [:rest]
      )

    ~H"""
    <a :if={@link?} data-part="action-button" aria-label={@label} class={@classes} {@link_attrs}>
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}
    </a>
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
