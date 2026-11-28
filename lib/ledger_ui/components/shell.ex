defmodule LedgerUI.Components.Shell do
  @moduledoc """
  The one frame of the app: the side menu, the top bar, the page and the parts that lie over them.
  `shell/1` draws the menu in one of two ways and keeps the same frame around it.

  ## Data mode: `nav`

  The menu is fed by one list of items (`LedgerUI.Components.Sidebar.sidebar/1`), so changing
  `format` changes how the menu is drawn and not the items.

      <.shell nav={MyAppWeb.Nav.items(assigns)} format="rail" current={@current_path}
        brand={%{name: "Ledger", logo: "S"}} user={@user}>
        <:topbar><.navbar>...</.navbar></:topbar>
        ...the page...
      </.shell>

  `nav`, `brand`, `user`, `plan`, `trial`, `rail_extra`, `footer`, `version`, `match`,
  `persist_groups`, `collapsible` and `collapsed` are those of `LedgerUI.Components.Sidebar.sidebar/1`,
  which documents the data of the items. `format` is how it is drawn (`sections`, `rail`, `tree` or
  `nested`).

  ## Slot mode: `<:sidebar>`

  When the `:sidebar` slot is given, the menu is your markup (the building blocks below: the icon
  rail, a panel, the sideblock, the horizontal navigation...) and `nav` and `format` are ignored.
  `layout` says which arrangement it is (`sidebar`, `minimal`, `sideblock`, `horizontal` or `framed`).

      <.shell id="shell" full sidebar_open={@sidebar_open} on_toggle="sidebar">
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
        <:topbar><.header /></:topbar>
        <.page_header title="Avatar">
          <:crumb navigate={~p"/elements"}>Elements</:crumb>
          <:crumb>Avatar</:crumb>
        </.page_header>
      </.shell>

  ## The frame (both modes)

  The `:topbar` slot is the row at the top of the page (a `navbar/1` or `header/1`), the `:tab_bar`
  slot is the phone's bottom bar of tabs (a `tab_bar/1`, shown only below 768px), the `:aside` slot is
  rendered after the page, over the whole shell (a drawer, a right sidebar, a modal).

  `full` makes it a full-screen app (no border, radius or shadow, viewport height) and `min_height`
  sets the minimum height. `float` makes the page a bordered, rounded card beside the menu (`layout="framed"`
  implies it). `preloader` covers the shell with a spinner until the hook mounts.

  `header_sticky` and `header_blur` (the top bar sticks and blurs what scrolls under it) default to
  on in slot mode and off in data mode (the `navbar/1` scrolls with the page there).

  ## State and the hook

  The root is the `group/shell` of its parts and carries the state other kits keep in `<body>`
  classes: `open` and `is-sidebar-open` (so `LedgerUI.open/close/toggle(socket_or_js, "shell")` drive
  it), `has-min-sidebar`, `navigation:sideblock`, `navigation:horizontal`, `is-header-blur` and
  `is-header-not-sticky`. The `LedgerUI.Shell` hook keeps the open state (`sidebar_open`; by default
  open for `sidebar` and `sideblock`), persists the user's choice at xl and up (`persist`,
  `localStorage["ledger-sidebar"]`), closes it below xl, and tells the server through `on_toggle`
  (an event name, pushed to `target` when given, or a `JS` command). `[data-sidebar-toggle]` inside
  the shell toggles it (`sidebar_toggle/1`).

  The root also exposes `--lu-sidebar-w`, the current width of the left menu (open, closed or
  collapsed, switched by CSS, so it follows the hook). Defaults: 248px open and 60px closed or
  collapsed (`sideblock`: 260px and 0; `minimal`: 60px; `horizontal`: 0). Override
  `--lu-sidebar-open-w`, `--lu-sidebar-closed-w` and `--lu-sidebar-collapsed-w` for another menu.
  `--lu-aside-w` (not set by the shell, 0 by default) is the width of a panel an app docks on the
  right; set it on the shell or any ancestor. `bulk_bar` with `offset="auto"` reads both.

  Hooks used: `LedgerUI.Shell`, `LedgerUI.Sidebar` (collapsing menus), `LedgerUI.RightSidebar`,
  `LedgerUI.Clock` and `LedgerUI.MonochromeToggle`; dark mode is `theme_toggle/1` and
  `theme_script/1` of `LedgerUI.Components.ThemeSwitch`.

  ## Building blocks

  The slot mode is made of the parts of this module, all public function components: the icon rail
  (`main_sidebar/1`, `main_sidebar_link/1`, `sidebar_profile/1`, `icon_rail/1`), the panel
  (`sidebar_panel/1`, `sidebar_nav/1`, `sidebar_nav_link/1`, `sidebar_nav_group/1`, ...), the minimized
  panel (`sidebar_panel_min/1`), `sideblock/1`, `header/1`, the horizontal navigation
  (`horizontal_nav_menu/1`), `right_sidebar/1`, the framed menu (`framed_sidebar/1`, `rail_link/1`,
  `rail_module/1`, `rail_heading/1`, `rail_workspace/1`, `rail_user/1`, `rail_toggle/1`), `tab_bar/1`,
  `page_header/1` (it was `AppShell.page_header/1`) and `monochrome_toggle/1`.

  Styled only with Tailwind utilities (no stylesheet of its own). The root keeps `overflow: clip`: a
  drawer that slides in over it is clipped, and `clip` (unlike `hidden`) cannot be scrolled by the
  focus the drawer takes. The collapsible menus (`framed_sidebar/1`, `Sidebar`) are the `group/side`
  of their parts and read `data-collapsed`, which the `LedgerUI.Sidebar` hook sets.

  ## Preview

  `variant="preview"` draws the canvas wireframe of a `layout` instead of the app (the docs and the
  showcase use it): `sidebar`, `minimal`, `sideblock`, `horizontal`, `framed` or `rail`. A box with
  grey bars for the menu, the top bar and the cards; `loop` animates the menu collapsing.

      <.shell variant="preview" layout="framed" loop />

  ## Configuration

      config :ledger_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}, footer: :version, version: "v1.4.2"

  Attributes always win over the config.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Dropdown
  import LedgerUI.Components.Avatar, only: [avatar: 1]
  import LedgerUI.Components.ThemeSwitch, only: [theme_toggle: 1]

  ## The frame

  @layouts ~w(sidebar minimal sideblock horizontal framed rail)

  attr :id, :string, default: "shell"
  attr :variant, :string, default: "app", values: ~w(app preview)

  attr :layout, :string,
    default: "sidebar",
    values: @layouts,
    doc:
      "The arrangement of the `:sidebar` slot (`rail` is only a wireframe, drawn as `sidebar`); with `preview`: the wireframe."

  attr :loop, :boolean,
    default: false,
    doc: "With `preview`: the menu collapses and expands on its own (the showcase demo)."

  attr :flat, :boolean,
    default: false,
    doc: "Data mode: the items of the menu without the column around them."

  attr :format, :any,
    default: nil,
    doc:
      "Data mode: how the menu is drawn, `sections`, `rail`, `tree` or `nested` (the `format` of `sidebar/1`; it was the `sidebar` attribute)."

  attr :nav, :list, default: nil
  attr :current, :string, default: nil
  attr :brand, :map, default: nil
  attr :user, :map, default: nil
  attr :footer, :any, default: nil
  attr :show_user, :boolean, default: nil
  attr :version, :any, default: nil
  attr :match, :string, default: "exact", values: ~w(exact prefix)
  attr :persist_groups, :boolean, default: false
  attr :plan, :map, default: nil
  attr :trial, :map, default: nil
  attr :rail_extra, :list, default: []
  attr :collapsible, :boolean, default: true
  attr :collapsed, :boolean, default: false

  attr :full, :boolean,
    default: false,
    doc:
      "Full-screen app: no border, radius or shadow, and a minimum height of the viewport (`100vh`) instead of 520px."

  attr :float, :boolean,
    default: false,
    doc:
      "The floating page (a bordered, rounded card beside the menu); `layout=\"framed\"` implies it."

  attr :min_height, :string,
    default: nil,
    doc:
      ~s|The minimum height of the shell, a CSS length ("900px", "40rem"). Default: 520px, or the viewport with `full`.|

  attr :sidebar_open, :boolean,
    default: nil,
    doc:
      "The open state of the menu (the `open` / `is-sidebar-open` classes). Default: open for the `sidebar` and `sideblock` layouts."

  attr :persist, :boolean,
    default: true,
    doc: "Keep the open state the user chose (xl and up) in `localStorage[\"ledger-sidebar\"]`."

  attr :on_toggle, :any,
    default: nil,
    doc:
      "An event name pushed with `%{\"id\" => id, \"open\" => boolean}` when the menu opens or closes, or a `Phoenix.LiveView.JS` command."

  attr :target, :any, default: nil, doc: "The `phx-target` of the `on_toggle` event."
  attr :preloader, :boolean, default: false, doc: "A spinner over the shell until it mounts."

  attr :header_sticky, :boolean,
    default: nil,
    doc: "The top bar sticks to the top. Default: on in slot mode, off in data mode."

  attr :header_blur, :boolean,
    default: nil,
    doc: "The top bar blurs what scrolls under it. Default: on in slot mode, off in data mode."

  attr :class, :any, default: nil
  attr :main_class, :any, default: nil
  attr :rest, :global

  slot :aside,
    doc: "Rendered after the page, over the whole shell: a drawer, a modal, a right sidebar."

  slot :brand_mark
  slot :inner_block
  slot :mobile_drawer

  slot :sidebar,
    doc:
      "Slot mode: your own menu (the main sidebar and its panel, the sideblock...). With it `nav` and `format` are ignored."

  slot :sidebar_footer
  slot :tab_bar, doc: "A bottom bar of tabs for phones: a `tab_bar/1`."
  slot :topbar, doc: "The row at the top of the page: a `navbar/1` or `header/1`."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def shell(%{variant: "preview"} = assigns) do
    ~H"""
    <div
      data-part="shell"
      class={
        cx([
          "relative flex h-[190px] overflow-hidden rounded-lg bg-shell text-[0px] shadow-[inset_0_0_0_1px_var(--lu-line)]",
          @layout in ["minimal", "horizontal"] && "flex-col",
          @layout == "framed" && "gap-2 p-2",
          @class
        ])
      }
      {@rest}
    >
      <div
        :if={@layout == "rail"}
        data-part="shell-wire-rail"
        class="flex w-[22px] flex-none flex-col items-center gap-1.5 pt-2.5"
      >
        <i data-part="shell-wire-rail-dot" class={wire_dot()}></i><i
          data-part="shell-wire-rail-dot-active"
          class={wire_dot(true)}
        ></i><i
          data-part="shell-wire-rail-dot"
          class={wire_dot()}
        ></i><i data-part="shell-wire-rail-dot" class={wire_dot()}></i>
      </div>
      <.wire_side :if={@layout in ~w(sidebar sideblock framed)} layout={@layout} loop={@loop} />
      <.wire_side :if={@layout == "rail"} layout="rail" loop={@loop} />
      <div
        :if={@layout in ~w(sidebar sideblock framed)}
        data-part="shell-wire-column"
        class="flex min-w-0 flex-1 flex-col"
      >
        <.wire_bar /><.wire_main framed={@layout == "framed"} />
      </div>
      <div :if={@layout == "rail"} data-part="shell-wire-rail-column" class="flex flex-1 flex-col">
        <.wire_bar /><.wire_main />
      </div>
      <.wire_bar :if={@layout == "minimal"} />
      <.wire_bar :if={@layout == "horizontal"} nav />
      <.wire_main :if={@layout in ~w(minimal horizontal)} />
    </div>
    """
  end

  def shell(assigns) do
    changed0 = assigns.__changed__
    slot? = assigns.sidebar != []
    layout = if slot? and assigns.layout != "rail", do: assigns.layout, else: "sidebar"

    open =
      if is_nil(assigns.sidebar_open),
        do: layout in ["sidebar", "sideblock"],
        else: assigns.sidebar_open

    float? = assigns.float or (slot? and layout == "framed")
    full? = assigns.full
    chrome? = slot?
    blur? = if is_nil(assigns.header_blur), do: chrome?, else: assigns.header_blur
    sticky? = if is_nil(assigns.header_sticky), do: chrome?, else: assigns.header_sticky

    assigns =
      assigns
      |> assign(:slot?, slot?)
      |> assign(:layout, layout)
      |> assign(:open, open)
      |> assign(
        :classes,
        cx([
          # `overflow-clip`, never `hidden`: the focus a page drawer takes must not scroll the app
          "group/shell flex overflow-clip bg-shell",
          min_height_class(full?, assigns.min_height),
          assigns.tab_bar != [] && "max-md:pb-16",
          !full? &&
            "rounded-2xl border border-line shadow-[0_30px_80px_-30px_color-mix(in_oklab,var(--lu-accent-700)_25%,transparent)] dark:shadow-[0_30px_80px_-30px_color-mix(in_oklab,var(--lu-accent-300)_25%,transparent)]",
          float? && "py-2 pr-2",
          open && "open is-sidebar-open",
          side_width_classes(layout),
          layout == "minimal" && "has-min-sidebar",
          layout == "sideblock" && "navigation:sideblock",
          layout == "horizontal" && "navigation:horizontal",
          blur? && "is-header-blur",
          !sticky? && "is-header-not-sticky",
          assigns.class
        ])
      )
      |> assign(
        :main_classes,
        cx([
          # `p-0`: a page stylesheet that styles the bare `main` element must not pad the shell's column
          "flex min-w-0 flex-1 flex-col bg-page p-0",
          if(float? and not full?,
            do: "rounded-xl border border-line shadow-sm",
            else: "border-l border-line"
          ),
          assigns.main_class
        ])
      )
      |> assign(:on_toggle_event, if(is_binary(assigns.on_toggle), do: assigns.on_toggle))
      |> assign(
        :on_toggle_js,
        if(match?(%Phoenix.LiveView.JS{}, assigns.on_toggle), do: assigns.on_toggle)
      )
      |> assign(:style, shell_style(assigns))

    assigns =
      settle(assigns, changed0,
        slot?: [:sidebar],
        layout: [:sidebar, :layout],
        open: [:sidebar_open, :layout],
        classes: [
          :min_height,
          :full,
          :tab_bar,
          :float,
          :slot?,
          :layout,
          :open,
          :header_blur,
          :header_sticky,
          :class
        ],
        main_classes: [:float, :slot?, :layout, :full, :main_class],
        on_toggle_event: [:on_toggle],
        on_toggle_js: [:on_toggle],
        style: [:min_height, :rest]
      )

    ~H"""
    <div
      id={@id}
      data-part="shell"
      data-layout={@layout}
      data-full={@full && "true"}
      data-lu-overlay
      phx-hook="LedgerUI.Shell"
      data-lu-persist={to_string(@persist)}
      data-lu-open={to_string(@open)}
      data-lu-layout={@layout}
      data-lu-on-toggle={@on_toggle_event}
      data-lu-target={is_binary(@target) && @target}
      data-on-toggle-js={@on_toggle_js}
      class={@classes}
      {style_attr(@style)}
      {Map.delete(@rest, :style)}
    >
      <div
        :if={@preloader}
        data-part="shell-preloader"
        data-preloader
        class="fixed inset-0 z-[100] grid place-items-center bg-page"
      >
        <span data-part="shell-preloader-spinner" class={spinner_classes()}></span>
      </div>
      <%= if @slot? do %>
        {render_slot(@sidebar)}
      <% else %>
        <LedgerUI.Components.Sidebar.sidebar
          locale={@locale}
          id={"#{@id}-menu"}
          format={@format}
          nav={@nav}
          current={@current}
          brand={@brand}
          user={@user}
          footer={@footer}
          show_user={@show_user}
          version={@version}
          match={@match}
          persist_groups={@persist_groups}
          plan={@plan}
          trial={@trial}
          rail_extra={@rail_extra}
          collapsible={@collapsible}
          collapsed={@collapsed}
          variant="sidebar"
          flat={@flat}
        >
          <:brand_mark :if={@brand_mark != []}>{render_slot(@brand_mark)}</:brand_mark>
          <:mobile_drawer :if={@mobile_drawer != []}>{render_slot(@mobile_drawer)}</:mobile_drawer>
          <:sidebar_footer :if={@sidebar_footer != []}>
            {render_slot(@sidebar_footer)}
          </:sidebar_footer>
        </LedgerUI.Components.Sidebar.sidebar>
      <% end %>
      <main data-part="shell-main" class={@main_classes}>
        {render_slot(@topbar)}
        {render_slot(@inner_block)}
      </main>
      {render_slot(@aside)}
      <div
        :if={@tab_bar != []}
        data-part="tab-bar-slot"
        class="hidden pb-[env(safe-area-inset-bottom)] max-md:fixed max-md:inset-x-0 max-md:bottom-0 max-md:z-40 max-md:block"
      >
        {render_slot(@tab_bar)}
      </div>
    </div>
    """
  end

  # `--lu-sidebar-w`: the current width of the left menu, for whoever centres something on the
  # main area (`bulk_bar` with `offset="auto"`). It follows the root's `is-sidebar-open` class (the
  # hook toggles it) and a collapsed menu (`data-collapsed`). The widths are the kit's defaults per
  # layout; an app with a different menu overrides `--lu-sidebar-open-w`, `--lu-sidebar-closed-w`
  # and `--lu-sidebar-collapsed-w`.
  defp side_width_classes(layout) do
    {open, closed} = side_widths(layout)

    [
      "[--lu-sidebar-w:var(--lu-sidebar-open-w,#{open}px)]",
      "not-[.open]:[--lu-sidebar-w:var(--lu-sidebar-closed-w,#{closed}px)]",
      "has-[aside[data-collapsed]]:[--lu-sidebar-w:var(--lu-sidebar-collapsed-w,60px)]"
    ]
  end

  defp side_widths("sideblock"), do: {260, 0}
  defp side_widths("horizontal"), do: {0, 0}
  defp side_widths("minimal"), do: {60, 60}
  defp side_widths(_), do: {248, 60}

  defp min_height_class(_full, h) when is_binary(h), do: "min-h-(--lu-shell-min)"
  defp min_height_class(true, _), do: "min-h-screen"
  defp min_height_class(false, _), do: "min-h-[520px]"

  # `min_height` goes through a variable; the caller's own `style` is kept
  defp shell_style(%{min_height: nil, rest: rest}), do: rest[:style]

  defp shell_style(%{min_height: h, rest: rest}),
    do: Enum.join(Enum.reject(["--lu-shell-min:#{h}", rest[:style]], &is_nil/1), ";")

  defp wire_dot(on? \\ false),
    do: ["block size-2.5 rounded-[3px]", if(on?, do: "bg-accent-500", else: "bg-line-strong")]

  # one bar of the wireframe: width in `w`, `on` takes the accent
  attr :w, :string, default: nil
  attr :h, :string, default: "h-[7px]"
  attr :on, :boolean, default: false
  attr :class, :string, default: nil

  defp wi(assigns) do
    ~H"""
    <i
      data-part="wire-item"
      class={[
        "block rounded-[4px]",
        @h,
        if(@on, do: "bg-accent-500", else: "bg-line-strong"),
        @w,
        @class
      ]}
    ></i>
    """
  end

  attr :layout, :string, required: true
  attr :loop, :boolean, default: false

  defp wire_side(assigns) do
    ~H"""
    <div
      data-part="shell-wire-side"
      class={
        cx([
          "flex flex-none flex-col gap-1.5 px-2 py-2.5",
          side_look(@layout),
          @loop &&
            "animate-[mo-sbw_6s_cubic-bezier(.4,0,.2,1)_infinite] overflow-hidden [&_i]:min-w-2.5"
        ])
      }
    >
      <.wi w="w-[70%]" /><.wi on /><.wi /><.wi w="w-[80%]" /><.wi w="w-[60%]" />
    </div>
    """
  end

  defp side_look("sideblock"),
    do: "m-2 w-[26%] rounded-md bg-panel shadow-[0_0_0_1px_var(--lu-line)]"

  defp side_look("rail"), do: "w-[26%] border-l border-line"
  defp side_look(_), do: "w-[30%]"

  attr :nav, :boolean, default: false

  defp wire_bar(%{nav: true} = assigns) do
    ~H"""
    <div
      data-part="wire-bar"
      class="flex h-[22px] items-center gap-1.5 border-b border-line bg-page px-2.5"
    >
      <.wi w="w-[8%]" /><.wi w="w-[8%]" on /><.wi w="w-[8%]" /><.wi w="w-[10%]" class="ml-auto" />
    </div>
    """
  end

  defp wire_bar(assigns) do
    ~H"""
    <div
      data-part="wire-bar-simple"
      class="flex h-[22px] items-center gap-1.5 border-b border-line bg-page px-2.5"
    >
      <.wi w="w-[18%]" /><.wi w="w-[10%]" class="ml-auto" />
    </div>
    """
  end

  attr :framed, :boolean, default: false

  defp wire_main(assigns) do
    ~H"""
    <div
      data-part="wire-main"
      class={[
        "flex flex-1 flex-col gap-[7px] bg-page p-2.5",
        @framed && "rounded-md shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-sm)]"
      ]}
    >
      <.wi h="h-[9px]" w="w-[40%]" />
      <div data-part="wire-main-cards" class="grid grid-cols-3 gap-1.5">
        <b data-part="wire-main-card" class="block h-[34px] rounded-[6px] bg-sunken"></b><b
          data-part="wire-main-card"
          class="block h-[34px] rounded-[6px] bg-sunken"
        ></b><b data-part="wire-main-card" class="block h-[34px] rounded-[6px] bg-sunken"></b>
      </div>
      <.wi w="w-[80%]" /><.wi w="w-[60%]" />
    </div>
    """
  end

  ## Shared look (public for `Sidebar`, `Navbar` and the other shell parts; not part of the API)

  @tbtn "relative grid size-10 cursor-pointer place-items-center rounded-lg border border-line bg-panel text-ink-2 hover:bg-hover"
  @tbtn_dot "after:absolute after:top-2 after:right-[9px] after:size-[7px] after:rounded-full after:shadow-[0_0_0_2px_var(--lu-bg-panel)] after:content-['']"
  # `warn` is the canvas's fixed amber (`.lu-tbtn.dot.warn`), the same as the warning counter
  @tbtn_dot_tone %{
    "neg" => "after:bg-neg",
    "warn" => "after:bg-[#f59e0b]",
    "pos" => "after:bg-pos"
  }

  @doc false
  # The 40px bordered button of the top bar (`dot`: something unread; `tone`: its color, `neg|warn|pos`).
  def tbtn_classes(opts \\ [])
  def tbtn_classes(dot?) when is_boolean(dot?) or is_nil(dot?), do: tbtn_classes(dot: dot?)

  def tbtn_classes(opts) do
    [
      if(opts[:size] == :sm,
        do:
          String.replace(@tbtn, "size-10 ", "size-8 ")
          |> String.replace("rounded-lg", "rounded-md"),
        else: @tbtn
      ),
      opts[:dot] && [@tbtn_dot, Map.get(@tbtn_dot_tone, opts[:tone] || "neg", "after:bg-neg")]
    ]
  end

  # Everything under a collapsible menu (`group/side`) reads `data-collapsed`.
  @subnav "group/subnav flex w-[248px] flex-none flex-col gap-0.5 border-l border-line px-2.5 py-3.5"
  @subnav_title "mx-2.5 mb-3 mt-1 text-[16px] font-semibold"

  @doc false
  def subnav_classes, do: @subnav

  @doc false
  def subnav_title_classes, do: @subnav_title

  # Inside the shell the header sticks to the top (and blurs what scrolls under it).
  @topbar "flex shrink-0 items-center border-b border-line " <>
            "group-not-[.is-header-not-sticky]/shell:sticky group-not-[.is-header-not-sticky]/shell:top-0 group-not-[.is-header-not-sticky]/shell:z-30 group-not-[.is-header-not-sticky]/shell:bg-page " <>
            "group-[.is-header-blur:not(.is-header-not-sticky)]/shell:bg-[color-mix(in_srgb,var(--lu-bg-page)_82%,transparent)] group-[.is-header-blur:not(.is-header-not-sticky)]/shell:backdrop-blur-[8px]"

  @doc false
  def topbar_classes, do: @topbar

  @side_hidden "group-data-[collapsed]/side:hidden"

  @doc false
  def side_hidden, do: @side_hidden

  @nav_item "flex w-full items-center gap-[11px] rounded-md border-0 pr-2.5 text-left no-underline focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none " <>
              "[&_svg:not([data-part=nav-caret])]:size-[19px] " <>
              "group-data-[collapsed]/side:relative group-data-[collapsed]/side:justify-center group-data-[collapsed]/side:gap-0 group-data-[collapsed]/side:p-0 group-data-[collapsed]/side:text-[0px]"
  @nav_on "bg-selected text-ink [&_svg]:text-accent-content"
  # `color`: the active item takes the soft fill and the ink of the color (`LedgerUI.Color`); the icon keeps the accent ink, as in the canvas
  @nav_on_color "bg-(--c-soft) text-(--c-ink) [&_svg]:text-accent-content"
  @nav_off "bg-transparent text-ink-2 hover:bg-hover hover:text-ink [&_svg:not([data-part=nav-caret])]:text-ink-2"
  @nav_r "ml-auto inline-flex items-center gap-1.5 text-[12.5px] font-normal tabular-nums text-muted group-data-[lu-subnav]/subnav:font-mono group-data-[lu-subnav]/subnav:text-[12px]"

  @on_rail "bg-selected text-ink"
  @off_rail "bg-transparent text-muted hover:bg-hover hover:text-ink"
  @on_tabs "text-ink shadow-[inset_0_-2px_0_var(--lu-ink)] after:absolute after:inset-x-0 after:-bottom-px after:h-0.5 after:rounded-[2px] after:bg-ink after:content-['']"
  @off_tabs "text-muted hover:text-ink"

  @doc false
  # The attributes that turn a menu container into a `LedgerUI.ActiveLink` (the active item is marked
  # on the client from `data-lu-match`). `kind` picks the classes of the active and of the other items:
  # `:nav` (`sidebar_nav_link`, `rail_link`, `navbar_links`), `:rail` (`main_sidebar_link`) or `:tabs`
  # (`navbar_tabs`). With `false` there is nothing to add.
  def active_link_attrs(false, _kind), do: %{}
  def active_link_attrs(nil, _kind), do: %{}

  def active_link_attrs(true, :nav),
    do: hook_attrs(@nav_on, @nav_off)

  def active_link_attrs(true, :rail),
    do: hook_attrs(@on_rail, @off_rail)

  def active_link_attrs(true, :tabs),
    do: hook_attrs(@on_tabs, @off_tabs)

  defp hook_attrs(on, off),
    do: %{
      "phx-hook" => "LedgerUI.ActiveLink",
      "data-lu-active-class" => on,
      "data-lu-inactive-class" => off
    }

  @doc false
  # A link/button of a menu. `sub`: a child item; `hnav`: the auto-width 34px item of the horizontal
  # navigation; `slim`: the 32px item of the top bar links.
  def nav_item_classes(opts \\ []) do
    sub = opts[:sub]

    [
      @nav_item,
      if(opts[:on], do: if(opts[:color], do: @nav_on_color, else: @nav_on), else: @nav_off),
      opts[:color] && LedgerUI.Color.vars(opts[:color]),
      if(opts[:disabled], do: "cursor-not-allowed opacity-45", else: "cursor-pointer"),
      cond do
        opts[:tight] ->
          "h-8 pl-2.5 text-[14px] font-normal"

        opts[:hnav] ->
          "!w-auto h-[34px] text-[14.5px] font-medium pl-2.5"

        opts[:slim] ->
          "!w-auto h-8 text-[14.5px] font-medium pl-2.5"

        sub ->
          "h-8 pl-10 text-[14px] font-normal group-data-[lu-subnav]/subnav:h-9"

        true ->
          "h-9 pl-2.5 text-[14.5px] font-medium group-data-[lu-subnav]/subnav:h-9 group-data-[lu-subnav]/subnav:text-[14px]"
      end,
      sub && @side_hidden
    ]
  end

  @doc false
  # The `r` of an item: a count, a mark, a keyboard hint (`alert`: the red dot before it).
  def nav_r_classes(alert? \\ false) do
    if alert? do
      # the red dot stays when the menu collapses: pinned to the item
      [
        @nav_r,
        "text-neg before:size-1.5 before:rounded-full before:bg-neg before:content-['']",
        "group-data-[collapsed]/side:absolute",
        "group-data-[collapsed]/side:m-0",
        "group-data-[collapsed]/side:inline-flex"
      ]
    else
      [@nav_r, @side_hidden]
    end
  end

  @doc false
  # An `r` that shows only as a dot when the menu collapses (`lu-sb-badge`).
  def nav_badge_classes do
    [
      @nav_r,
      "group-data-[collapsed]/side:absolute",
      "group-data-[collapsed]/side:top-1.5",
      "group-data-[collapsed]/side:right-2",
      "group-data-[collapsed]/side:block",
      "group-data-[collapsed]/side:size-2",
      "group-data-[collapsed]/side:rounded-full",
      "group-data-[collapsed]/side:bg-neg",
      "group-data-[collapsed]/side:p-0",
      "group-data-[collapsed]/side:text-[0px]"
    ]
  end

  @doc false
  def nav_caret_classes,
    do:
      "ml-auto size-3.5 text-subtle transition-transform duration-150 group-aria-[expanded=false]/exp:-rotate-90 " <>
        @side_hidden

  @doc false
  # The small title over a group of items.
  def nav_h_classes(upper? \\ false) do
    [
      "flex items-center gap-1 px-2.5 pb-1.5 pt-3.5 font-medium text-muted",
      if(upper?,
        do: "font-mono text-[11px] uppercase tracking-[.06em]",
        else: "text-[12.5px]"
      ),
      @side_hidden
    ]
  end

  @doc false
  def nav_sep_classes, do: "mx-1 my-2.5 h-px bg-line"

  @doc false
  # The workspace / brand box (`mb`: the margin under it).
  def ws_classes(opts \\ []) do
    [
      "flex items-center gap-2.5 overflow-hidden rounded-lg p-2",
      opts[:mb] || "mb-2.5",
      if(opts[:bare],
        do: "cursor-default",
        else: "cursor-pointer border border-line bg-panel shadow-xs"
      ),
      "group-data-[collapsed]/side:justify-center",
      "group-data-[collapsed]/side:p-1",
      opts[:collapsed_gap] && "group-data-[collapsed]/side:gap-[14px]"
    ]
  end

  @doc false
  def ws_logo_classes(tone \\ :inverse),
    do: [
      "relative grid size-9 flex-none place-items-center rounded-md text-[12.5px] leading-4",
      if(tone == :accent,
        do: "bg-accent-soft font-semibold text-accent-content",
        else: "bg-inverse text-on-inverse"
      )
    ]

  @doc false
  # (its `span` rule reaches the text box too: the name inherits the muted colour)
  def ws_text_classes,
    do: ["flex min-w-0 flex-1 flex-col text-[12.5px] leading-4 text-muted", @side_hidden]

  @doc false
  def ws_name_classes, do: "truncate text-[15px] font-semibold leading-[19px]"

  @doc false
  def ws_sub_classes, do: "truncate text-[12.5px] leading-4 text-muted"

  @doc false
  def person_classes, do: ["flex min-w-0 items-center gap-2.5", @side_hidden]

  @doc false
  # The `t` box of a person: its `span` rule (muted, 12.5px, clipped) reaches this box too, so the
  # name inherits the muted colour.
  def person_text_classes,
    do:
      "flex min-w-0 flex-col overflow-hidden text-ellipsis whitespace-nowrap text-[12.5px] leading-[17px] text-muted"

  @doc false
  def person_name_classes, do: "truncate text-[14px] font-semibold leading-[19px]"

  @doc false
  def person_sub_classes, do: "truncate text-[12.5px] leading-[17px] text-muted"

  @doc false
  def user_classes,
    do: [
      "mt-1.5 flex items-center gap-2.5 border-t border-line px-2 py-2.5",
      "group-data-[collapsed]/side:justify-center",
      "group-data-[collapsed]/side:p-1"
    ]

  @rail_btn "relative grid size-[42px] cursor-pointer place-items-center border-0 [&_svg]:size-[21px]"

  @doc false
  # `:on`, `:off`, `:accent` (the active link of the minimized panel) or `:extra` (a round app).
  def rail_btn_classes(state) when is_boolean(state),
    do: rail_btn_classes(if(state, do: :on, else: :off))

  def rail_btn_classes(:on), do: [@rail_btn, "rounded-md bg-selected text-ink"]

  def rail_btn_classes(:off),
    do: [@rail_btn, "rounded-md bg-transparent text-muted hover:bg-hover hover:text-ink"]

  def rail_btn_classes(:accent),
    do: [@rail_btn, "rounded-md bg-accent-soft text-accent-content"]

  def rail_btn_classes(:extra), do: [@rail_btn, "rounded-full text-white"]

  @doc false
  def rail_count_classes(tone \\ "neg"),
    do: [
      "absolute right-px top-0.5 inline-grid h-4 min-w-4 place-items-center rounded-[5px] px-[5px] text-[10px] font-semibold tabular-nums",
      if(tone == "warn", do: "bg-[#f59e0b] text-[#1b1300]", else: "bg-neg text-white")
    ]

  @doc false
  def rail_logo_classes,
    do: "relative mb-3.5 grid size-10 place-items-center rounded-md bg-inverse text-on-inverse"

  @doc false
  # The search field of the top bars: a box whose real `<input>` (or static text) fills it.
  def search_box_classes(size \\ :header) do
    [
      "flex min-w-0 items-center gap-2 border border-transparent bg-sunken",
      if(size == :sm, do: "px-2.5", else: "px-3"),
      "text-ink focus-within:border-accent-500 focus-within:bg-panel focus-within:shadow-[0_0_0_3px_var(--lu-focus)] [&>svg]:text-ink",
      case size do
        :header -> "h-10 rounded-[12px]"
        :sm -> "h-8 rounded-[8px]"
        _ -> "h-9 rounded-md"
      end
    ]
  end

  @doc false
  def search_input_classes,
    do:
      "h-full min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 text-[14px] outline-0 [&::-webkit-search-cancel-button]:appearance-none"

  @doc false
  def spinner_classes,
    do:
      "inline-block size-5 flex-none animate-[lu-spin_.7s_linear_infinite] rounded-full border-2 border-selected border-t-accent-500"

  @doc false
  def media_icon_classes(tone) do
    [
      "inline-grid size-8 flex-none place-items-center rounded-md",
      case tone do
        "acc" -> "bg-accent-soft text-accent-content"
        "pos" -> "bg-pos-soft text-pos"
        "neg" -> "bg-neg-soft text-neg"
        "warn" -> "bg-warn-soft text-warn"
        "info" -> "bg-info-soft text-info"
        _ -> "bg-sunken text-ink-2"
      end
    ]
  end

  ## Main sidebar (icon rail)

  attr :id, :string, default: "main-sidebar"

  attr :current, :any,
    default: nil,
    doc: "The current path (matched against each item's link), or an item's `name`."

  attr :centered, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  attr :active_link, :boolean,
    default: false,
    doc:
      "Marks the active item on the client (`LedgerUI.ActiveLink`) from the `match` of each item; needs an `id`."

  slot :bottom

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :match, :string, doc: "The path (prefix) that makes the item active on the client."
    attr :label, :string
    attr :icon, :string, doc: "The name of the icon the link shows (or put it in the slot)."
    attr :name, :any, doc: "Marks the item as active when `current` is this name."
    attr :active, :boolean
    attr :class, :any
    attr :style, :string
    attr :count, :any, doc: "A counter badge on the corner of the button."
    attr :count_tone, :string, doc: "`neg` (default) or `warn`."
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
    <nav
      id={@id}
      data-part="main-sidebar"
      class={cx(["flex w-16 flex-none flex-col items-center gap-1.5 py-3", @class])}
      {active_link_attrs(@active_link, :rail)}
      {@rest}
    >
      <%= for l <- @logo do %>
        <a
          :if={link_to(l)}
          {anchor(link_to(l))}
          data-part="main-sidebar-logo"
          class={rail_logo_classes()}
        >
          <img
            :if={l[:src]}
            data-part="main-sidebar-img"
            src={l.src}
            alt={l[:alt] || ""}
            class="absolute inset-0 size-full rounded-[inherit] object-cover"
          />
          {render_slot(l)}
        </a>
        <span :if={!link_to(l)} data-part="main-sidebar-logo" class={rail_logo_classes()}>
          <img
            :if={l[:src]}
            data-part="main-sidebar-logo-image"
            src={l.src}
            alt={l[:alt] || ""}
            class="absolute inset-0 size-full rounded-[inherit] object-cover"
          />
          {render_slot(l)}
        </span>
      <% end %>
      <div :if={@centered} data-part="main-sidebar-spacer" class="min-w-0 flex-1"></div>
      <.main_sidebar_link
        :for={item <- @item}
        label={item[:label]}
        active={
          item[:active] || (item[:name] != nil and to_string(item[:name]) == to_string(@current))
        }
        current={@current && to_string(@current)}
        class={item[:class]}
        count={item[:count]}
        count_tone={item[:count_tone] || "neg"}
        match={item[:match]}
        {style_attr(item[:style])}
        href={item[:href]}
        navigate={item[:navigate]}
        patch={item[:patch]}
      >
        <.icon :if={item[:icon]} name={item[:icon]} />{item[:inner_block] && render_slot(item)}
      </.main_sidebar_link>
      <div :if={@bottom != [] or @centered} data-part="main-sidebar-spacer" class="min-w-0 flex-1">
      </div>
      {render_slot(@bottom)}
    </nav>
    """
  end

  attr :label, :string, default: nil, doc: "The tooltip and the accessible name."
  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :count, :any, default: nil, doc: "A counter badge on the corner of the button."

  attr :count_tone, :string,
    default: "neg",
    values: ~w(neg warn),
    doc: "The color of the counter."

  attr :match, :string,
    default: nil,
    doc: "The path (prefix) that makes the link active on the client."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true

  @doc "One icon link of the main sidebar."
  def main_sidebar_link(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(:to, link_to(assigns.rest))
      |> assign(
        :anchor,
        link_to(assigns.rest) &&
          LedgerUI.LinkAttrs.resolve(assigns.rest, [
            "data-part",
            "class",
            "aria-label",
            "aria-current",
            "data-lu-match"
          ])
      )

    assigns =
      settle(assigns, changed0, on: [:active, :rest, :current], to: [:rest], anchor: [:rest])

    ~H"""
    <a
      :if={@to}
      data-part="main-sidebar-link"
      class={cx([rail_btn_classes(@on), @class])}
      aria-label={@label}
      aria-current={@on && "page"}
      data-lu-match={@match}
      {@anchor}
    >
      {render_slot(@inner_block)}<span
        :if={@count not in [nil, false]}
        data-part="main-sidebar-link-count"
        class={rail_count_classes(@count_tone)}
      >{@count}</span>
    </a>
    <button
      :if={!@to}
      type="button"
      data-part="main-sidebar-link"
      class={cx([rail_btn_classes(@on), @class])}
      aria-label={@label}
      {@rest}
    >
      {render_slot(@inner_block)}<span
        :if={@count not in [nil, false]}
        data-part="main-sidebar-link-count"
        class={rail_count_classes(@count_tone)}
      >{@count}</span>
    </button>
    """
  end

  attr :id, :string, required: true
  attr :src, :string, required: true
  attr :alt, :string, default: nil
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
    "success" => "online",
    "warning" => "away",
    "error" => "busy",
    "info" => "info",
    "neutral" => "offline"
  }

  @doc "The avatar at the bottom of the main sidebar and the profile box it opens on its right."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def sidebar_profile(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, alt: "shell.avatar")

    assigns = assign(assigns, :st, @status_class[assigns.status || ""])
    box = "#{assigns.id}-box"
    assigns = assign(assigns, :box, box)
    assigns = settle(assigns, changed0, st: [:status], box: [:id])

    ~H"""
    <div
      id={@id}
      data-part="sidebar-profile"
      class={cx(["relative", @class])}
      phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@box}")}
      {@rest}
    >
      <button
        data-part="sidebar-profile-button"
        type="button"
        aria-haspopup="menu"
        aria-controls={@box}
        aria-label={@name}
        class={rail_btn_classes(false)}
        phx-click={JS.toggle_attribute({"hidden", "hidden"}, to: "##{@box}")}
      >
        <.avatar src={@src} alt={@alt} size="36" status={@st} />
      </button>
      <div
        id={@box}
        data-part="sidebar-profile-box"
        class={
          cx([
            Dropdown.pop_classes(),
            "absolute bottom-0 left-[calc(100%+8px)] z-50 w-[260px] text-left"
          ])
        }
        role="menu"
        hidden
      >
        <div data-part="sidebar-profile-head" class={[person_classes(), "px-2.5 py-2"]}>
          <.avatar src={@src} alt={@alt} size="40" />
          <span data-part="sidebar-profile-text" class={person_text_classes()}>
            <b data-part="sidebar-profile-name" class={person_name_classes()}>{@name}</b>
            <span :if={@subtitle} data-part="sidebar-profile-sub" class={person_sub_classes()}>{@subtitle}</span>
          </span>
        </div>
        <div data-part="sidebar-profile-separator" class={Dropdown.separator_classes()}></div>
        <a
          :for={item <- @item}
          data-part="sidebar-profile-link"
          {anchor(link_to(item), method: item[:method])}
          role="menuitem"
          class={Dropdown.item_classes(media: true)}
          phx-click={JS.set_attribute({"hidden", ""}, to: "##{@box}")}
        >
          <span
            data-part="sidebar-profile-item-icon"
            class={media_icon_classes(item_tone(item[:color]))}
          >{render_slot(item)}</span>
          <span data-part="sidebar-profile-item-text" class="flex flex-col leading-[17px]">
            <span>{item[:title]}</span>
            <small
              :if={item[:description]}
              data-part="sidebar-profile-item-description"
              class="text-[12px] text-muted"
            >{item[:description]}</small>
          </span>
        </a>
        <div :if={@footer != []} data-part="sidebar-profile-footer" class="p-1.5">
          {render_slot(@footer)}
        </div>
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
    <div data-part="sidebar-panel" data-lu-subnav class={cx([subnav_classes(), @class])} {@rest}>
      <h4 data-part="sidebar-panel-title" class={subnav_title_classes()}>{@title}</h4>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :active_link, :boolean,
    default: false,
    doc:
      "Marks the active item on the client (`LedgerUI.ActiveLink`) from the `match` of each link; needs an `id`."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A list of the sidebar panel (or the sideblock)."
  def sidebar_nav(assigns) do
    ~H"""
    <nav
      data-part="sidebar-nav"
      class={cx(["flex flex-col gap-0.5", @class])}
      {active_link_attrs(@active_link, :nav)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  attr :active, :boolean, default: false
  attr :current, :string, default: nil

  attr :color, :string,
    default: nil,
    values: [nil | ~w(neutral primary secondary info success warning error)],
    doc:
      "The active link takes the soft fill and the ink of this color (default: the selected look)."

  attr :match, :string,
    default: nil,
    doc: "The path (prefix) that makes the link active on the client."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true
  slot :count, doc: "The count (or the key hint) at the end of the link."

  @doc "A plain link of the sidebar panel, active with `active` or when its path is `current`."
  def sidebar_nav_link(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(
        :to,
        LedgerUI.LinkAttrs.resolve(assigns.rest, ["data-part", "class", "aria-current"])
      )

    assigns = settle(assigns, changed0, on: [:active, :rest, :current], to: [:rest])

    ~H"""
    <a
      data-part="sidebar-nav-link"
      class={cx([nav_item_classes(on: @on, color: @color), @class])}
      aria-current={@on && "page"}
      data-lu-match={@match}
      {@to}
    >
      {render_slot(@inner_block)}
      <.sidebar_nav_count :for={c <- @count}>{render_slot(c)}</.sidebar_nav_count>
    </a>
    """
  end

  slot :inner_block, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The count (or the key hint) at the end of a link of the sidebar panel (`<:count>` of `sidebar_nav_link/1` renders it)."
  def sidebar_nav_count(assigns) do
    ~H"""
    <span data-part="sidebar-nav-count" class={cx([nav_r_classes(), @class])} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :icon, :string,
    default: nil,
    doc: "A small icon before the title (`chevron-down`, as in a group)."

  attr :upper, :boolean, default: false, doc: "Mono caps, as the heading of the rail."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The title over a group of links of the sidebar panel, with no toggle (`sidebar_nav_group/1` is the collapsible one)."
  def sidebar_nav_heading(assigns) do
    ~H"""
    <div data-part="sidebar-nav-heading" class={cx([nav_h_classes(@upper), @class])} {@rest}>
      <.icon :if={@icon} name={@icon} size="sm" />{render_slot(@inner_block)}
    </div>
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
    changed0 = assigns.__changed__
    id = assigns.id || "sidebar-group-" <> slug(assigns.label)

    items =
      Enum.map(assigns.item, fn i ->
        Map.put(i, :on, i[:active] || current?(i, assigns.current))
      end)

    open = if is_nil(assigns.open), do: Enum.any?(items, & &1.on), else: assigns.open
    name = assigns.name

    toggle =
      %JS{}
      |> JS.set_attribute({"hidden", ""}, to: ~s|[data-lu-sb-body="#{name}"]:not(##{id}-body)|)
      |> JS.set_attribute({"aria-expanded", "false"},
        to: ~s|[data-lu-sb-head="#{name}"]:not(##{id}-head)|
      )
      |> JS.toggle_attribute({"hidden", "hidden"}, to: "##{id}-body")
      |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-head")

    assigns =
      assigns |> assign(id: id, items: items, is_open: open, toggle: toggle)

    assigns =
      settle(assigns, changed0,
        id: [:id, :label],
        items: [:item, :current],
        is_open: [:open, :items],
        toggle: [:id, :name]
      )

    ~H"""
    <div id={@id} data-part="sidebar-nav-group" class={@class} {@rest}>
      <button
        data-part="sidebar-nav-group-button"
        id={"#{@id}-head"}
        type="button"
        class={["group/exp", nav_item_classes()]}
        data-lu-sb-head={@name}
        aria-expanded={to_string(@is_open)}
        aria-controls={"#{@id}-body"}
        phx-click={@toggle}
      >
        {@label}
        <.icon name="chevron-down" size="sm" data-part="nav-caret" class={nav_caret_classes()} />
      </button>
      <div id={"#{@id}-body"} data-lu-sb-body={@name} hidden={!@is_open}>
        <div data-part="sidebar-nav-group-items" class="flex flex-col gap-0.5">
          <a
            :for={i <- @items}
            data-part="sidebar-nav-group-link"
            {anchor(link_to(i))}
            class={nav_item_classes(sub: true, on: i.on)}
            aria-current={i.on && "page"}
            data-lu-match={i[:match]}
          >
            {render_slot(i)}
          </a>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil

  @doc "The line between the lists of the sidebar panel."
  def sidebar_nav_divider(assigns) do
    ~H"""
    <div data-part="sidebar-nav-divider" class={cx([nav_sep_classes(), @class])}></div>
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
      class={
        cx([
          "flex w-16 flex-none flex-col items-center gap-1.5 border-l border-line py-3",
          @class
        ])
      }
      {@rest}
    >
      <div :if={@header != []}>{render_slot(@header)}</div>
      {render_slot(@inner_block)}
      <div data-part="sidebar-panel-min-spacer" class="min-w-0 flex-1"></div>
      <div :if={@footer != []}>{render_slot(@footer)}</div>
    </div>
    """
  end

  attr :class, :any, default: nil
  slot :inner_block, required: true

  @doc "A list of icon links of the minimized panel."
  def sidebar_min_group(assigns) do
    ~H"""
    <div data-part="sidebar-min-group" class={cx(["flex flex-col items-center gap-1.5", @class])}>
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

  @doc "An icon link of the minimized panel. The active one is accent soft."
  def sidebar_min_link(assigns) do
    changed0 = assigns.__changed__
    on = assigns.active or current?(assigns.rest, assigns.current)

    assigns =
      assign(assigns,
        on: on,
        to:
          LedgerUI.LinkAttrs.resolve(assigns.rest, [
            "data-part",
            "aria-label",
            "aria-current",
            "class"
          ])
      )

    assigns = settle(assigns, changed0, on: [:active, :rest, :current], to: [:rest])

    ~H"""
    <a
      data-part="sidebar-min-link"
      aria-label={@label}
      aria-current={@on && "page"}
      class={
        cx([
          rail_btn_classes(if @on, do: :accent, else: :off),
          @class
        ])
      }
      {@to}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :class, :any, default: nil

  @doc "The line between the lists of the minimized panel."
  def sidebar_min_divider(assigns) do
    ~H"""
    <div data-part="sidebar-min-divider" class={cx(["my-1.5 h-px w-7 bg-line", @class])}></div>
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
    <aside
      data-part="sideblock"
      class={
        cx([
          "flex w-[260px] flex-none flex-col gap-0.5 bg-shell p-3 group-not-[.open]/shell:hidden",
          @class
        ])
      }
      {@rest}
    >
      <%= for l <- @logo do %>
        <a data-part="sideblock-link" {anchor(link_to(l))} class={ws_classes(mb: "mb-2")}>
          <span data-part="sideblock-logo" class={ws_logo_classes()}>
            <img
              :if={l[:src]}
              data-part="sideblock-img"
              src={l.src}
              alt={l[:alt] || ""}
              class="absolute inset-0 size-full rounded-[inherit] object-cover"
            />
            {render_slot(l)}
          </span>
        </a>
      <% end %>
      {render_slot(@inner_block)}
    </aside>
    """
  end

  ## Header

  attr :id, :string, default: "app-header"
  attr :toggle, :boolean, default: true
  attr :search, :boolean, default: true
  attr :search_placeholder, :string, default: nil
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
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def header(%{nav: [_ | _]} = assigns) do
    assigns = I18n.texts(assigns, search_placeholder: "data_table.search")

    ~H"""
    <header
      id={@id}
      data-part="header"
      class={cx([topbar_classes(), "h-auto flex-wrap gap-x-4 gap-y-2.5 pl-6 pr-5", @class])}
      {@rest}
    >
      <.sidebar_toggle :if={@toggle} locale={@locale} />
      <a
        :for={b <- @brand}
        data-part="header-link"
        {anchor(link_to(b))}
        class="inline-flex items-center gap-2 font-semibold text-ink no-underline"
      >
        <img :if={b[:src]} data-part="header-img" src={b.src} alt="" class="size-7 rounded-lg" />{b[
          :label
        ]}
      </a>
      <div data-part="header-spacer" class="min-w-0 flex-1"></div>
      <.hdr_tools
        id={@id}
        search={@search}
        search_placeholder={@search_placeholder}
        search_input={@search_input}
        search_results={@search_results}
        mobile_search={@mobile_search}
        actions={@actions}
        theme_toggle={@theme_toggle}
        monochrome_toggle={@monochrome_toggle}
        notifications={@notifications}
        right_sidebar={@right_sidebar}
        profile={@profile}
        locale={@locale}
      />
      <nav data-part="header-nav" class="flex basis-full items-center gap-1 pb-2">
        {render_slot(@nav)}
      </nav>
    </header>
    """
  end

  def header(assigns) do
    assigns = I18n.texts(assigns, search_placeholder: "data_table.search")

    ~H"""
    <header
      id={@id}
      data-part="header"
      class={cx([topbar_classes(), "h-16 gap-2.5 pl-6 pr-5", @class])}
      {@rest}
    >
      <.sidebar_toggle :if={@toggle} locale={@locale} />
      {render_slot(@start)}
      <div data-part="header-spacer" class="min-w-0 flex-1"></div>
      <.hdr_tools
        id={@id}
        search={@search}
        search_placeholder={@search_placeholder}
        search_input={@search_input}
        search_results={@search_results}
        mobile_search={@mobile_search}
        actions={@actions}
        theme_toggle={@theme_toggle}
        monochrome_toggle={@monochrome_toggle}
        notifications={@notifications}
        right_sidebar={@right_sidebar}
        profile={@profile}
        locale={@locale}
      />
    </header>
    """
  end

  defp hdr_tools(assigns) do
    ~H"""
    <div
      :if={@search}
      data-part="header-search-wrap"
      class="relative"
      phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@id}-results")}
    >
      <span data-part="header-search" class={[search_box_classes(), "w-[280px]"]}>
        <.icon name="search" size="md" />
        <input
          data-part="header-tools-input"
          type="search"
          placeholder={@search_placeholder}
          phx-focus={JS.remove_attribute("hidden", to: "##{@id}-results")}
          autocomplete="off"
          class={search_input_classes()}
          {@search_input}
        />
      </span>
      <div
        :if={@search_results != [] or @mobile_search != []}
        id={"#{@id}-results"}
        data-part="header-search-results"
        class={cx([Dropdown.pop_classes(), "absolute inset-x-0 top-[calc(100%+6px)] z-50"])}
        hidden
      >
        {render_slot(@search_results)}
        {render_slot(@mobile_search)}
      </div>
    </div>
    {render_slot(@actions)}
    <.theme_toggle :if={@theme_toggle} id={"#{@id}-theme"} locale={@locale} />
    <.monochrome_toggle :if={@monochrome_toggle} id={"#{@id}-mono"} locale={@locale} />
    <div
      :for={n <- @notifications}
      data-part="header-notifications-wrap"
      class="relative"
      phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@id}-notifications")}
    >
      <button
        data-part="header-tools-button"
        type="button"
        class={tbtn_classes(n[:dot])}
        aria-label={n[:label] || I18n.t("navbar.notifications", @locale)}
        aria-controls={"#{@id}-notifications"}
        phx-click={JS.toggle_attribute({"hidden", "hidden"}, to: "##{@id}-notifications")}
      >
        <.icon name="bell" />
      </button>
      <div
        id={"#{@id}-notifications"}
        data-part="header-notifications"
        class={cx([Dropdown.pop_classes(), "absolute right-0 top-[calc(100%+8px)] z-50 w-[340px]"])}
        hidden
      >
        {render_slot(n)}
      </div>
    </div>
    <.right_sidebar_toggle :if={@right_sidebar} target={@right_sidebar} locale={@locale} />
    {render_slot(@profile)}
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The animated hamburger: three bars that turn into an arrow while the sidebar is open."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def sidebar_toggle(assigns) do
    ~H"""
    <button
      type="button"
      data-sidebar-toggle
      data-part="sidebar-toggle"
      aria-label={I18n.t("shell.toggle_sidebar", @locale)}
      class={
        cx([
          tbtn_classes(),
          "[&_svg]:transition-transform [&_svg]:duration-200 group-[.is-sidebar-open]/shell:[&_svg]:scale-x-[-1] motion-reduce:[&_svg]:transition-none",
          @class
        ])
      }
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
    changed0 = assigns.__changed__

    items =
      Enum.map(assigns.item, &Map.put(&1, :on, &1[:active] || current?(&1, assigns.current)))

    on = assigns.active or Enum.any?(items, & &1.on)
    assigns = assign(assigns, items: items, on: on)
    assigns = settle(assigns, changed0, items: [:item, :current], on: [:active, :items])

    ~H"""
    <div
      id={@id}
      data-part="horizontal-nav-menu"
      class={cx(["relative", @class])}
      phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@id}-box")}
      {@rest}
    >
      <button
        data-part="horizontal-nav-menu-button"
        type="button"
        class={nav_item_classes(on: @on, hnav: true)}
        aria-haspopup="menu"
        aria-controls={"#{@id}-box"}
        aria-current={@on && "page"}
        phx-click={JS.toggle_attribute({"hidden", "hidden"}, to: "##{@id}-box")}
      >
        {render_slot(@icon)}{@label}<.icon name="chevron-down" size="sm" />
      </button>
      <div
        id={"#{@id}-box"}
        data-part="horizontal-nav-box"
        class={cx([Dropdown.pop_classes(), "absolute left-0 top-[calc(100%+6px)] z-50"])}
        role="menu"
        hidden
      >
        <a
          :for={i <- @items}
          data-part="horizontal-nav-menu-link"
          {anchor(link_to(i))}
          role="menuitem"
          class={Dropdown.item_classes(selected: i.on)}
          phx-click={JS.set_attribute({"hidden", ""}, to: {:closest, "[role=menu]"})}
        >
          {render_slot(i)}
        </a>
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
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(
        :to,
        LedgerUI.LinkAttrs.resolve(assigns.rest, [
          "data-part",
          "role",
          "class",
          "aria-current",
          "phx-click"
        ])
      )

    assigns = settle(assigns, changed0, on: [:active, :rest, :current], to: [:rest])

    ~H"""
    <a
      data-part="horizontal-nav-link-link"
      role="menuitem"
      class={cx([Dropdown.item_classes(selected: @on), @class])}
      aria-current={@on && "page"}
      phx-click={JS.set_attribute({"hidden", ""}, to: {:closest, "[role=menu]"})}
      {@to}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :class, :any, default: nil

  @doc "The line between the links of a horizontal navigation box."
  def horizontal_nav_divider(assigns) do
    ~H"""
    <div data-part="horizontal-nav-divider" class={cx([Dropdown.separator_classes(), @class])}></div>
    """
  end

  ## Right sidebar

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :label, :string, default: nil
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
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def right_sidebar(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "shell.sidebar")

    assigns =
      assigns
      |> assign(:on_open_event, if(is_binary(assigns.on_open), do: assigns.on_open))
      |> assign(:on_close_event, if(is_binary(assigns.on_close), do: assigns.on_close))
      |> assign(:on_open_js, match?(%Phoenix.LiveView.JS{}, assigns.on_open) && assigns.on_open)
      |> assign(
        :on_close_js,
        match?(%Phoenix.LiveView.JS{}, assigns.on_close) && assigns.on_close
      )

    assigns =
      settle(assigns, changed0,
        on_open_event: [:on_open],
        on_close_event: [:on_close],
        on_open_js: [:on_open],
        on_close_js: [:on_close]
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
      class={
        cx([
          "hidden [&.open]:fixed [&.open]:inset-0 [&.open]:z-50 [&.open]:block",
          @open && "open",
          @class
        ])
      }
      {@rest}
    >
      <div
        data-part="right-sidebar-scrim"
        class="absolute inset-0 flex items-center justify-center overflow-hidden bg-overlay"
        data-rs-close
        aria-hidden="true"
      >
      </div>
      <aside
        data-part="right-sidebar-panel"
        role="dialog"
        aria-label={@label}
        class="absolute inset-y-0 right-0 flex w-[min(360px,100vw)] flex-col border-l border-line bg-panel shadow-lg"
      >
        <div
          data-part="right-sidebar-head"
          class="flex items-center gap-2 border-b border-line px-4 py-3"
        >
          <div data-part="right-sidebar-title" class="min-w-0 flex-1">{render_slot(@title)}</div>
          <button
            data-part="right-sidebar-button"
            type="button"
            class={tbtn_classes()}
            data-rs-close
            aria-label={I18n.t("common.close", @locale)}
          >
            <.icon name="x" />
          </button>
        </div>
        <div data-part="right-sidebar-body" class="flex-1 overflow-auto py-3">
          {render_slot(@inner_block)}
        </div>
        <div
          :if={@footer != []}
          data-part="right-sidebar-footer"
          class="flex justify-center gap-1.5 border-t border-line p-2.5"
        >
          {render_slot(@footer)}
        </div>
      </aside>
    </div>
    """
  end

  attr :target, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The header button that toggles a `right_sidebar/1`."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def right_sidebar_toggle(assigns) do
    ~H"""
    <button
      data-part="right-sidebar-toggle-button"
      type="button"
      aria-label={I18n.t("shell.toggle_right_sidebar", @locale)}
      aria-controls={@target}
      class={cx([tbtn_classes(), @class])}
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

  attr :collapsed_width, :integer,
    default: nil,
    doc:
      "The width of the collapsed rail in px (default 60). Sets `--lu-rail-collapsed` on the menu; the variable can also be set in CSS."

  attr :persist, :boolean, default: true
  attr :on_collapse, :string, default: nil
  attr :shortcut, :string, default: "b"
  attr :target, :any, default: nil
  attr :label, :string, default: nil
  attr :mobile_label, :string, default: nil
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
  (`rail_link/1`, `rail_module/1`) and the bottom items. It collapses to a rail of icons (the
  names, headings and the workspace go away, badges become dots) and the choice is kept in
  `localStorage`. Below 768px it is a top bar with a hamburger.
  """
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def framed_sidebar(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "shell.main_menu", mobile_label: "landing_nav.menu")

    assigns =
      assign(
        assigns,
        :style,
        [
          assigns.collapsed_width && "--lu-rail-collapsed: #{assigns.collapsed_width}px",
          assigns.rest[:style]
        ]
        |> Enum.reject(&(&1 in [nil, false, ""]))
        |> Enum.join(";")
        |> then(&if(&1 == "", do: [], else: [style: &1]))
      )

    assigns = settle(assigns, changed0, style: [:collapsed_width, :rest])

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
      class={
        cx([
          "group/side flex w-[248px] flex-none flex-col gap-0.5 bg-transparent p-3 data-[collapsed]:w-(--lu-rail-collapsed,60px) data-[collapsed]:overflow-visible data-[collapsed]:px-2",
          @class
        ])
      }
      {@style}
      {Map.delete(@rest, :style)}
    >
      <div
        :if={@brand != [] or @wordmark != []}
        data-part="framed-sidebar-brand"
        class={ws_classes(bare: true)}
      >
        <span :if={@brand != []} data-part="framed-sidebar-logo" class={ws_logo_classes()}>{render_slot(
          @brand
        )}</span>
        <span :if={@wordmark != []} data-part="framed-sidebar-wordmark" class={ws_text_classes()}><b
          data-part="framed-sidebar-wordmark-name"
          class={ws_name_classes()}
        >{render_slot(@wordmark)}</b></span>
        <button
          data-part="framed-sidebar-button"
          type="button"
          data-lu-sb-burger
          aria-label={@mobile_label}
          aria-expanded="false"
          class={[tbtn_classes(), "hidden"]}
        >
          <.icon name="menu" />
        </button>
      </div>
      <div :if={@workspace != []} data-part="framed-sidebar-workspace" class={side_hidden()}>
        {render_slot(@workspace)}
      </div>
      <%= for s <- @search do %>
        <button
          data-part="framed-sidebar-search"
          type="button"
          id={s[:id]}
          title={s[:title]}
          aria-label={s[:"aria-label"]}
          phx-click={s[:"phx-click"]}
          phx-target={s[:"phx-target"]}
          class={
            cx([search_box_classes(:navbar), "mb-2 mt-1 w-full cursor-pointer text-left", s[:class]])
          }
        >
          {render_slot(s)}
        </button>
      <% end %>
      <nav data-part="framed-sidebar-nav" class="flex flex-col gap-0.5">
        {render_slot(@inner_block)}
      </nav>
      <div data-part="framed-sidebar-spacer" class="min-w-0 flex-1"></div>
      <div :if={@bottom != []} data-part="framed-sidebar-bottom" class="flex flex-col gap-0.5">
        {render_slot(@bottom)}
      </div>
    </aside>
    """
  end

  attr :label, :string, default: nil
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
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def tab_bar(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "shell.sections")

    tabs =
      Enum.map(assigns.tab, fn t ->
        on = t[:active] || tab_match?(t, assigns.current, t[:match] || assigns.match)
        Map.put(t, :on, on)
      end)

    assigns = assign(assigns, :tabs, tabs)
    assigns = settle(assigns, changed0, tabs: [:tab, :current, :match])

    ~H"""
    <nav
      data-part="tab-bar"
      aria-label={@label}
      class={
        cx([
          "flex items-center justify-around gap-1 border-t border-line bg-panel px-2 py-1.5",
          @class
        ])
      }
      {@rest}
    >
      <a
        :for={t <- @tabs}
        data-part="tab-bar-link"
        {anchor(link_to(t))}
        aria-label={t[:label]}
        aria-current={t.on && "page"}
        class={
          cx([
            "flex flex-1 flex-col items-center gap-0.5 py-1.5 text-[11px] no-underline",
            if(t.on, do: "text-accent-content", else: "text-muted"),
            t[:class]
          ])
        }
      >
        {render_slot(t)}
        <span :if={@variant == "canvas"}>{t[:label]}</span>
      </a>
    </nav>
    """
  end

  attr :for, :string, required: true, doc: "The id of the `framed_sidebar/1`."
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "A button that collapses and expands the `framed_sidebar/1` with that id, from anywhere."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def rail_toggle(assigns) do
    assigns = I18n.texts(assigns, label: "shell.collapse_menu")

    ~H"""
    <button
      data-part="rail-toggle-button"
      type="button"
      data-rail-toggle={@for}
      aria-label={@label}
      aria-pressed="false"
      class={cx([tbtn_classes(), @class])}
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
  attr :variant, :string, default: "default", values: ~w(default sub)
  attr :active, :boolean, default: false
  attr :current, :string, default: nil

  attr :match, :string,
    default: nil,
    doc: "The path (prefix) that makes the link active on the client."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, doc: "The icon (optional in the `sub` variant)."
  slot :trailing, doc: "Right-aligned content (a `kbd` hint...); hidden when the rail collapses."

  @doc "A page of the framed menu: the icon, the label, an optional badge and a tooltip for the rail."
  def rail_link(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:on, assigns.active or current?(assigns.rest, assigns.current))
      |> assign(
        :to,
        LedgerUI.LinkAttrs.resolve(assigns.rest, [
          "data-part",
          "data-lu-sb-item",
          "class",
          "aria-current",
          "data-lu-match"
        ])
      )

    assigns = settle(assigns, changed0, on: [:active, :rest, :current], to: [:rest])

    ~H"""
    <a
      data-part="rail-link"
      data-lu-sb-item
      class={cx([nav_item_classes(on: @on, sub: @variant == "sub"), @class])}
      aria-current={@on && "page"}
      data-lu-match={@match}
      {@to}
    >
      {render_slot(@inner_block)}<span
        data-part="rail-link-label"
        class="group-data-[collapsed]/side:hidden"
      >{@label}</span>
      <span :if={@trailing != []} data-part="rail-link-trailing" class={nav_r_classes()}>
        {render_slot(@trailing)}
      </span>
      <span :if={@badge} data-part="rail-link-badge" class={nav_badge_classes()}>{@badge}</span>
    </a>
    """
  end

  attr :variant, :string, default: "mono", values: ~w(mono sans)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A small uppercase title over a group of `rail_link/1`s; hidden in the rail. `mono` (default) or `sans`."
  def rail_heading(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :classes, rail_heading_classes(assigns.variant))
    assigns = settle(assigns, changed0, classes: [:variant])

    ~H"""
    <div data-part="rail-heading" class={cx([@classes, @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp rail_heading_classes("sans"),
    do: [
      "flex items-center gap-1 px-2.5 pb-1.5 pt-3.5 font-sans text-[11.5px] font-medium uppercase tracking-[.08em] text-muted",
      @side_hidden
    ]

  defp rail_heading_classes(_), do: nav_h_classes(true)

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
    attr :badge, :string
    attr :match, :string, doc: "The path (prefix) that makes the page active on the client."
  end

  @doc "A module of the framed menu: a button that opens the pages under it."
  def rail_module(assigns) do
    changed0 = assigns.__changed__

    items =
      Enum.map(assigns.item, &Map.put(&1, :on, &1[:active] || current?(&1, assigns.current)))

    any = Enum.any?(items, & &1.on)
    open = if is_nil(assigns.open), do: any, else: assigns.open
    id = assigns.id

    toggle =
      %JS{}
      |> JS.toggle_attribute({"hidden", "hidden"}, to: "##{id}-body")
      |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-head")

    # The head shows the active mark only when it stands for the page: with the group closed
    # (`aria-expanded=false`) or the menu collapsed. Open, only the active child carries it.
    head_on =
      "aria-[expanded=false]:bg-selected aria-[expanded=false]:text-ink " <>
        "aria-[expanded=false]:[&_svg:not([data-part=nav-caret])]:text-accent-content " <>
        "group-data-[collapsed]/side:bg-selected group-data-[collapsed]/side:text-ink " <>
        "group-data-[collapsed]/side:[&_svg:not([data-part=nav-caret])]:text-accent-content"

    assigns =
      assign(assigns, items: items, any: any, is_open: open, toggle: toggle, head_on: head_on)

    assigns =
      settle(assigns, changed0,
        items: [:item, :current],
        any: [:items],
        is_open: [:open, :any],
        toggle: [:id],
        head_on: []
      )

    ~H"""
    <div id={@id} data-part="rail-module" class={@class} {@rest}>
      <button
        data-part="rail-module-button"
        id={"#{@id}-head"}
        type="button"
        data-lu-sb-module
        data-lu-sb-item
        class={["group/exp", nav_item_classes(), @any && @head_on]}
        aria-expanded={to_string(@is_open)}
        aria-controls={"#{@id}-body"}
        phx-click={@toggle}
      >
        {render_slot(@icon)}<span
          data-part="rail-module-label"
          class="group-data-[collapsed]/side:hidden"
        >{@label}</span>
        <span :if={@badge} data-part="rail-module-badge" class={nav_badge_classes()}>{@badge}</span>
        <.icon name="chevron-down" size="sm" data-part="nav-caret" class={nav_caret_classes()} />
      </button>
      <div
        data-part="rail-module-body"
        id={"#{@id}-body"}
        hidden={!@is_open}
        class="group-data-[collapsed]/side:hidden"
      >
        <div data-part="rail-module-items" class="flex flex-col gap-0.5">
          <a
            :for={i <- @items}
            data-part="rail-module-link"
            {anchor(link_to(i))}
            class={nav_item_classes(sub: true, on: i.on)}
            aria-current={i.on && "page"}
          >
            {render_slot(i)}
            <span :if={i[:badge]} data-part="rail-module-link-badge" class={nav_badge_classes()}>
              {i[:badge]}
            </span>
          </a>
        </div>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :subtitle, :string, default: nil
  attr :initials, :string, default: nil

  attr :bare, :boolean,
    default: false,
    doc: "No margin under the box (for use outside of the menu)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "The workspace switcher under the brand of the framed menu. It is a button: `phx-click` opens your list."
  def rail_workspace(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :ini, assigns.initials || initials(assigns.name))
    assigns = settle(assigns, changed0, ini: [:initials, :name])

    ~H"""
    <button
      type="button"
      data-part="rail-workspace"
      class={cx([ws_classes(mb: @bare && "mb-0"), "w-full text-left", side_hidden(), @class])}
      {@rest}
    >
      <span data-part="rail-workspace-logo" class={ws_logo_classes(:accent)}>
        <%= if @inner_block == [] do %>
          {@ini}
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </span>
      <span data-part="rail-workspace-text" class={ws_text_classes()}>
        <b data-part="rail-workspace-name" class={ws_name_classes()}>{@name}</b>
        <span :if={@subtitle} data-part="rail-workspace-sub" class={ws_sub_classes()}>{@subtitle}</span>
      </span>
      <.icon name="updown" size="md" class={["text-ink", side_hidden()]} />
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
    <div data-part="rail-user" class={cx([user_classes(), @class])} {@rest}>
      {render_slot(@inner_block)}
      <span data-part="rail-user-person" class={[person_classes(), "min-w-0 flex-1"]}>
        <span data-part="rail-user-text" class={person_text_classes()}>
          <b data-part="rail-user-name" class={person_name_classes()}>{@name}</b>
          <span :if={@subtitle} data-part="rail-user-sub" class={person_sub_classes()}>{@subtitle}</span>
        </span>
      </span>
    </div>
    """
  end

  ## Page header

  attr :title, :string, default: nil, doc: "The title text. Or give the `:title` slot."

  attr :title_class, :any,
    default: nil,
    doc: "Classes of the `h1` (e.g. an `animate-[…]` utility for the canvas)."

  attr :variant, :string, default: "inline", values: ~w(inline page)

  attr :show_heading, :boolean,
    default: true,
    doc:
      "`false` does not render the `h1` (the title, the `:heading` slot and the inline badge); the crumbs, description and actions stay."

  attr :density, :string,
    default: "default",
    values: ~w(default compact),
    doc: "The top padding: `default` is 26px (`pt-[26px]`), `compact` is 24px (`pt-6`)."

  attr :description, :string, default: nil
  attr :back, :string, default: nil
  attr :back_label, :string, default: nil
  attr :badge_position, :string, default: "above", values: ~w(above inline)
  attr :clock, :boolean, default: false
  attr :locale, :string, default: nil
  attr :bell, :boolean, default: false
  attr :bell_label, :string, default: nil
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

  @ph "flex flex-wrap items-end gap-4 px-7 pb-[18px] pt-[26px]"
  @ph_page "flex flex-col flex-wrap items-stretch gap-2.5 px-7 pb-0 pt-[26px]"
  @ph_compact String.replace(@ph, "pt-[26px]", "pt-6")
  @ph_page_compact String.replace(@ph_page, "pt-[26px]", "pt-6")
  @ph_h1 "m-0 font-display text-[34px] font-semibold leading-10 tracking-[-.03em]"
  @ph_p "mb-0 mt-1 text-[15px] text-muted"
  @ph_act "ml-auto flex flex-wrap gap-2"

  @doc """
  The title of a page. `variant="inline"` is the row: title (with the breadcrumb above it), a
  description and the `:actions` at the right, then the `:tabs`. `variant="page"` is the framed
  shell's title block: a top row (the `:leading` slot, the crumbs, the clock and the bell) or a
  `back` link, the badge, the title with a context line and the actions, and the tabs.
  """
  def page_header(%{variant: "inline"} = assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, bell_label: "navbar.notifications")

    assigns =
      assign(assigns,
        ph: if(assigns.density == "compact", do: @ph_compact, else: @ph),
        h1: @ph_h1,
        p: @ph_p,
        act: @ph_act
      )

    assigns = settle(assigns, changed0, ph: [:density], h1: [], p: [], act: [])

    ~H"""
    <div data-part="page-header" class={cx([@ph, @class])} {@rest}>
      <div>
        <.ph_crumbs :if={@crumb != []} crumb={@crumb} locale={@locale} />
        <h1 :if={@show_heading} data-part="page-header-title" class={cx([@h1, @title_class])}>
          {if @heading != [], do: render_slot(@heading), else: @title}
        </h1>
        <p :if={@description} data-part="page-header-description" class={@p}>{@description}</p>
        <p :if={@subtitle != []} data-part="page-header-subtitle" class={@p}>
          {render_slot(@subtitle)}
        </p>
        {render_slot(@inner_block)}
      </div>
      <div :if={@actions != []} data-part="page-header-actions" class={@act}>
        {render_slot(@actions)}
      </div>
    </div>
    <div :if={@tabs != []} data-part="page-header-tabs" class="px-7">{render_slot(@tabs)}</div>
    """
  end

  def page_header(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, bell_label: "navbar.notifications")

    assigns =
      assigns
      |> assign(
        top?: assigns.crumb != [] or assigns.clock or assigns.bell or assigns.leading != [],
        bell_click: bell_click(assigns.on_bell),
        ph: if(assigns.density == "compact", do: @ph_page_compact, else: @ph_page),
        h1: @ph_h1,
        p: @ph_p,
        act: @ph_act
      )

    assigns =
      settle(assigns, changed0,
        top?: [:crumb, :clock, :bell, :leading],
        bell_click: [:on_bell],
        ph: [:density],
        h1: [],
        p: [],
        act: []
      )

    ~H"""
    <div data-part="page-header" class={cx([@ph, @class])} {@rest}>
      <div
        :if={!@back and @top?}
        data-part="page-header-top"
        class="flex min-h-8 items-center gap-2.5"
      >
        {render_slot(@leading)}
        <.ph_crumbs :if={@crumb != []} crumb={@crumb} locale={@locale} />
        <span data-part="page-header-spacer" class="min-w-0 flex-1"></span>
        <span
          :if={@clock}
          data-part="page-header-clock"
          id={@rest[:id] && "#{@rest[:id]}-clock"}
          phx-hook="LedgerUI.Clock"
          data-lu-locale={@locale}
          class="font-mono text-[12px] leading-4 text-muted"
        ></span>
        <%= if @notifications != [] do %>
          {render_slot(@notifications)}
        <% else %>
          <button
            :if={@bell}
            data-part="page-header-button"
            type="button"
            class={tbtn_classes()}
            aria-label={@bell_label}
            phx-click={@bell_click}
          >
            <.icon name="bell" />
          </button>
        <% end %>
      </div>
      <a
        :if={@back}
        data-part="page-header-link"
        {anchor(navigate: @back)}
        class="inline-flex h-auto cursor-pointer items-center justify-center gap-1.5 self-start whitespace-nowrap border-0 bg-transparent px-2.5 text-[13px] font-medium leading-none text-accent-content no-underline hover:underline hover:underline-offset-[3px] [&_svg]:size-4"
      >
        <.icon name="chevron-left" size="sm" />{@back_label}
      </a>
      <div :if={@badge != [] and @badge_position == "above"}>{render_slot(@badge)}</div>
      <div data-part="page-header-row" class="flex flex-wrap items-end gap-4">
        <div data-part="page-header-heading" class="flex items-center gap-3.5">
          <div :if={@icon != []}>{render_slot(@icon)}</div>
          <div>
            <h1 :if={@show_heading} data-part="page-header-title" class={cx([@h1, @title_class])}>
              {if @heading != [], do: render_slot(@heading), else: @title}<span
                :if={@badge != [] and @badge_position == "inline"}
                data-part="page-header-badge"
                class="ml-2.5 align-middle text-[14px]"
              >{render_slot(@badge)}</span>
            </h1>
            <p :if={@description} data-part="page-header-description" class={@p}>{@description}</p>
            <p :if={@subtitle != []} data-part="page-header-subtitle" class={@p}>
              {render_slot(@subtitle)}
            </p>
            {render_slot(@inner_block)}
          </div>
        </div>
        <div :if={@actions != []} data-part="page-header-actions" class={@act}>
          {render_slot(@actions)}
        </div>
      </div>
      <div :if={@tabs != []} data-part="page-header-tabs" class="px-7">{render_slot(@tabs)}</div>
    </div>
    """
  end

  attr :crumb, :list, required: true

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  defp ph_crumbs(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :last, length(assigns.crumb) - 1)
    assigns = assign(assigns, :crumbs, Enum.with_index(assigns.crumb))
    assigns = settle(assigns, changed0, last: [:crumb], crumbs: [:crumb])

    ~H"""
    <nav
      data-part="page-header-crumbs"
      aria-label={I18n.t("navbar.breadcrumb", @locale)}
      class="mb-1 flex items-center gap-2 text-[13.5px] text-muted"
    >
      <%= for {c, i} <- @crumbs do %>
        <span :if={i > 0} data-part="page-header-crumbs-separator" class="text-line-strong"><.icon
          name="chevron-right"
          size="sm"
        /></span>
        <a
          :if={i != @last and link_to(c)}
          data-part="page-header-crumbs-link"
          {anchor(link_to(c))}
          class="text-muted no-underline hover:text-ink"
        >{render_slot(c)}</a>
        <span :if={i != @last and !link_to(c)}>{render_slot(c)}</span>
        <span
          :if={i == @last}
          data-part="page-header-crumbs-current"
          class="font-medium text-ink"
          aria-current="page"
        >{render_slot(c)}</span>
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
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def monochrome_toggle(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:on_change_event, if(is_binary(assigns.on_change), do: assigns.on_change))
      |> assign(
        :on_change_js,
        match?(%Phoenix.LiveView.JS{}, assigns.on_change) && assigns.on_change
      )

    assigns = settle(assigns, changed0, on_change_event: [:on_change], on_change_js: [:on_change])

    ~H"""
    <button
      :if={@variant == "button"}
      id={@id}
      type="button"
      phx-hook="LedgerUI.MonochromeToggle"
      data-lu-on-change={@on_change_event}
      data-lu-target={is_binary(@target) && @target}
      data-on-change-js={@on_change_js}
      data-part="monochrome-toggle"
      aria-label={I18n.t("shell.monochrome", @locale)}
      aria-pressed="false"
      class={cx([tbtn_classes(), @class])}
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
      data-part="monochrome-toggle"
      role="switch"
      aria-checked="false"
      class={
        cx([
          "group inline-flex cursor-pointer items-center gap-2.5 text-[14px] text-ink [--in:3px] [--r:7px] [--th:22px] [--tw:36px]",
          @class
        ])
      }
      {@rest}
    >
      <i
        data-part="monochrome-toggle-track"
        class="relative block h-(--th) w-(--tw) flex-none rounded-(--r) bg-line-strong transition-[background-color] duration-150 after:absolute after:top-(--in) after:left-(--in) after:size-[calc(var(--th)-2*var(--in))] after:rounded-[calc(var(--r)-var(--in)+1px)] after:bg-white after:shadow-[0_1px_2px_rgba(0,0,0,.25)] after:transition-transform after:duration-[180ms] after:ease-[cubic-bezier(.3,.7,.4,1)] after:content-[''] group-aria-checked:bg-accent group-aria-checked:after:translate-x-[calc(var(--tw)-var(--th))]"
      ></i><span data-part="monochrome-toggle-label" class="flex flex-col gap-0.5">{render_slot(
        @inner_block
      )}</span>
    </span>
    """
  end

  ## Helpers

  defp link_to(%{navigate: to}) when is_binary(to), do: [navigate: to]
  defp link_to(%{patch: to}) when is_binary(to), do: [patch: to]
  defp link_to(%{href: to}) when is_binary(to), do: [href: to]
  defp link_to(_), do: nil

  # The attributes of the `<a>` that `<.link>` would render for a destination (see `LedgerUI.LinkAttrs`).
  defp anchor(dest, extra \\ []),
    do: LedgerUI.LinkAttrs.resolve(Keyword.merge(dest || [href: "#"], extra))

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
    do: s |> String.downcase() |> slugify()

  # Sem regex: cada trecho de bytes fora de [a-z0-9] vira um "-"; as pontas são aparadas.
  defp slugify(s), do: s |> slug_bytes(<<>>) |> String.trim("-")

  defp slug_bytes(<<c, rest::binary>>, acc) when c in ?a..?z or c in ?0..?9,
    do: slug_bytes(rest, <<acc::binary, c>>)

  defp slug_bytes(<<_, rest::binary>>, acc), do: slug_bytes(skip_other(rest), <<acc::binary, ?->>)
  defp slug_bytes(<<>>, acc), do: acc

  defp skip_other(<<c, _::binary>> = s) when c in ?a..?z or c in ?0..?9, do: s
  defp skip_other(<<_, rest::binary>>), do: skip_other(rest)
  defp skip_other(<<>>), do: <<>>

  defp initials(name),
    do:
      name
      |> String.split([" ", "\n", "\t", "\r"], trim: true)
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

  ## Names of the design's cards

  attr :id, :string, default: "main-sidebar"

  attr :current, :any,
    default: nil,
    doc: "The current path (matched against each item's link), or an item's `name`."

  attr :centered, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  attr :active_link, :boolean,
    default: false,
    doc:
      "Marks the active item on the client (`LedgerUI.ActiveLink`) from the `match` of each item; needs an `id`."

  slot :bottom

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :match, :string, doc: "The path (prefix) that makes the item active on the client."
    attr :label, :string
    attr :icon, :string, doc: "The name of the icon the link shows (or put it in the slot)."
    attr :name, :any, doc: "Marks the item as active when `current` is this name."
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

  @doc "Same as `main_sidebar/1` (same attributes and slots), under the name the design vitrine uses."
  def icon_rail(assigns), do: main_sidebar(assigns)

  attr :title, :string, required: true

  attr :loop, :boolean,
    default: false,
    doc: "The canvas loop: the first group closes and opens again, forever."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :group, doc: "A collapsible group under the title: a caption and the links." do
    attr :label, :string, required: true
    attr :open, :boolean, doc: "Open at first (the default)."
  end

  slot :inner_block, doc: "What goes before the groups."

  @doc """
  The sub navigation next to the icon rail: a title and groups of links that open and close.

      <.sub_nav title="Cases">
        <:group label="Status">
          <.sidebar_nav_link navigate={~p"/cases/open"}>Open</.sidebar_nav_link>
        </:group>
      </.sub_nav>
  """
  def sub_nav(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(assigns,
        groups:
          assigns.group
          |> Enum.with_index()
          |> Enum.map(fn {g, i} ->
            id = "subnav-#{slug(assigns.title)}-#{i}"

            Map.merge(Map.take(g, [:label]), %{
              slot: g,
              id: id,
              open: g[:open] != false,
              loop: assigns.loop and i == 0
            })
          end)
      )

    assigns = settle(assigns, changed0, groups: [:group, :title, :loop])

    ~H"""
    <div data-part="sub-nav" data-lu-subnav class={cx([subnav_classes(), @class])} {@rest}>
      <h4 data-part="sub-nav-title" class={subnav_title_classes()}>{@title}</h4>
      {render_slot(@inner_block)}
      <%= for g <- @groups do %>
        <button
          data-part="sub-nav-button"
          type="button"
          class={[
            "group/exp w-full cursor-pointer border-0 bg-transparent text-left [font:inherit]",
            nav_h_classes()
          ]}
          aria-expanded={to_string(g.open)}
          aria-controls={g.id}
          phx-click={
            JS.toggle_attribute({"hidden", "hidden"}, to: "#" <> g.id)
            |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "[aria-controls=#{g.id}]")
          }
        >
          <.icon
            name="chevron-down"
            size="sm"
            class={[
              "transition-transform duration-150 group-aria-[expanded=false]/exp:-rotate-90",
              g.loop && "animate-[mo-rot_5s_ease-in-out_infinite]"
            ]}
          />{g.label}
        </button>
        <div
          id={g.id}
          hidden={!g.open}
          class={g.loop && "animate-[mo-expand_5s_ease-in-out_infinite] overflow-hidden [--mh:160px]"}
        >
          {render_slot(g.slot)}
        </div>
      <% end %>
    </div>
    """
  end
end
