defmodule LedgerUI.Components.AppShell do
  @moduledoc """
  The application shell: the page frame, the main sidebar (the icon rail), the sidebar panel with its
  collapsible groups, the minimized panel, the sideblock, the horizontal navigation, the header, the
  right sidebar, the framed menu, the page header and the mode toggles.

      <.app_shell id="shell" sidebar_open={@sidebar_open} on_toggle="sidebar">
        <:sidebar>
          <.main_sidebar current={@current_path}>
            <:logo navigate={~p"/"}><.icon name="grid" /></:logo>
            <:item navigate={~p"/dashboards"} label="Dashboards"><.icon name="home" /></:item>
          </.main_sidebar>
          <.sidebar_panel title="Layouts">
            <.sidebar_nav>
              <.sidebar_nav_link navigate={~p"/orders"} current={@current_path}>Orders</.sidebar_nav_link>
            </.sidebar_nav>
          </.sidebar_panel>
        </:sidebar>
        <:header><.header /></:header>
        <.page_header title="Avatar">
          <:crumb navigate={~p"/elements"}>Elements</:crumb>
          <:crumb>Avatar</:crumb>
        </.page_header>
      </.app_shell>

  The state kept in `<body>` classes by other kits lives on the shell root: `is-sidebar-open`
  (mirrored by the class `open`, so `LedgerUI.open/close/toggle(socket_or_js, "shell")` drive it),
  `has-min-sidebar`, `navigation:sideblock`, `navigation:horizontal`, `is-header-blur` and
  `is-header-not-sticky`.

  Hooks used: `LedgerUI.AppShell`, `LedgerUI.Sidebar` (framed menu), `LedgerUI.RightSidebar`,
  `LedgerUI.Clock` and `LedgerUI.MonochromeToggle`; dark mode is `theme_toggle/1` and
  `theme_script/1` of `LedgerUI.Components.ThemeSwitch`.

  Written for the `lu-*` stylesheet: where it has no class (the right sidebar, the framed rail,
  the phone tab bar) the rules live in `priv/static/ledger_ui.css`, loaded after `ledger.css`.
  """
  use LedgerUI.Component

  import LedgerUI.Components.ThemeSwitch, only: [theme_toggle: 1]

  ## App shell

  attr :id, :string, default: "app-shell"

  attr :layout, :string,
    default: "sidebar",
    values: ~w(sidebar minimal sideblock horizontal framed)

  attr :sidebar_open, :boolean, default: nil

  attr :full, :boolean,
    default: false,
    doc:
      "Full-screen app (`lu-app full`): no frame, border, radius or shadow, `min-height: 100vh`. " <>
        "Without it the non-framed layouts carry the same reset inline."

  attr :header_blur, :boolean, default: true
  attr :header_sticky, :boolean, default: true
  attr :persist, :boolean, default: true
  attr :preloader, :boolean, default: false
  attr :on_toggle, :any, default: nil
  attr :target, :any, default: nil
  attr :main_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :aside, doc: "Fixed parts: the right sidebar, drawers."
  slot :header, doc: "The `header/1`."
  slot :inner_block
  slot :sidebar, doc: "The main sidebar and its panel, or the sideblock."
  slot :tab_bar, doc: "A bottom bar of tabs for phones (`layout=\"framed\"`): a `tab_bar/1`."

  def app_shell(assigns) do
    layout = assigns.layout

    open =
      if is_nil(assigns.sidebar_open),
        do: layout in ["sidebar", "sideblock"],
        else: assigns.sidebar_open

    js? = match?(%Phoenix.LiveView.JS{}, assigns.on_toggle)

    assigns =
      assigns
      |> assign(:open, open)
      |> assign(
        :classes,
        cx([
          "lu-app lu-shell",
          layout == "framed" && "float",
          assigns.full && "full",
          open && "open is-sidebar-open",
          layout == "minimal" && "has-min-sidebar",
          layout == "sideblock" && "navigation:sideblock",
          layout == "horizontal" && "navigation:horizontal",
          assigns.header_blur && "is-header-blur",
          !assigns.header_sticky && "is-header-not-sticky",
          assigns.class
        ])
      )
      |> assign(:on_toggle_event, if(is_binary(assigns.on_toggle), do: assigns.on_toggle))
      |> assign(:on_toggle_js, if(js?, do: assigns.on_toggle))
      |> assign(:style, shell_style(assigns.rest, assigns.full))

    ~H"""
    <div
      id={@id}
      data-part="app-shell"
      data-layout={@layout}
      data-lu-overlay
      phx-hook="LedgerUI.AppShell"
      data-lu-persist={to_string(@persist)}
      data-lu-open={to_string(@open)}
      data-lu-layout={@layout}
      data-lu-on-toggle={@on_toggle_event}
      data-lu-target={is_binary(@target) && @target}
      data-on-toggle-js={@on_toggle_js}
      class={@classes}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      <div
        :if={@preloader}
        class="lu-preloader"
        data-preloader
        style="position:fixed;inset:0;z-index:100;background:var(--bg-page);display:grid;place-items:center"
      >
        <span class="lu-spin"></span>
      </div>
      {render_slot(@sidebar)}
      <main class={cx(["main-content", @main_class])} style="min-width:0">
        {render_slot(@header)}
        {render_slot(@inner_block)}
      </main>
      {render_slot(@aside)}
      <div :if={@tab_bar != []} class="lu-tabbar-slot">{render_slot(@tab_bar)}</div>
    </div>
    """
  end

  defp shell_style(rest, full) do
    base = if full, do: nil, else: "min-height:100vh;border-radius:0;border:0;box-shadow:none"

    case rest do
      %{style: s} when is_binary(s) and s != "" -> if base, do: base <> ";" <> s, else: s
      _ -> base
    end
  end

  ## Main sidebar (icon rail)

  attr :id, :string, default: "main-sidebar"
  attr :current, :string, default: nil
  attr :centered, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  slot :bottom

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :label, :string
    attr :active, :boolean
    attr :class, :any
    attr :style, :string
  end

  slot :logo do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :src, :string
    attr :alt, :string
  end

  @doc "The main sidebar: the icon rail with the logo, the section links and the bottom links."
  def main_sidebar(assigns) do
    ~H"""
    <nav id={@id} data-part="main-sidebar" class={cx(["lu-rail", @class])} {@rest}>
      <%= for l <- @logo do %>
        <.link :if={link_to(l)} {link_to(l)} class="logo">
          <img
            :if={l[:src]}
            src={l.src}
            alt={l[:alt] || ""}
            style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
          />
          {render_slot(l)}
        </.link>
        <span :if={!link_to(l)} class="logo">
          <img
            :if={l[:src]}
            src={l.src}
            alt={l[:alt] || ""}
            style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
          />
          {render_slot(l)}
        </span>
      <% end %>
      <div :if={@centered} class="lu-grow"></div>
      <.main_sidebar_link
        :for={item <- @item}
        label={item[:label]}
        active={item[:active] || false}
        current={@current}
        class={item[:class]}
        {style_attr(item[:style])}
        href={item[:href]}
        navigate={item[:navigate]}
        patch={item[:patch]}
      >
        {render_slot(item)}
      </.main_sidebar_link>
      <div :if={@bottom != [] or @centered} class="lu-grow"></div>
      {render_slot(@bottom)}
    </nav>
    """
  end

  attr :label, :string, default: nil, doc: "The tooltip and the accessible name."
  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true

  @doc "One icon link of the main sidebar."
  def main_sidebar_link(assigns) do
    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(:cur, current?(assigns.rest, assigns.current))
      |> assign(:to, link_to(assigns.rest))

    ~H"""
    <.link
      :if={@to}
      {@to}
      class={cx(["lu-rail-btn", @on && "on", @class])}
      aria-label={@label}
      aria-current={@on && "page"}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={!@to}
      type="button"
      class={cx(["lu-rail-btn", @on && "on", @class])}
      aria-label={@label}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :id, :string, required: true
  attr :src, :string, required: true
  attr :alt, :string, default: "avatar"
  attr :name, :string, required: true
  attr :subtitle, :string, default: nil

  attr :status, :string,
    default: "success",
    values: [nil, "", "success", "warning", "error", "info", "neutral"]

  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :footer

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :method, :string
    attr :color, :string
    attr :title, :string
    attr :description, :string
  end

  @status_class %{
    "success" => "",
    "warning" => "away",
    "error" => "busy",
    "info" => "",
    "neutral" => "off"
  }

  @doc "The avatar at the bottom of the main sidebar and the profile box it opens on its right."
  def sidebar_profile(assigns) do
    assigns = assign(assigns, :st, @status_class[assigns.status || ""])
    box = "#{assigns.id}-box"
    assigns = assign(assigns, :box, box)

    ~H"""
    <div
      id={@id}
      data-part="sidebar-profile"
      class={cx(["lu-sb-profile", @class])}
      style="position:relative"
      phx-click-away={JS.hide(to: "##{@box}")}
      {@rest}
    >
      <button
        type="button"
        aria-haspopup="menu"
        aria-controls={@box}
        aria-label={@name}
        class="lu-rail-btn"
        phx-click={JS.toggle(to: "##{@box}")}
      >
        <span class="lu-av" style="--s:36px">
          <img
            src={@src}
            alt={@alt}
            style="width:100%;height:100%;border-radius:50%;object-fit:cover"
          />
          <span :if={@status} class={cx(["st", @st])}></span>
        </span>
      </button>
      <div
        id={@box}
        class="lu-pop"
        role="menu"
        style="position:absolute;left:calc(100% + 8px);bottom:0;z-index:50;width:260px;text-align:left"
        hidden
        keep-hidden
      >
        <div class="lu-person" style="padding:8px 10px">
          <span class="lu-av" style="--s:40px"><img
            src={@src}
            alt={@alt}
            style="width:100%;height:100%;border-radius:50%;object-fit:cover"
          /></span>
          <span class="t">
            <b>{@name}</b>
            <span :if={@subtitle}>{@subtitle}</span>
          </span>
        </div>
        <div class="lu-menu-sep"></div>
        <.link
          :for={item <- @item}
          {link_to(item) || [href: "#"]}
          method={item[:method]}
          role="menuitem"
          class="lu-menu-item media"
          phx-click={JS.hide(to: "##{@box}")}
        >
          <span class={cx(["lu-ic", item_tone(item[:color])])}>{render_slot(item)}</span>
          <span class="tx">
            <span>{item[:title]}</span>
            <small :if={item[:description]}>{item[:description]}</small>
          </span>
        </.link>
        <div :if={@footer != []} style="padding:6px">{render_slot(@footer)}</div>
      </div>
    </div>
    """
  end

  ## Sidebar panel

  attr :title, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The sidebar panel next to the main sidebar: its title and the scrolling body."
  def sidebar_panel(assigns) do
    ~H"""
    <div data-part="sidebar-panel" class={cx(["lu-subnav", @class])} {@rest}>
      <h4>{@title}</h4>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A list of the sidebar panel (or the sideblock)."
  def sidebar_nav(assigns) do
    ~H"""
    <nav
      data-part="sidebar-nav"
      class={cx(["lu-sb-nav", @class])}
      style="display:flex;flex-direction:column;gap:2px"
      {@rest}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true

  @doc "A plain link of the sidebar panel, active with `active` or when its path is `current`."
  def sidebar_nav_link(assigns) do
    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(:cur, current?(assigns.rest, assigns.current))
      |> assign(:to, link_to(assigns.rest) || [href: "#"])

    ~H"""
    <.link
      {@to}
      class={cx(["lu-nav-item", @on && "on", @class])}
      aria-current={@on && "page"}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :id, :string, default: nil, doc: "Defaults to `sidebar-group-<label>`."
  attr :label, :string, required: true
  attr :open, :boolean, default: nil

  attr :name, :string,
    default: "sidebar-nav",
    doc: "Groups with the same name open one at a time."

  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
  end

  @doc "A collapsible group of the sidebar panel. It opens when one of its items is active (or with `open`)."
  def sidebar_nav_group(assigns) do
    id = assigns.id || "sidebar-group-" <> slug(assigns.label)

    items =
      Enum.map(assigns.item, fn i ->
        Map.put(i, :on, i[:active] || current?(i, assigns.current))
      end)

    open = if is_nil(assigns.open), do: Enum.any?(items, & &1.on), else: assigns.open
    name = assigns.name

    toggle =
      %JS{}
      |> JS.hide(to: ~s|[data-lu-sb-body="#{name}"]:not(##{id}-body)|)
      |> JS.set_attribute({"aria-expanded", "false"},
        to: ~s|[data-lu-sb-head="#{name}"]:not(##{id}-head)|
      )
      |> JS.toggle(to: "##{id}-body")
      |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-head")

    assigns =
      assigns |> assign(id: id, items: items, is_open: open, toggle: toggle)

    ~H"""
    <div id={@id} data-part="sidebar-nav-group" class={cx(["lu-sb-group", @class])} {@rest}>
      <button
        id={"#{@id}-head"}
        type="button"
        class="lu-nav-item"
        data-lu-sb-head={@name}
        aria-expanded={to_string(@is_open)}
        aria-controls={"#{@id}-body"}
        phx-click={@toggle}
      >
        {@label}
        <.icon name="chevron-down" class="caret" />
      </button>
      <div id={"#{@id}-body"} data-lu-sb-body={@name} hidden={!@is_open} keep-hidden>
        <div style="display:flex;flex-direction:column;gap:2px">
          <.link
            :for={i <- @items}
            {link_to(i) || [href: "#"]}
            class={cx(["lu-nav-item sub", i.on && "on"])}
            aria-current={i.on && "page"}
          >
            {render_slot(i)}
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil

  @doc "The line between the lists of the sidebar panel."
  def sidebar_nav_divider(assigns) do
    ~H"""
    <div data-part="sidebar-nav-divider" class={cx(["lu-nav-sep", @class])}></div>
    """
  end

  ## Minimized panel

  attr :class, :any, default: nil
  attr :rest, :global
  slot :footer
  slot :header
  slot :inner_block, required: true

  @doc "The minimized sidebar panel (`layout=\"minimal\"`): a header, the icon links and a footer."
  def sidebar_panel_min(assigns) do
    ~H"""
    <div
      data-part="sidebar-panel-min"
      class={@class}
      style="width:64px;flex:none;display:flex;flex-direction:column;align-items:center;gap:6px;padding:12px 0;border-left:1px solid var(--line)"
      {@rest}
    >
      <div :if={@header != []}>{render_slot(@header)}</div>
      {render_slot(@inner_block)}
      <div class="lu-grow"></div>
      <div :if={@footer != []}>{render_slot(@footer)}</div>
    </div>
    """
  end

  attr :class, :any, default: nil
  slot :inner_block, required: true

  @doc "A list of icon links of the minimized panel."
  def sidebar_min_group(assigns) do
    ~H"""
    <div
      data-part="sidebar-min-group"
      class={cx(["lu-sb-min-group", @class])}
      style="display:flex;flex-direction:column;align-items:center;gap:6px"
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @tones ~w(neutral primary secondary info success warning error)

  attr :label, :string, default: nil
  attr :color, :string, default: "neutral", values: @tones
  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true

  @doc "An icon link of the minimized panel. Active links are accent soft, the others take `color`."
  def sidebar_min_link(assigns) do
    on = assigns.active or current?(assigns.rest, assigns.current)
    tone = if on, do: "c-primary", else: "c-#{assigns.color}"
    assigns = assign(assigns, on: on, tone: tone, to: link_to(assigns.rest) || [href: "#"])

    ~H"""
    <.link
      {@to}
      aria-label={@label}
      aria-current={@on && "page"}
      class={cx(["lu-rail-btn", @on && "on", @tone, @class])}
      {style_attr(@on && "background:var(--accent-soft);color:var(--accent-ink)")}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :class, :any, default: nil

  @doc "The line between the lists of the minimized panel."
  def sidebar_min_divider(assigns) do
    ~H"""
    <div
      data-part="sidebar-min-divider"
      class={cx(["lu-nav-sep", @class])}
      style="width:28px;margin:6px 0"
    >
    </div>
    """
  end

  ## Sideblock

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  slot :logo do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :src, :string
    attr :alt, :string
  end

  @doc "The sideblock (`layout=\"sideblock\"`): one wide sidebar with the logo and the navigation."
  def sideblock(assigns) do
    ~H"""
    <aside data-part="sideblock" class={cx(["lu-side lu-sideblock", @class])} {@rest}>
      <%= for l <- @logo do %>
        <.link {link_to(l) || [href: "#"]} class="lu-ws" style="margin-bottom:8px">
          <span class="logo">
            <img
              :if={l[:src]}
              src={l.src}
              alt={l[:alt] || ""}
              style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
            />
            {render_slot(l)}
          </span>
        </.link>
      <% end %>
      {render_slot(@inner_block)}
    </aside>
    """
  end

  ## Header

  attr :id, :string, default: "app-header"
  attr :toggle, :boolean, default: true
  attr :search, :boolean, default: true
  attr :search_placeholder, :string, default: "Search here..."
  attr :search_input, :map, default: %{}
  attr :theme_toggle, :boolean, default: true
  attr :monochrome_toggle, :boolean, default: true
  attr :right_sidebar, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :mobile_search

  slot :brand do
    attr :href, :string
    attr :navigate, :string
    attr :src, :string
    attr :label, :string
  end

  slot :nav

  slot :notifications do
    attr :dot, :boolean
    attr :label, :string
  end

  slot :profile
  slot :search_results
  slot :start

  @doc """
  The header: the animated sidebar toggle, the search bar, the dark mode and monochrome toggles, the
  notifications, the right sidebar toggle and a profile slot. With a `:nav` slot it is the
  horizontal navigation header: the `:brand` and the navigation row below.
  """
  def header(%{nav: [_ | _]} = assigns) do
    ~H"""
    <header
      id={@id}
      data-part="header"
      class={cx(["lu-topbar", @class])}
      style="height:auto;flex-wrap:wrap;gap:10px 16px"
      {@rest}
    >
      <.sidebar_toggle :if={@toggle} class="lu-hdr-burger" />
      <.link
        :for={b <- @brand}
        {link_to(b) || [href: "#"]}
        style="display:inline-flex;align-items:center;gap:8px;font-weight:600;color:var(--ink);text-decoration:none"
      >
        <img :if={b[:src]} src={b.src} alt="" style="width:28px;height:28px;border-radius:8px" />{b[
          :label
        ]}
      </.link>
      <div class="lu-grow"></div>
      <.hdr_tools {assigns} />
      <nav style="flex-basis:100%;display:flex;align-items:center;gap:4px;padding-bottom:8px">
        {render_slot(@nav)}
      </nav>
    </header>
    """
  end

  def header(assigns) do
    ~H"""
    <header id={@id} data-part="header" class={cx(["lu-topbar", @class])} {@rest}>
      <.sidebar_toggle :if={@toggle} />
      {render_slot(@start)}
      <div class="lu-grow" style="flex:1"></div>
      <.hdr_tools {assigns} />
    </header>
    """
  end

  defp hdr_tools(assigns) do
    ~H"""
    <div :if={@search} style="position:relative" phx-click-away={JS.hide(to: "##{@id}-results")}>
      <span class="lu-input search" style="width:280px;height:40px;border-radius:12px">
        <.icon name="search" size="md" />
        <input
          type="search"
          placeholder={@search_placeholder}
          phx-focus={JS.show(to: "##{@id}-results")}
          autocomplete="off"
          {@search_input}
        />
      </span>
      <div
        :if={@search_results != [] or @mobile_search != []}
        id={"#{@id}-results"}
        class="lu-pop"
        style="position:absolute;top:calc(100% + 6px);left:0;right:0;z-index:50"
        hidden
        keep-hidden
      >
        {render_slot(@search_results)}
        {render_slot(@mobile_search)}
      </div>
    </div>
    {render_slot(@actions)}
    <.theme_toggle :if={@theme_toggle} id={"#{@id}-theme"} />
    <.monochrome_toggle :if={@monochrome_toggle} id={"#{@id}-mono"} />
    <div
      :for={n <- @notifications}
      style="position:relative"
      phx-click-away={JS.hide(to: "##{@id}-notifications")}
    >
      <button
        type="button"
        class={cx(["lu-tbtn", n[:dot] && "dot"])}
        aria-label={n[:label] || "Notifications"}
        aria-controls={"#{@id}-notifications"}
        phx-click={JS.toggle(to: "##{@id}-notifications")}
      >
        <.icon name="bell" />
      </button>
      <div
        id={"#{@id}-notifications"}
        class="lu-pop"
        style="position:absolute;right:0;top:calc(100% + 8px);z-index:50;width:340px"
        hidden
        keep-hidden
      >
        {render_slot(n)}
      </div>
    </div>
    <.right_sidebar_toggle :if={@right_sidebar} target={@right_sidebar} />
    {render_slot(@profile)}
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The animated hamburger: three bars that turn into an arrow while the sidebar is open."
  def sidebar_toggle(assigns) do
    ~H"""
    <button
      type="button"
      data-sidebar-toggle
      aria-label="Toggle sidebar"
      class={cx(["lu-tbtn lu-sb-toggle", @class])}
      {@rest}
    >
      <.icon name="menu" />
    </button>
    """
  end

  ## Horizontal navigation

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon
  slot :inner_block

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
  end

  @doc "A dropdown of the horizontal navigation: an icon and a label, and a box of links."
  def horizontal_nav_menu(assigns) do
    items =
      Enum.map(assigns.item, &Map.put(&1, :on, &1[:active] || current?(&1, assigns.current)))

    on = assigns.active or Enum.any?(items, & &1.on)
    assigns = assign(assigns, items: items, on: on)

    ~H"""
    <div
      id={@id}
      data-part="horizontal-nav-menu"
      class={cx(["lu-hnav", @class])}
      style="position:relative"
      phx-click-away={JS.hide(to: "##{@id}-box")}
      {@rest}
    >
      <button
        type="button"
        class={cx(["lu-nav-item", @on && "on"])}
        style="width:auto;height:34px"
        aria-haspopup="menu"
        aria-controls={"#{@id}-box"}
        aria-current={@on && "page"}
        phx-click={JS.toggle(to: "##{@id}-box")}
      >
        {render_slot(@icon)}{@label}<.icon name="chevron-down" size="sm" />
      </button>
      <div
        id={"#{@id}-box"}
        class="lu-pop"
        role="menu"
        style="position:absolute;top:calc(100% + 6px);left:0;z-index:50"
        hidden
        keep-hidden
      >
        <.link
          :for={i <- @items}
          {link_to(i) || [href: "#"]}
          role="menuitem"
          class={cx(["lu-menu-item", i.on && "sel"])}
          phx-click={JS.hide(to: {:closest, ".lu-pop"})}
        >
          {render_slot(i)}
        </.link>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true

  @doc "A link of a horizontal navigation box. A click closes the box."
  def horizontal_nav_link(assigns) do
    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(:cur, current?(assigns.rest, assigns.current))
      |> assign(:to, link_to(assigns.rest) || [href: "#"])

    ~H"""
    <.link
      {@to}
      role="menuitem"
      class={cx(["lu-menu-item", @on && "sel", @class])}
      aria-current={@on && "page"}
      phx-click={JS.hide(to: {:closest, ".lu-pop"})}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :class, :any, default: nil

  @doc "The line between the links of a horizontal navigation box."
  def horizontal_nav_divider(assigns) do
    ~H"""
    <div data-part="horizontal-nav-divider" class={cx(["lu-menu-sep", @class])}></div>
    """
  end

  ## Right sidebar

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :label, :string, default: "Sidebar"
  attr :persist_tab, :boolean, default: false
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :footer
  slot :inner_block
  slot :title

  @doc """
  A drawer from the right with an overlay, a top row (`:title` and the close button), the content and
  a `:footer`. Opened with `open`, `right_sidebar_toggle/1` or `LedgerUI.open/close/toggle(id)`; Esc,
  the overlay and the close button close it.
  """
  def right_sidebar(assigns) do
    assigns =
      assigns
      |> assign(:on_open_event, if(is_binary(assigns.on_open), do: assigns.on_open))
      |> assign(:on_close_event, if(is_binary(assigns.on_close), do: assigns.on_close))
      |> assign(:on_open_js, match?(%Phoenix.LiveView.JS{}, assigns.on_open) && assigns.on_open)
      |> assign(
        :on_close_js,
        match?(%Phoenix.LiveView.JS{}, assigns.on_close) && assigns.on_close
      )

    ~H"""
    <div
      id={@id}
      data-part="right-sidebar"
      data-lu-overlay
      phx-hook="LedgerUI.RightSidebar"
      data-lu-persist-tab={@persist_tab && "true"}
      data-lu-on-open={@on_open_event}
      data-lu-on-close={@on_close_event}
      data-lu-target={is_binary(@target) && @target}
      data-on-open-js={@on_open_js}
      data-on-close-js={@on_close_js}
      class={cx(["lu-rs", @open && "open", @class])}
      style="display:none"
      {@rest}
    >
      <div class="lu-scrim" data-rs-close aria-hidden="true"></div>
      <aside role="dialog" aria-label={@label} class="lu-rs-panel">
        <div class="lu-rs-top">
          <div style="flex:1;min-width:0">{render_slot(@title)}</div>
          <button type="button" class="lu-tbtn" data-rs-close aria-label="Close"><.icon name="x" /></button>
        </div>
        <div class="lu-rs-body">{render_slot(@inner_block)}</div>
        <div :if={@footer != []} class="lu-rs-foot">{render_slot(@footer)}</div>
      </aside>
    </div>
    """
  end

  attr :target, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The header button that toggles a `right_sidebar/1`."
  def right_sidebar_toggle(assigns) do
    ~H"""
    <button
      type="button"
      aria-label="Toggle right sidebar"
      aria-controls={@target}
      class={cx(["lu-tbtn", @class])}
      phx-click={LedgerUI.toggle(@target)}
      {@rest}
    >
      <.icon name="grid" />
    </button>
    """
  end

  ## Framed shell

  attr :id, :string, required: true
  attr :collapsed, :boolean, default: false
  attr :persist, :boolean, default: true
  attr :on_collapse, :string, default: nil
  attr :shortcut, :string, default: "b"
  attr :target, :any, default: nil
  attr :label, :string, default: "Main menu"
  attr :mobile_label, :string, default: "Menu"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :bottom
  slot :brand
  slot :inner_block, required: true

  slot :search do
    attr :id, :string
    attr :class, :string
    attr :title, :string
    attr :"aria-label", :string
    attr :"phx-click", :any
    attr :"phx-target", :any
  end

  slot :wordmark
  slot :workspace

  @doc """
  The menu of the framed shell: the brand, an optional workspace and search, the navigation
  (`rail_link/1`, `rail_module/1`) and the bottom items. It collapses to a rail of icons (anything
  with the class `rail-label` goes away, badges become dots) and the choice is kept in
  `localStorage`. Below 768px it is a top bar with a hamburger.
  """
  def framed_sidebar(assigns) do
    ~H"""
    <aside
      id={@id}
      data-part="framed-sidebar"
      phx-hook="LedgerUI.Sidebar"
      data-lu-collapsed={to_string(@collapsed)}
      data-lu-persist={to_string(@persist)}
      data-lu-shortcut={@shortcut}
      data-lu-on-collapse={@on_collapse}
      data-lu-target={is_binary(@target) && @target}
      aria-label={@label}
      class={cx(["lu-side lu-side-framed", @class])}
      style="background:transparent;width:248px"
      {@rest}
    >
      <div
        :if={@brand != [] or @wordmark != []}
        class="lu-ws"
        style="border:0;box-shadow:none;background:none;cursor:default"
      >
        <span :if={@brand != []} class="logo">{render_slot(@brand)}</span>
        <span :if={@wordmark != []} class="t rail-label"><b>{render_slot(@wordmark)}</b></span>
        <button
          type="button"
          data-lu-sb-burger
          aria-label={@mobile_label}
          aria-expanded="false"
          class="lu-tbtn lu-sb-burger"
          style="display:none"
        >
          <.icon name="menu" />
        </button>
      </div>
      <div :if={@workspace != []} class="rail-label">{render_slot(@workspace)}</div>
      <%= for s <- @search do %>
        <button
          type="button"
          id={s[:id]}
          title={s[:title]}
          aria-label={s[:"aria-label"]}
          phx-click={s[:"phx-click"]}
          phx-target={s[:"phx-target"]}
          class={cx(["lu-input search", s[:class]])}
          style="width:100%;cursor:pointer;text-align:left;margin:4px 0 8px"
        >
          {render_slot(s)}
        </button>
      <% end %>
      <nav style="display:flex;flex-direction:column;gap:2px">{render_slot(@inner_block)}</nav>
      <div class="lu-grow"></div>
      <div :if={@bottom != []} style="display:flex;flex-direction:column;gap:2px">
        {render_slot(@bottom)}
      </div>
    </aside>
    """
  end

  attr :label, :string, default: "Sections"
  attr :current, :string, default: nil
  attr :variant, :string, default: "default", values: ~w(default canvas)
  attr :match, :string, default: "exact", values: ~w(exact prefix)
  attr :class, :any, default: nil
  attr :rest, :global

  slot :tab, required: true do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :label, :string
    attr :active, :boolean
    attr :class, :string
    attr :match, :string
  end

  @doc "A phone's bottom bar of tabs: one icon per section, the current one in the accent color."
  def tab_bar(assigns) do
    tabs =
      Enum.map(assigns.tab, fn t ->
        on = t[:active] || tab_match?(t, assigns.current, t[:match] || assigns.match)
        Map.put(t, :on, on)
      end)

    assigns = assign(assigns, :tabs, tabs)

    ~H"""
    <nav
      data-part="tab-bar"
      aria-label={@label}
      class={cx(["lu-tabbar", @variant == "canvas" && "canvas", @class])}
      style="display:flex;justify-content:space-around;align-items:center;gap:4px;padding:6px 8px;background:var(--bg-panel);border-top:1px solid var(--line)"
      {@rest}
    >
      <.link
        :for={t <- @tabs}
        {link_to(t) || [href: "#"]}
        aria-label={t[:label]}
        aria-current={t.on && "page"}
        class={cx(["lu-tab-item", t[:class], t.on && "on"])}
        style={"display:flex;flex-direction:column;align-items:center;gap:2px;flex:1;padding:6px 0;text-decoration:none;font-size:11px;color:#{if t.on, do: "var(--accent-ink)", else: "var(--muted)"}"}
      >
        {render_slot(t)}
        <span :if={@variant == "canvas"}>{t[:label]}</span>
      </.link>
    </nav>
    """
  end

  attr :for, :string, required: true, doc: "The id of the `framed_sidebar/1`."
  attr :label, :string, default: "Collapse menu"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "A button that collapses and expands the `framed_sidebar/1` with that id, from anywhere."
  def rail_toggle(assigns) do
    ~H"""
    <button
      type="button"
      data-rail-toggle={@for}
      aria-label={@label}
      aria-pressed="false"
      class={cx(["lu-tbtn", @class])}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        <.icon name="sidebar" />
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  attr :label, :string, required: true
  attr :badge, :string, default: nil
  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true

  @doc "A page of the framed menu: the icon, the label, an optional badge and a tooltip for the rail."
  def rail_link(assigns) do
    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(:cur, current?(assigns.rest, assigns.current))
      |> assign(:to, link_to(assigns.rest) || [href: "#"])

    ~H"""
    <.link
      {@to}
      class={cx(["lu-nav-item", @on && "on", @class])}
      aria-current={@on && "page"}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      {render_slot(@inner_block)}<span class="rail-label">{@label}</span>
      <span :if={@badge} class="r lu-sb-badge">{@badge}</span>
    </.link>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A small uppercase title over a group of `rail_link/1`s; hidden in the rail."
  def rail_heading(assigns) do
    ~H"""
    <div
      data-part="rail-heading"
      class={cx(["lu-nav-h rail-label", @class])}
      style="text-transform:uppercase;letter-spacing:.06em;font-family:var(--font-mono);font-size:11px"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :badge, :string, default: nil
  attr :open, :boolean, default: nil
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, required: true

  slot :item, required: true do
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :active, :boolean
  end

  @doc "A module of the framed menu: a button that opens the pages under it."
  def rail_module(assigns) do
    items =
      Enum.map(assigns.item, &Map.put(&1, :on, &1[:active] || current?(&1, assigns.current)))

    any = Enum.any?(items, & &1.on)
    open = if is_nil(assigns.open), do: any, else: assigns.open
    id = assigns.id

    toggle =
      %JS{}
      |> JS.toggle(to: "##{id}-body")
      |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-head")

    assigns = assign(assigns, items: items, any: any, is_open: open, toggle: toggle)

    ~H"""
    <div id={@id} data-part="rail-module" class={@class} {@rest}>
      <button
        id={"#{@id}-head"}
        type="button"
        data-lu-sb-module
        class={cx(["lu-nav-item", @any && "on"])}
        aria-expanded={to_string(@is_open)}
        aria-controls={"#{@id}-body"}
        phx-click={@toggle}
      >
        {render_slot(@icon)}<span class="rail-label">{@label}</span>
        <span :if={@badge} class="r lu-sb-badge">{@badge}</span>
        <.icon name="chevron-down" class="caret" />
      </button>
      <div id={"#{@id}-body"} hidden={!@is_open} keep-hidden class="rail-label">
        <div style="display:flex;flex-direction:column;gap:2px">
          <.link
            :for={i <- @items}
            {link_to(i) || [href: "#"]}
            class={cx(["lu-nav-item sub", i.on && "on"])}
            aria-current={i.on && "page"}
          >
            {render_slot(i)}
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :subtitle, :string, default: nil
  attr :initials, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "The workspace switcher under the brand of the framed menu. It is a button: `phx-click` opens your list."
  def rail_workspace(assigns) do
    assigns = assign(assigns, :ini, assigns.initials || initials(assigns.name))

    ~H"""
    <button
      type="button"
      data-part="rail-workspace"
      class={cx(["lu-ws rail-label", @class])}
      style="width:100%;text-align:left"
      {@rest}
    >
      <span class="logo" style="background:var(--accent-soft);color:var(--accent-ink);font-weight:600">
        <%= if @inner_block == [] do %>
          {@ini}
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </span>
      <span class="t">
        <b>{@name}</b>
        <span :if={@subtitle}>{@subtitle}</span>
      </span>
      <.icon name="updown" size="md" class="lu-muted" />
    </button>
    """
  end

  attr :name, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The person at the bottom of the framed menu: their picture and, outside the rail, their name."
  def rail_user(assigns) do
    ~H"""
    <div data-part="rail-user" class={cx(["lu-user", @class])} {@rest}>
      {render_slot(@inner_block)}
      <span class="lu-person lu-grow rail-label">
        <span class="t">
          <b>{@name}</b>
          <span :if={@subtitle}>{@subtitle}</span>
        </span>
      </span>
    </div>
    """
  end

  ## Page header

  attr :title, :string, default: nil, doc: "The title text. Or give the `:title` slot."

  attr :title_class, :any,
    default: nil,
    doc: "Classes of the `h1` (the canvas animates it with `mo-stg`)."

  attr :variant, :string, default: "inline", values: ~w(inline page)
  attr :description, :string, default: nil
  attr :back, :string, default: nil
  attr :back_label, :string, default: nil
  attr :badge_position, :string, default: "above", values: ~w(above inline)
  attr :clock, :boolean, default: false
  attr :locale, :string, default: nil
  attr :bell, :boolean, default: false
  attr :bell_label, :string, default: "Notifications"
  attr :on_bell, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :badge

  slot :crumb do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
  end

  slot :icon
  slot :inner_block
  slot :leading
  slot :notifications
  slot :subtitle, doc: "A description with markup, instead of `description`."
  slot :tabs
  slot :heading, doc: "The content of the `h1` with markup, instead of `title`."

  @doc """
  The title of a page. `variant="inline"` is the row: title (with the breadcrumb above it), a
  description and the `:actions` at the right, then the `:tabs`. `variant="page"` is the framed
  shell's title block: a top row (the `:leading` slot, the crumbs, the clock and the bell) or a
  `back` link, the badge, the title with a context line and the actions, and the tabs.
  """
  def page_header(%{variant: "inline"} = assigns) do
    ~H"""
    <div data-part="page-header" class={cx(["lu-page-h", @class])} {@rest}>
      <div>
        <.ph_crumbs :if={@crumb != []} crumb={@crumb} />
        <h1 {if @title_class, do: [class: @title_class], else: []}>
          {if @heading != [], do: render_slot(@heading), else: @title}
        </h1>
        <p :if={@description}>{@description}</p>
        <p :if={@subtitle != []}>{render_slot(@subtitle)}</p>
        {render_slot(@inner_block)}
      </div>
      <div :if={@actions != []} class="act">{render_slot(@actions)}</div>
    </div>
    <div :if={@tabs != []} style="padding:0 28px">{render_slot(@tabs)}</div>
    """
  end

  def page_header(assigns) do
    assigns =
      assigns
      |> assign(:page?, assigns.variant == "page")
      |> assign(
        :top?,
        assigns.crumb != [] or assigns.clock or assigns.bell or assigns.leading != []
      )
      |> assign(:bell_click, bell_click(assigns.on_bell))

    ~H"""
    <div
      data-part="page-header"
      class={cx(["lu-page-h", @class])}
      {style_attr(@page? && "flex-direction:column;align-items:stretch;gap:10px;padding-bottom:0")}
      {@rest}
    >
      <div
        :if={@page? and !@back and @top?}
        style="display:flex;align-items:center;gap:10px;min-height:32px"
      >
        {render_slot(@leading)}
        <.ph_crumbs :if={@crumb != []} crumb={@crumb} />
        <span class="lu-grow" style="flex:1"></span>
        <span
          :if={@clock}
          id={@rest[:id] && "#{@rest[:id]}-clock"}
          phx-hook="LedgerUI.Clock"
          data-lu-locale={@locale}
          class="lu-xs lu-muted mono"
        ></span>
        <%= if @notifications != [] do %>
          {render_slot(@notifications)}
        <% else %>
          <button
            :if={@bell}
            type="button"
            class="lu-tbtn"
            aria-label={@bell_label}
            phx-click={@bell_click}
          >
            <.icon name="bell" />
          </button>
        <% end %>
      </div>
      <.link
        :if={@page? and @back}
        navigate={@back}
        class="lu-btn link sm"
        style="align-self:flex-start"
      >
        <.icon name="chevron-left" size="sm" />{@back_label}
      </.link>
      <div :if={@page? and @badge != [] and @badge_position == "above"}>{render_slot(@badge)}</div>
      <div {style_attr(if @page?, do: "display:flex;align-items:flex-end;gap:16px;flex-wrap:wrap")}>
        <div {style_attr(if @page?, do: "display:flex;align-items:center;gap:14px")}>
          <div :if={@icon != []}>{render_slot(@icon)}</div>
          <div>
            <.ph_crumbs :if={!@page? and @crumb != []} crumb={@crumb} />
            <h1
              {if @title_class, do: [class: @title_class], else: []}
              {style_attr(@page? && "font-size:34px")}
            >
              {if @heading != [], do: render_slot(@heading), else: @title}<span
                :if={@page? and @badge != [] and @badge_position == "inline"}
                style="margin-left:10px;font-size:14px;vertical-align:middle"
              >{render_slot(@badge)}</span>
            </h1>
            <p :if={@description}>{@description}</p>
            <p :if={@subtitle != []}>{render_slot(@subtitle)}</p>
            {render_slot(@inner_block)}
          </div>
        </div>
        <div :if={@actions != []} class="act">{render_slot(@actions)}</div>
      </div>
      <div :if={@tabs != []} style="padding:0 28px">{render_slot(@tabs)}</div>
    </div>
    """
  end

  attr :crumb, :list, required: true

  defp ph_crumbs(assigns) do
    assigns = assign(assigns, :last, length(assigns.crumb) - 1)
    assigns = assign(assigns, :crumbs, Enum.with_index(assigns.crumb))

    ~H"""
    <nav class="lu-crumb" aria-label="Breadcrumb" style="font-size:13.5px;margin-bottom:4px">
      <%= for {c, i} <- @crumbs do %>
        <span :if={i > 0} class="s"><.icon name="chevron-right" size="sm" /></span>
        <.link :if={i != @last and link_to(c)} {link_to(c)}>{render_slot(c)}</.link>
        <span :if={i != @last and !link_to(c)}>{render_slot(c)}</span>
        <span :if={i == @last} class="cur" aria-current="page">{render_slot(c)}</span>
      <% end %>
    </nav>
    """
  end

  ## Monochrome

  attr :id, :string, default: "monochrome-toggle"
  attr :variant, :string, default: "button", values: ~w(button switch)
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "The monochrome mode: the palette button of the header or a switch. It toggles `is-monochrome` on `<body>`."
  def monochrome_toggle(assigns) do
    assigns =
      assigns
      |> assign(:on_change_event, if(is_binary(assigns.on_change), do: assigns.on_change))
      |> assign(
        :on_change_js,
        match?(%Phoenix.LiveView.JS{}, assigns.on_change) && assigns.on_change
      )

    ~H"""
    <button
      :if={@variant == "button"}
      id={@id}
      type="button"
      phx-hook="LedgerUI.MonochromeToggle"
      data-lu-on-change={@on_change_event}
      data-lu-target={is_binary(@target) && @target}
      data-on-change-js={@on_change_js}
      aria-label="Monochrome mode"
      aria-pressed="false"
      class={cx(["lu-tbtn", @class])}
      {@rest}
    >
      <.icon name="palette" />
    </button>
    <span
      :if={@variant == "switch"}
      id={@id}
      phx-hook="LedgerUI.MonochromeToggle"
      data-lu-variant="switch"
      data-lu-on-change={@on_change_event}
      data-lu-target={is_binary(@target) && @target}
      data-on-change-js={@on_change_js}
      class={cx(["lu-sw", @class])}
      {@rest}
    >
      <i></i><span class="t">{render_slot(@inner_block)}</span>
    </span>
    """
  end

  ## Helpers

  defp link_to(%{navigate: to}) when is_binary(to), do: [navigate: to]
  defp link_to(%{patch: to}) when is_binary(to), do: [patch: to]
  defp link_to(%{href: to}) when is_binary(to), do: [href: to]
  defp link_to(_), do: nil

  defp current?(_, nil), do: false

  defp current?(item, current) do
    current in [item[:navigate], item[:patch], item[:href]]
  end

  defp tab_match?(_, nil, _), do: false

  defp tab_match?(tab, current, "prefix") do
    case link_to(tab) do
      [{_, "/"}] ->
        current == "/"

      [{_, to}] ->
        cp = current |> String.split("?") |> hd()
        tp = to |> String.split("?") |> hd()
        cp == tp or String.starts_with?(cp, tp <> "/")

      _ ->
        false
    end
  end

  defp tab_match?(tab, current, _), do: current?(tab, current)

  defp bell_click(nil), do: nil
  defp bell_click(event) when is_binary(event), do: event
  defp bell_click(%Phoenix.LiveView.JS{} = js), do: js

  defp slug(s),
    do: s |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")

  defp initials(name),
    do:
      name
      |> String.split(~r/\s+/, trim: true)
      |> Enum.take(2)
      |> Enum.map_join(&String.first/1)
      |> String.upcase()

  defp item_tone(nil), do: nil
  defp item_tone("primary"), do: "acc"
  defp item_tone("success"), do: "pos"
  defp item_tone("error"), do: "neg"
  defp item_tone("warning"), do: "warn"
  defp item_tone("info"), do: "info"
  defp item_tone(_), do: nil

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
