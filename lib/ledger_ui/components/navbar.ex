defmodule LedgerUI.Components.Navbar do
  @moduledoc """
  The app top bar: a container (`navbar/1`) and small pieces to put in it. The right side keeps the
  same vocabulary (search, notifications, theme, language and the user); the variants change what
  goes on the left and the visual weight.

      <.navbar>
        <.navbar_crumbs items={[%{label: "Início", navigate: ~p"/"}, %{label: "Site novo"}]} />
        <:end>
          <.navbar_search placeholder="Buscar…" phx-click={JS.exec("data-show", to: "#palette")} />
          <.navbar_bell dot />
          <.theme_switch id="theme" variant="icons" size="sm" />
          <.navbar_user id="me" user={@user}>
            <:menu>
              <.navbar_menu_head user={@user} />
              <.navbar_menu_item icon="user" navigate={~p"/perfil"}>Perfil</.navbar_menu_item>
              <.navbar_menu_item icon="logout" danger href={~p"/sair"} method="delete">Sair</.navbar_menu_item>
            </:menu>
          </.navbar_user>
        </:end>
      </.navbar>

  `variant`: `"default"` (64px, a line under it), `"float"` (a detached raised bar), `"clear"`
  (transparent, over a hero), `"dense"` (48px) or `"mobile"` (56px). `size="sm"` is 52px. Slots:
  `inner_block` (the left side), `:center`, `:end` (the right side) and `:tabs`, which makes the bar
  two rows (the tabs row under the content).

  The slots are rendered straight inside the `<header>` (a flex row), so the items are its direct
  children and the crumbs take the free space. Inside `Shell` the bar sticks to the top and
  blurs what scrolls under it, like `Shell.header/1`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Dropdown
  import LedgerUI.Components.Avatar, only: [avatar: 1, avatar_group: 1]
  import LedgerUI.Components.Badge, only: [badge: 1]
  import LedgerUI.Components.Typography, only: [kbd: 1]

  import LedgerUI.Components.Shell,
    only: [
      active_link_attrs: 2,
      nav_item_classes: 1,
      person_classes: 0,
      person_name_classes: 0,
      person_text_classes: 0,
      person_sub_classes: 0,
      search_box_classes: 1,
      search_input_classes: 0,
      tbtn_classes: 1,
      topbar_classes: 0,
      ws_classes: 1,
      ws_logo_classes: 0,
      ws_name_classes: 0,
      ws_sub_classes: 0,
      ws_text_classes: 0
    ]

  @shell_bar topbar_classes()

  # One string of geometry per bar: height, padding and gap never come twice. `mobile` beats `sm`,
  # `sm` beats `dense`; the tabs make a column.
  defp bar_classes(%{variant: v} = a) do
    height =
      cond do
        a.tabs != [] -> "h-auto"
        v == "mobile" -> "h-14"
        a.size == "sm" -> "h-[52px]"
        v == "dense" -> "h-12"
        true -> "h-16"
      end

    pad = if v == "mobile", do: "px-3", else: "pl-6 pr-5"
    flow = if a.tabs != [], do: "flex-col items-stretch gap-0 pb-0", else: "gap-2.5"

    case v do
      # no border and no sticky background: a detached card / a transparent bar
      "float" ->
        [
          "flex shrink-0 items-center",
          "m-2.5 rounded-xl bg-panel shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-md)]",
          height,
          pad,
          flow
        ]

      "clear" ->
        ["flex shrink-0 items-center bg-transparent", height, pad, flow]

      _ ->
        [@shell_bar, height, pad, flow]
    end
  end

  ## Container

  attr :variant, :string,
    default: "default",
    values: ~w(default canvas float clear dense mobile),
    doc: "`canvas` is the same as `default` (the canvas's own bar)."

  attr :size, :string, default: "md", values: ~w(md sm)
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "The left side."
  slot :center, doc: "Between the left and the right: `navbar_links/1`, a wide `navbar_search/1`."
  slot :end, doc: "The right side."
  slot :tabs, doc: "`navbar_tabs/1`: makes the bar two rows."

  def navbar(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :end_slot, assigns[:end] || [])

    assigns = assign(assigns, :classes, cx(["group/navbar", bar_classes(assigns), assigns.class]))

    assigns =
      settle(assigns, changed0,
        end_slot: [:end],
        # `tabs` is not a source (a slot only checked for being empty: fixed by the call site)
        classes: [:variant, :size, :class]
      )

    ~H"""
    <header :if={@tabs == []} id={@id} data-part="navbar" class={@classes} {@rest}>
      {render_slot(@inner_block)}
      {render_slot(@center)}
      {render_slot(@end_slot)}
    </header>
    <header :if={@tabs != []} id={@id} data-part="navbar" class={@classes} {@rest}>
      <div data-part="navbar-row" class="flex h-14 items-center gap-2.5">
        {render_slot(@inner_block)}
        {render_slot(@center)}
        {render_slot(@end_slot)}
      </div>
      <div data-part="navbar-tabs-row" class="flex">{render_slot(@tabs)}</div>
    </header>
    """
  end

  ## Left side

  attr :name, :string, default: nil
  attr :logo, :string, default: nil, doc: "The letter in the logo (default: the first of `name`)."
  attr :src, :string, default: nil, doc: "A picture for the logo instead of the letter."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The logo and the name of the app."
  def navbar_brand(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :letter, assigns.logo || first_letter(assigns.name))
    assigns = settle(assigns, changed0, letter: [:logo, :name])

    ~H"""
    <span
      data-part="navbar-brand"
      class={cx(["inline-flex items-center gap-2.5 text-[15px] font-semibold", @class])}
      {@rest}
    >
      <span
        data-part="navbar-brand-mark"
        class="inline-grid size-7 place-items-center overflow-hidden rounded-md bg-inverse text-[13px] font-bold text-on-inverse"
      >
        <img
          :if={@src}
          data-part="navbar-brand-img"
          src={@src}
          alt=""
          class="size-full rounded-[inherit] object-cover"
        />
        <span :if={!@src}>{@letter}</span>
      </span>
      <span :if={@name}>{@name}</span>
    </span>
    """
  end

  attr :items, :list, required: true

  attr :label, :any,
    default: nil,
    doc: "The `aria-label` of the `nav` (`nil` leaves it out)."

  attr :variant, :string,
    default: "canvas",
    values: ~w(canvas plain),
    doc: "`plain` is the bare trail of the app top bar (larger text, no chips)."

  attr :icon, :string, default: nil, doc: "An icon before the trail (`grid`)."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The path to the page. Each item is `%{label: "...", navigate: path}` (or `href` / `patch`); the
  last one, the page itself, is the current one, and an item with no link is plain text.
  """
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def navbar_crumbs(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "navbar.breadcrumb")

    last = length(assigns.items) - 1
    assigns = assign(assigns, :rows, Enum.with_index(assigns.items))
    assigns = assign(assigns, :last, last)
    canvas? = assigns.variant == "canvas"

    assigns =
      assign(assigns,
        link_cls: [
          "text-muted no-underline hover:text-ink",
          canvas? && "rounded-md px-2 py-[3px] hover:bg-hover"
        ],
        cur_cls: ["font-medium text-ink", canvas? && "rounded-md bg-sunken px-2 py-[3px]"],
        root_cls: [
          "flex items-center text-muted group-data-[part=navbar]/navbar:flex-1",
          if(canvas?, do: "gap-1 text-[13.5px]", else: "gap-2 text-[15px]")
        ]
      )

    assigns =
      settle(assigns, changed0,
        rows: [:items],
        last: [:items],
        link_cls: [:variant],
        cur_cls: [:variant],
        root_cls: [:variant]
      )

    ~H"""
    <nav
      data-part="navbar-crumbs"
      class={cx([@root_cls, @class])}
      aria-label={@label}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} size="md" />
      <%= for {item, i} <- @rows do %>
        <span :if={i > 0} data-part="navbar-crumbs-separator" class="text-line-strong">/</span>
        <span
          :if={i == @last}
          data-part="navbar-crumbs-current"
          class={@cur_cls}
          aria-current={@label && "page"}
        >{item.label}</span>
        <a
          :if={i != @last && target(item)}
          data-part="navbar-crumbs-link"
          {LedgerUI.LinkAttrs.resolve(target(item))}
          class={@link_cls}
        >{item.label}</a>
        <span :if={i != @last && !target(item)}>{item.label}</span>
      <% end %>
    </nav>
    """
  end

  attr :name, :string, required: true
  attr :sub, :string, default: nil
  attr :logo, :string, default: nil
  attr :src, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The workspace switcher: logo, name, a line under it and a chevron. `phx-click` opens your menu."
  def navbar_workspace(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :letter, assigns.logo || first_letter(assigns.name))
    assigns = settle(assigns, changed0, letter: [:logo, :name])

    ~H"""
    <span data-part="navbar-workspace" class="flex min-w-0 flex-1">
      <button
        data-part="navbar-workspace-button"
        type="button"
        class={cx([ws_classes(mb: "m-0"), "text-left", @class])}
        {@rest}
      >
        <span data-part="navbar-workspace-logo" class={ws_logo_classes()}>
          <img
            :if={@src}
            data-part="navbar-workspace-img"
            src={@src}
            alt=""
            class="size-full rounded-[inherit] object-cover"
          />
          <span :if={!@src}>{@letter}</span>
        </span>
        <span data-part="navbar-workspace-text" class={ws_text_classes()}>
          <b data-part="navbar-workspace-name" class={ws_name_classes()}>{@name}</b>
          <span :if={@sub} data-part="navbar-workspace-sub" class={ws_sub_classes()}>{@sub}</span>
        </span>
        <.icon name="updown" size="md" class="text-ink" />
      </button>
    </span>
    """
  end

  attr :label, :string, required: true
  attr :square, :string, default: nil, doc: "The text in the square (2 or 3 letters)."

  attr :color, :string,
    default: nil,
    doc:
      "The CSS color of the square (any CSS value, so it has no `values:`; for a semantic tone use `var(--lu-pos)` and the like)."

  attr :tag, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "A selector in a path of selectors (organization, project). `phx-click` opens the list."
  def navbar_chip(assigns) do
    ~H"""
    <button
      type="button"
      data-part="navbar-chip"
      class={
        cx([
          "inline-flex h-8 cursor-pointer items-center gap-2 rounded-md border-0 bg-transparent px-2 text-[14px] font-medium text-ink",
          @class
        ])
      }
      {@rest}
    >
      <span
        :if={@square}
        data-part="navbar-chip-square"
        class={[
          "inline-grid h-5 min-w-5 place-items-center rounded-sm px-1 text-[10.5px] font-bold text-white",
          !@color && "bg-ink"
        ]}
        style={@color && "background:#{@color}"}
      >{@square}</span>
      {@label}
      <.badge :if={@tag} canvas size="sm">{@tag}</.badge>
      <.icon name="updown" size="sm" class="text-ink" />
    </button>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The `/` between two selectors."
  def navbar_slash(assigns) do
    ~H"""
    <span
      data-part="navbar-slash"
      class={cx(["text-line-strong", @class])}
      aria-hidden="true"
      {@rest}
    >/</span>
    """
  end

  ## Middle

  attr :items, :list, required: true
  attr :current, :string, default: nil

  attr :active_link, :boolean,
    default: false,
    doc:
      "Marks the active item on the client (`LedgerUI.ActiveLink`) from the `match` of each item; needs an `id`."

  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The main links, centered. Items are `%{label:, navigate:, active:}` (`href` / `patch` work too).
  The active one is the item with `active: true` or the one whose link equals `current`.

  With `active_link` (and an `id`) the client marks the active one instead (`LedgerUI.ActiveLink`):
  give each item `match: "/path"` and the menu is not sent again when the route changes.
  """
  def navbar_links(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :items, mark_active(assigns.items, assigns.current))
    assigns = settle(assigns, changed0, items: [:current])

    ~H"""
    <nav
      data-part="navbar-links"
      aria-label={@label}
      class={cx(["flex flex-1 items-center justify-center gap-1", @class])}
      {active_link_attrs(@active_link, :nav)}
      {@rest}
    >
      <a
        :for={item <- @items}
        data-part="navbar-links-link"
        {LedgerUI.LinkAttrs.resolve(target(item) || [])}
        class={nav_item_classes(on: item.active, slim: true)}
        aria-current={item.active && "page"}
        data-lu-match={item[:match]}
      >
        {item.label}
      </a>
    </nav>
    """
  end

  attr :items, :list, required: true
  attr :current, :string, default: nil

  attr :active_link, :boolean,
    default: false,
    doc:
      "Marks the active item on the client (`LedgerUI.ActiveLink`) from the `match` of each item; needs an `id`."

  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The tabs of the page, for the `:tabs` slot of `navbar/1`. Items are those of `navbar_links/1` (with `match` and `active_link` too) plus an optional `count`."
  def navbar_tabs(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :items, mark_active(assigns.items, assigns.current))
    assigns = settle(assigns, changed0, items: [:current])

    ~H"""
    <nav
      data-part="navbar-tabs"
      aria-label={@label}
      class={cx(["relative flex w-full gap-[22px] border-b border-line px-1", @class])}
      {active_link_attrs(@active_link, :tabs)}
      {@rest}
    >
      <a
        :for={item <- @items}
        data-part="navbar-tabs-link"
        {LedgerUI.LinkAttrs.resolve(target(item) || [])}
        aria-current={item.active && "page"}
        data-lu-match={item[:match]}
        class={[
          "relative inline-flex h-10 cursor-pointer items-center gap-[7px] px-2.5 text-[14px] font-medium no-underline",
          if(item.active,
            do:
              "text-ink shadow-[inset_0_-2px_0_var(--lu-ink)] after:absolute after:inset-x-0 after:-bottom-px after:h-0.5 after:rounded-[2px] after:bg-ink after:content-['']",
            else: "text-muted hover:text-ink"
          )
        ]}
      >
        {item.label}
        <span
          :if={item[:count]}
          data-part="navbar-tabs-count"
          class="font-mono text-[11.5px] text-muted"
        >{item.count}</span>
      </a>
    </nav>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The centered title of the mobile bar."
  def navbar_title(assigns) do
    ~H"""
    <span
      data-part="navbar-title"
      class={cx(["flex-1 text-center text-[15px] font-semibold", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  ## Right side

  attr :placeholder, :string, default: nil
  attr :kbd, :string, default: "⌘K", doc: "The shortcut shown at the end; `nil` hides it."
  attr :wide, :boolean, default: false

  attr :size, :string,
    default: "md",
    values: ~w(md sm),
    doc: "`md` is 36px tall; `sm` is the compact field: 32px (`h-8`), 8px radius, `px-2.5`."

  attr :input, :boolean,
    default: false,
    doc: "A real `<input>` with the placeholder, instead of the static text (a field of the bar)."

  attr :demo, :string,
    default: nil,
    values: [nil, "typing"],
    doc:
      "`typing`: the canvas loop. `value` is typed one letter after the other, with a blinking caret, and erased, forever."

  attr :loop, :boolean, default: false, doc: "Same as `demo=\"typing\"`."

  attr :icon_only, :boolean,
    default: false,
    doc:
      "Only the search icon, as a button of the bar (the placeholder is its `aria-label`): the compact form of `navbar_cluster/1`."

  attr :value, :string, default: nil, doc: "The text typed by the `typing` demo."
  attr :width, :string, default: nil, doc: ~s|A CSS width ("240px", "100%").|
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-click)

  @doc """
  The search field of the bar. It is a trigger, not an input: with `phx-click` it becomes a button
  (role and tabindex) that opens the command palette.
  """
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def navbar_search(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, placeholder: "navbar.search")

    rest = assigns.rest
    clickable = Map.has_key?(rest, :"phx-click")

    assigns =
      assigns
      |> assign(:style, search_style(assigns))
      |> assign(:box, if(assigns.size == "sm", do: :sm, else: :navbar))
      |> assign(:typing, assigns.demo == "typing" or assigns.loop)
      |> assign(:steps, String.length(assigns.value || assigns.placeholder))
      |> assign(:role, clickable && "button")
      |> assign(:tabindex, clickable && "0")

    # `steps` reads the placeholder (a text of the process locale) only when `value` is not given.
    assigns =
      settle(
        assigns,
        changed0,
        [
          style: [:width, :rest],
          box: [:size],
          typing: [:demo, :loop],
          role: [:rest],
          tabindex: [:rest]
        ] ++ if(assigns.value, do: [steps: [:value]], else: [])
      )

    ~H"""
    <span
      data-part="navbar-search"
      class={
        cx([
          if(@icon_only, do: icon_only_classes(@size), else: search_box_classes(@box)),
          @wide && !@icon_only && "w-full max-w-[520px]",
          @class
        ])
      }
      data-icon-only={@icon_only}
      aria-label={@icon_only && @placeholder}
      role={@role}
      tabindex={@tabindex}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      <.icon name="search" size="md" />
      <input
        :if={@input and !@typing and !@icon_only}
        data-part="navbar-search-input"
        placeholder={@placeholder}
        class={search_input_classes()}
      />
      <span
        :if={@typing and !@icon_only}
        data-part="navbar-search-value"
        class="flex min-w-0 flex-1 items-center overflow-hidden text-[14px] whitespace-nowrap"
      ><span
        data-part="navbar-search-typed"
        class="inline-block max-w-0 animate-[lu-typeloop_6s_steps(var(--steps,20))_infinite] overflow-hidden align-bottom whitespace-nowrap"
        style={"--steps:#{@steps}"}
      >{@value || @placeholder}</span><span
        data-part="navbar-search-caret"
        class="ml-px h-[18px] w-[1.5px] flex-none animate-[lu-caret_1s_steps(1)_infinite] bg-ink"
      ></span></span>
      <span
        :if={!@input and !@typing and !@icon_only}
        data-part="navbar-search-value"
        class="flex min-w-0 flex-1 items-center overflow-hidden whitespace-nowrap text-[14px]"
      ><span data-part="navbar-search-placeholder">{@placeholder}</span></span>
      <.kbd :if={@kbd && !@icon_only}>{@kbd}</.kbd>
    </span>
    """
  end

  # The pieces inside the capsule: no border of their own, 8px corners, 18px icons, the search field on
  # the tray surface. The names of the parts are the contract (`navbar_icon`, `theme_toggle`,
  # `navbar_bell`, `navbar_search`).
  @cluster_base "inline-flex items-center bg-panel border border-line shadow-[var(--lu-shadow-xs)] " <>
                  "[&_[data-part=navbar-icon]]:border-0 [&_[data-part=theme-toggle]]:border-0 [&_[data-part=navbar-bell]]:border-0 " <>
                  "[&_[data-part=navbar-icon]_svg]:size-[18px] [&_[data-part=theme-toggle]_svg]:size-[18px] [&_[data-part=navbar-bell]_svg]:size-[18px] " <>
                  "[&_[data-part=navbar-search]]:bg-tray " <>
                  "[&_[data-part=navbar-bell-count]]:-top-1 [&_[data-part=navbar-bell-count]]:-right-1 " <>
                  "[&_[data-part=navbar-bell-count]]:px-1 [&_[data-part=navbar-bell-count]]:text-[10.5px] [&_[data-part=navbar-bell-count]]:leading-none " <>
                  "[&_[data-part=navbar-bell-count]]:font-semibold [&_[data-part=navbar-bell-count]]:border-panel " <>
                  "[&_[data-part=navbar-search]:not([data-icon-only])]:mr-1 " <>
                  "[&_[data-part=navbar-search]:not([data-icon-only])]:w-[200px]"

  @cluster_shape %{
    "rounded" =>
      "rounded-md [&_[data-part=navbar-search]]:rounded-sm [&_[data-part=navbar-icon]]:rounded-sm " <>
        "[&_[data-part=theme-toggle]]:rounded-sm [&_[data-part=navbar-bell]]:rounded-sm",
    "pill" =>
      "rounded-full [&_[data-part=navbar-search]]:rounded-full [&_[data-part=navbar-icon]]:rounded-full " <>
        "[&_[data-part=theme-toggle]]:rounded-full [&_[data-part=navbar-bell]]:rounded-full"
  }

  # md: 32px cells in 4px of padding; sm: 28px cells in 3px. The unread dot is 8px (with a 2px panel ring).
  @cluster_size %{
    "md" =>
      "gap-0.5 p-1 [&_[data-part=navbar-icon]]:size-8 [&_[data-part=theme-toggle]]:size-8 [&_[data-part=navbar-bell]]:size-8 " <>
        "[&_[data-part=navbar-bell-count]]:h-[18px] [&_[data-part=navbar-bell-count]]:min-w-[18px] " <>
        "[&_[data-part=navbar-search]]:h-8 [&_[data-part=navbar-search][data-icon-only]]:size-8 " <>
        "[&_[data-part=navbar-icon]]:after:absolute [&_[data-part=navbar-icon]]:after:top-1.5 [&_[data-part=navbar-icon]]:after:right-1.5 [&_[data-part=navbar-icon]]:after:size-2",
    "sm" =>
      "gap-0.5 p-[3px] [&_[data-part=navbar-icon]]:size-7 [&_[data-part=theme-toggle]]:size-7 [&_[data-part=navbar-bell]]:size-7 " <>
        "[&_[data-part=navbar-bell-count]]:h-4 [&_[data-part=navbar-bell-count]]:min-w-4 " <>
        "[&_[data-part=navbar-search]]:h-7 [&_[data-part=navbar-search][data-icon-only]]:size-7 " <>
        "[&_[data-part=navbar-icon]]:after:absolute [&_[data-part=navbar-icon]]:after:top-1 [&_[data-part=navbar-icon]]:after:right-1 [&_[data-part=navbar-icon]]:after:size-2"
  }

  attr :shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc: "`rounded` (default): 12px corners; `pill`: fully round, and so are the buttons inside."

  attr :size, :string,
    default: "md",
    values: ~w(md sm),
    doc: "`md`: 32px buttons in 4px of padding; `sm`: 28px buttons in 3px."

  attr :label, :string, default: nil, doc: "The `aria-label` of the group (`nil` leaves it out)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "The pieces of the bar, in order."

  @doc """
  The top-bar actions in one capsule: a single surface (panel, thin border, 12px corners, `shadow-xs`,
  4px of padding and 2px between the pieces); the buttons inside have no border of their own (the
  cluster takes it off, so the pieces keep their HTML outside it). The search field is on the tray
  surface (32px tall, 8px corners, with its `kbd`), the icon buttons are 32x32 with 8px corners and
  18px icons. The notification dot is 8px with a 2px ring in the panel colour; a `count` is a `bg-neg`
  badge with 5px corners. `shape="pill"` makes everything fully round; `size="sm"` shrinks the
  cells to 28px.

      <.navbar_cluster shape="rounded">
        <.navbar_search kbd="⌘ K" phx-click={JS.exec("data-show", to: "#palette")} />
        <.navbar_lang locales={["PT", "EN"]} current="PT" />
        <.navbar_fullscreen />
        <.theme_toggle />
        <.navbar_bell dot />
        <.navbar_user user={@user} />
      </.navbar_cluster>

  For the compact form use `<.navbar_search icon_only />`. `lu:fullscreen` (dispatched on any
  element, as `navbar_fullscreen/1` does with `JS.dispatch("lu:fullscreen")`) toggles the browser
  fullscreen; it is handled by a listener of the kit's JS.

  The "Shortcuts" button of `page_trail/1` (`variant="menu"`) goes in the `:end` slot of the
  navbar BEFORE the cluster, with the same height and surface:

      <:end>
        <.page_trail id="trail" trail={@page_trail} variant="menu" label="Atalhos" />
        <.navbar_cluster>...</.navbar_cluster>
      </:end>
  """
  def navbar_cluster(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(
        assigns,
        :classes,
        cx([
          @cluster_base,
          @cluster_shape[assigns.shape],
          @cluster_size[assigns.size],
          assigns.class
        ])
      )

    assigns = settle(assigns, changed0, classes: [:shape, :size, :class])

    ~H"""
    <div data-part="navbar-cluster" role="group" aria-label={@label} class={@classes} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :dot, :boolean, default: false, doc: "There is something unread."

  attr :tone, :string,
    default: nil,
    values: [nil | LedgerUI.Helpers.tone_values(~w(neg warn pos))],
    doc:
      "The color of the dot (default `pos`) or of the count badge (default `neg`): `neg`, `warn`, `pos`; `error`, `warning` and `success` are aliases."

  attr :count, :integer,
    default: nil,
    doc: "A count badge instead of the dot."

  attr :label, :string, default: nil
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)

  @bell_tone LedgerUI.Helpers.tone_map(%{
               "neg" => "bg-neg text-white",
               "warn" => "bg-[#f59e0b] text-[#1b1300]",
               "pos" => "bg-pos text-white"
             })

  @doc "The notifications button; `dot` shows the dot of something unread."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def navbar_bell(%{count: count} = assigns) when is_integer(count) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "navbar.notifications")

    assigns =
      assigns
      |> assign(:clickable, clickable?(assigns.rest))
      |> assign(:badge_tone, @bell_tone[assigns.tone || "neg"])

    assigns = settle(assigns, changed0, clickable: [:rest], badge_tone: [:tone])

    ~H"""
    <span
      data-part="navbar-bell"
      class={
        cx([
          "relative inline-grid size-9 place-items-center rounded-md border border-line-strong bg-panel",
          @class
        ])
      }
      role={@clickable && "button"}
      tabindex={@clickable && "0"}
      aria-label={@clickable && @label}
      {@rest}
    >
      <.icon name="bell" /><b
        data-part="navbar-bell-count"
        class={[
          "absolute -top-[5px] -right-[5px] grid h-[18px] min-w-[18px] place-items-center rounded-[5px] border-2 border-page px-[5px] text-[11px]",
          @badge_tone
        ]}
      >{@count}</b>
    </span>
    """
  end

  def navbar_bell(assigns) do
    assigns = I18n.texts(assigns, label: "navbar.notifications")

    ~H"""
    <.nb_btn
      name="bell"
      label={@label}
      size={@size}
      dot={@dot}
      tone={@tone || "pos"}
      class={@class}
      rest={@rest}
    />
    """
  end

  attr :name, :string, required: true, doc: "A Hugeicons name."
  attr :label, :string, required: true
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)

  @doc "An icon button of the bar (search on a small screen, help, the menu of the mobile bar)."
  def navbar_icon(assigns) do
    ~H"""
    <.nb_btn name={@name} label={@label} size={@size} class={@class} rest={@rest} />
    """
  end

  attr :label, :string, default: nil, doc: "The `aria-label` (default \"Fullscreen\")."
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :class, :any, default: nil
  attr :rest, :global

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  @doc """
  The fullscreen button of the bar: it dispatches `lu:fullscreen` (the kit's JS toggles the browser
  fullscreen of the page) and, while the page is fullscreen, shows the "exit" icon and
  `aria-pressed="true"`. `detail.to` of the event (a selector) would fullscreen another element.
  """
  def navbar_fullscreen(assigns) do
    assigns = I18n.texts(assigns, label: "navbar.fullscreen")

    ~H"""
    <button
      type="button"
      data-part="navbar-icon"
      data-lu-fullscreen
      aria-label={@label}
      aria-pressed="false"
      phx-click={JS.dispatch("lu:fullscreen")}
      phx-mounted={JS.ignore_attributes(["aria-pressed"])}
      class={cx([tbtn_classes(size: if(@size == "sm", do: :sm)), "group/fs", @class])}
      {@rest}
    >
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.5"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
        data-icon="fullscreen-enter"
        class="size-4 group-aria-pressed/fs:hidden"
      >
        <path d="M3 8V5.5A2.5 2.5 0 0 1 5.5 3H8M16 3h2.5A2.5 2.5 0 0 1 21 5.5V8M21 16v2.5a2.5 2.5 0 0 1-2.5 2.5H16M8 21H5.5A2.5 2.5 0 0 1 3 18.5V16" />
      </svg>
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.5"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
        data-icon="fullscreen-exit"
        class="hidden size-4 group-aria-pressed/fs:block"
      >
        <path d="M8 3v2.5A2.5 2.5 0 0 1 5.5 8H3M21 8h-2.5A2.5 2.5 0 0 1 16 5.5V3M3 16h2.5A2.5 2.5 0 0 1 8 18.5V21M16 21v-2.5a2.5 2.5 0 0 1 2.5-2.5H21" />
      </svg>
    </button>
    """
  end

  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :size, :string, default: "md"
  attr :dot, :boolean, default: false
  attr :tone, :string, default: "neg"
  attr :class, :any, default: nil
  attr :rest, :map, default: %{}

  defp nb_btn(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:link, target(assigns.rest) && LedgerUI.LinkAttrs.resolve(target(assigns.rest)))
      |> assign(
        :cls,
        tbtn_classes(
          dot: assigns.dot,
          tone: assigns.tone,
          size: if(assigns.size == "sm", do: :sm)
        )
      )

    assigns = settle(assigns, changed0, link: [:rest], cls: [:dot, :tone, :size])

    ~H"""
    <a :if={@link} {@link} data-part="navbar-icon" aria-label={@label} class={cx([@cls, @class])}>
      <.icon name={@name} />
    </a>
    <button
      :if={!@link}
      type="button"
      data-part="navbar-icon"
      aria-label={@label}
      class={cx([@cls, @class])}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      <.icon name={@name} />
    </button>
    """
  end

  attr :locales, :list, required: true
  attr :current, :string, default: nil
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @seg_item "inline-flex h-6 cursor-pointer items-center gap-1.5 rounded-[6px] border-0 px-[9px] text-[12.5px] font-medium no-underline transition-[color,background-color] duration-150"
  @seg_on "bg-panel text-ink shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)]"
  @seg_off "bg-transparent text-muted hover:text-ink"

  @doc """
  The language switcher: a small segmented group. `locales` is a list of codes (`["PT", "EN"]`,
  with `current`) or of maps `%{code:, navigate:, active:, click:, label:}`.
  """
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def navbar_lang(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "navbar.language")

    locales =
      Enum.map(assigns.locales, fn
        code when is_binary(code) -> %{code: code, active: code == assigns.current}
        %{code: code} = l -> Map.put_new(l, :active, code == assigns.current)
      end)

    assigns = assign(assigns, :locales, locales)
    assigns = settle(assigns, changed0, locales: [:current])

    ~H"""
    <span
      data-part="navbar-lang"
      role="group"
      aria-label={@label}
      class={cx(["inline-flex gap-0.5 rounded-md bg-sunken p-[3px]", @class])}
      {@rest}
    >
      <%= for l <- @locales do %>
        <a
          :if={target(l)}
          data-part="navbar-lang-link"
          {LedgerUI.LinkAttrs.resolve(target(l))}
          class={[seg_item(), if(l.active, do: seg_on(), else: seg_off())]}
          title={l[:label]}
          aria-current={l.active && "true"}
        >{l.code}</a>
        <button
          :if={!target(l)}
          data-part="navbar-lang-button"
          type="button"
          class={[seg_item(), if(l.active, do: seg_on(), else: seg_off())]}
          title={l[:label]}
          phx-click={l[:click]}
          aria-pressed={to_string(l.active)}
        >
          {l.code}
        </button>
      <% end %>
    </span>
    """
  end

  defp seg_item, do: @seg_item
  defp seg_on, do: @seg_on
  defp seg_off, do: @seg_off

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The thin vertical line between the icons and the user."
  def navbar_sep(assigns) do
    ~H"""
    <span
      data-part="navbar-sep"
      class={cx(["h-6 w-px flex-none bg-line", @class])}
      aria-hidden="true"
      {@rest}
    ></span>
    """
  end

  attr :label, :string, required: true

  attr :tone, :string,
    default: "ok",
    values: LedgerUI.Helpers.tone_values(~w(ok warn)),
    doc: "`ok` (green) or `warn` (amber); `success` and `warning` are aliases."

  attr :compact, :boolean,
    default: false,
    doc: "Only the status dot, the label as its title."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The environment pill (`Produção`, `Homologação`); `tone` is `ok` (green) or `warn` (amber)."
  def navbar_env(%{compact: true} = assigns) do
    ~H"""
    <span
      data-part="navbar-env"
      class={cx([stat_dot(tone_short(@tone)), @class])}
      title={@label}
      {@rest}
    ></span>
    """
  end

  def navbar_env(assigns) do
    ~H"""
    <.badge
      canvas
      color={if(tone_short(@tone) == "warn", do: "warning", else: "success")}
      data-part="navbar-env"
      class={@class}
      {@rest}
    >
      <span
        data-part="navbar-env-dot"
        class="inline-block size-[7px] flex-none rounded-full bg-current"
      ></span>{@label}
    </.badge>
    """
  end

  defp stat_dot("warn"), do: "size-2 rounded-full bg-warn shadow-[0_0_0_3px_var(--lu-warn-soft)]"
  defp stat_dot(_), do: "size-2 rounded-full bg-pos shadow-[0_0_0_3px_var(--lu-pos-soft)]"

  attr :text, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The save state: a green check and a muted text (`Salvo há 2 min`)."
  def navbar_sync(assigns) do
    ~H"""
    <span
      data-part="navbar-sync"
      class={cx(["inline-flex items-center gap-1.5 text-[12px] leading-4 text-muted", @class])}
      {@rest}
    >
      <.icon name="check" size="sm" class="text-pos" />{@text}
    </span>
    """
  end

  attr :users, :list, required: true
  attr :max, :integer, default: 3

  attr :total, :integer,
    default: nil,
    doc: "How many people there are (default: the length of `users`)."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The people on the page, as overlapping avatars; the rest is a `+N` bubble."
  def navbar_avatars(assigns) do
    changed0 = assigns.__changed__
    shown = Enum.take(assigns.users, assigns.max)
    total = assigns.total || length(assigns.users)
    assigns = assign(assigns, shown: shown, more: max(total - length(shown), 0))
    assigns = settle(assigns, changed0, shown: [:users, :max], more: [:users, :max, :total])

    ~H"""
    <.avatar_group
      data-part="navbar-avatars"
      size="28"
      more={@more > 0 && @more}
      class={cx([@more > 0 && "[&>[data-part=avatar]:last-child]:bg-sunken", @class])}
      ring_color="panel"
      {@rest}
    >
      <.avatar
        :for={u <- @shown}
        src={u[:avatar]}
        initials={initials(u)}
        color={tone_of(u)}
        alt={u[:name]}
        size="28"
        title={u[:name]}
      />
    </.avatar_group>
    """
  end

  attr :user, :map, required: true, doc: "`%{name, email, role, initials, avatar, color}`."
  attr :variant, :string, default: "avatar", values: ~w(avatar ring named)
  attr :size, :integer, default: nil, doc: "Avatar size in px (32; 26 for `named`)."
  attr :id, :string, default: nil, doc: "Required with a `:menu`."
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :menu,
    doc:
      "The content of the panel: `navbar_menu_*` pieces, links with `role=\"menuitem\"`, `<hr />`."

  @doc """
  The user of the bar: the avatar, with a status ring (`"ring"`) or with the name (`"named"`).
  Without the `:menu` slot it is a plain avatar (a button when it has `phx-click`). With it, the
  button opens a raised panel (`role="menu"`, hidden at first; `id` is required) toggled with
  `Phoenix.LiveView.JS`: a click outside closes it.
  """
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def navbar_user(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "navbar.account")

    if assigns.menu != [] and is_nil(assigns.id),
      do: raise(ArgumentError, "navbar_user with a :menu slot needs an id")

    assigns =
      assigns
      |> assign(:tone, tone_of(assigns.user))
      |> assign(:size, assigns.size || if(assigns.variant == "named", do: 26, else: 32))
      |> assign(:menu?, assigns.menu != [])
      |> assign(:wrap, wrap_class(assigns.variant))
      |> assign(:btn, btn_class(assigns.variant))

    assigns =
      settle(assigns, changed0,
        tone: [:user],
        size: [:variant],
        menu?: [],
        wrap: [:variant],
        btn: [:variant]
      )

    ~H"""
    <.nb_av
      :if={!@menu? and @variant == "avatar"}
      user={@user}
      size={@size}
      tone={@tone}
      class={@class}
      rest={@rest}
    />
    <span
      :if={!@menu? and @variant != "avatar"}
      data-part="navbar-user"
      class={cx([@wrap, @class])}
      {@rest}
    >
      <.nb_av user={@user} size={@size} tone={@tone} />
      <%= if @variant == "named" do %>
        {@user[:name]}
      <% end %>
    </span>
    <span
      :if={@menu?}
      id={@id}
      data-part="navbar-user"
      class="relative inline-flex"
      phx-click-away={JS.set_attribute({"hidden", ""}, to: "##{@id}-menu")}
      phx-window-keydown={JS.set_attribute({"hidden", ""}, to: "##{@id}-menu")}
      phx-key="Escape"
    >
      <button
        data-part="navbar-user-button"
        type="button"
        aria-label={@label}
        aria-haspopup="menu"
        aria-controls={"#{@id}-menu"}
        phx-click={JS.toggle_attribute({"hidden", "hidden"}, to: "##{@id}-menu")}
        class={cx([@btn, @class])}
        {@rest}
      >
        <.nb_av user={@user} size={@size} tone={@tone} />
        <%= if @variant == "named" do %>
          {@user[:name]}
        <% end %>
      </button>
      <div
        data-part="navbar-user-menu"
        id={"#{@id}-menu"}
        role="menu"
        class={
          cx([
            Dropdown.pop_classes(),
            "absolute right-0 top-[calc(100%+8px)] z-50 w-[260px] text-left"
          ])
        }
        hidden
      >
        {render_slot(@menu)}
      </div>
    </span>
    """
  end

  attr :user, :map, required: true
  attr :size, :integer, default: 32
  attr :tone, :string, default: "t1"
  attr :class, :any, default: nil
  attr :rest, :map, default: %{}

  defp nb_av(assigns) do
    ~H"""
    <.avatar
      src={@user[:avatar]}
      initials={initials(@user)}
      color={@tone}
      size={to_string(@size)}
      class={@class}
      {Map.drop(@rest, [:style])}
    />
    """
  end

  attr :user, :map, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :badge

  @doc "The head of the user menu: the avatar, the name and the email, and a `:badge` (the role) at the end."
  def navbar_menu_head(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :tone, tone_of(assigns.user))
    assigns = settle(assigns, changed0, tone: [:user])

    ~H"""
    <div
      data-part="navbar-menu-head"
      class={cx([person_classes(), "px-2.5 py-2", @class])}
      {@rest}
    >
      <.nb_av user={@user} size={36} tone={@tone} />
      <span data-part="navbar-menu-head-text" class={person_text_classes()}>
        <b data-part="navbar-menu-head-name" class={person_name_classes()}>{@user[:name]}</b>
        <span :if={@user[:email]} data-part="navbar-menu-head-email" class={person_sub_classes()}>{@user[
          :email
        ]}</span>
      </span>
      <span :if={@badge != []} data-part="navbar-menu-head-badge" class="ml-auto">{render_slot(@badge)}</span>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :action

  @doc "The status line of the menu: a green dot, the label and an `:action` at the end."
  def navbar_menu_status(assigns) do
    ~H"""
    <div
      data-part="navbar-menu-status"
      class={cx(["flex items-center gap-2 px-2.5 py-1.5 text-[13.5px]", @class])}
      {@rest}
    >
      <span data-part="navbar-menu-status-dot" class={stat_dot("ok")}></span>{@label}
      <span
        :if={@action != []}
        data-part="navbar-menu-status-action"
        class="ml-auto text-[12.5px] text-accent-content"
      >{render_slot(@action)}</span>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A row of the menu with a label and a control at the end (`theme_switch/1`, `navbar_lang/1`)."
  def navbar_menu_row(assigns) do
    ~H"""
    <div
      data-part="navbar-menu-row"
      class={cx(["flex items-center gap-2 px-2.5 py-1 text-[13.5px] text-ink-2", @class])}
      {@rest}
    >
      <span>{@label}</span>
      <span data-part="navbar-menu-row-end" class="ml-auto inline-flex">{render_slot(@inner_block)}</span>
    </div>
    """
  end

  attr :icon, :string, default: nil
  attr :kbd, :string, default: nil
  attr :danger, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download target rel)
  slot :inner_block, required: true

  @doc """
  An item of the menu: a link (`navigate`, `href`, `patch`, with `method="delete"` for a sign-out)
  or, with only `phx-click`, an action.
  """
  def navbar_menu_item(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(
        :link,
        target(assigns.rest) &&
          LedgerUI.LinkAttrs.resolve(assigns.rest, ["data-part", "role", "class"])
      )
      |> assign(:cls, Dropdown.item_classes(tone: assigns.danger && "danger"))

    assigns = settle(assigns, changed0, link: [:rest], cls: [:danger])

    ~H"""
    <a
      :if={@link}
      data-part="navbar-menu-item-link"
      role="menuitem"
      class={cx([@cls, @class])}
      {@link}
    >
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}<span
        :if={@kbd}
        data-part="navbar-menu-item-end"
        class={Dropdown.item_end_classes()}
      ><.kbd>{@kbd}</.kbd></span>
    </a>
    <button
      :if={!@link}
      data-part="navbar-menu-item-button"
      type="button"
      role="menuitem"
      class={cx([@cls, @class])}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}<span
        :if={@kbd}
        data-part="navbar-menu-item-end"
        class={Dropdown.item_end_classes()}
      ><.kbd>{@kbd}</.kbd></span>
    </button>
    """
  end

  ## Helpers

  defp target(%{navigate: to}) when is_binary(to), do: [navigate: to]
  defp target(%{patch: to}) when is_binary(to), do: [patch: to]
  defp target(%{href: to}) when is_binary(to), do: [href: to]
  defp target(_), do: nil

  defp icon_only_classes(size) do
    [
      "inline-grid flex-none cursor-pointer place-items-center rounded-md border border-transparent text-ink-2 hover:bg-hover",
      if(size == "sm", do: "size-8", else: "size-9")
    ]
  end

  defp clickable?(rest), do: Map.has_key?(rest, :"phx-click") or target(rest) != nil

  defp mark_active(items, current) do
    Enum.map(items, fn item ->
      active =
        Map.get(item, :active, false) ||
          (current != nil and current in [item[:navigate], item[:patch], item[:href]])

      Map.put(item, :active, active)
    end)
  end

  defp first_letter(nil), do: ""
  defp first_letter(name), do: name |> String.first() |> String.upcase()

  defp search_style(%{width: w, rest: rest}) do
    [w && "width:#{w}", rest[:style]]
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Enum.join(";")
    |> then(&if(&1 == "", do: nil, else: &1))
  end

  @named_box "inline-flex items-center gap-2 rounded-full shadow-[0_0_0_1px_var(--lu-line)]"

  defp wrap_class("ring"),
    do:
      "inline-flex rounded-full shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-accent-500)]"

  defp wrap_class("named"),
    do: [@named_box, "py-[3px] pl-[3px] pr-2.5 text-[13px] font-medium"]

  defp wrap_class(_), do: nil

  # a button reset; the box of the variant stays (the chip loses its padding and font to the reset)
  @btn_reset "cursor-pointer border-0 bg-transparent p-0 text-inherit [font:inherit]"
  defp btn_class("ring"), do: ["inline-flex", @btn_reset, wrap_class("ring")]
  defp btn_class("named"), do: [@btn_reset, @named_box]
  defp btn_class(_), do: @btn_reset

  defp initials(%{initials: i}) when is_binary(i), do: i

  defp initials(%{name: name}) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end

  defp initials(_), do: ""

  defp tone_of(%{tone: t}) when is_binary(t), do: t
  defp tone_of(%{name: name}) when is_binary(name), do: "t#{rem(:erlang.phash2(name), 5) + 1}"
  defp tone_of(_), do: "t1"

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
