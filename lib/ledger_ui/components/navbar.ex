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

  The slots are rendered straight inside `<header class="lu-topbar">` (flex row), so the items are
  its direct children and the crumbs take the free space.
  """
  use LedgerUI.Component

  @styles %{
    "base" => "lu-topbar",
    "variant" => %{
      "default" => nil,
      "float" => "float",
      "clear" => "clear",
      "dense" => "dense",
      "mobile" => "mobile"
    },
    "size" => %{"md" => nil, "sm" => "sm"}
  }

  ## Container

  attr :variant, :string, default: "default", values: ~w(default float clear dense mobile)
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "The left side."
  slot :center, doc: "Between the left and the right: `navbar_links/1`, a wide `navbar_search/1`."
  slot :end, doc: "The right side."
  slot :tabs, doc: "`navbar_tabs/1`: makes the bar two rows."

  def navbar(assigns) do
    assigns = assign(assigns, :end_slot, assigns[:end] || [])

    assigns =
      assign(
        assigns,
        :classes,
        cx([
          @styles["base"],
          @styles["variant"][assigns.variant],
          @styles["size"][assigns.size],
          assigns.class
        ])
      )

    ~H"""
    <header :if={@tabs == []} id={@id} data-part="navbar" class={@classes} {@rest}>
      {render_slot(@inner_block)}
      {render_slot(@center)}
      {render_slot(@end_slot)}
    </header>
    <header
      :if={@tabs != []}
      id={@id}
      data-part="navbar"
      class={@classes}
      style="height:auto;flex-direction:column;align-items:stretch;gap:0;padding-bottom:0"
      {@rest}
    >
      <div style="display:flex;align-items:center;gap:10px;height:56px">
        {render_slot(@inner_block)}
        {render_slot(@center)}
        {render_slot(@end_slot)}
      </div>
      <div style="display:flex">{render_slot(@tabs)}</div>
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
    assigns = assign(assigns, :letter, assigns.logo || first_letter(assigns.name))

    ~H"""
    <span
      data-part="navbar-brand"
      class={cx(["lu-nb-brand", @class])}
      style="display:inline-flex;align-items:center;gap:10px;font-weight:600;font-size:15px"
      {@rest}
    >
      <span {style_attr(tile(28, 8))}>
        <img
          :if={@src}
          src={@src}
          alt=""
          style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
        />
        <span :if={!@src}>{@letter}</span>
      </span>
      <span :if={@name}>{@name}</span>
    </span>
    """
  end

  attr :items, :list, required: true

  attr :label, :any,
    default: "Breadcrumb",
    doc: "The `aria-label` of the `nav` (`nil` leaves it out)."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The path to the page. Each item is `%{label: "...", navigate: path}` (or `href` / `patch`); the
  last one, the page itself, is the current one, and an item with no link is plain text.
  """
  def navbar_crumbs(assigns) do
    last = length(assigns.items) - 1
    assigns = assign(assigns, :items, Enum.with_index(assigns.items))
    assigns = assign(assigns, :last, last)

    ~H"""
    <nav data-part="navbar-crumbs" class={cx(["lu-crumb canvas", @class])} aria-label={@label} {@rest}>
      <%= for {item, i} <- @items do %>
        <span :if={i > 0} class="s">/</span>
        <span :if={i == @last} class="cur" aria-current={@label && "page"}>{item.label}</span>
        <.link :if={i != @last && target(item)} {target(item)}>{item.label}</.link>
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
    assigns = assign(assigns, :letter, assigns.logo || first_letter(assigns.name))

    ~H"""
    <span data-part="navbar-workspace" class="lu-nb-start" style="flex:1;display:flex;min-width:0">
      <button type="button" class={cx(["lu-ws", @class])} style="margin:0;text-align:left" {@rest}>
        <span class="logo">
          <img
            :if={@src}
            src={@src}
            alt=""
            style="width:100%;height:100%;object-fit:cover;border-radius:inherit"
          />
          <span :if={!@src}>{@letter}</span>
        </span>
        <span class="t">
          <b>{@name}</b>
          <span :if={@sub}>{@sub}</span>
        </span>
        <.icon name="updown" size="md" class="lu-muted" />
      </button>
    </span>
    """
  end

  attr :label, :string, required: true
  attr :square, :string, default: nil, doc: "The text in the square (2 or 3 letters)."
  attr :color, :string, default: nil, doc: "The CSS color of the square."
  attr :tag, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "A selector in a path of selectors (organization, project). `phx-click` opens the list."
  def navbar_chip(assigns) do
    assigns = assign(assigns, :sq_style, square_style(assigns.color))

    ~H"""
    <button
      type="button"
      data-part="navbar-chip"
      class={cx(["lu-nb-chip", @class])}
      style="display:inline-flex;align-items:center;gap:8px;height:32px;padding:0 8px;border:0;border-radius:8px;background:none;color:var(--ink);font-size:14px;font-weight:500;cursor:pointer"
      {@rest}
    >
      <span :if={@square} {style_attr(@sq_style)}>{@square}</span>
      {@label}
      <span :if={@tag} class="lu-badge sm">{@tag}</span>
      <.icon name="updown" size="sm" class="lu-muted" />
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
      class={cx(["lu-nb-slash", @class])}
      style="color:var(--line-strong)"
      aria-hidden="true"
      {@rest}
    >/</span>
    """
  end

  ## Middle

  attr :items, :list, required: true
  attr :current, :string, default: nil
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The main links, centered. Items are `%{label:, navigate:, active:}` (`href` / `patch` work too).
  The active one is the item with `active: true` or the one whose link equals `current`.
  """
  def navbar_links(assigns) do
    assigns = assign(assigns, :items, mark_active(assigns.items, assigns.current))

    ~H"""
    <nav
      data-part="navbar-links"
      aria-label={@label}
      class={cx(["lu-nb-links", @class])}
      style="display:flex;align-items:center;justify-content:center;gap:4px;flex:1"
      {@rest}
    >
      <.link
        :for={item <- @items}
        {target(item) || [href: "#"]}
        class={cx(["lu-nav-item", item.active && "on"])}
        style="width:auto;height:32px"
        aria-current={item.active && "page"}
      >
        {item.label}
      </.link>
    </nav>
    """
  end

  attr :items, :list, required: true
  attr :current, :string, default: nil
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The tabs of the page, for the `:tabs` slot of `navbar/1`. Items are those of `navbar_links/1` plus an optional `count`."
  def navbar_tabs(assigns) do
    assigns = assign(assigns, :items, mark_active(assigns.items, assigns.current))

    ~H"""
    <nav
      data-part="navbar-tabs"
      aria-label={@label}
      class={cx(["lu-tb line", @class])}
      style="width:100%;padding:0 4px"
      {@rest}
    >
      <.link
        :for={item <- @items}
        {target(item) || [href: "#"]}
        aria-current={item.active && "page"}
        {style_attr(tab_style(item.active))}
      >
        {item.label}
        <span :if={item[:count]} class="mono" style="font-size:11.5px;color:var(--muted)">{item.count}</span>
      </.link>
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
      class={cx(["lu-nb-title", @class])}
      style="flex:1;text-align:center;font-weight:600;font-size:15px"
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  ## Right side

  attr :placeholder, :string, default: "Search"
  attr :kbd, :string, default: "⌘K", doc: "The shortcut shown at the end; `nil` hides it."
  attr :wide, :boolean, default: false
  attr :width, :string, default: nil, doc: ~s|A CSS width ("240px", "100%").|
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-click)

  @doc """
  The search field of the bar. It is a trigger, not an input: with `phx-click` it becomes a button
  (role and tabindex) that opens the command palette.
  """
  def navbar_search(assigns) do
    rest = assigns.rest
    clickable = Map.has_key?(rest, :"phx-click")

    assigns =
      assigns
      |> assign(:style, search_style(assigns))
      |> assign(:role, clickable && "button")
      |> assign(:tabindex, clickable && "0")

    ~H"""
    <span
      data-part="navbar-search"
      class={cx(["lu-input search", @wide && "lu-nb-wide", @class])}
      role={@role}
      tabindex={@tabindex}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      <.icon name="search" size="md" />
      <span class="val"><span class="ph">{@placeholder}</span></span>
      <kbd :if={@kbd} class="lu-kbd">{@kbd}</kbd>
    </span>
    """
  end

  attr :dot, :boolean, default: false, doc: "There is something unread."

  attr :count, :integer,
    default: nil,
    doc: "A count badge (the `lu-bell` form) instead of the dot."

  attr :label, :string, default: "Notifications"
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)

  @doc "The notifications button; `dot` shows the dot of something unread."
  def navbar_bell(%{count: count} = assigns) when is_integer(count) do
    assigns = assign(assigns, :clickable, clickable?(assigns.rest))

    ~H"""
    <span
      data-part="navbar-bell"
      class={cx(["lu-bell", @class])}
      role={@clickable && "button"}
      tabindex={@clickable && "0"}
      aria-label={@clickable && @label}
      {@rest}
    >
      <.icon name="bell" /><b>{@count}</b>
    </span>
    """
  end

  def navbar_bell(assigns) do
    assigns = assign(assigns, :icon_size, assigns.size)

    ~H"""
    <.nb_btn
      name="bell"
      label={@label}
      size={@size}
      class={cx([@dot && "dot", @class])}
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

  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :size, :string, default: "md"
  attr :class, :any, default: nil
  attr :rest, :map, default: %{}

  defp nb_btn(assigns) do
    assigns =
      assigns
      |> assign(:link, target(assigns.rest))
      |> assign(:style, if(assigns.size == "sm", do: "width:32px;height:32px;border-radius:10px"))

    ~H"""
    <.link
      :if={@link}
      {@link}
      data-part="navbar-icon"
      aria-label={@label}
      class={cx(["lu-tbtn", @class])}
      {style_attr(@style)}
    >
      <.icon name={@name} />
    </.link>
    <button
      :if={!@link}
      type="button"
      data-part="navbar-icon"
      aria-label={@label}
      class={cx(["lu-tbtn", @class])}
      {style_attr(@style)}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      <.icon name={@name} />
    </button>
    """
  end

  attr :locales, :list, required: true
  attr :current, :string, default: nil
  attr :label, :string, default: "Language"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The language switcher: a small segmented group. `locales` is a list of codes (`["PT", "EN"]`,
  with `current`) or of maps `%{code:, navigate:, active:, click:, label:}`.
  """
  def navbar_lang(assigns) do
    locales =
      Enum.map(assigns.locales, fn
        code when is_binary(code) -> %{code: code, active: code == assigns.current}
        %{code: code} = l -> Map.put_new(l, :active, code == assigns.current)
      end)

    assigns = assign(assigns, :locales, locales)

    ~H"""
    <span
      data-part="navbar-lang"
      role="group"
      aria-label={@label}
      class={cx(["lu-seg sm", @class])}
      {@rest}
    >
      <%= for l <- @locales do %>
        <.link
          :if={target(l)}
          {target(l)}
          class={l.active && "on"}
          title={l[:label]}
          aria-current={l.active && "true"}
        >{l.code}</.link>
        <button
          :if={!target(l)}
          type="button"
          class={l.active && "on"}
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

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The thin vertical line between the icons and the user."
  def navbar_sep(assigns) do
    ~H"""
    <span
      data-part="navbar-sep"
      class={cx(["lu-nb-sep", @class])}
      style="width:1px;height:24px;background:var(--line);flex:none"
      aria-hidden="true"
      {@rest}
    ></span>
    """
  end

  attr :label, :string, required: true
  attr :tone, :string, default: "ok", values: ~w(ok warn)

  attr :compact, :boolean,
    default: false,
    doc: "Only the status dot (`lu-stat-dot`), the label as its title."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The environment pill (`Produção`, `Homologação`); `tone` is `ok` (green) or `warn` (amber)."
  def navbar_env(%{compact: true} = assigns) do
    ~H"""
    <span
      data-part="navbar-env"
      class={cx(["lu-stat-dot", @tone == "warn" && "warn", @class])}
      title={@label}
      {@rest}
    ></span>
    """
  end

  def navbar_env(assigns) do
    ~H"""
    <span
      data-part="navbar-env"
      class={cx(["lu-badge", if(@tone == "warn", do: "warn", else: "pos"), @class])}
      {@rest}
    >
      <span class="lu-dot"></span>{@label}
    </span>
    """
  end

  attr :text, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The save state: a green check and a muted text (`Salvo há 2 min`)."
  def navbar_sync(assigns) do
    ~H"""
    <span
      data-part="navbar-sync"
      class={cx(["lu-xs lu-muted", @class])}
      style="display:inline-flex;align-items:center;gap:6px"
      {@rest}
    >
      <.icon name="check" size="sm" style="color:var(--pos)" />{@text}
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
    shown = Enum.take(assigns.users, assigns.max)
    total = assigns.total || length(assigns.users)
    assigns = assign(assigns, shown: shown, more: max(total - length(shown), 0))

    ~H"""
    <span data-part="navbar-avatars" class={cx(["lu-av-grp", @class])} {@rest}>
      <span
        :for={u <- @shown}
        class={cx(["lu-av", tone_of(u)])}
        style="--s:28px"
        title={u[:name]}
      >
        <img :if={u[:avatar]} src={u.avatar} alt={u[:name] || ""} {style_attr(img_style())} />
        <%= if !u[:avatar] do %>
          {initials(u)}
        <% end %>
      </span>
      <span :if={@more > 0} class="lu-av" style="--s:28px">+{@more}</span>
    </span>
    """
  end

  attr :user, :map, required: true, doc: "`%{name, email, role, initials, avatar, color}`."
  attr :variant, :string, default: "avatar", values: ~w(avatar ring named)
  attr :size, :integer, default: nil, doc: "Avatar size in px (32; 26 for `named`)."
  attr :id, :string, default: nil, doc: "Required with a `:menu`."
  attr :label, :string, default: "Account menu"
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
  def navbar_user(assigns) do
    if assigns.menu != [] and is_nil(assigns.id),
      do: raise(ArgumentError, "navbar_user with a :menu slot needs an id")

    assigns =
      assigns
      |> assign(:tone, tone_of(assigns.user))
      |> assign(:size, assigns.size || if(assigns.variant == "named", do: 26, else: 32))
      |> assign(:menu?, assigns.menu != [])
      |> assign(:wrap, wrap_class(assigns.variant))
      |> assign(:button?, assigns.menu != [] or clickable?(assigns.rest))

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
      {style_attr(wrap_style(@variant))}
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
      style="position:relative;display:inline-flex"
      phx-click-away={JS.hide(to: "##{@id}-menu")}
      phx-window-keydown={JS.hide(to: "##{@id}-menu")}
      phx-key="Escape"
    >
      <button
        type="button"
        aria-label={@label}
        aria-haspopup="menu"
        aria-controls={"#{@id}-menu"}
        phx-click={JS.toggle(to: "##{@id}-menu")}
        class={cx([@wrap, @class])}
        {style_attr(btn_style(@variant))}
        {@rest}
      >
        <.nb_av user={@user} size={@size} tone={@tone} />
        <%= if @variant == "named" do %>
          {@user[:name]}
        <% end %>
      </button>
      <div
        id={"#{@id}-menu"}
        role="menu"
        class="lu-pop"
        style="position:absolute;right:0;top:calc(100% + 8px);z-index:50;width:260px;text-align:left"
        hidden
        keep-hidden
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
    <span class={cx(["lu-av", @tone, @class])} style={"--s:#{@size}px"} {Map.drop(@rest, [:style])}>
      <img :if={@user[:avatar]} src={@user.avatar} alt="" {style_attr(img_style())} />
      <%= if !@user[:avatar] do %>
        {initials(@user)}
      <% end %>
    </span>
    """
  end

  attr :user, :map, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :badge

  @doc "The head of the user menu: the avatar, the name and the email, and a `:badge` (the role) at the end."
  def navbar_menu_head(assigns) do
    assigns = assign(assigns, :tone, tone_of(assigns.user))

    ~H"""
    <div
      data-part="navbar-menu-head"
      class={cx(["lu-person", @class])}
      style="padding:8px 10px"
      {@rest}
    >
      <.nb_av user={@user} size={36} tone={@tone} />
      <span class="t">
        <b>{@user[:name]}</b>
        <span :if={@user[:email]}>{@user[:email]}</span>
      </span>
      <span :if={@badge != []} style="margin-left:auto">{render_slot(@badge)}</span>
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
      class={cx(["lu-nb-status", @class])}
      style="display:flex;align-items:center;gap:8px;padding:6px 10px;font-size:13.5px"
      {@rest}
    >
      <span class="lu-stat-dot"></span>{@label}
      <span :if={@action != []} style="margin-left:auto;color:var(--accent-ink);font-size:12.5px">{render_slot(
        @action
      )}</span>
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
      class={cx(["lu-nb-row", @class])}
      style="display:flex;align-items:center;gap:8px;padding:4px 10px;font-size:13.5px;color:var(--ink-2)"
      {@rest}
    >
      <span>{@label}</span>
      <span style="margin-left:auto;display:inline-flex">{render_slot(@inner_block)}</span>
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
    assigns = assign(assigns, :link, target(assigns.rest))

    ~H"""
    <.link
      :if={@link}
      {@link}
      role="menuitem"
      class={cx(["lu-menu-item", @danger && "danger", @class])}
      {Map.drop(@rest, [:href, :navigate, :patch])}
    >
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}<span :if={@kbd} class="r"><kbd class="lu-kbd">{@kbd}</kbd></span>
    </.link>
    <button
      :if={!@link}
      type="button"
      role="menuitem"
      class={cx(["lu-menu-item", @danger && "danger", @class])}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} />{render_slot(@inner_block)}<span :if={@kbd} class="r"><kbd class="lu-kbd">{@kbd}</kbd></span>
    </button>
    """
  end

  ## Helpers

  defp target(%{navigate: to}) when is_binary(to), do: [navigate: to]
  defp target(%{patch: to}) when is_binary(to), do: [patch: to]
  defp target(%{href: to}) when is_binary(to), do: [href: to]
  defp target(_), do: nil

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

  defp tile(size, radius),
    do:
      "display:inline-grid;place-items:center;width:#{size}px;height:#{size}px;border-radius:#{radius}px;background:var(--inverse);color:var(--on-inverse);font-size:13px;font-weight:700;overflow:hidden"

  defp square_style(color) do
    bg = color || "var(--ink)"

    "display:inline-grid;place-items:center;min-width:20px;height:20px;padding:0 4px;border-radius:6px;background:#{bg};color:#fff;font-size:10.5px;font-weight:700"
  end

  defp search_style(%{width: w, wide: wide, rest: rest}) do
    base =
      cond do
        w -> "width:#{w}"
        wide -> "width:100%;max-width:520px"
        true -> nil
      end

    [base, rest[:style]]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(";")
    |> then(&if(&1 == "", do: nil, else: &1))
  end

  defp tab_style(active) do
    base =
      "position:relative;height:40px;padding:0 10px;display:inline-flex;align-items:center;gap:7px;font-size:14px;font-weight:500;text-decoration:none;"

    base <>
      if(active,
        do: "color:var(--ink);box-shadow:inset 0 -2px 0 var(--ink)",
        else: "color:var(--muted)"
      )
  end

  defp wrap_class("ring"), do: "lu-uring"
  defp wrap_class("named"), do: "lu-uchip"
  defp wrap_class(_), do: nil

  @btn_reset "border:0;background:none;padding:0;cursor:pointer;color:inherit;font:inherit"
  defp btn_style("ring"), do: "display:inline-flex;" <> @btn_reset
  defp btn_style(_), do: @btn_reset

  defp wrap_style("ring"), do: "display:inline-flex"
  defp wrap_style(_), do: nil

  defp img_style, do: "width:100%;height:100%;border-radius:50%;object-fit:cover"

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
