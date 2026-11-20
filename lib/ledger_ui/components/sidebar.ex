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

  `"floating"` (default) is the card with corners and a shadow, `"sidebar"` sits flush with a line at
  its edge, `"inset"` drops the card too.

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

  Every format collapses to icons (tooltips with the label, counts turn into dots) with the
  `LedgerUI.Sidebar` hook: `collapsed` is the start, `on_collapse` is pushed with
  `%{"id" => id, "collapsed" => boolean}`, the choice is kept in `localStorage["ledger-rail"]`
  (`persist`), `rail_toggle/1` collapses it from anywhere and so does Ctrl/Cmd + `shortcut`.
  Below 768px the menu is a top bar with a hamburger.
  """
  use LedgerUI.Component

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
    "ink" => "var(--ink)"
  }

  @variants %{"floating" => "floating", "sidebar" => nil, "inset" => "inset"}
  @statuses %{"ok" => "", "warning" => "warn", "down" => "bad"}

  attr :id, :string, default: "sidebar"
  attr :format, :any, default: nil
  attr :nav, :list, default: nil
  attr :current, :string, default: nil
  attr :brand, :map, default: nil
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
  attr :persist, :boolean, default: true
  attr :on_collapse, :string, default: nil
  attr :target, :any, default: nil
  attr :shortcut, :string, default: "b"
  attr :variant, :string, default: "floating", values: ~w(floating sidebar inset)
  attr :label, :any, default: "Main menu"
  attr :collapse_label, :string, default: "Collapse menu"
  attr :mobile_label, :string, default: "Menu"

  attr :nav_class, :any,
    default: nil,
    doc: "Classes of the column that holds the items (`lu-hl-nav` animates them)."

  attr :flat, :boolean,
    default: false,
    doc: "Draws the items straight in the menu, without the column that wraps a run of them."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :brand_mark, doc: "Replaces the logo and the name of the brand."
  slot :mobile_drawer, doc: "Content of the menu body shown only below 768px."
  slot :sidebar_footer, doc: "At the end of the foot of the menu."

  def sidebar(assigns) do
    cfg = Application.get_env(:ledger_ui, :shell, [])
    format = to_string(assigns.format || cfg[:sidebar] || "sections")

    nav =
      assigns.nav || config_nav(cfg[:nav], assigns) || []

    version = assigns.version || cfg[:version]

    footer =
      footer_mode(assigns.footer || cfg[:footer], assigns.show_user, cfg[:show_user], version)

    entries = normalize(nav, format, assigns.current, assigns.match)

    assigns =
      assigns
      |> assign(:format, format)
      |> assign(:entries, entries)
      |> assign(:footer_mode, footer)
      |> assign(:version_map, version_map(version))
      |> assign(:vclass, @variants[assigns.variant])
      |> assign(:brand_map, assigns.brand || %{})
      |> assign(:persist_attr, if(assigns.persist, do: "true", else: "false"))
      |> assign(:shortcut_attr, assigns.shortcut)

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
      data-lu-format={@format != "sections" && @format}
      class={cx(["lu-side", @vclass, @class])}
      {style_attr(format_style(@format))}
      {@rest}
    >
      <.sb_sections :if={@format == "sections"} {assigns} />
      <.sb_tree :if={@format == "tree"} {assigns} />
      <.sb_rail :if={@format == "rail"} {assigns} />
      <.sb_nested :if={@format == "nested"} {assigns} />
    </aside>
    """
  end

  ## Formats

  defp has_foot?(a) do
    foot_groups(a.entries) != [] or
      (a.footer_mode in ["plan", "user"] and (a.plan || a.user) != nil) or
      (a.footer_mode == "version" and a.version_map != nil) or a.sidebar_footer != []
  end

  defp format_style("rail"),
    do: "width:auto;flex-direction:row;padding:0;gap:0;background:transparent"

  defp format_style(_), do: nil

  defp sb_sections(assigns) do
    ~H"""
    <.sb_brand brand={@brand_map} brand_mark={@brand_mark} />
    <.sb_entries entries={@entries} format="sections" id={@id} nav_class={@nav_class} flat={@flat} />
    <div :if={has_foot?(assigns)} class="lu-grow"></div>
    <.sb_plan :if={@footer_mode in ["plan", "user"] and @plan} plan={@plan} />
    <div :if={foot_groups(@entries) != []} style="margin-top:8px">
      <.sb_item :for={item <- foot_items(@entries)} item={item} format="sections" id={@id} />
    </div>
    <.sb_user :if={@footer_mode == "user" and @user} user={@user} />
    <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
    {render_slot(@sidebar_footer)}
    <div :if={@mobile_drawer != []} class="lu-sb-drawer" style="display:none">
      {render_slot(@mobile_drawer)}
    </div>
    """
  end

  defp sb_tree(assigns) do
    ~H"""
    <div
      :if={@brand_map != %{} or @brand_mark != [] or @collapsible}
      style="display:flex;align-items:center;gap:8px"
    >
      <div style="flex:1;min-width:0">
        <.sb_brand brand={@brand_map} brand_mark={@brand_mark} switch={false} />
      </div>
      <button
        :if={@collapsible}
        type="button"
        data-lu-sb-toggle
        aria-label={@collapse_label}
        class="lu-tbtn"
        style="width:32px;height:32px;border-radius:9px;margin-bottom:10px"
      >
        <.icon name="sidebar" />
      </button>
    </div>
    <.sb_entries entries={@entries} format="tree" id={@id} nav_class={@nav_class} flat={@flat} />
    <div :if={has_foot?(assigns)} class="lu-grow"></div>
    <div :if={foot_groups(@entries) != []}>
      <.sb_item :for={item <- foot_items(@entries)} item={item} format="tree" id={@id} />
    </div>
    <.sb_user :if={@footer_mode in ["user", "plan"] and @user} user={@user} />
    <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
    {render_slot(@sidebar_footer)}
    <div :if={@mobile_drawer != []} class="lu-sb-drawer" style="display:none">
      {render_slot(@mobile_drawer)}
    </div>
    """
  end

  defp sb_nested(assigns) do
    ~H"""
    <.sb_team brand={@brand_map} id={@id} />
    <.sb_entries entries={@entries} format="nested" id={@id} nav_class={@nav_class} flat={@flat} />
    <div :if={has_foot?(assigns)} class="lu-grow"></div>
    <div :if={foot_groups(@entries) != []}>
      <.sb_item :for={item <- foot_items(@entries)} item={item} format="nested" id={@id} />
    </div>
    <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
    <.sb_user_menu :if={@footer_mode in ["user", "plan"] and @user} user={@user} id={@id} />
    {render_slot(@sidebar_footer)}
    <div :if={@mobile_drawer != []} class="lu-sb-drawer" style="display:none">
      {render_slot(@mobile_drawer)}
    </div>
    """
  end

  defp sb_rail(assigns) do
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

    ~H"""
    <nav class="lu-rail" aria-label={@label} style="background:var(--bg-shell)">
      <span class="logo" data-part="rail-logo">
        <img
          :if={@brand_map[:src]}
          src={@brand_map[:src]}
          alt=""
          style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
        />
        <span :if={!@brand_map[:src]}>{@brand_map[:logo] || first_letter(@brand_map[:name])}</span>
      </span>
      <.rail_btn :if={@home} item={@home} />
      <.sb_avatar :if={@user && @footer_mode == "user"} user={@user} size={32} />
      <.rail_btn :for={g <- @groups} item={group_as_item(g)} on={g == @active_group} />
      <.rail_extra_btn :for={x <- @rail_extra} app={x} />
      <.rail_btn :for={i <- @others} item={i} />
      <div class="lu-grow"></div>
      <.rail_btn :for={i <- @foots} item={i} />
      <button
        :if={@collapsible}
        type="button"
        data-lu-sb-toggle
        class="lu-rail-btn"
        aria-label={@collapse_label}
      >
        <.icon name="sidebar" />
      </button>
    </nav>
    <div
      :if={@active_group}
      class="lu-subnav"
      data-part="rail-panel"
      style="background:var(--bg-panel);border-radius:0 18px 18px 0"
    >
      <h4>{@active_group.group}</h4>
      <.link
        :if={@active_group[:action]}
        {dest(@active_group.action) || [href: "#"]}
        class="lu-btn primary block"
        style="margin:0 0 10px"
      >
        <.icon :if={@active_group.action[:icon]} name={sb_icon(@active_group.action[:icon])} />{@active_group.action[
          :label
        ]}
      </.link>
      <.sb_group_items items={@active_group.items} id={@id} />
      <div :if={@active_group[:try]} class="lu-nav-h">{@active_group.try[:label] || "Try"}</div>
      <.sb_item
        :for={i <- (@active_group[:try] || %{})[:items] || []}
        item={normalize_item(i, "rail", @current, @match)}
        format="rail"
        id={@id}
      />
      <div class="lu-grow"></div>
      <.sb_trial :if={@trial} trial={@trial} />
      <.sb_version :if={@footer_mode == "version" and @version_map} version={@version_map} />
      {render_slot(@sidebar_footer)}
      <div :if={@mobile_drawer != []} class="lu-sb-drawer" style="display:none">
        {render_slot(@mobile_drawer)}
      </div>
    </div>
    """
  end

  ## Pieces

  attr :brand, :map, required: true
  attr :brand_mark, :list, default: []
  attr :switch, :boolean, default: true

  defp sb_brand(assigns) do
    brand = assigns.brand
    switch = Map.get(brand, :switch, true)
    click = is_map(switch) && switch[:click]

    assigns =
      assigns
      |> assign(:show_switch, assigns.switch and switch != false)
      |> assign(:click, click)
      |> assign(:switch_label, is_map(switch) && switch[:label])

    ~H"""
    <div
      :if={@brand != %{} or @brand_mark != []}
      class="lu-ws"
      data-part="brand"
      role={@click && "button"}
      phx-click={@click}
      aria-label={@switch_label}
    >
      <%= if @brand_mark != [] do %>
        {render_slot(@brand_mark)}
      <% else %>
        <span class="logo">
          <img
            :if={@brand[:src]}
            src={@brand[:src]}
            alt=""
            style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
          />
          <.chart_mark :if={!@brand[:src] and @brand[:mark]} />
          <%= if !@brand[:src] and !@brand[:mark] do %>
            {@brand[:logo] || first_letter(@brand[:name])}
          <% end %>
        </span>
        <span class="t">
          <b>{@brand[:name]}</b>
          <span :if={@brand[:sub]}>{@brand[:sub]}</span>
        </span>
      <% end %>
      <.icon
        :if={@show_switch and @brand != %{} and @brand_mark == [] and Map.has_key?(@brand, :switch)}
        name="updown"
        size="md"
        class="lu-muted"
      />
    </div>
    """
  end

  defp chart_mark(assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      height="18"
      style="fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round"
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
    menu = assigns.brand[:menu]
    assigns = assign(assigns, :menu, menu)

    ~H"""
    <div style="position:relative">
      <button
        type="button"
        class="lu-ws"
        data-part="team"
        style="width:100%;text-align:left;margin-bottom:6px"
        aria-haspopup={@menu && "menu"}
        phx-click={@menu && JS.toggle(to: "##{@id}-team")}
      >
        <span class="logo">
          <img
            :if={@brand[:src]}
            src={@brand[:src]}
            alt=""
            style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
          />
          <%= if !@brand[:src] do %>
            {@brand[:logo] || first_letter(@brand[:name])}
          <% end %>
        </span>
        <span class="t">
          <b>{@brand[:name]}</b>
          <span :if={@brand[:plan]}>{@brand[:plan]}</span>
        </span>
        <.icon name="updown" size="md" class="lu-muted" />
      </button>
      <div
        :if={@menu}
        id={"#{@id}-team"}
        class="lu-pop"
        role="menu"
        style="position:absolute;left:100%;top:0;margin-left:8px;z-index:50"
        hidden
        keep-hidden
        phx-click-away={JS.hide(to: "##{@id}-team")}
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
    <div style="position:relative">
      <div
        class="lu-user"
        role={@user[:menu] && "button"}
        tabindex={@user[:menu] && "0"}
        phx-click={@user[:menu] && JS.toggle(to: "##{@id}-user")}
        style="cursor:pointer"
      >
        <.sb_avatar user={@user} size={36} />
        <span class="lu-person lu-grow">
          <span class="t">
            <b>{@user[:name]}</b>
            <span :if={@user[:role] || @user[:email]}>{@user[:role] || @user[:email]}</span>
          </span>
        </span>
        <.icon name="updown" size="md" class="lu-muted" />
      </div>
      <div
        :if={@user[:menu]}
        id={"#{@id}-user"}
        class="lu-pop"
        role="menu"
        style="position:absolute;left:100%;bottom:0;margin-left:8px;z-index:50"
        hidden
        keep-hidden
        phx-click-away={JS.hide(to: "##{@id}-user")}
      >
        <div class="lu-person" style="padding:8px 10px">
          <.sb_avatar user={@user} size={32} />
          <span class="t"><b>{@user[:name]}</b><span :if={@user[:role] || @user[:email]}>{@user[:role] ||
            @user[:email]}</span></span>
        </div>
        <div class="lu-menu-sep"></div>
        <.sb_menu items={@user[:menu]} />
      </div>
    </div>
    """
  end

  attr :items, :list, required: true

  defp sb_menu(assigns) do
    ~H"""
    <%= for m <- @items do %>
      <div :if={m == :separator} class="lu-menu-sep"></div>
      <div :if={is_map(m) and m[:heading]} class="lu-menu-label">{m[:label]}</div>
      <%= if is_map(m) and !m[:heading] do %>
        <.link
          :if={dest(m)}
          {dest(m)}
          method={m[:method]}
          role="menuitem"
          class={cx(["lu-menu-item", m[:danger] && "danger"])}
        >
          <.icon :if={m[:icon]} name={sb_icon(m[:icon])} />{m[:label]}<span :if={m[:hint]} class="r">{m[
            :hint
          ]}</span>
        </.link>
        <button
          :if={!dest(m)}
          type="button"
          role="menuitem"
          phx-click={m[:click]}
          class={cx(["lu-menu-item", m[:danger] && "danger"])}
        >
          <.icon :if={m[:icon]} name={sb_icon(m[:icon])} />{m[:label]}<span :if={m[:hint]} class="r">{m[
            :hint
          ]}</span>
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
    assigns = assign(assigns, :runs, runs(assigns.entries, assigns.flat))

    ~H"""
    <%= for run <- @runs do %>
      <div
        :if={match?({:items, _}, run)}
        class={@nav_class}
        style="display:flex;flex-direction:column;gap:2px"
      >
        <.sb_item :for={i <- elem(run, 1)} item={i} format={@format} id={@id} />
      </div>
      <div :if={match?({:sep, _}, run)} class="lu-nav-sep"></div>
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
        key: g.group
      )

    ~H"""
    <div
      class="lu-nav-h"
      data-lu-sb-group={@collapsible && @key}
      aria-expanded={@collapsible && to_string(@open)}
      aria-controls={@collapsible && gid(@id, @key)}
      {style_attr(group_label_style(@format, @collapsible))}
    >
      <.icon :if={@collapsible && @format == "tree"} name="chevron-down" size="sm" />
      {@group.group}
      <.icon
        :if={@collapsible && @format != "tree"}
        name="chevron-down"
        size="sm"
        class="lu-sb-chev"
        style="margin-left:auto"
      />
    </div>
    <div id={gid(@id, @key)} hidden={!@open} keep-hidden>
      <div style="display:flex;flex-direction:column;gap:2px">
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
    title = assigns.item[:title] || (is_binary(d) && d) || nil
    assigns = assign(assigns, :title, title)

    ~H"""
    <span
      class="lu-nav-item lu-sb-item dis"
      aria-disabled="true"
      title={@title}
      style="opacity:.45;cursor:not-allowed"
    >
      <.sb_item_inner item={@item} format={@format} />
    </span>
    """
  end

  defp sb_item(assigns) do
    item = assigns.item
    kids = item[:children] || []
    tree? = assigns.format == "tree"
    parent? = kids != []
    key = item[:label]
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

    ~H"""
    <.link
      {@dest || [href: "#"]}
      class={cx(["lu-nav-item", @item[:active] && "on", @item[:class]])}
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
        class="caret"
      />
    </.link>
    <%= if @parent? do %>
      <%= if @tree? do %>
        <.link
          :for={{k, n} <- Enum.with_index(@kids)}
          {dest(k) || [href: "#"]}
          class={cx(["lu-nav-item sub", k[:active] && "on"])}
          aria-current={k[:active] && "page"}
          id={@collapsible && "#{kids_id(@id, @key)}-#{n}"}
          hidden={@collapsible && !@open}
          keep-hidden={@collapsible}
          data-lu-sb-child={@collapsible && @key}
        >
          {k[:label]}
        </.link>
      <% else %>
        <div style="margin-left:20px;padding-left:8px;border-left:1px solid var(--line);display:flex;flex-direction:column;gap:2px">
          <.link
            :for={k <- @kids}
            {dest(k) || [href: "#"]}
            class={cx(["lu-nav-item sub", k[:active] && "on"])}
            style="padding-left:10px;height:32px"
            aria-current={k[:active] && "page"}
          >
            <span :if={k[:color]} {style_attr(color_dot(k[:color]))}></span>{k[:label]}
          </.link>
        </div>
      <% end %>
    <% end %>
    """
  end

  attr :item, :map, required: true
  attr :format, :string, required: true

  defp sb_item_inner(assigns) do
    item = assigns.item
    chip? = assigns.format == "tree" and item[:color] != nil
    assigns = assign(assigns, chip?: chip?)

    ~H"""
    <span :if={@chip? and @item[:icon]} {style_attr(chip_style(@item[:color]))}><.icon name={
      sb_icon(@item[:icon])
    } /></span>
    <%= if !@chip? and @item[:icon] do %>
      <.icon name={sb_icon(@item[:icon])} />
    <% end %>
    {@item[:label]}
    <span :if={@item[:count] != nil} class={cx(["r", @item[:alert] && "alert"])}>{@item[:count]}</span>
    <span :if={@item[:kbd]} class="r"><kbd class="lu-kbd">{@item[:kbd]}</kbd></span>
    <span
      :if={@item[:badge]}
      class="r alert"
      role={is_binary(@item[:badge]) && "img"}
      aria-label={is_binary(@item[:badge]) && @item[:badge]}
    ></span>
    """
  end

  defp rail_btn(assigns) do
    assigns = assign_new(assigns, :on, fn -> assigns.item[:active] end)

    ~H"""
    <.link
      {dest(@item) || [href: "#"]}
      class={cx(["lu-rail-btn", @on && "on"])}
      aria-label={@item[:label]}
      aria-current={@on && "page"}
      title={@item[:label]}
    >
      <.icon name={sb_icon(@item[:icon] || "doc")} />
      <span :if={@item[:count] != nil} class="lu-count">{@item[:count]}</span>
      <span
        :if={@item[:badge]}
        class="lu-count"
        style="min-width:8px;width:8px;height:8px;padding:0;border-radius:50%"
      ></span>
    </.link>
    """
  end

  defp rail_extra_btn(assigns) do
    ~H"""
    <.link
      {dest(@app) || [href: "#"]}
      class="lu-rail-btn"
      aria-label={@app[:label]}
      title={@app[:label]}
      style={"border-radius:50%;background:#{chip_color(@app[:color])};color:#fff"}
    >
      <.icon name={sb_icon(@app[:icon] || "spark")} />
    </.link>
    """
  end

  attr :user, :map, required: true
  attr :size, :integer, default: 36

  defp sb_avatar(assigns) do
    ~H"""
    <span class={cx(["lu-av", av_tone(@user)])} style={"--s:#{@size}px;" <> av_color(@user)}>
      <img
        :if={@user[:avatar]}
        src={@user.avatar}
        alt=""
        style="width:100%;height:100%;border-radius:50%;object-fit:cover"
      />
      <%= if !@user[:avatar] do %>
        {user_initials(@user)}
      <% end %>
      <span :if={@user[:status]} class={cx(["st", to_string(@user[:status])])}></span>
    </span>
    """
  end

  attr :user, :map, required: true

  defp sb_user(assigns) do
    ~H"""
    <div class="lu-user" data-part="user">
      <.sb_avatar user={@user} size={36} />
      <span class="lu-person lu-grow">
        <span class="t">
          <b>{@user[:name]}</b>
          <span :if={@user[:role] || @user[:email]}>{@user[:role] || @user[:email]}</span>
        </span>
      </span>
      <.icon name="updown" size="md" class="lu-muted" />
    </div>
    """
  end

  attr :plan, :map, required: true

  defp sb_plan(assigns) do
    ~H"""
    <div class="lu-promo" data-part="plan">
      <div class="lu-row" style="flex-wrap:nowrap">
        <span class="ic"><.icon name="sparkles" size="md" /></span>
        <span class="lu-col" style="gap:0">
          <b>{@plan[:name]}</b>
          <span :if={@plan[:text]} class="lu-xs lu-muted">{@plan[:text]}</span>
        </span>
        <span :if={@plan[:badge]} class="lu-badge acc" style="margin-left:auto">{@plan[:badge]}</span>
      </div>
      <span :if={@plan[:description]} class="lu-small lu-ink2">{@plan[:description]}</span>
      <.link
        :if={@plan[:action] && dest(@plan[:action])}
        {dest(@plan[:action])}
        class="lu-btn primary block"
        style="justify-content:space-between"
      >
        <.plan_action action={@plan[:action]} />
      </.link>
      <button
        :if={@plan[:action] && !dest(@plan[:action])}
        type="button"
        class="lu-btn primary block"
        style="justify-content:space-between"
        phx-click={@plan[:action][:click]}
      >
        <.plan_action action={@plan[:action]} />
      </button>
    </div>
    """
  end

  defp plan_action(assigns) do
    ~H"""
    <span class="lu-row" style="gap:8px"><span class="lead" style="margin-left:-8px"><.icon
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
    <div class="lu-promo" data-part="trial">
      <b :if={@trial[:title]}>{@trial[:title]}</b>
      <span :if={@trial[:label]} class="lu-xs lu-muted">{@trial[:label]}</span>
      <span :if={@trial[:text]} class="lu-small lu-ink2">{@trial[:text]}</span>
      <span
        :if={@trial[:value]}
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@trial[:value]}
        style="display:block;height:6px;border-radius:3px;background:var(--bg-sunken);overflow:hidden"
      >
        <span style={"display:block;height:100%;width:#{@trial[:value]}%;background:var(--teal-500)"}></span>
      </span>
      <.link :if={@trial[:action]} {dest(@trial) || [href: "#"]} class="lu-btn primary block">{@trial[
        :action
      ]}</.link>
    </div>
    """
  end

  attr :version, :map, required: true

  defp sb_version(assigns) do
    v = assigns.version
    status = @statuses[to_string(v[:status] || "ok")] || ""
    full = if v[:build], do: "Version #{v.version} (#{v.build})", else: "Version #{v.version}"
    assigns = assign(assigns, status: status, full: full, link: dest(v))

    ~H"""
    <div
      class="lu-sb-version lu-xs lu-muted"
      data-part="version"
      title={@full}
      aria-label={@full}
      style="display:flex;align-items:center;gap:8px;padding:8px 10px"
    >
      <span class={cx(["lu-stat-dot", @status != "" && @status])}></span>
      <span class="mono lu-sb-vtext">{@version.version}</span>
      <span :if={@version[:build]} class="mono lu-sb-vtext">{@version.build}</span>
      <.link
        :if={@link}
        {@link}
        class="lu-sb-vtext"
        title={@version[:title]}
        style="margin-left:auto;color:var(--accent-ink);text-decoration:none"
      >
        {@version[:label] || "What's new"}
      </.link>
    </div>
    """
  end

  ## Data

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

  defp group_label_style("tree", _), do: "cursor:pointer"
  defp group_label_style(_, true), do: "cursor:pointer"

  defp group_label_style(_, _),
    do:
      "text-transform:uppercase;letter-spacing:.06em;font-family:var(--font-mono);font-size:11px"

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

  defp chip_color(nil), do: "var(--ink)"
  defp chip_color(c), do: Map.get(@colors, to_string(c), to_string(c))

  defp chip_style(color),
    do:
      "display:inline-grid;place-items:center;width:22px;height:22px;border-radius:6px;background:#{chip_color(color)};color:#fff;flex:none"

  defp color_dot(color),
    do: "width:8px;height:8px;border-radius:50%;background:#{chip_color(color)};flex:none"

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
  defp av_tone(%{color: c}) when is_binary(c), do: nil
  defp av_tone(%{name: n}) when is_binary(n), do: "t#{rem(:erlang.phash2(n), 5) + 1}"
  defp av_tone(_), do: "t1"

  defp av_color(%{color: c}) when is_binary(c), do: "background:#{c};color:#fff"
  defp av_color(_), do: ""

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
