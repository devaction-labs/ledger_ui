defmodule LedgerUI.Components.Sidebar do
  @moduledoc """
  The side menu of the shell, in four formats that read the same data:

    * `sections` (default): the brand with a company switcher, groups with an uppercase mono
      label, "settings and help" at the foot and the plan card.
    * `rail`: a 64px rail of icons (logo, home, one icon per group, extra apps in coloured circles,
      the foot items) beside the panel of the active module (title, create button, items, "try"
      shortcuts, trial card).
    * `tree`: the brand with a collapse button, collapsible groups, children joined by a line,
      square coloured icons and the user card at the foot.
    * `nested`: the shadcn/ui sidebar: team switcher, quiet group labels, items with children and
      the user at the foot, both able to open a menu.

          <.sidebar format="rail" nav={MyAppWeb.Nav.items(assigns)} current={@current_path}
            brand={%{name: "Ledger", logo: "S"}} user={%{name: "Marina Costa", email: "marina@ledger.com"}} />

  Changing `format` changes how the menu is drawn, never the items.

  ## `variant`

  `"floating"` (default) is the card with corners and a shadow, `"sidebar"` sits flush on the shell
  background, `"inset"` drops the card too.

  ## The menu data

  `nav` is a list of maps, in order. A map with `group` is a group, any other is an item.

  Item keys: `label`, `icon` (a short name of the table in the README, or any icon name), `navigate`
  / `patch` / `href`, `count`, `badge`, `color`, `children`, `collapsible`, `open`, `active`,
  `kbd` (a shortcut at the right), `caret` (`"down"` | `"right"`: a chevron at the end without children), `loose` (drawn outside the column of the items around it), `current`, `match` (`"exact"` | `"prefix"`), `disabled` (a "coming soon" item: a `span` with
  `aria-disabled="true"`), `title`, `formats` and `style`.

  Group keys: `group`, `icon`, `items`, `collapsible`, `open`, `navigate` / `patch` / `href`,
  `footer: true` (the foot of the menu), `action` (`%{label, navigate, icon}`) and `try`
  (`%{label, items}`) for the rail panel.

  ## Configuration

      config :ledger_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}, footer: :version, version: "v1.4.2"

  What you pass always wins.

  ## The foot

  `footer`: `"user"` (the user card / the avatar of the rail), `"version"` (the version line:
  a status dot, `v1.4.2`, the build and a "What's new" link; `version` is a string or
  `%{version, build, navigate, label, title, status}`), `"none"`, or left out (each format's own).

  ## Collapsing

  Styled only with utilities: the menu is the `group/side` of its parts, which read `data-collapsed`.
  Every format collapses to icons (tooltips with the label, counts turn into dots) with the
  `LedgerUI.Sidebar` hook: `collapsed` is the start, `on_collapse` is pushed with
  `%{"id" => id, "collapsed" => boolean}`, the choice is kept in `localStorage["ledger-rail"]`
  (`persist`), `rail_toggle/1` collapses it from anywhere and so does Ctrl/Cmd + `shortcut`.
  Below 768px the menu is a top bar with a hamburger.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Dropdown
  import LedgerUI.Components.Avatar, only: [avatar: 1]
  import LedgerUI.Components.Badge, only: [badge: 1]
  import LedgerUI.Components.Button, only: [button: 1]
  import LedgerUI.Components.Typography, only: [kbd: 1]

  import LedgerUI.Components.Shell,
    only: [
      nav_caret_classes: 0,
      nav_h_classes: 0,
      nav_h_classes: 1,
      nav_item_classes: 1,
      nav_r_classes: 0,
      nav_r_classes: 1,
      nav_sep_classes: 0,
      person_classes: 0,
      person_name_classes: 0,
      person_text_classes: 0,
      person_sub_classes: 0,
      rail_btn_classes: 1,
      rail_count_classes: 0,
      rail_logo_classes: 0,
      side_hidden: 0,
      subnav_classes: 0,
      subnav_title_classes: 0,
      tbtn_classes: 0,
      user_classes: 0,
      ws_classes: 0,
      ws_classes: 1,
      ws_logo_classes: 0,
      ws_name_classes: 0,
      ws_sub_classes: 0,
      ws_text_classes: 0
    ]

  @icon_map %{
    "add" => "plus",
    "bank" => "bank",
    "bell" => "bell",
    "box" => "package",
    "calendar" => "calendar",
    "cancel" => "x-circle",
    "card" => "card",
    "cart" => "cart",
    "chart" => "bar",
    "clock" => "clock",
    "doc" => "file",
    "filter" => "filter",
    "flash" => "zap",
    "globe" => "globe",
    "goal" => "target",
    "heart" => "star",
    "help" => "help",
    "home" => "home",
    "invoice" => "invoice",
    "kanban" => "kanban",
    "message" => "message",
    "money" => "cash",
    "pin" => "pin",
    "settings" => "settings",
    "sidebar" => "sidebar",
    "spark" => "sparkles",
    "tag" => "tag",
    "trend" => "trend-up",
    "truck" => "truck",
    "user" => "user",
    "users" => "users",
    "wallet" => "wallet"
  }

  @colors %{
    "blue" => "#3b82f6",
    "green" => "#22a06b",
    "rose" => "#e5484d",
    "violet" => "#8b5cf6",
    "orange" => "#f59e0b",
    "ink" => "var(--lu-ink)"
  }

  @statuses %{"ok" => "", "warning" => "warn", "down" => "bad"}

  attr :id, :string, default: "sidebar"
  attr :format, :any, default: nil
  attr :nav, :list, default: nil

  attr :current, :any,
    default: nil,
    doc:
      "The current path, matched against the items' links; or, with `<:item>` slots, an item's `name`."

  attr :brand, :map, default: nil

  attr :workspace, :map,
    default: nil,
    doc:
      "The workspace the menu belongs to, `%{name:, context:}`: a `brand` (the chart mark, the name and the muted context line) when `brand` is not given."

  attr :views_label, :string,
    default: nil,
    doc: "The caption of the group of the `<:view>` items."

  attr :user, :map, default: nil
  attr :footer, :any, default: nil
  attr :show_user, :boolean, default: nil
  attr :version, :any, default: nil
  attr :plan, :map, default: nil
  attr :trial, :map, default: nil
  attr :rail_extra, :list, default: []
  attr :collapsible, :boolean, default: true
  attr :match, :string, default: "exact", values: ~w(exact prefix)
  attr :persist_groups, :boolean, default: false
  attr :collapsed, :boolean, default: false

  attr :collapsed_width, :integer,
    default: nil,
    doc:
      "The width of the collapsed menu in px (default 60). Sets `--lu-rail-collapsed` on the menu; the variable can also be set in CSS."

  attr :persist, :boolean, default: true
  attr :on_collapse, :string, default: nil
  attr :target, :any, default: nil
  attr :shortcut, :string, default: "b"
  attr :variant, :string, default: "floating", values: ~w(floating sidebar inset)
  attr :label, :any, default: :default
  attr :collapse_label, :string, default: nil
  attr :mobile_label, :string, default: nil

  attr :nav_class, :any,
    default: nil,
    doc:
      "Classes of the column that holds the items (an `animate-[…]` utility can highlight them in turn)."

  attr :flat, :boolean,
    default: false,
    doc: "Draws the items straight in the menu, without the column that wraps a run of them."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :item,
    doc:
      "A link of the menu, its content the label, instead of `nav` (the same keys as an item of `nav`)." do
    attr :icon, :string
    attr :name, :any, doc: "Marks the item active when `current` is this name."
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :badge, :any
    attr :count, :any
    attr :tone, :string, doc: "`neg`, `pos`, `warn`, `info`: the colour of the badge."
    attr :active, :boolean

    attr :label, :string,
      doc:
        "The text, also the tooltip and the accessible name of the collapsed and rail menus; the content when not given."
  end

  slot :view, doc: "A saved view: an item of the group `views_label` after the `<:item>`s." do
    attr :icon, :string
    attr :name, :any
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :count, :any
    attr :label, :string
  end

  slot :brand_mark, doc: "Replaces the logo and the name of the brand."
  slot :mobile_drawer, doc: "Content of the menu body shown only below 768px."
  slot :sidebar_footer, doc: "At the end of the foot of the menu."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def sidebar(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, [label: "shell.main_menu"], :default)

    assigns =
      I18n.texts(assigns,
        views_label: "sidebar.views",
        collapse_label: "shell.collapse_menu",
        mobile_label: "landing_nav.menu"
      )

    cfg = Application.get_env(:ledger_ui, :shell, [])
    format = to_string(assigns.format || cfg[:sidebar] || "sections")

    assigns =
      assigns
      |> assign(:fmt, format)
      |> assign(:classes, root_classes(format, assigns.variant, assigns.class))
      |> assign(:burger_class, burger_class())
      |> assign(:persist_attr, if(assigns.persist, do: "true", else: "false"))
      |> assign(:shortcut_attr, assigns.shortcut)
      |> assign(:style_attrs, style_attrs(assigns.collapsed_width, assigns.rest[:style]))

    # `fmt` reads the `:shell` config when `format` is not given: it is derived from `format` only
    # when it is.
    assigns =
      settle(
        assigns,
        changed0,
        opt(assigns.format, fmt: [:format]) ++
          [
            classes: [:fmt, :variant, :class],
            burger_class: [],
            persist_attr: [:persist],
            shortcut_attr: [:shortcut],
            style_attrs: [:collapsed_width, :rest]
          ]
      )

    # The body takes the attributes one by one (raw, as the caller gave them) and works out the
    # entries itself: the menu is the heavy part and does not depend on the state of the root
    # (`collapsed`, `class`...), so a render that only changes those does not send it again.
    ~H"""
    <aside
      id={@id}
      data-part="sidebar"
      phx-hook="LedgerUI.Sidebar"
      data-lu-collapsed={to_string(@collapsed)}
      data-lu-persist={@persist_attr}
      data-lu-shortcut={@shortcut_attr}
      data-lu-on-collapse={@on_collapse}
      data-lu-target={is_binary(@target) && @target}
      data-lu-groups={@persist_groups && "true"}
      data-lu-collapse-label={@collapse_label}
      data-lu-mobile-label={@mobile_label}
      aria-label={@label}
      data-lu-format={@fmt != "sections" && @fmt}
      data-lu-burger-class={@burger_class}
      data-collapsed={@collapsed && ""}
      class={@classes}
      {@style_attrs}
      {Map.delete(@rest, :style)}
    >
      <.sb_body
        id={@id}
        format={@format}
        nav={@nav}
        item={@item}
        view={@view}
        views_label={@views_label}
        current={@current}
        match={@match}
        brand={@brand}
        workspace={@workspace}
        brand_mark={@brand_mark}
        user={@user}
        footer={@footer}
        show_user={@show_user}
        version={@version}
        plan={@plan}
        trial={@trial}
        rail_extra={@rail_extra}
        collapsible={@collapsible}
        collapse_label={@collapse_label}
        label={@label}
        locale={@locale}
        nav_class={@nav_class}
        flat={@flat}
        mobile_drawer={@mobile_drawer}
        sidebar_footer={@sidebar_footer}
      />
    </aside>
    """
  end

  # The content of the menu. Called directly with the format function, so that the template of the
  # format tracks the changes of the attributes it got (no spread of all the assigns).
  defp sb_body(assigns) do
    changed0 = assigns.__changed__
    cfg = Application.get_env(:ledger_ui, :shell, [])
    format = to_string(assigns.format || cfg[:sidebar] || "sections")

    current = assigns.current && to_string(assigns.current)

    nav =
      assigns.nav || slot_nav(assigns, current) || config_nav(cfg[:nav], assigns) || []

    brand = assigns.brand || workspace_brand(assigns.workspace)

    version = assigns.version || cfg[:version]

    footer =
      footer_mode(assigns.footer || cfg[:footer], assigns.show_user, cfg[:show_user], version)

    entries = normalize(nav, format, current, assigns.match)

    assigns =
      assigns
      |> assign(:format, format)
      |> assign(:entries, entries)
      |> assign(:footer_mode, footer)
      |> assign(:version_map, version_map(version))
      |> assign(:brand_map, brand || %{})

    # What reads the `:shell` config or calls the `nav` function of the config is left out: it is
    # sent every time (and what lists it as a source with it).
    assigns = assign(assigns, :foot?, has_foot?(assigns))

    assigns =
      settle(
        assigns,
        changed0,
        opt(assigns.format, format: []) ++
          opt(assigns.nav && assigns.format, entries: [:nav, :format, :current, :match]) ++
          [brand_map: [:brand, :workspace]] ++
          opt(assigns.version, version_map: [:version]) ++
          [
            foot?: [:entries, :footer_mode, :plan, :user, :version_map, :sidebar_footer]
          ]
      )

    case format do
      "tree" -> sb_tree(assigns)
      "rail" -> sb_rail(assigns)
      "nested" -> sb_nested(assigns)
      _ -> sb_sections(assigns)
    end
  end

  defp style_attrs(width, style) do
    [width && "--lu-rail-collapsed: #{width}px", style]
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Enum.join(";")
    |> then(&if(&1 == "", do: [], else: [style: &1]))
  end

  # The hook creates the burger (below 768px) with these utilities.
  defp burger_class do
    cx([
      tbtn_classes(),
      "hidden max-md:absolute max-md:top-2.5 max-md:right-3 max-md:inline-grid!"
    ])
  end

  ## Root look

  @root "group/side flex flex-none " <>
          "max-md:m-0 max-md:min-h-0! max-md:w-auto! max-md:flex-col max-md:rounded-none max-md:shadow-none " <>
          "max-md:[&:not([data-mobile-open])>*:not([data-lu-sb-burger]):not([data-part=brand]):not([data-part=team]):not(:first-child)]:hidden"
  @collapsible "data-[collapsed]:w-(--lu-rail-collapsed,60px) data-[collapsed]:overflow-visible data-[collapsed]:px-2"
  @looks %{
    "floating" =>
      "m-2.5 rounded-xl bg-panel shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-md)]",
    "sidebar" => "bg-shell",
    "inset" => "bg-transparent"
  }

  defp root_classes("rail", variant, class) do
    # the rail format is two boxes side by side: no width, padding or background of its own
    cx([@root, "w-auto flex-row p-0", rail_look(variant), class])
  end

  defp root_classes(_, variant, class),
    do: cx([@root, "w-[260px] flex-col gap-0.5 p-3", @collapsible, @looks[variant], class])

  defp rail_look("floating"),
    do: "m-2.5 rounded-xl bg-transparent shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-md)]"

  defp rail_look(_), do: "bg-transparent"

  ## Formats

  # `kw` when `cond` is truthy, else `[]`.
  defp opt(cond, kw), do: if(cond, do: kw, else: [])

  defp has_foot?(a) do
    foot_groups(a.entries) != [] or
      (a.footer_mode in ["plan", "user"] and (a.plan || a.user) != nil) or
      (a.footer_mode == "version" and a.version_map != nil) or a.sidebar_footer != []
  end

  defp grow(assigns) do
    ~H"""
    <div data-part="sidebar-spacer" class="min-w-0 flex-1"></div>
    """
  end

  attr :drawer, :list, required: true

  defp drawer(assigns) do
    ~H"""
    <div
      :if={@drawer != []}
      data-part="sidebar-drawer"
      class="hidden group-data-[mobile-open]/side:block!"
    >
      {LedgerUI.Helpers.render_slot_full(@drawer)}
    </div>
    """
  end

  defp sb_sections(assigns) do
    ~H"""
    <.sb_brand brand={@brand_map} brand_mark={@brand_mark} />
    <.sb_entries entries={@entries} format="sections" id={@id} nav_class={@nav_class} flat={@flat} />
    <.grow :if={@foot?} />
    <.sb_plan :if={@footer_mode in ["plan", "user"] and @plan} plan={@plan} />
    <div :if={foot_groups(@entries) != []} data-part="sidebar-sections-footer" class="mt-2">
      <.sb_item :for={item <- foot_items(@entries)} item={item} format="sections" id={@id} />
    </div>
    <.sb_user :if={@footer_mode == "user" and @user} user={@user} />
    <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
    {render_slot(@sidebar_footer)}
    <.drawer drawer={@mobile_drawer} />
    """
  end

  defp sb_tree(assigns) do
    ~H"""
    <div
      :if={@brand_map != %{} or @brand_mark != [] or @collapsible}
      data-part="sidebar-tree-head"
      class="flex items-center gap-2"
    >
      <div data-part="sidebar-tree-brand" class="min-w-0 flex-1">
        <.sb_brand brand={@brand_map} brand_mark={@brand_mark} switch={false} />
      </div>
      <button
        :if={@collapsible}
        data-part="sidebar-tree-button"
        type="button"
        data-lu-sb-toggle
        aria-label={@collapse_label}
        class={[
          "relative mb-2.5 grid size-8 shrink-0 cursor-pointer place-items-center rounded-md border border-line bg-panel text-ink-2 hover:bg-hover"
        ]}
      >
        <.icon name="sidebar" />
      </button>
    </div>
    <.sb_entries entries={@entries} format="tree" id={@id} nav_class={@nav_class} flat={@flat} />
    <.grow :if={@foot?} />
    <div :if={foot_groups(@entries) != []}>
      <.sb_item :for={item <- foot_items(@entries)} item={item} format="tree" id={@id} />
    </div>
    <.sb_user :if={@footer_mode in ["user", "plan"] and @user} user={@user} />
    <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
    {render_slot(@sidebar_footer)}
    <.drawer drawer={@mobile_drawer} />
    """
  end

  defp sb_nested(assigns) do
    ~H"""
    <.sb_team brand={@brand_map} id={@id} />
    <.sb_entries entries={@entries} format="nested" id={@id} nav_class={@nav_class} flat={@flat} />
    <.grow :if={@foot?} />
    <div :if={foot_groups(@entries) != []}>
      <.sb_item :for={item <- foot_items(@entries)} item={item} format="nested" id={@id} />
    </div>
    <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
    <.sb_user_menu :if={@footer_mode in ["user", "plan"] and @user} user={@user} id={@id} />
    {render_slot(@sidebar_footer)}
    <.drawer drawer={@mobile_drawer} />
    """
  end

  defp sb_rail(assigns) do
    changed0 = assigns.__changed__
    assigns = assign_new(assigns, :locale, fn -> nil end)

    entries = assigns.entries
    groups = for {:group, g} <- entries, !g[:footer], do: g

    home =
      Enum.find_value(entries, fn
        {:item, i} -> i
        _ -> nil
      end)

    others = for {:item, i} <- entries, i != home, do: i
    foots = for {:group, g} <- entries, g[:footer], item <- g.items, do: item
    active = Enum.find(groups, &group_active?/1) || List.first(groups)

    assigns =
      assign(assigns,
        groups: groups,
        home: home,
        others: others,
        foots: foots,
        active_group: active
      )

    assigns =
      settle(assigns, changed0,
        groups: [:entries],
        home: [:entries],
        others: [:entries, :home],
        foots: [:entries],
        active_group: [:groups]
      )

    ~H"""
    <nav
      data-part="sidebar-rail-nav"
      aria-label={@label}
      class="flex w-16 flex-none flex-col items-center gap-1.5 bg-shell py-3"
    >
      <span data-part="rail-logo" class={rail_logo_classes()}>
        <img
          :if={@brand_map[:src]}
          data-part="sidebar-rail-img"
          src={@brand_map[:src]}
          alt=""
          class="absolute inset-0 size-full rounded-[inherit] object-cover"
        />
        <span :if={!@brand_map[:src]}>{@brand_map[:logo] || first_letter(@brand_map[:name])}</span>
      </span>
      <.rail_btn :if={@home} item={@home} />
      <.sb_avatar :if={@user && @footer_mode == "user"} user={@user} size={32} />
      <.rail_btn :for={g <- @groups} item={group_as_item(g)} on={g == @active_group} />
      <.rail_extra_btn :for={x <- @rail_extra} app={x} />
      <.rail_btn :for={i <- @others} item={i} />
      <.grow />
      <.rail_btn :for={i <- @foots} item={i} />
      <button
        :if={@collapsible}
        data-part="sidebar-rail-button"
        type="button"
        data-lu-sb-toggle
        class={rail_btn_classes(false)}
        aria-label={@collapse_label}
      >
        <.icon name="sidebar" />
      </button>
    </nav>
    <div
      :if={@active_group}
      data-part="rail-panel"
      data-lu-subnav
      class={[subnav_classes(), "rounded-r-xl bg-panel group-data-[collapsed]/side:hidden"]}
    >
      <h4 data-part="sidebar-rail-title" class={subnav_title_classes()}>{@active_group.group}</h4>
      <.button
        :if={@active_group[:action]}
        canvas
        appearance="primary"
        {dest(@active_group.action) || [href: "#"]}
        class="mb-2.5 w-full"
      >
        <.icon :if={@active_group.action[:icon]} name={sb_icon(@active_group.action[:icon])} />{@active_group.action[
          :label
        ]}
      </.button>
      <.sb_group_items items={@active_group.items} id={@id} />
      <div :if={@active_group[:try]} data-part="sidebar-rail-try-heading" class={nav_h_classes()}>
        {@active_group.try[:label] || I18n.t("sidebar.try", @locale)}
      </div>
      <.sb_item
        :for={i <- (@active_group[:try] || %{})[:items] || []}
        item={normalize_item(i, "rail", @current, @match)}
        format="rail"
        id={@id}
      />
      <.grow />
      <.sb_trial :if={@trial} trial={@trial} />
      <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
      {render_slot(@sidebar_footer)}
      <.drawer drawer={@mobile_drawer} />
    </div>
    """
  end

  ## Pieces

  attr :brand, :map, required: true
  attr :brand_mark, :list, default: []
  attr :switch, :boolean, default: true

  defp sb_brand(assigns) do
    changed0 = assigns.__changed__
    brand = assigns.brand
    switch = Map.get(brand, :switch, true)
    click = is_map(switch) && switch[:click]

    assigns =
      assigns
      |> assign(:show_switch, assigns.switch and switch != false)
      |> assign(:click, click)
      |> assign(:switch_label, is_map(switch) && switch[:label])

    assigns =
      settle(assigns, changed0,
        show_switch: [:switch, :brand],
        click: [:brand],
        switch_label: [:brand]
      )

    ~H"""
    <div
      :if={@brand != %{} or @brand_mark != []}
      class={ws_classes()}
      data-part="brand"
      role={@click && "button"}
      phx-click={@click}
      aria-label={@switch_label}
    >
      <%= if @brand_mark != [] do %>
        {render_slot(@brand_mark)}
      <% else %>
        <span data-part="sidebar-brand-logo" class={ws_logo_classes()}>
          <img
            :if={@brand[:src]}
            data-part="sidebar-brand-img"
            src={@brand[:src]}
            alt=""
            class="absolute inset-0 size-full rounded-[inherit] object-cover"
          />
          <.chart_mark :if={!@brand[:src] and @brand[:mark]} />
          <%= if !@brand[:src] and !@brand[:mark] do %>
            {@brand[:logo] || first_letter(@brand[:name])}
          <% end %>
        </span>
        <span data-part="sidebar-brand-text" class={ws_text_classes()}>
          <b data-part="sidebar-brand-name" class={ws_name_classes()}>{@brand[:name]}</b>
          <span :if={@brand[:sub]} data-part="sidebar-brand-sub" class={ws_sub_classes()}>{@brand[
            :sub
          ]}</span>
        </span>
      <% end %>
      <.icon
        :if={@show_switch and @brand != %{} and @brand_mark == [] and Map.has_key?(@brand, :switch)}
        name="updown"
        size="md"
        class={["text-ink", side_hidden()]}
      />
    </div>
    """
  end

  defp chart_mark(assigns) do
    ~H"""
    <svg
      data-part="sidebar-chart-mark"
      aria-hidden="true"
      height="18"
      class="fill-none stroke-current stroke-2 [stroke-linecap:round] [stroke-linejoin:round]"
      viewBox="0 0 24 24"
      width="18"
    >
      <path d="M4 19V5"></path>
      <path d="M4 19h16"></path>
      <path d="m8 14 3.5-4 3 2.5L19 7"></path>
    </svg>
    """
  end

  attr :brand, :map, required: true
  attr :id, :string, required: true

  defp sb_team(assigns) do
    changed0 = assigns.__changed__
    menu = assigns.brand[:menu]
    assigns = assign(assigns, :menu, menu)
    assigns = settle(assigns, changed0, menu: [:brand])

    ~H"""
    <div data-part="sidebar-team-wrap" class="relative">
      <button
        type="button"
        class={[ws_classes(mb: "mb-1.5"), "w-full text-left"]}
        data-part="team"
        aria-haspopup={@menu && "menu"}
        phx-click={@menu && JS.toggle_attribute({"hidden", "hidden"}, to: "##{@id}-team")}
      >
        <span data-part="sidebar-team-logo" class={ws_logo_classes()}>
          <img
            :if={@brand[:src]}
            data-part="sidebar-team-img"
            src={@brand[:src]}
            alt=""
            class="absolute inset-0 size-full rounded-[inherit] object-cover"
          />
          <%= if !@brand[:src] do %>
            {@brand[:logo] || first_letter(@brand[:name])}
          <% end %>
        </span>
        <span data-part="sidebar-team-text" class={ws_text_classes()}>
          <b data-part="sidebar-team-name" class={ws_name_classes()}>{@brand[:name]}</b>
          <span :if={@brand[:plan]} data-part="sidebar-team-plan" class={ws_sub_classes()}>{@brand[
            :plan
          ]}</span>
        </span>
        <.icon name="updown" size="md" class={["text-ink", side_hidden()]} />
      </button>
      <div
        :if={@menu}
        data-part="sidebar-team-popover"
        id={"#{@id}-team"}
        class={cx([Dropdown.pop_classes(), "absolute left-full top-0 z-50 ml-2"])}
        role="menu"
        hidden
        keep-hidden
        phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@id}-team")}
      >
        <.sb_menu items={@menu} />
      </div>
    </div>
    """
  end

  attr :user, :map, required: true
  attr :id, :string, required: true

  defp sb_user_menu(assigns) do
    ~H"""
    <div data-part="sidebar-user-menu-wrap" class="relative">
      <div
        data-part="sidebar-user-menu-trigger"
        class={[user_classes(), "cursor-pointer"]}
        role={@user[:menu] && "button"}
        tabindex={@user[:menu] && "0"}
        phx-click={@user[:menu] && JS.toggle_attribute({"hidden", "hidden"}, to: "##{@id}-user")}
      >
        <.sb_avatar user={@user} size={36} />
        <span data-part="sidebar-user-menu-person" class={[person_classes(), "min-w-0 flex-1"]}>
          <span data-part="sidebar-user-menu-text" class={person_text_classes()}>
            <b data-part="sidebar-user-menu-name" class={person_name_classes()}>{@user[:name]}</b>
            <span
              :if={@user[:role] || @user[:email]}
              data-part="sidebar-user-menu-sub"
              class={person_sub_classes()}
            >{@user[:role] ||
              @user[:email]}</span>
          </span>
        </span>
        <.icon name="updown" size="md" class={["text-ink", side_hidden()]} />
      </div>
      <div
        :if={@user[:menu]}
        data-part="sidebar-user-menu-popover"
        id={"#{@id}-user"}
        class={cx([Dropdown.pop_classes(), "absolute bottom-0 left-full z-50 ml-2"])}
        role="menu"
        hidden
        keep-hidden
        phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@id}-user")}
      >
        <div data-part="sidebar-user-menu-head" class={[person_classes(), "px-2.5 py-2"]}>
          <.sb_avatar user={@user} size={32} />
          <span data-part="sidebar-user-menu-head-text" class={person_text_classes()}><b
            data-part="sidebar-user-menu-head-name"
            class={person_name_classes()}
          >{@user[:name]}</b><span
            :if={@user[:role] || @user[:email]}
            data-part="sidebar-user-menu-head-sub"
            class={person_sub_classes()}
          >{@user[:role] ||
            @user[:email]}</span></span>
        </div>
        <div data-part="sidebar-user-menu-separator" class={Dropdown.separator_classes()}></div>
        <.sb_menu items={@user[:menu]} />
      </div>
    </div>
    """
  end

  attr :items, :list, required: true

  defp sb_menu(assigns) do
    ~H"""
    <%= for m <- @items do %>
      <div
        :if={m == :separator}
        data-part="sidebar-menu-separator"
        class={Dropdown.separator_classes()}
      >
      </div>
      <div
        :if={is_map(m) and m[:heading]}
        data-part="sidebar-menu-heading"
        class={Dropdown.label_classes()}
      >
        {m[:label]}
      </div>
      <%= if is_map(m) and !m[:heading] do %>
        <.link
          :if={dest(m)}
          data-part="sidebar-menu-link"
          {dest(m)}
          method={m[:method]}
          role="menuitem"
          class={Dropdown.item_classes(tone: m[:danger] && "danger")}
        >
          <.icon :if={m[:icon]} name={sb_icon(m[:icon])} />{m[:label]}<span
            :if={m[:hint]}
            data-part="sidebar-menu-item-end"
            class={Dropdown.item_end_classes()}
          >{m[:hint]}</span>
        </.link>
        <button
          :if={!dest(m)}
          data-part="sidebar-menu-button"
          type="button"
          role="menuitem"
          phx-click={m[:click]}
          class={Dropdown.item_classes(tone: m[:danger] && "danger")}
        >
          <.icon :if={m[:icon]} name={sb_icon(m[:icon])} />{m[:label]}<span
            :if={m[:hint]}
            data-part="sidebar-menu-item-end"
            class={Dropdown.item_end_classes()}
          >{m[:hint]}</span>
        </button>
      <% end %>
    <% end %>
    """
  end

  attr :entries, :list, required: true
  attr :format, :string, required: true
  attr :id, :string, required: true
  attr :nav_class, :any, default: nil
  attr :flat, :boolean, default: false

  # Items and groups in order; consecutive ungrouped items share one column.
  defp sb_entries(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :runs, runs(assigns.entries, assigns.flat))
    assigns = settle(assigns, changed0, runs: [:entries, :flat])

    ~H"""
    <%= for run <- @runs do %>
      <div
        :if={match?({:items, _}, run)}
        data-part="sidebar-entries-run"
        class={cx(["flex flex-col gap-0.5", @nav_class])}
      >
        <.sb_item :for={i <- elem(run, 1)} item={i} format={@format} id={@id} />
      </div>
      <div
        :if={match?({:sep, _}, run)}
        data-part="sidebar-entries-separator"
        class={nav_sep_classes()}
      >
      </div>
      <.sb_item :if={match?({:loose, _}, run)} item={elem(run, 1)} format={@format} id={@id} />
      <.sb_group :if={match?({:group, _}, run)} group={elem(run, 1)} format={@format} id={@id} />
    <% end %>
    """
  end

  attr :group, :map, required: true
  attr :format, :string, required: true
  attr :id, :string, required: true

  defp sb_group(%{group: %{footer: true}} = assigns), do: ~H""

  defp sb_group(assigns) do
    g = assigns.group
    collapsible = collapsible?(g, assigns.format)

    assigns =
      assign(assigns,
        collapsible: collapsible,
        open: !collapsible or group_open?(g),
        key: g.group,
        clickable: collapsible or assigns.format == "tree"
      )

    # The heading is a `:for` over one map that holds only what it draws: the LiveView compares
    # the entries and does not send it again when a render changes only the items of the group
    # (a new current page).
    assigns =
      assign(assigns, :heads, [
        %{
          label: g.group,
          collapsible: assigns.collapsible,
          open: assigns.open,
          key: assigns.key,
          clickable: assigns.clickable,
          format: assigns.format,
          id: assigns.id
        }
      ])

    ~H"""
    <div
      :for={h <- @heads}
      phx-no-format
      data-part="sidebar-group-heading"
      class={["group/exp", nav_h_classes(!h.clickable), h.clickable && "cursor-pointer"]}
      data-lu-sb-group={h.collapsible && h.key}
      aria-expanded={h.collapsible && to_string(h.open)}
      aria-controls={h.collapsible && gid(h.id, h.key)}
    >
      <.icon
        :if={h.collapsible && h.format == "tree"}
        name="chevron-down"
        size="sm"
        class="transition-transform duration-150 group-aria-[expanded=false]/exp:-rotate-90"
      />
      {h.label}
      <.icon
        :if={h.collapsible && h.format != "tree"}
        name="chevron-down"
        size="sm"
        class="ml-auto transition-transform duration-150 group-aria-[expanded=false]/exp:-rotate-90"
      />
    </div>
    <div id={gid(@id, @key)} hidden={!@open} keep-hidden>
      <div data-part="sidebar-group-items" class="flex flex-col gap-0.5">
        <.sb_item :for={i <- @group.items} item={i} format={@format} id={@id} />
      </div>
    </div>
    """
  end

  attr :items, :list, required: true
  attr :id, :string, required: true

  # Rail panel: items and nested collapsible groups.
  defp sb_group_items(assigns) do
    ~H"""
    <%= for it <- @items do %>
      <.sb_item :if={it[:group] == nil} item={it} format="rail" id={@id} />
      <.sb_group :if={it[:group] != nil} group={it} format="rail" id={@id} />
    <% end %>
    """
  end

  attr :item, :map, required: true
  attr :format, :string, required: true
  attr :id, :string, required: true

  defp sb_item(%{item: %{disabled: d}} = assigns) when d not in [nil, false] do
    changed0 = assigns.__changed__
    title = assigns.item[:title] || (is_binary(d) && d) || nil
    assigns = assign(assigns, :title, title)
    assigns = settle(assigns, changed0, title: [:item])

    ~H"""
    <span
      data-part="sidebar-item-disabled"
      data-lu-sb-item
      class={nav_item_classes(disabled: true)}
      aria-disabled="true"
      title={@title}
    >
      <.sb_item_inner item={@item} format={@format} />
    </span>
    """
  end

  defp sb_item(assigns) do
    changed0 = assigns.__changed__
    item = assigns.item
    kids = item[:children] || []
    tree? = assigns.format == "tree"
    parent? = kids != []
    key = item[:label] || item[:icon]
    collapsible = parent? and tree? and item[:collapsible] != false
    open = item_open?(item)

    assigns =
      assign(assigns,
        kids: kids,
        parent?: parent?,
        tree?: tree?,
        collapsible: collapsible,
        open: open,
        key: key,
        dest: dest(item)
      )

    assigns =
      settle(assigns, changed0,
        kids: [:item],
        parent?: [:kids],
        tree?: [:format],
        collapsible: [:item, :parent?, :tree?],
        open: [:item],
        key: [:item],
        dest: [:item]
      )

    ~H"""
    <.link
      data-part="sidebar-item-link"
      {@dest || [href: "#"]}
      data-lu-sb-item
      class={cx(["group/exp", nav_item_classes(on: @item[:active]), @item[:class]])}
      aria-current={@item[:active] && "page"}
      aria-expanded={@collapsible && to_string(@open)}
      aria-controls={@collapsible && kids_id(@id, @key)}
      data-lu-sb-parent={@collapsible && @key}
      data-lu-sb-dest={@collapsible && @dest && "1"}
      {style_attr(@item[:style])}
    >
      <.sb_item_inner item={@item} format={@format} />
      <.icon
        :if={(@parent? and @tree?) or @item[:caret]}
        name={caret_icon(@item[:caret])}
        size="sm"
        data-part="nav-caret"
        class={nav_caret_classes()}
      />
    </.link>
    <%= if @parent? do %>
      <%= if @tree? do %>
        <.link
          :for={{k, n} <- Enum.with_index(@kids)}
          data-part="sidebar-item-child-link"
          {dest(k) || [href: "#"]}
          class={nav_item_classes(sub: true, on: k[:active])}
          aria-current={k[:active] && "page"}
          id={@collapsible && "#{kids_id(@id, @key)}-#{n}"}
          hidden={@collapsible && !@open}
          keep-hidden={@collapsible}
          data-lu-sb-child={@collapsible && @key}
        >
          {k[:label]}
        </.link>
      <% else %>
        <div
          data-part="sidebar-item-children"
          class="ml-5 flex flex-col gap-0.5 border-l border-line pl-2"
        >
          <.link
            :for={k <- @kids}
            data-part="sidebar-item-dotted-link"
            {dest(k) || [href: "#"]}
            class={nav_item_classes(sub: true, tight: true, on: k[:active])}
            aria-current={k[:active] && "page"}
          >
            <span
              :if={k[:color]}
              data-part="sidebar-item-dot"
              class="size-2 flex-none rounded-full"
              {style_attr(color_dot(k[:color]))}
            ></span>{k[:label]}
          </.link>
        </div>
      <% end %>
    <% end %>
    """
  end

  attr :item, :map, required: true
  attr :format, :string, required: true

  defp sb_item_inner(assigns) do
    changed0 = assigns.__changed__
    item = assigns.item
    chip? = assigns.format == "tree" and item[:color] != nil
    assigns = assign(assigns, chip?: chip?)
    assigns = settle(assigns, changed0, chip?: [:item, :format])

    ~H"""
    <span
      :if={@chip? and @item[:icon]}
      data-part="sidebar-item-chip"
      class="inline-grid size-[22px] flex-none place-items-center rounded-sm text-white"
      {style_attr(chip_style(@item[:color]))}
    ><.icon name={sb_icon(@item[:icon])} /></span>
    <%= if !@chip? and @item[:icon] do %>
      <.icon name={sb_icon(@item[:icon])} />
    <% end %>
    {if @item[:content], do: LedgerUI.Helpers.render_slot_full(@item[:content]), else: @item[:label]}
    <span
      :if={@item[:count] != nil}
      data-part="sidebar-item-count"
      class={nav_r_classes(@item[:alert])}
    >{@item[:count]}</span>
    <span :if={@item[:kbd]} data-part="sidebar-item-kbd" class={nav_r_classes()}><.kbd>
      {@item[:kbd]}
    </.kbd></span>
    <span
      :if={@item[:badge]}
      data-part="sidebar-item-badge"
      class={nav_r_classes(true)}
      role={is_binary(@item[:badge]) && "img"}
      aria-label={is_binary(@item[:badge]) && @item[:badge]}
    ></span>
    """
  end

  defp rail_btn(assigns) do
    assigns = assign_new(assigns, :on, fn -> assigns.item[:active] end)

    ~H"""
    <.link
      data-part="rail-btn-link"
      {dest(@item) || [href: "#"]}
      class={rail_btn_classes(!!@on)}
      aria-label={@item[:label]}
      aria-current={@on && "page"}
      title={@item[:label]}
    >
      <.icon name={sb_icon(@item[:icon] || "doc")} />
      <span :if={@item[:count] != nil} data-part="rail-btn-count" class={rail_count_classes()}>{@item[
        :count
      ]}</span>
      <span
        :if={@item[:badge]}
        data-part="rail-btn-dot"
        class="absolute right-px top-0.5 inline-grid size-2 min-w-2 place-items-center rounded-full bg-neg p-0"
      ></span>
    </.link>
    """
  end

  defp rail_extra_btn(assigns) do
    ~H"""
    <.link
      data-part="rail-extra-btn-link"
      {dest(@app) || [href: "#"]}
      class={rail_btn_classes(:extra)}
      aria-label={@app[:label]}
      title={@app[:label]}
      style={"background:#{chip_color(@app[:color])}"}
    >
      <.icon name={sb_icon(@app[:icon] || "spark")} />
    </.link>
    """
  end

  attr :user, :map, required: true
  attr :size, :integer, default: 36

  defp sb_avatar(assigns) do
    ~H"""
    <.avatar
      src={@user[:avatar]}
      initials={user_initials(@user)}
      color={av_tone(@user)}
      background={av_background(@user)}
      size={to_string(@size)}
      status={@user[:status]}
    />
    """
  end

  attr :user, :map, required: true

  defp sb_user(assigns) do
    ~H"""
    <div class={user_classes()} data-part="user">
      <.sb_avatar user={@user} size={36} />
      <span data-part="sidebar-user-person" class={[person_classes(), "min-w-0 flex-1"]}>
        <span data-part="sidebar-user-text" class={person_text_classes()}>
          <b data-part="sidebar-user-name" class={person_name_classes()}>{@user[:name]}</b>
          <span
            :if={@user[:role] || @user[:email]}
            data-part="sidebar-user-sub"
            class={person_sub_classes()}
          >{@user[:role] ||
            @user[:email]}</span>
        </span>
      </span>
      <.icon name="updown" size="md" class={["text-ink", side_hidden()]} />
    </div>
    """
  end

  @promo "relative flex flex-col gap-2.5 overflow-hidden rounded-xl border border-line bg-panel p-3.5 " <>
           "before:pointer-events-none before:absolute before:-top-10 before:-right-10 before:size-[140px] before:rounded-full before:opacity-80 before:content-[''] " <>
           "before:bg-[radial-gradient(circle,var(--lu-accent-100),transparent_70%)] group-data-[collapsed]/side:hidden"

  attr :plan, :map, required: true

  defp sb_plan(assigns) do
    ~H"""
    <div class={promo()} data-part="plan">
      <div data-part="sidebar-plan-head" class="flex flex-nowrap items-center gap-2.5">
        <span
          data-part="sidebar-plan-icon"
          class="grid size-9 place-items-center rounded-md bg-lime-soft text-lime"
        >
          <.icon name="sparkles" size="md" />
        </span>
        <span data-part="sidebar-plan-text" class="flex flex-col gap-0">
          <b>{@plan[:name]}</b>
          <span
            :if={@plan[:text]}
            data-part="sidebar-plan-detail"
            class="text-[12px] leading-4 text-muted"
          >{@plan[:text]}</span>
        </span>
        <.badge :if={@plan[:badge]} canvas color="primary" class="ml-auto">{@plan[:badge]}</.badge>
      </div>
      <span
        :if={@plan[:description]}
        data-part="sidebar-plan-description"
        class="text-[13px] leading-[18px] text-ink-2"
      >{@plan[
        :description
      ]}</span>
      <.button
        :if={@plan[:action] && dest(@plan[:action])}
        canvas
        appearance="primary"
        {dest(@plan[:action])}
        class="w-full justify-between!"
      >
        <.plan_action action={@plan[:action]} />
      </.button>
      <.button
        :if={@plan[:action] && !dest(@plan[:action])}
        canvas
        appearance="primary"
        class="w-full justify-between!"
        phx-click={@plan[:action][:click]}
      >
        <.plan_action action={@plan[:action]} />
      </.button>
    </div>
    """
  end

  defp promo, do: @promo

  defp plan_action(assigns) do
    ~H"""
    <span data-part="plan-action-avatars" class="flex flex-wrap items-center gap-2"><span
      data-part="plan-action-icon"
      class="-ml-2 grid size-[26px] place-items-center rounded-[7px] bg-on-inverse text-inverse"
    ><.icon
          name={sb_icon(@action[:icon] || "spark")}
          size="sm"
        /></span>{@action[
      :label
    ]}</span><.icon name="arrow-right" size="sm" />
    """
  end

  attr :trial, :map, required: true

  defp sb_trial(assigns) do
    ~H"""
    <div class={promo()} data-part="trial">
      <b :if={@trial[:title]}>{@trial[:title]}</b>
      <span
        :if={@trial[:label]}
        data-part="sidebar-trial-label"
        class="text-[12px] leading-4 text-muted"
      >{@trial[:label]}</span>
      <span
        :if={@trial[:text]}
        data-part="sidebar-trial-text"
        class="text-[13px] leading-[18px] text-ink-2"
      >{@trial[:text]}</span>
      <span
        :if={@trial[:value]}
        data-part="sidebar-trial-progress"
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@trial[:value]}
        class="block h-1.5 overflow-hidden rounded-[3px] bg-sunken"
      >
        <span
          data-part="sidebar-trial-bar"
          class="block h-full bg-accent-500"
          style={"width:#{@trial[:value]}%"}
        ></span>
      </span>
      <.button
        :if={@trial[:action]}
        canvas
        appearance="primary"
        {dest(@trial) || [href: "#"]}
        class="w-full"
      >{@trial[:action]}</.button>
    </div>
    """
  end

  attr :version, :map, required: true

  defp sb_version(assigns) do
    changed0 = assigns.__changed__
    v = assigns.version
    status = @statuses[to_string(v[:status] || "ok")] || ""
    full = if v[:build], do: "Version #{v.version} (#{v.build})", else: "Version #{v.version}"
    assigns = assign(assigns, status: status, full: full, link: dest(v))
    assigns = settle(assigns, changed0, status: [:version], full: [:version], link: [:version])

    ~H"""
    <div
      class="flex items-center gap-2 px-2.5 py-2 text-[12px] leading-4 text-muted group-data-[collapsed]/side:justify-center"
      data-part="version"
      title={@full}
      aria-label={@full}
    >
      <span
        data-part="sidebar-version-dot"
        class={[
          "size-2 flex-none rounded-full",
          if(@status == "warn",
            do: "bg-warn shadow-[0_0_0_3px_var(--lu-warn-soft)]",
            else: "bg-pos shadow-[0_0_0_3px_var(--lu-pos-soft)]"
          )
        ]}
      ></span>
      <span data-part="sidebar-version-text" class={["font-mono", side_hidden()]}>{@version.version}</span>
      <span
        :if={@version[:build]}
        data-part="sidebar-version-build"
        class={["font-mono", side_hidden()]}
      >{@version.build}</span>
      <.link
        :if={@link}
        data-part="sidebar-version-link"
        {@link}
        class={["ml-auto text-accent-content no-underline", side_hidden()]}
        title={@version[:title]}
      >
        {@version[:label] || "What's new"}
      </.link>
    </div>
    """
  end

  ## Data

  defp workspace_brand(nil), do: nil

  defp workspace_brand(ws),
    do: %{name: ws[:name], sub: ws[:context] || ws[:sub], mark: true}

  defp slot_nav(%{item: [], view: []}, _current), do: nil

  defp slot_nav(%{item: items, view: views} = assigns, current) do
    entries = Enum.map(items, &slot_item(&1, current))

    if views == [],
      do: entries,
      else:
        entries ++
          [%{group: assigns.views_label, items: Enum.map(views, &slot_item(&1, current))}]
  end

  @tones %{"neg" => "rose", "pos" => "green", "warn" => "orange", "info" => "blue"}

  defp slot_item(slot, current) do
    %{
      label: slot[:label],
      content: if(is_nil(slot[:label]), do: [slot]),
      icon: slot[:icon],
      navigate: slot[:navigate],
      patch: slot[:patch],
      href: slot[:href],
      count: slot[:count],
      badge: slot[:badge],
      color: @tones[slot[:tone]],
      active: slot[:active] == true or (slot[:name] != nil and to_string(slot[:name]) == current)
    }
    |> Map.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp config_nav({mod, fun}, assigns), do: apply(mod, fun, [assigns])
  defp config_nav(_, _), do: nil

  defp footer_mode(footer, show_user, cfg_show_user, version) do
    case footer && to_string(footer) do
      mode when mode in ["user", "version", "none"] ->
        mode

      _ ->
        show_user = if is_nil(show_user), do: cfg_show_user, else: show_user

        cond do
          show_user == false and version -> "version"
          show_user == false -> "none"
          version -> "version"
          true -> "default"
        end
    end
    |> case do
      "default" -> "plan"
      other -> other
    end
  end

  defp version_map(nil), do: nil
  defp version_map(v) when is_binary(v), do: %{version: v}
  defp version_map(%{version: _} = v), do: v
  defp version_map(_), do: nil

  # {:item, item} | {:group, group_with_items} | {:sep, nil}
  defp normalize(nav, format, current, match) do
    for entry <- nav, entry == :separator or visible?(entry, format) do
      cond do
        entry == :separator ->
          {:sep, nil}

        entry[:group] ->
          items =
            for i <- entry[:items] || [],
                visible?(i, format),
                do: normalize_entry(i, format, current, match)

          {:group,
           entry |> Map.put(:items, items) |> Map.put(:active, Enum.any?(items, &active_any?/1))}

        true ->
          {:item, normalize_item(entry, format, current, match)}
      end
    end
  end

  defp normalize_entry(%{group: _} = g, format, current, match) do
    items =
      for i <- g[:items] || [], visible?(i, format), do: normalize_item(i, format, current, match)

    g |> Map.put(:items, items) |> Map.put(:active, Enum.any?(items, &active_any?/1))
  end

  defp normalize_entry(i, format, current, match), do: normalize_item(i, format, current, match)

  defp normalize_item(item, format, current, match) do
    kids =
      for k <- item[:children] || [],
          visible?(k, format),
          do: normalize_item(k, format, current, match)

    own = !item[:disabled] and active?(item, current, match)

    item
    |> Map.put(:children, kids)
    |> Map.put(:active, own)
    |> Map.put(:child_active, Enum.any?(kids, & &1.active))
  end

  defp active_any?(%{items: items}), do: Enum.any?(items, &active_any?/1)
  defp active_any?(%{active: a, child_active: c}), do: a or c
  defp active_any?(%{active: a}), do: a
  defp active_any?(_), do: false

  defp group_active?(%{active: a}), do: a
  defp group_active?(_), do: false

  defp visible?(%{formats: formats}, format) when is_list(formats),
    do: format in Enum.map(formats, &to_string/1)

  defp visible?(_, _), do: true

  defp active?(item, current, match) do
    cond do
      item[:active] == true or item[:current] == true ->
        true

      is_nil(current) ->
        false

      true ->
        case dest(item) do
          nil ->
            false

          d ->
            path_match?(
              d[:navigate] || d[:patch] || d[:href],
              current,
              to_string(item[:match] || match)
            )
        end
    end
  end

  defp path_match?(nil, _, _), do: false
  defp path_match?(dest, current, "exact"), do: dest == current

  defp path_match?(dest, current, "prefix") do
    dp = path_of(dest)
    cp = path_of(current)
    dp == cp or (dp != "/" and String.starts_with?(cp, dp <> "/"))
  end

  defp path_of(url), do: url |> String.split("?") |> hd()

  defp dest(%{navigate: to}) when is_binary(to), do: [navigate: to]
  defp dest(%{patch: to}) when is_binary(to), do: [patch: to]
  defp dest(%{href: to}) when is_binary(to), do: [href: to]
  defp dest(_), do: nil

  defp runs(entries, true) do
    Enum.map(entries, fn
      {:item, i} -> {:loose, i}
      {:sep, _} -> {:sep, nil}
      {:group, g} -> {:group, g}
    end)
  end

  defp runs(entries, false) do
    entries
    |> Enum.chunk_by(&elem(&1, 0))
    |> Enum.flat_map(fn
      [{:item, _} | _] = items -> item_runs(Enum.map(items, &elem(&1, 1)))
      [{:sep, _} | _] = seps -> Enum.map(seps, fn _ -> {:sep, nil} end)
      groups -> Enum.map(groups, fn {:group, g} -> {:group, g} end)
    end)
  end

  # An item with `loose: true` is drawn on its own, outside the column of the items around it.
  defp item_runs(items) do
    items
    |> Enum.chunk_by(&(&1[:loose] == true))
    |> Enum.flat_map(fn
      [%{loose: true} | _] = loose -> Enum.map(loose, &{:loose, &1})
      run -> [{:items, run}]
    end)
  end

  defp foot_groups(entries), do: for({:group, %{footer: true} = g} <- entries, do: g)
  defp foot_items(entries), do: Enum.flat_map(foot_groups(entries), & &1.items)

  defp group_as_item(g) do
    first = g.items |> List.first() || %{}

    g
    |> Map.take([:navigate, :patch, :href, :icon, :active])
    |> Map.put(:label, g.group)
    |> then(fn m ->
      if dest(m), do: m, else: Map.merge(m, Map.take(first, [:navigate, :patch, :href]))
    end)
  end

  defp collapsible?(g, "tree"), do: g[:collapsible] != false
  defp collapsible?(g, "rail"), do: g[:collapsible] != false and (g[:items] || []) != []
  defp collapsible?(g, "nested"), do: g[:collapsible] == true
  defp collapsible?(g, _), do: g[:collapsible] == true

  defp group_open?(g) do
    case g[:open] do
      nil -> g[:active] == true
      v -> v
    end
  end

  defp item_open?(item) do
    case item[:open] do
      nil -> item[:active] == true or item[:child_active] == true
      v -> v
    end
  end

  defp gid(id, key), do: "#{id}-g-#{slug(key)}"
  defp kids_id(id, key), do: "#{id}-k-#{slug(key)}"
  defp slug(nil), do: "x"

  defp slug(s),
    do:
      s
      |> to_string()
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

  defp caret_icon(c) when c in ["right", :right], do: "chevron-right"
  defp caret_icon(_), do: "chevron-down"

  defp sb_icon(name) when is_binary(name), do: Map.get(@icon_map, name, name)
  defp sb_icon(name), do: name

  defp chip_color(nil), do: "var(--lu-ink)"
  defp chip_color(c), do: Map.get(@colors, to_string(c), to_string(c))

  defp chip_style(color), do: "background:#{chip_color(color)}"
  defp color_dot(color), do: "background:#{chip_color(color)}"

  defp first_letter(nil), do: ""
  defp first_letter(name), do: name |> String.first() |> String.upcase()

  defp user_initials(%{initials: i}) when is_binary(i), do: i

  defp user_initials(%{name: n}) when is_binary(n),
    do:
      n
      |> String.split(~r/\s+/, trim: true)
      |> Enum.take(2)
      |> Enum.map_join(&String.first/1)
      |> String.upcase()

  defp user_initials(_), do: ""

  defp av_tone(%{tone: t}) when is_binary(t), do: t
  defp av_tone(%{color: c}) when is_binary(c), do: "none"
  defp av_tone(%{name: n}) when is_binary(n), do: "t#{rem(:erlang.phash2(n), 5) + 1}"
  defp av_tone(_), do: "t1"

  defp av_background(%{color: c}) when is_binary(c), do: c
  defp av_background(_), do: nil

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
