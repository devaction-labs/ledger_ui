defmodule LedgerUI.Components.Sidebar do
  @moduledoc """
  The side menu of the shell, in five formats that read the same data:

    * `sections` (default): the brand with a company switcher, groups with an uppercase mono
      label, "settings and help" at the foot and the plan card.
    * `rail`: a 64px rail of icons (logo, home, one icon per group, extra apps in coloured circles,
      the foot items) beside the panel of the active module (title, create button, items, "try"
      shortcuts, trial card).
    * `tree`: the brand with a collapse button, collapsible groups, children joined by a line,
      square coloured icons and the user card at the foot.
    * `nested`: the shadcn/ui sidebar: team switcher, quiet group labels, items with children and
      the user at the foot, both able to open a menu.
    * `aurora`: the collapsible navigation of the Aurora look (see "The aurora format").

          <.sidebar format="rail" nav={MyAppWeb.Nav.items(assigns)} current={@current_path}
            brand={%{name: "Ledger", logo: "S"}} user={%{name: "Marina Costa", email: "marina@ledger.com"}} />

  Changing `format` changes how the menu is drawn, never the items.

  ## `variant`

  `"floating"` (default) is the inset block with rounded corners, `"sidebar"` sits flush on the shell
  background, `"inset"` drops the margin too. None of them paints a background of its own: the
  page behind (`bg-app`) shows through.

  ## The menu data

  `nav` is a list of maps, in order. A map with `group` is a group, any other is an item.

  Item keys: `label`, `icon` (a short name of the table in the README, or any icon name), `navigate`
  / `patch` / `href`, `count`, `badge`, `color`, `children`, `collapsible`, `open`, `active`,
  `kbd` (a shortcut at the right), `caret` (`"down"` | `"right"`: a chevron at the end without children), `loose` (drawn outside the column of the items around it), `current`, `match` (`"exact"` | `"prefix"`), `disabled` (a "coming soon" item: a `span` with
  `aria-disabled="true"`), `title`, `formats`, `style`, and for `format="aurora"` `preview` and `alert`.

  Group keys: `group`, `icon`, `items`, `collapsible`, `open`, `navigate` / `patch` / `href`,
  `footer: true` (the foot of the menu), `action` (`%{label, navigate, icon}`) and `try`
  (`%{label, items}`) for the rail panel.

  ## The active item on the client (#105)

  `current` (or `active` in an item) marks the active item on the server, so a route change sends
  the menu again. For a menu in a sticky LiveView use `active_link` and give each item
  `match_path: "/items"` (the key of a map in `nav`, the attr of `<:item>` and `<:view>`, also in
  `children`): the `LedgerUI.ActiveLink` hook, put on one column that holds the items, marks the
  item whose `match_path` is the longest prefix of the path (on a segment: `/items` takes `/items/3`,
  not `/items-2`) on mount and on each navigation, and the server sends nothing on a route change.
  `match_path` is not `match` (`exact` | `prefix`), which is how `current` is compared on the server.
  Not for the `rail` format (it raises), and the items of a `footer: true` group stay with the server.

      <.sidebar id="menu" active_link nav={[%{label: "Items", navigate: ~p"/items", match_path: "/items"}]} />

  ## The aurora format

  Three glass cards (the brand with a collapse button and a search button, the navigation, the user)
  that go from 248px (labels, group titles, counts, children with a guide line) to a 64px rail of icons
  with the same icons in the same column. The toggle button, Ctrl/Cmd + `shortcut` (default `b`) and
  `rail_toggle/1` switch the two states on the client with no round trip, and the choice (and the
  open groups with `persist_groups`) is kept in the browser. Put it in the `:rail` slot of
  `<.shell layout="aurora">`: the grid column follows the width.

      <.sidebar id="app-nav" format="aurora" current={@current_path} peek persist_groups
        brand={%{name: "Orbit Cloud", subtitle: "Finance workspace", logo: "O"}}
        search={%{label: "Search", kbd: "⌘ K", click: JS.push("open-palette")}}
        user={%{name: "Alex Nogueira"}}
        nav={[
          %{group: "Main", items: [
            %{label: "Overview", icon: "home", navigate: ~p"/"},
            %{label: "Contacts", icon: "users", navigate: ~p"/contacts", count: 214,
              preview: %{title: "Contacts", description: "Clients and people"}}
          ]},
          %{group: "Sales", collapsible: true, items: [
            %{label: "Orders", icon: "box", children: [
              %{label: "Proposals", navigate: ~p"/proposals"},
              %{label: "Contracts", navigate: ~p"/contracts"}
            ]}
          ]}
        ]} />

  Nested slots do not exist in HEEx, so what the board calls `<:group>`, `<:item>`, `<:child>` and
  `<:preview>` is data in `nav`: a group is a map with `group` and `items`, an item with `children` is a
  parent, and `preview: %{title:, description:, image:}` is the card shown beside the item when the menu
  is collapsed (the `LedgerUI.RailPreview` hook; `image` is the URL of the thumbnail). Collapsed, an
  item with `children` opens a floating submenu on hover or focus (`role="menu"`) instead of the
  preview. Expanded, it is a disclosure with its children under a guide line, the active child
  painting the line. Group titles open and close their group (`collapsible: true`; `open` or the
  active item decides the start). `alert: true` draws a red dot (also on the icon when collapsed).

  Keys of `brand`: `name`, `subtitle` (or `sub`), `logo` / `src` / `mark`. `search`: `label`, `kbd`,
  `click` (a `%JS{}` or an event name) or `navigate`. `peek` (with `peek_delay`, 300ms): collapsed, a
  pointer resting on the menu opens the full version over the page, without pushing it; it closes
  when the pointer leaves.

  Keyboard: Esc closes the submenu, the preview and the peek; Up / Down move between the items (and
  inside a submenu); Right opens a group, a parent or the submenu; Left closes it (or goes back to
  the parent).

  The state is applied before the first paint by the `data-collapsed` attribute of `<html>`, written
  by `sidebar_script/1` in the `<head>` (like `theme_script/1`); without it the menu draws expanded
  until the hook mounts. It is for `md` and up (below it the menu is the top bar with a hamburger).
  `active_link` does not work with this format (it raises, as with `rail`).

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

  # #119: `on_collapse` is read by the `LedgerUI.Sidebar` hook as an event name (a `%JS{}` raises).
  @ledger_ui_event_guard true

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

  attr :active_link, :boolean,
    default: false,
    doc:
      "Marks the active item on the client (`LedgerUI.ActiveLink`) from the `match_path` of each item (or `<:item match_path>`), so the menu is not sent again when the route changes. Not for the `rail` format; the items of a `footer` group are left out."

  attr :persist_groups, :boolean, default: false
  attr :collapsed, :boolean, default: false

  attr :search, :map,
    default: nil,
    doc:
      "`format=\"aurora\"`: the search button under the brand, `%{label:, kbd:, click:, navigate:}` (`click` a `%JS{}` or an event name). None without it."

  attr :peek, :boolean,
    default: false,
    doc:
      "`format=\"aurora\"`: collapsed, a pointer resting on the menu for `peek_delay` ms opens the full menu over the page (it does not push it) and it closes when the pointer leaves."

  attr :peek_delay, :integer,
    default: 300,
    doc: "`format=\"aurora\"` with `peek`: the milliseconds the pointer must rest."

  attr :collapsed_width, :integer,
    default: nil,
    doc:
      "The width of the collapsed menu in px (default 60). Sets `--lu-rail-collapsed` on the menu; the variable can also be set in CSS."

  attr :persist, :boolean, default: true

  attr :on_collapse, :string,
    default: nil,
    doc: "An event name pushed with `%{\"id\", \"collapsed\"}` (a `%JS{}` raises)."

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

    attr :match_path, :string,
      doc:
        "With `active_link`: the path of the client that marks the item (itself or a prefix on a segment: `/items` for `/items/3`)."

    attr :tone, :string,
      doc:
        "`neg`, `pos`, `warn`, `info`: the colour of the badge (`error`, `success` and `warning` are aliases)."

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
    attr :match_path, :string, doc: "As in `<:item>`."
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

    if assigns.active_link and format == "rail" do
      raise ArgumentError,
            "LedgerUI.Components.Sidebar.sidebar/1: `active_link` does not work with " <>
              ~s|format="rail"; the rail menu is marked by the server (`current`)|
    end

    if assigns.active_link and format == "aurora" do
      raise ArgumentError,
            "LedgerUI.Components.Sidebar.sidebar/1: `active_link` does not work with " <>
              ~s|format="aurora"; the menu is marked by the server (`current`)|
    end

    assigns =
      assigns
      |> assign(:fmt, format)
      |> assign(:classes, root_classes(format, assigns.variant, assigns.class))
      |> assign(:burger_class, burger_class())
      |> assign(:persist_attr, if(assigns.persist, do: "true", else: "false"))
      |> assign(:shortcut_attr, assigns.shortcut)
      |> assign(:style_attrs, style_attrs(assigns.collapsed_width, assigns.rest[:style]))
      |> assign(:peek_delay_attr, assigns.peek && assigns.peek_delay)

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
            style_attrs: [:collapsed_width, :rest],
            peek_delay_attr: [:peek, :peek_delay]
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
      data-lu-peek={@peek && "true"}
      data-lu-peek-delay={@peek_delay_attr}
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
        active_link={@active_link}
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
        search={@search}
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
      "aurora" -> sb_aurora(assigns)
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
    "floating" => "m-2.5 rounded-2xl bg-transparent",
    "sidebar" => "bg-transparent",
    "inset" => "bg-transparent"
  }

  defp root_classes("rail", variant, class) do
    # the rail format is two boxes side by side: no width, padding or background of its own
    cx([@root, "w-auto flex-row p-0", rail_look(variant), class])
  end

  # the width goes 248 -> 64 (`data-collapsed` of the menu, or of `<html>` before the hook mounts); in
  # `data-peek` it stays 64 so the page does not move and the body floats over it
  defp root_classes("aurora", _variant, class) do
    cx([
      @root,
      "relative h-full w-[248px] flex-col transition-[width,padding] duration-200 ease-out",
      "data-[collapsed]:w-16 data-[collapsed]:px-[5px] in-data-[collapsed]:w-16 in-data-[collapsed]:px-[5px] data-[peek]:w-16",
      class
    ])
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
    <.sb_entries
      entries={@entries}
      format="sections"
      id={@id}
      nav_class={@nav_class}
      flat={@flat}
      active_link={@active_link}
    />
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
    <.sb_entries
      entries={@entries}
      format="tree"
      id={@id}
      nav_class={@nav_class}
      flat={@flat}
      active_link={@active_link}
    />
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
    <.sb_entries
      entries={@entries}
      format="nested"
      id={@id}
      nav_class={@nav_class}
      flat={@flat}
      active_link={@active_link}
    />
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

  ## Aurora

  @au_card "flex flex-col gap-1 rounded-[18px] border border-white/85 bg-panel/50 p-1.5 shadow-xs backdrop-blur-[14px] dark:border-white/7"
  # The column of the icons. The menu has 5px of padding more when collapsed, so the items give 5px
  # back: an icon is in the same place in both states, and while the 200ms go by (the same curve).
  @au_col "pl-[15px] in-data-[collapsed]:pl-2.5"
  # What leaves in the first half of the change (100ms) and comes back in the second.
  @au_fade "transition-opacity duration-100 delay-100 in-data-[collapsed]:opacity-0 in-data-[collapsed]:delay-0"
  @au_item "relative flex h-10 w-full flex-none cursor-pointer items-center gap-3 overflow-hidden rounded-md pr-2.5 text-left text-[14px] font-medium no-underline outline-none transition-[padding,background-color,color] duration-200 in-data-[collapsed]:pr-0 focus-visible:shadow-[inset_0_0_0_2px_var(--lu-focus)] [&_svg:not([data-caret])]:size-5 [&_svg:not([data-caret])]:flex-none"
  @au_on "bg-panel text-ink shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-xs)]"
  @au_off "bg-transparent text-ink-2 hover:bg-hover hover:text-ink"
  @au_child "relative flex h-[34px] w-full items-center rounded-md pr-2.5 pl-[47px] text-left text-[13.5px] no-underline outline-none transition-colors before:absolute before:-inset-y-0.5 before:left-6 before:w-[1.5px] before:content-[''] focus-visible:shadow-[inset_0_0_0_2px_var(--lu-focus)]"
  @au_child_on "bg-panel font-medium text-ink shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-xs)] before:bg-ink"
  @au_child_off "text-ink-2 before:bg-line-strong hover:bg-hover hover:text-ink"
  @au_menu "fixed top-0 left-0 z-50 hidden w-60 flex-col gap-0.5 rounded-lg border border-line bg-panel p-1.5 text-ink shadow-popover before:absolute before:top-(--ay) before:-left-[7px] before:size-3 before:rotate-45 before:rounded-bl-[3px] before:border-b before:border-l before:border-line before:bg-panel before:content-[''] md:data-[open]:flex"
  @au_menu_item "flex h-[34px] w-full items-center rounded-[10px] px-2 text-[13.5px] no-underline outline-none hover:bg-hover hover:text-ink focus-visible:bg-hover focus-visible:shadow-[inset_0_0_0_2px_var(--lu-focus)]"

  # The entries with a `uid` in each item (the ids of its children, submenu and preview), the lists
  # of the previews and of the submenus (drawn outside the glass cards: a `fixed` box inside a
  # `backdrop-filter` one is placed by it) and the runs the nav card draws.
  defp au_prepare(entries, id, flat?) do
    {entries, _} =
      Enum.map_reduce(entries, 0, fn
        {:item, i}, n ->
          {{:item, au_uid(i, id, n)}, n + 1}

        {:group, g}, n ->
          {items, n} =
            Enum.map_reduce(g.items, n, fn
              %{group: _} = nested, n -> {nested, n}
              i, n -> {au_uid(i, id, n), n + 1}
            end)

          {{:group, %{g | items: items}}, n}

        other, n ->
          {other, n}
      end)

    all =
      Enum.flat_map(entries, fn
        {:item, i} -> [i]
        {:group, g} -> Enum.reject(g.items, &Map.has_key?(&1, :group))
        _ -> []
      end)

    previews = for i <- all, i[:pv_id], do: %{id: i.pv_id, preview: i.preview}

    menus =
      for i <- all, i.children != [], !i[:disabled] do
        %{id: i.menu_id, label: i[:label], icon: i[:icon], children: i.children}
      end

    {entries, previews, menus, au_runs(entries, flat?)}
  end

  defp au_uid(item, id, n) do
    uid = "#{id}-n#{n}"
    kids? = (item[:children] || []) != [] and !item[:disabled]
    pv? = !kids? and is_map(item[:preview]) and !item[:disabled]

    item
    |> Map.put(:uid, uid)
    |> Map.put(:kids_id, "#{uid}-kids")
    |> Map.put(:menu_id, "#{uid}-menu")
    |> Map.put(:pv_id, pv? && "#{uid}-pv")
  end

  # `[%{key:, kind: :items | :loose | :sep | :group, items:, group:}]`; the footer groups are the
  # last run of items, after a line.
  defp au_runs(entries, flat?) do
    {foot, rest} = Enum.split_with(entries, &match?({:group, %{footer: true}}, &1))

    foot_items = Enum.flat_map(foot, fn {:group, g} -> g.items end)

    runs =
      rest
      |> runs(flat?)
      |> Kernel.++(if foot_items == [], do: [], else: [{:sep, nil}, {:items, foot_items}])
      |> Enum.with_index()
      |> Enum.map(fn
        {{:items, items}, n} -> %{key: "r#{n}", kind: :items, items: items, group: nil}
        {{:loose, item}, n} -> %{key: "r#{n}", kind: :loose, items: [item], group: nil}
        {{:sep, _}, n} -> %{key: "r#{n}", kind: :sep, items: [], group: nil}
        {{:group, g}, n} -> %{key: "r#{n}", kind: :group, items: [], group: g}
      end)

    runs
  end

  defp sb_aurora(assigns) do
    changed0 = assigns.__changed__

    {entries, previews, menus, runs} =
      au_prepare(assigns.entries, assigns.id, assigns.flat)

    brand = assigns.brand_map

    assigns =
      assign(assigns,
        previews: previews,
        menus: menus,
        runs: runs,
        subtitle: brand[:subtitle] || brand[:sub],
        search_click: au_search_click(assigns.search),
        user_on: assigns.user != nil and assigns.footer_mode in ["user", "plan"],
        has_nav: entries != []
      )

    assigns =
      settle(assigns, changed0,
        previews: [:entries, :id, :flat],
        menus: [:entries, :id, :flat],
        runs: [:entries, :id, :flat],
        subtitle: [:brand_map],
        search_click: [:search],
        user_on: [:user, :footer_mode],
        has_nav: [:entries]
      )

    ~H"""
    <div
      data-part="sidebar-aurora"
      class="group/aurora relative flex h-full min-h-0 flex-col gap-3 transition-[width,padding] duration-200 group-data-[peek]/side:absolute group-data-[peek]/side:inset-y-0 group-data-[peek]/side:-left-2 group-data-[peek]/side:z-40 group-data-[peek]/side:w-[264px] group-data-[peek]/side:rounded-2xl group-data-[peek]/side:bg-app group-data-[peek]/side:p-2 group-data-[peek]/side:shadow-popover"
    >
      <div data-part="sidebar-aurora-top" class={au_card()}>
        <div
          data-part="sidebar-aurora-head"
          class="flex min-w-0 items-center pl-[5px] in-data-[collapsed]:flex-col in-data-[collapsed]:items-start in-data-[collapsed]:pl-0"
        >
          <div :if={@brand_mark != []} data-part="sidebar-aurora-brand" class="min-w-0 flex-1">
            {render_slot(@brand_mark)}
          </div>
          <div
            :if={@brand_mark == []}
            data-part="brand"
            class="flex min-w-0 flex-1 items-center"
          >
            <span
              data-part="sidebar-aurora-logo-cell"
              class="grid size-10 flex-none place-items-center"
            >
              <span
                data-part="sidebar-brand-logo"
                class="relative grid size-8 place-items-center overflow-hidden rounded-[10px] bg-inverse text-[12.5px] leading-4 text-on-inverse"
              >
                <img
                  :if={@brand_map[:src]}
                  data-part="sidebar-brand-img"
                  src={@brand_map[:src]}
                  alt=""
                  class="absolute inset-0 size-full rounded-[inherit] object-cover"
                />
                <.chart_mark :if={!@brand_map[:src] and @brand_map[:mark]} />
                <%= if !@brand_map[:src] and !@brand_map[:mark] do %>
                  {@brand_map[:logo] || first_letter(@brand_map[:name])}
                <% end %>
              </span>
            </span>
            <span
              data-part="sidebar-aurora-brand-text"
              class={[
                "ml-2 flex min-w-0 flex-1 flex-col transition-[opacity,display] transition-discrete duration-100 in-data-[collapsed]:hidden in-data-[collapsed]:opacity-0 starting:opacity-0"
              ]}
            >
              <b
                data-part="sidebar-brand-name"
                class="truncate text-[14.5px] leading-[19px] font-semibold text-ink"
              >{@brand_map[:name]}</b>
              <span
                :if={@subtitle}
                data-part="sidebar-brand-sub"
                class="truncate text-[12px] leading-4 text-muted"
              >{@subtitle}</span>
            </span>
          </div>
          <button
            :if={@collapsible}
            data-part="sidebar-aurora-toggle"
            type="button"
            data-lu-sb-toggle
            aria-label={@collapse_label}
            aria-keyshortcuts="Control+B Meta+B"
            class="mr-0.5 grid size-10 flex-none cursor-pointer place-items-center rounded-md text-ink-2 outline-none hover:bg-hover hover:text-ink focus-visible:shadow-[inset_0_0_0_2px_var(--lu-focus)] in-data-[collapsed]:mr-0 [&_svg]:size-[18px]"
          >
            <.icon name="sidebar" />
          </button>
        </div>
        <button
          :if={@search}
          data-part="sidebar-aurora-search"
          type="button"
          phx-click={@search_click}
          data-lu-au-nav
          aria-label={@search[:label]}
          class="flex h-10 w-full cursor-pointer items-center gap-3 overflow-hidden rounded-md bg-panel pr-2 pl-[15px] text-left text-[13.5px] text-muted shadow-[0_0_0_1px_var(--lu-line)] outline-none transition-[padding,background-color,box-shadow] duration-200 in-data-[collapsed]:bg-transparent in-data-[collapsed]:pl-2.5 in-data-[collapsed]:pr-0 in-data-[collapsed]:shadow-none hover:text-ink focus-visible:shadow-[inset_0_0_0_2px_var(--lu-focus)] [&_svg]:size-5 [&_svg]:flex-none"
        >
          <.icon name="search" />
          <span class={["min-w-0 flex-1 truncate", au_fade()]}>{@search[:label]}</span>
          <span
            :if={@search[:kbd]}
            data-part="sidebar-aurora-search-kbd"
            class={[
              "rounded-[5px] border border-line px-1.5 py-px font-mono text-[11px] text-ink-2",
              au_fade()
            ]}
          >{@search[:kbd]}</span>
        </button>
      </div>
      <nav
        :if={@has_nav}
        id={"#{@id}-nav"}
        aria-label={@label}
        phx-hook="LedgerUI.RailPreview"
        data-lu-when="collapsed"
        data-lu-delay="150"
        class="flex min-h-0 flex-col"
      >
        <div
          data-part="sidebar-aurora-nav"
          class={[au_card(), "min-h-0 overflow-x-hidden overflow-y-auto", @nav_class]}
        >
          <.au_run :for={r <- @runs} :key={r.key} run={r} id={@id} />
        </div>
        <.au_preview :for={p <- @previews} :key={p.id} id={p.id} preview={p.preview} />
        <.au_menu :for={m <- @menus} :key={m.id} menu={m} />
      </nav>
      <div data-part="sidebar-spacer" class="min-h-0 flex-1"></div>
      <.au_user :if={@user_on} user={@user} id={@id} />
      {render_slot(@sidebar_footer)}
      <.drawer drawer={@mobile_drawer} />
    </div>
    """
  end

  defp au_card, do: @au_card
  defp au_fade, do: @au_fade

  defp au_search_click(nil), do: nil
  defp au_search_click(%{click: c}) when c not in [nil, false], do: c
  defp au_search_click(%{navigate: to}) when is_binary(to), do: JS.navigate(to)
  defp au_search_click(_), do: nil

  attr :run, :map, required: true
  attr :id, :string, required: true

  defp au_run(%{run: %{kind: :items}} = assigns) do
    ~H"""
    <div data-part="sidebar-aurora-run" class="flex flex-col gap-1">
      <.au_item :for={i <- @run.items} :key={i.uid} item={i} id={@id} />
    </div>
    """
  end

  defp au_run(%{run: %{kind: :loose}} = assigns) do
    ~H"""
    <.au_item :for={i <- @run.items} :key={i.uid} item={i} id={@id} />
    """
  end

  defp au_run(%{run: %{kind: :sep}} = assigns) do
    ~H"""
    <div data-part="sidebar-aurora-separator" class="mx-2 my-1 h-px bg-line"></div>
    """
  end

  defp au_run(assigns) do
    ~H"""
    <.au_group group={@run.group} id={@id} />
    """
  end

  attr :group, :map, required: true
  attr :id, :string, required: true

  defp au_group(assigns) do
    g = assigns.group
    collapsible = collapsible?(g, "aurora")
    open = !collapsible or group_open?(g)

    assigns =
      assign(assigns,
        items: Enum.reject(g.items, &Map.has_key?(&1, :group)),
        body_id: gid(assigns.id, g.group),
        heads: [%{label: g.group, collapsible: collapsible, open: open, key: g.group}],
        closed: !open
      )

    ~H"""
    <section data-part="sidebar-aurora-group" class="flex flex-col">
      <%= for h <- @heads do %>
        <button
          :if={h.collapsible}
          type="button"
          data-part="sidebar-group-heading"
          data-lu-sb-group={h.key}
          data-lu-au-nav
          aria-expanded={to_string(h.open)}
          aria-controls={@body_id}
          class={[
            "group/exp mt-1.5 flex h-7 w-full flex-none cursor-pointer items-center gap-1 overflow-hidden rounded-md pr-2.5 pl-[15px] text-left text-[12px] font-medium text-muted outline-none transition-[height,opacity,padding,margin,visibility] duration-200 hover:text-ink focus-visible:shadow-[inset_0_0_0_2px_var(--lu-focus)]",
            "in-data-[collapsed]:invisible in-data-[collapsed]:mt-0 in-data-[collapsed]:h-0 in-data-[collapsed]:opacity-0"
          ]}
        >
          <span class="min-w-0 flex-1 truncate">{h.label}</span>
          <.icon
            name="chevron-down"
            size="sm"
            data-caret
            class="flex-none transition-transform duration-200 group-aria-[expanded=false]/exp:-rotate-90"
          />
        </button>
        <div
          :if={!h.collapsible}
          data-part="sidebar-group-heading"
          class="mt-1.5 flex h-7 flex-none items-center overflow-hidden pr-2.5 pl-[15px] text-[12px] font-medium text-muted transition-[height,opacity,margin,visibility] duration-200 in-data-[collapsed]:invisible in-data-[collapsed]:mt-0 in-data-[collapsed]:h-0 in-data-[collapsed]:opacity-0"
        >
          <span class="truncate">{h.label}</span>
        </div>
      <% end %>
      <div
        id={@body_id}
        data-lu-au-body
        data-closed={@closed && ""}
        class="grid grid-rows-[1fr] transition-[grid-template-rows,visibility] duration-200 not-in-data-[collapsed]:data-[closed]:invisible not-in-data-[collapsed]:data-[closed]:grid-rows-[0fr]"
      >
        <div class="min-h-0 overflow-hidden">
          <div data-part="sidebar-group-items" class="flex flex-col gap-1">
            <.au_item :for={i <- @items} :key={i.uid} item={i} id={@id} />
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :item, :map, required: true
  attr :id, :string, required: true

  defp au_item(%{item: %{disabled: d}} = assigns) when d not in [nil, false] do
    ~H"""
    <span
      data-part="sidebar-item-disabled"
      aria-disabled="true"
      title={@item[:title] || (is_binary(@item[:disabled]) && @item[:disabled]) || nil}
      class={au_item_class(false, "cursor-not-allowed opacity-45")}
    >
      <.au_inner item={@item} />
    </span>
    """
  end

  defp au_item(%{item: %{children: [_ | _]}} = assigns) do
    item = assigns.item

    assigns =
      assign(assigns,
        dest: dest(item),
        key: item[:label] || item[:icon],
        open: item_open?(item),
        on: item[:active] == true or item[:child_active] == true
      )

    ~H"""
    <div data-part="sidebar-aurora-parent" class="flex flex-col gap-1">
      <a
        :if={@dest}
        data-part="sidebar-item-link"
        {anchor(@dest)}
        data-lu-au-item
        data-lu-au-nav
        data-lu-sb-parent={@key}
        data-lu-sb-dest="1"
        data-lu-au-kids={@item.kids_id}
        data-lu-au-menu={@item.menu_id}
        aria-expanded={to_string(@open)}
        aria-controls={@item.kids_id}
        aria-current={@item[:active] && "page"}
        class={au_item_class(@item[:active] == true, @item[:class])}
      >
        <.au_inner item={@item} caret />
      </a>
      <button
        :if={!@dest}
        data-part="sidebar-item-link"
        type="button"
        data-lu-au-item
        data-lu-au-nav
        data-lu-sb-parent={@key}
        data-lu-au-kids={@item.kids_id}
        data-lu-au-menu={@item.menu_id}
        aria-expanded={to_string(@open)}
        aria-controls={@item.kids_id}
        class={au_item_class(false, @item[:class])}
      >
        <.au_inner item={@item} caret />
      </button>
      <div
        id={@item.kids_id}
        data-lu-au-body
        data-closed={!@open && ""}
        class="grid grid-rows-[1fr] transition-[grid-template-rows,visibility] duration-200 in-data-[collapsed]:invisible in-data-[collapsed]:grid-rows-[0fr] data-[closed]:invisible data-[closed]:grid-rows-[0fr]"
      >
        <div class="min-h-0 overflow-hidden">
          <div data-part="sidebar-item-children" class="flex flex-col gap-1">
            <a
              :for={k <- @item.children}
              data-part="sidebar-item-child-link"
              {anchor(dest(k))}
              data-lu-au-nav
              data-lu-au-of={@key}
              data-lu-match={k[:match_path]}
              aria-current={k[:active] && "page"}
              class={au_child_class(k[:active] == true)}
            >
              <span class="truncate">{k[:label]}</span>
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp au_item(assigns) do
    assigns = assign(assigns, dest: dest(assigns.item))

    ~H"""
    <a
      data-part="sidebar-item-link"
      {anchor(@dest)}
      data-lu-au-item
      data-lu-au-nav
      data-rail-item={@item.pv_id && ""}
      data-lu-match={@item[:match_path]}
      aria-describedby={@item.pv_id}
      aria-current={@item[:active] && "page"}
      class={au_item_class(@item[:active] == true, @item[:class])}
      {style_attr(@item[:style])}
    >
      <.au_inner item={@item} />
    </a>
    """
  end

  defp au_item_class(on, extra),
    do: cx(["group/it", @au_item, @au_col, if(on, do: @au_on, else: @au_off), extra])

  defp au_child_class(on), do: cx([@au_child, if(on, do: @au_child_on, else: @au_child_off)])

  attr :item, :map, required: true
  attr :caret, :boolean, default: false

  defp au_inner(assigns) do
    ~H"""
    <.icon :if={@item[:icon]} name={sb_icon(@item[:icon])} />
    <span
      data-part="sidebar-aurora-label"
      data-lu-au-label
      class={["min-w-0 flex-1 truncate", au_fade()]}
    >{@item[:label]}</span>
    <span
      :if={@item[:count] != nil}
      data-part="sidebar-item-count"
      class={["text-[12px] font-normal text-muted tabular-nums", au_fade()]}
    >{@item[:count]}</span>
    <.icon
      :if={@caret}
      name="chevron-down"
      size="sm"
      data-caret
      class={[
        "flex-none text-muted transition-transform group-aria-[expanded=true]/it:rotate-180",
        au_fade()
      ]}
    />
    <span
      :if={@item[:alert] || @item[:badge]}
      data-part="sidebar-aurora-alert"
      role={is_binary(@item[:badge]) && "img"}
      aria-label={is_binary(@item[:badge]) && @item[:badge]}
      class="size-[7px] flex-none rounded-full bg-neg ring-2 ring-panel in-data-[collapsed]:absolute in-data-[collapsed]:top-2 in-data-[collapsed]:right-2"
    ></span>
    """
  end

  attr :id, :string, required: true
  attr :preview, :map, required: true

  defp au_preview(assigns) do
    assigns =
      assign(assigns,
        title: assigns.preview[:title],
        description: assigns.preview[:description],
        image: assigns.preview[:image]
      )

    ~H"""
    <div
      id={@id}
      role="tooltip"
      data-part="rail-preview"
      data-lu-rail-preview
      class={LedgerUI.Components.Rail.preview_class()}
    >
      <div
        :if={@image}
        data-part="rail-preview-art"
        class="relative h-24 overflow-hidden rounded-md bg-white/8"
      >
        <img src={@image} alt="" class="size-full object-cover" />
      </div>
      <b :if={@title} class="px-1 text-[15px] leading-5 font-medium text-white">{@title}</b>
      <span
        :if={@description}
        class={["px-1 pb-1 text-[13px] leading-[18px] text-white/62", @title && "-mt-1.5"]}
      >{@description}</span>
    </div>
    """
  end

  attr :menu, :map, required: true

  # The submenu of a parent when the menu is collapsed: the hook (`LedgerUI.Sidebar`) shows and
  # places it on hover or focus.
  defp au_menu(assigns) do
    ~H"""
    <div
      id={@menu.id}
      role="menu"
      aria-label={@menu.label}
      data-part="sidebar-aurora-submenu"
      data-lu-au-menu-box
      class={au_menu()}
    >
      <div
        data-part="sidebar-aurora-submenu-title"
        class="flex items-center gap-2 px-2 pt-2 pb-1.5 text-[13.5px] font-semibold text-ink [&_svg]:size-4 [&_svg]:text-ink-2"
      >
        <.icon :if={@menu[:icon]} name={sb_icon(@menu[:icon])} />{@menu.label}
      </div>
      <a
        :for={k <- @menu.children}
        data-part="sidebar-aurora-submenu-item"
        {anchor(dest(k))}
        role="menuitem"
        tabindex="-1"
        aria-current={k[:active] && "page"}
        class={[
          au_menu_item(),
          if(k[:active], do: "bg-tray font-medium text-ink", else: "text-ink-2")
        ]}
      >
        {k[:label]}
      </a>
    </div>
    """
  end

  defp au_menu, do: @au_menu
  defp au_menu_item, do: @au_menu_item

  attr :user, :map, required: true
  attr :id, :string, required: true

  defp au_user(assigns) do
    ~H"""
    <div data-part="sidebar-aurora-user-wrap" class="relative flex-none">
      <div data-part="sidebar-aurora-user" class={au_card()}>
        <div
          data-part="user"
          role={@user[:menu] && "button"}
          tabindex={@user[:menu] && "0"}
          phx-click={@user[:menu] && JS.toggle_attribute({"hidden", "hidden"}, to: "##{@id}-user")}
          class={[
            "flex h-10 w-full items-center gap-3 overflow-hidden rounded-md pr-2 pl-[9px] outline-none transition-[padding] duration-200 in-data-[collapsed]:pl-1 focus-visible:shadow-[inset_0_0_0_2px_var(--lu-focus)]",
            @user[:menu] && "cursor-pointer"
          ]}
        >
          <span class="flex-none"><.sb_avatar user={@user} size={32} /></span>
          <span
            data-part="sidebar-aurora-user-name"
            class={["min-w-0 flex-1 truncate text-[14px] font-medium text-ink", au_fade()]}
          >{@user[:name]}</span>
          <.icon
            name="updown"
            size="md"
            class={["flex-none text-muted", au_fade()]}
          />
        </div>
      </div>
      <div
        :if={@user[:menu]}
        data-part="sidebar-user-menu-popover"
        id={"#{@id}-user"}
        class={cx([Dropdown.pop_classes(), "absolute bottom-0 left-full z-50 ml-2"])}
        role="menu"
        hidden
        phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@id}-user")}
      >
        <div data-part="sidebar-user-menu-head" class={[person_classes(), "px-2.5 py-2"]}>
          <.sb_avatar user={@user} size={32} />
          <span data-part="sidebar-user-menu-head-text" class={person_text_classes()}>
            <b data-part="sidebar-user-menu-head-name" class={person_name_classes()}>{@user[:name]}</b>
            <span
              :if={@user[:role] || @user[:email]}
              data-part="sidebar-user-menu-head-sub"
              class={person_sub_classes()}
            >{@user[:role] || @user[:email]}</span>
          </span>
        </div>
        <div data-part="sidebar-user-menu-separator" class={Dropdown.separator_classes()}></div>
        <.sb_menu items={@user[:menu]} />
      </div>
    </div>
    """
  end

  @doc """
  The inline script that applies the collapsed state of `format="aurora"` before the first paint: it
  puts `data-collapsed` on `<html>` when the browser kept the menu collapsed (the same
  `localStorage["ledger-rail"]` the `LedgerUI.Sidebar` hook writes), so the menu is drawn at 64px from
  the first frame and does not flash 248px and shrink. Put it in the `<head>`, next to
  `theme_script/1`:

      <head>
        <.theme_script />
        <.sidebar_script />
      </head>

  It is plain and synchronous on purpose (it must block rendering). With a strict CSP pass the request
  nonce: `<.sidebar_script nonce={assigns[:csp_nonce]} />`. Do not use it when the menu has
  `persist={false}`.
  """
  attr :nonce, :string,
    default: nil,
    doc: "The CSP nonce put on the `<script>` (`script-src 'nonce-...'`). Omitted when `nil`."

  attr :rest, :global, doc: "Extra attributes for the `<script>` tag."

  def sidebar_script(assigns) do
    ~H"""
    <script nonce={@nonce} {@rest}>
      <%= Phoenix.HTML.raw(sidebar_script_body()) %>
    </script>
    """
  end

  @doc false
  def sidebar_script_body do
    ~S|(function(){try{if(localStorage.getItem("ledger-rail")==="1")document.documentElement.setAttribute("data-collapsed","")}catch(e){}})();|
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
        <a
          :if={dest(m)}
          data-part="sidebar-menu-link"
          {anchor(dest(m), method: m[:method])}
          role="menuitem"
          class={Dropdown.item_classes(tone: m[:danger] && "danger")}
        >
          <.icon :if={m[:icon]} name={sb_icon(m[:icon])} />{m[:label]}<span
            :if={m[:hint]}
            data-part="sidebar-menu-item-end"
            class={Dropdown.item_end_classes()}
          >{m[:hint]}</span>
        </a>
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
  attr :active_link, :boolean, default: false

  # With `active_link` the items sit in one column that is the `LedgerUI.ActiveLink` hook (#105); the
  # column holds the same entries that are drawn without it.
  defp sb_entries(%{active_link: true} = assigns) do
    ~H"""
    <div
      id={"#{@id}-active-link"}
      data-part="sidebar-active-link"
      class="flex flex-col gap-0.5"
      {LedgerUI.Components.Shell.active_link_attrs(true, :nav)}
    >
      <.sb_entries
        entries={@entries}
        format={@format}
        id={@id}
        nav_class={@nav_class}
        flat={@flat}
        active_link={false}
      />
    </div>
    """
  end

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
    <div id={gid(@id, @key)} hidden={!@open}>
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
    <a
      data-part="sidebar-item-link"
      {anchor(@dest)}
      data-lu-sb-item
      data-lu-match={@item[:match_path]}
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
    </a>
    <%= if @parent? do %>
      <%= if @tree? do %>
        <a
          :for={{k, n} <- Enum.with_index(@kids)}
          data-part="sidebar-item-child-link"
          {anchor(dest(k))}
          class={nav_item_classes(sub: true, on: k[:active])}
          aria-current={k[:active] && "page"}
          data-lu-match={k[:match_path]}
          id={@collapsible && "#{kids_id(@id, @key)}-#{n}"}
          hidden={@collapsible && !@open}
          data-lu-sb-child={@collapsible && @key}
        >
          {k[:label]}
        </a>
      <% else %>
        <div
          data-part="sidebar-item-children"
          class="ml-5 flex flex-col gap-0.5 border-l border-line pl-2"
        >
          <a
            :for={k <- @kids}
            data-part="sidebar-item-dotted-link"
            {anchor(dest(k))}
            class={nav_item_classes(sub: true, tight: true, on: k[:active])}
            aria-current={k[:active] && "page"}
            data-lu-match={k[:match_path]}
          >
            <span
              :if={k[:color]}
              data-part="sidebar-item-dot"
              class="size-2 flex-none rounded-full"
              {style_attr(color_dot(k[:color]))}
            ></span>{k[:label]}
          </a>
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
    <a
      data-part="rail-btn-link"
      {anchor(dest(@item))}
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
    </a>
    """
  end

  defp rail_extra_btn(assigns) do
    ~H"""
    <a
      data-part="rail-extra-btn-link"
      {anchor(dest(@app))}
      class={rail_btn_classes(:extra)}
      aria-label={@app[:label]}
      title={@app[:label]}
      style={"background:#{chip_color(@app[:color])}"}
    >
      <.icon name={sb_icon(@app[:icon] || "spark")} />
    </a>
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
      <a
        :if={@link}
        data-part="sidebar-version-link"
        {anchor(@link)}
        class={["ml-auto text-accent-content no-underline", side_hidden()]}
        title={@version[:title]}
      >
        {@version[:label] || "What's new"}
      </a>
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

  @tones LedgerUI.Helpers.tone_map(%{
           "neg" => "rose",
           "pos" => "green",
           "warn" => "orange",
           "info" => "blue"
         })

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
      match_path: slot[:match_path],
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

  # The attributes of the `<a>` that `<.link>` would render for a destination (see `LedgerUI.LinkAttrs`).
  defp anchor(dest, extra \\ []),
    do: LedgerUI.LinkAttrs.resolve(Keyword.merge(dest || [href: "#"], extra))

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
      |> slugify()

  # Sem regex: cada trecho de bytes fora de [a-z0-9] vira um "-"; as pontas são aparadas.
  defp slugify(s), do: s |> slug_bytes(<<>>) |> String.trim("-")

  defp slug_bytes(<<c, rest::binary>>, acc) when c in ?a..?z or c in ?0..?9,
    do: slug_bytes(rest, <<acc::binary, c>>)

  defp slug_bytes(<<_, rest::binary>>, acc), do: slug_bytes(skip_other(rest), <<acc::binary, ?->>)
  defp slug_bytes(<<>>, acc), do: acc

  defp skip_other(<<c, _::binary>> = s) when c in ?a..?z or c in ?0..?9, do: s
  defp skip_other(<<_, rest::binary>>), do: skip_other(rest)
  defp skip_other(<<>>), do: <<>>

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
      |> String.split([" ", "\n", "\t", "\r"], trim: true)
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
