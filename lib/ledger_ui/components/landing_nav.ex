defmodule LedgerUI.Components.LandingNav do
  @moduledoc """
  The marketing-site top bar: the logo on the left, the links in the center (one may open a mega
  menu), Entrar and the primary button on the right.

      <.landing_nav id="site-nav" brand={%{name: "Ledger", logo: "L", navigate: ~p"/"}}>
        <:link label="Produto">
          <.landing_mega>
            <.landing_feature icon="kanban" title="Projetos" description="Kanban, prazos" navigate={~p"/projetos"} />
          </.landing_mega>
        </:link>
        <:link label="Preços" navigate={~p"/precos"} active />
        <:actions>
          <.landing_login navigate={~p"/entrar"}>Entrar</.landing_login>
          <.landing_cta navigate={~p"/cadastro"}>Começar grátis</.landing_cta>
        </:actions>
      </.landing_nav>

  ## Variants

    * `default` - the classic bar, in the page flow.
    * `float` - a detached pill of frosted glass.
    * `clear` - transparent over a hero image; with `sticky` it turns solid once the page scrolls.
    * `tint` and `dark` - the accent wash and the near-black bar.
    * `mobile` - the phone layout at any width: logo and the menu button.
    * `hero` - transparent over a dark hero (the landing's `.lp-nav`): 80px tall, the logo on the left,
      the links as pills centered between the logo and the actions, and the bar itself in the dark theme
      (`data-theme="dark"`, so its text, hover and the solid state use the kit's dark tokens in either
      theme; see `theme` to follow the page instead). The links are always centered. They hide below 1024px. With `sticky` the bar overlays the hero (negative bottom
      margin) and turns solid after `stuck_after` px; put it outside the hero element, or it only sticks
      while the hero is in view.

  ## Theme and alignment

    * `theme` (`hero` only) - `"dark"` (default, as in 0.5.8: the bar is a dark scope over a dark hero),
      `"auto"` (no `data-theme`: the bar, its links and the solid state follow the page theme, for a hero
      that is light in the light theme) or `"light"`.
    * `align="center"` - the links sit centered between the logo and the actions (the other variants
      keep them next to the logo). The `hero` bar already centers them; `mobile` has no links.

  `sticky` pins the bar to the top (`position: sticky`) and mounts the `LedgerUI.LandingNav` hook,
  which sets `data-stuck` after `stuck_after` px of scroll. A `:link` with inner content is a
  trigger: a button with `aria-expanded` / `aria-controls` that opens the content as the mega menu
  (`landing_mega/1`), with hover (`open_on="hover"`) or click; Escape and a click outside close it,
  arrows walk the items. The hook is mounted when there is a trigger, `sticky` or `responsive`.

  `autohide` (with `sticky`) slides the bar away while the page scrolls down and brings it back when it
  scrolls up, when the focus enters it or at the top of the page; it is not hidden while a menu is open.
  With `prefers-reduced-motion: reduce` it still hides and shows, but without the slide.

  `spy` marks, with `aria-current="true"`, the link whose `#anchor` section is the last one above
  `spy_offset` px from the top of the view (none while the first section is still below it, the last one at
  the end of the page); the mobile panel links are marked too. It leaves the `active` links
  (`aria-current="page"`) that are not anchors alone.

      <.landing_nav id="nav" variant="hero" sticky autohide spy brand={%{name: "Nexus", icon: "sparkles"}}>
        <:link label="Recursos" href="#recursos" />
        <:link label="Preços" href="#precos" />
        <:actions :if={!@current_scope}><.landing_login href="/entrar">Entrar</.landing_login></:actions>
        <:signed_in :if={@current_scope}><.landing_cta href="/dashboard">Dashboard</.landing_cta></:signed_in>
      </.landing_nav>

  `:signed_in` is the action of a visitor with a session (the Dashboard button): when it has an entry it
  is drawn in place of `:actions`, in the bar and in the mobile panel.

  `responsive` hides the links and the primary button below 768px and shows the menu button
  (a panel listing every link and the `:actions` again, so do not put an `id` inside `:actions`).
  The `mobile` variant always has the menu button. Without a `:logo` slot the `brand` map is used
  (`%{name, navigate, logo | src | icon}`: `icon` draws the bare icon beside the name, as in the canvas).

  A `:link` with `caret` is a plain link with the "▾" after its label, for a mega menu that is drawn
  apart (`landing_mega/1` beside the bar, as in the canvas).

  Only utilities: the anchors of the bar are `text-inherit no-underline opacity-80` through a
  zero-specificity rule on the bar, so a utility on an anchor (the active link, a feature) wins.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Button, only: [button: 1]

  @variants ~w(default float clear tint dark mobile hero)

  # The bar: its anchors (links, the login, the CTA) are `text-inherit no-underline opacity-80`
  # through a zero-specificity descendant rule, so any utility on an anchor wins over it.
  # below 768px a `responsive` bar keeps only the logo and the menu button
  @bar "[:where(&)_a]:text-inherit [:where(&)_a]:no-underline [:where(&)_a]:opacity-80 " <>
         "flex h-[60px] items-center rounded-lg px-5 text-[14px] " <>
         "data-[stuck]:border-b data-[stuck]:border-line data-[stuck]:bg-panel data-[stuck]:shadow-md " <>
         "max-md:[&[data-responsive]:not([data-lu-variant=mobile])>:is(a:not([data-part=landing-brand]),button,[data-lnav-trigger])]:hidden! " <>
         "max-md:[&[data-responsive]>[data-lnav-panel]]:hidden!"
  # the hero bar: 80px tall, wide padding, square; its links hide below 1024px
  @bar_hero @bar
            |> String.replace("h-[60px]", "h-20")
            |> String.replace("rounded-lg px-5", "px-16 max-lg:px-7 max-sm:px-[18px]")
            |> Kernel.<>(
              " max-lg:[&>:is([data-part=landing-nav-link],[data-part=landing-nav-button])]:hidden!"
            )
  @autohide "transition-transform duration-200 motion-reduce:transition-none data-[hidden]:-translate-y-full data-[hidden]:shadow-none"
  # the link pills of the hero bar (the active one and the section in view are lit)
  @hero_link "rounded-full px-3.5 py-2 text-[14.5px] text-muted opacity-100 transition-colors hover:bg-hover hover:text-ink aria-[current]:bg-hover aria-[current]:text-ink"
  @spy_link "aria-[current=true]:font-semibold aria-[current=true]:opacity-100"
  @looks %{
    "default" => "gap-[22px] rounded-none border-b border-line",
    "float" => "gap-[22px] bg-panel shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-md)]",
    "clear" => "gap-[22px] bg-transparent",
    "tint" => "gap-[22px] bg-accent-soft",
    "dark" => "gap-[22px] bg-[#0e100f] text-[#f2f3f2]",
    "mobile" => "gap-2.5",
    "hero" => "gap-1.5 rounded-none bg-transparent text-ink"
  }

  attr :id, :string, required: true
  attr :variant, :string, default: "default", values: @variants

  attr :theme, :string,
    default: "dark",
    values: ~w(dark auto light),
    doc: "`hero` only: the theme scope of the bar; `auto` follows the page theme."

  attr :align, :string,
    default: "start",
    values: ~w(start center),
    doc: "`center` centers the links between the logo and the actions."

  attr :open_on, :string, default: "hover", values: ~w(hover click)
  attr :sticky, :boolean, default: false
  attr :stuck_after, :integer, default: 8

  attr :autohide, :boolean,
    default: false,
    doc: "With `sticky`: hides on the way down, shows on the way up."

  attr :spy, :boolean,
    default: false,
    doc: "Marks (`aria-current=\"true\"`) the link of the `#anchor` section in view."

  attr :spy_offset, :integer,
    default: 120,
    doc: "How far from the top of the view a section counts as the current one."

  attr :responsive, :boolean, default: false, doc: "Show the phone menu button below 768px."
  attr :brand, :map, default: nil

  attr :label, :any,
    default: :default,
    doc:
      "The accessible name of the links (`nil` leaves it out; the default is the locale's \"Main\")."

  attr :menu_label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions

  slot :signed_in,
    doc:
      "The action of a visitor with a session; drawn in place of `:actions` when it has an entry."

  slot :link do
    attr :label, :string
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean

    attr :caret, :boolean,
      doc: "Adds the ▾ after the label, for a link that has its mega menu apart."
  end

  slot :logo

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def landing_nav(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, menu_label: "landing_nav.menu")

    assigns = I18n.texts(assigns, [label: "landing_nav.main"], :default)

    links =
      assigns.link
      |> Enum.with_index()
      |> Enum.map(fn {l, i} ->
        Map.merge(%{i: i, trigger: !has_target?(l) and l.inner_block != nil}, %{slot: l})
      end)

    triggers? = Enum.any?(links, & &1.trigger)
    mobile? = assigns.variant == "mobile"
    menu? = mobile? or assigns.responsive
    hero? = assigns.variant == "hero"
    hook? = triggers? or assigns.sticky or menu? or assigns.spy

    assigns =
      assigns
      |> assign(:links, links)
      |> assign(:menu?, menu?)
      |> assign(:mobile?, mobile?)
      |> assign(:hero?, hero?)
      |> assign(:scope, hero? && if(assigns.theme == "auto", do: nil, else: assigns.theme))
      |> assign(:center?, assigns.align == "center" and not hero? and not mobile?)
      |> assign(:spy_cls, @spy_link)
      |> assign(
        :end_slot,
        if(assigns.signed_in != [], do: assigns.signed_in, else: assigns.actions)
      )
      |> assign(:link_cls, link_classes(assigns.spy, hero?))
      |> assign(:autohide?, assigns.sticky and assigns.autohide)
      |> assign(:hook, if(hook?, do: "LedgerUI.LandingNav"))
      |> assign(
        :classes,
        cx([
          if(hero?, do: @bar_hero, else: @bar),
          @looks[assigns.variant],
          if(assigns.sticky, do: "sticky top-0 z-40", else: "relative"),
          hero? and assigns.sticky and "-mb-20",
          assigns.sticky and assigns.autohide and @autohide,
          assigns.class
        ])
      )
      |> assign(
        :ham,
        cond do
          mobile? -> "inline-grid ml-auto"
          assigns.responsive -> "inline-grid max-md:ml-auto md:hidden!"
          true -> "hidden"
        end
      )
      |> assign(:panel_target, "#{assigns.id}-mobile")
      |> assign(
        :interactive,
        assigns.link != [] or assigns.actions != [] or assigns.signed_in != []
      )

    assigns =
      settle(assigns, changed0,
        links: [:link],
        menu?: [:variant, :responsive],
        mobile?: [:variant],
        hero?: [:variant],
        scope: [:hero?, :theme],
        center?: [:align, :hero?, :mobile?],
        spy_cls: [],
        end_slot: [:signed_in, :actions],
        link_cls: [:spy, :hero?],
        autohide?: [:sticky, :autohide],
        hook: [:links, :sticky, :menu?, :spy],
        classes: [:hero?, :variant, :sticky, :autohide, :class],
        ham: [:mobile?, :responsive],
        panel_target: [:id],
        interactive: [:link, :actions, :signed_in]
      )

    ~H"""
    <nav
      id={@id}
      data-part="landing-nav"
      data-lu-variant={@variant}
      data-theme={@scope}
      aria-label={@label}
      phx-hook={@hook}
      data-lu-open-on={@hook && @open_on}
      data-lu-stuck-after={@hook && @sticky && @stuck_after}
      data-lu-sticky={@sticky && ""}
      data-lu-autohide={@autohide? && ""}
      data-lu-spy={@spy && ""}
      data-lu-spy-offset={@spy && @spy_offset}
      data-responsive={@responsive && ""}
      class={@classes}
      {@rest}
    >
      <div :if={@hero?} data-part="landing-nav-start" class="flex flex-1 basis-0 items-center">
        <.ln_start logo={@logo} brand={@brand} />
      </div>
      <.ln_start :if={!@hero?} logo={@logo} brand={@brand} />
      <span :if={@center?} data-part="landing-nav-spacer" class="min-w-0 flex-1"></span>
      <%= for l <- @links do %>
        <a
          :if={has_target?(l.slot)}
          data-part="landing-nav-link"
          {LedgerUI.LinkAttrs.resolve(
            Keyword.put(
              target(l.slot),
              :class,
              cx([@link_cls, l.slot[:active] && "font-semibold opacity-100"]) |> blank_nil()
            )
          )}
          aria-current={l.slot[:active] && "page"}
        >
          {l.slot[:label]}{l.slot[:caret] && " ▾"}
        </a>
        <button
          :if={l.trigger}
          data-part="landing-nav-button"
          type="button"
          data-lnav-trigger={l.i}
          aria-expanded="false"
          aria-controls={"#{@id}-panel-#{l.i}"}
          aria-haspopup="true"
          class="cursor-pointer border-0 bg-transparent p-0 text-inherit opacity-80 [font:inherit]"
        >
          {l.slot[:label]} ▾
        </button>
        <a :if={!has_target?(l.slot) and !l.trigger} href="#">
          {l.slot[:label]}{l.slot[:caret] && " ▾"}
        </a>
      <% end %>
      <span :if={!@mobile? and !@hero?} data-part="landing-nav-spacer" class="min-w-0 flex-1"></span>
      <div
        :if={@hero?}
        data-part="landing-nav-actions"
        class="flex flex-1 basis-0 items-center justify-end gap-[18px] max-md:[[data-responsive]>&]:hidden"
      >
        {render_slot(@end_slot)}
      </div>
      <%= if !@hero? do %>
        {render_slot(@end_slot)}
      <% end %>
      <span
        :if={@menu?}
        data-part="landing-nav-ham"
        class={["cursor-pointer", @ham]}
        data-lu-lnav-ham
        role={@interactive && "button"}
        aria-label={@interactive && @menu_label}
        aria-expanded={@interactive && "false"}
        aria-controls={@interactive && @panel_target}
        tabindex={@interactive && "0"}
        phx-click={@interactive && JS.toggle(to: "##{@panel_target}", display: "flex")}
      >
        <.icon name="menu" size="md" />
      </span>
      <%= for l <- @links, l.trigger do %>
        <div
          data-part="landing-nav-panel"
          id={"#{@id}-panel-#{l.i}"}
          data-lnav-panel={l.i}
          class="hidden"
          keep-style
        >
          {render_slot(l.slot)}
        </div>
      <% end %>
      <div
        :if={@menu? and @interactive}
        id={@panel_target}
        data-part="landing-nav-mobile"
        class="absolute left-0 right-0 top-full z-40 hidden flex-col gap-1.5 rounded-lg border border-line bg-panel px-4 py-3 text-ink shadow-md md:hidden!"
        keep-style
      >
        <%= for l <- @links do %>
          <a
            :if={has_target?(l.slot)}
            data-part="landing-nav-panel-link"
            {LedgerUI.LinkAttrs.resolve(target(l.slot))}
            class={cx(["py-2 text-inherit no-underline", @spy && @spy_cls])}
          >{l.slot[:label]}</a>
          <a
            :if={!has_target?(l.slot)}
            data-part="landing-nav-panel-link"
            href="#"
            class="py-2 text-inherit no-underline"
          >{l.slot[
            :label
          ]}</a>
        <% end %>
        <div data-part="landing-nav-panel-actions" class="mt-1.5 flex flex-col gap-2">
          {render_slot(@end_slot)}
        </div>
      </div>
    </nav>
    """
  end

  defp ln_start(assigns) do
    ~H"""
    <%= if @logo != [] do %>
      {render_slot(@logo)}
    <% else %>
      <.ln_brand :if={@brand} brand={@brand} />
    <% end %>
    """
  end

  defp link_classes(spy?, hero?), do: cx([hero? && @hero_link, spy? && @spy_link])

  defp blank_nil(""), do: nil
  defp blank_nil(class), do: class

  defp ln_brand(assigns) do
    changed0 = assigns.__changed__
    b = assigns.brand

    assigns =
      assign(assigns,
        to: target(b) && LedgerUI.LinkAttrs.resolve(target(b)),
        letter: b[:logo] || first_letter(b[:name])
      )

    assigns = settle(assigns, changed0, to: [:brand], letter: [:brand])

    ~H"""
    <a
      :if={@to}
      {@to}
      data-part="landing-brand"
      class="flex items-center gap-2 font-bold opacity-100"
    >
      <.ln_logo brand={@brand} letter={@letter} />{@brand[:name]}
    </a>
    <span :if={!@to} data-part="landing-brand" class="flex items-center gap-2 font-bold">
      <.ln_logo brand={@brand} letter={@letter} />{@brand[:name]}
    </span>
    """
  end

  defp ln_logo(%{brand: %{icon: icon}} = assigns) when is_binary(icon) do
    ~H"""
    <.icon name={@brand.icon} size="md" />
    """
  end

  defp ln_logo(assigns) do
    ~H"""
    <span
      :if={@brand[:src] || @brand[:logo]}
      data-part="landing-logo-mark"
      class="inline-grid size-7 place-items-center overflow-hidden rounded-[8px] bg-inverse text-[13px] font-bold text-on-inverse"
    >
      <img
        :if={@brand[:src]}
        data-part="landing-logo-img"
        src={@brand[:src]}
        alt=""
        class="size-full object-cover"
      />
      <%= if !@brand[:src] do %>
        {@letter}
      <% end %>
    </span>
    """
  end

  defp has_target?(l), do: target(l) != nil

  # The link attrs the component has (`target/1` reads them).
  # The attributes of the `<a>` of a link component (see `LedgerUI.LinkAttrs`): the link attrs of
  # the call (`#` without one), plus `extra`; `own` are the ones the template writes itself.
  defp link_attrs(assigns, extra, own) do
    LedgerUI.LinkAttrs.resolve(
      Map.merge(Map.new(extra), Map.new(target(assigns) || [href: "#"])),
      own
    )
  end

  defp link_src(assigns), do: Enum.filter([:href, :navigate, :patch], &Map.has_key?(assigns, &1))

  defp target(%{navigate: to}) when is_binary(to), do: [navigate: to]
  defp target(%{patch: to}) when is_binary(to), do: [patch: to]
  defp target(%{href: to}) when is_binary(to), do: [href: to]
  defp target(_), do: nil

  defp first_letter(nil), do: ""
  defp first_letter(name), do: name |> String.first() |> String.upcase()

  ## Actions

  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The \"Entrar\" link of the bar."
  def landing_login(assigns) do
    changed0 = assigns.__changed__
    # `class` goes in the spread: a `class={nil}` on a tag would render `class=""`
    assigns =
      assign(
        assigns,
        :to,
        link_attrs(assigns, Map.put(assigns.rest, :class, assigns.class), ["data-part"])
      )

    assigns = settle(assigns, changed0, to: [:rest, :class | link_src(assigns)])

    ~H"""
    <a data-part="landing-login-link" {@to}>{render_slot(@inner_block)}</a>
    """
  end

  attr :size, :string, default: "md", values: ~w(md lg)
  attr :block, :boolean, default: false
  attr :icon, :string, default: nil
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value phx-click)
  slot :inner_block, required: true

  @doc "The primary button of the bar. A link when it has `href`, `navigate` or `patch`, else a `button`."
  def landing_cta(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:kind, cta_kind(assigns))
      |> assign(:btn_size, if(assigns.size == "lg", do: "lg", else: "sm"))

    assigns = settle(assigns, changed0, kind: link_src(assigns), btn_size: [:size])

    cta(assigns)
  end

  defp cta_kind(%{navigate: to}) when is_binary(to), do: :navigate
  defp cta_kind(%{patch: to}) when is_binary(to), do: :patch
  defp cta_kind(%{href: to}) when is_binary(to), do: :href
  defp cta_kind(_), do: :button

  # A call of `<.button>` with a spread (`{@rest}`) is never "unchanged": it sends the whole button
  # when only the label changes. With no extra attributes (the usual case) it is called with the
  # attributes written out, one clause per kind of target (`<.button href={nil}>` would be a link).
  defp cta(%{rest: rest, kind: kind} = assigns) when map_size(rest) == 0 do
    case kind do
      :navigate -> cta_navigate(assigns)
      :patch -> cta_patch(assigns)
      :href -> cta_href(assigns)
      :button -> cta_button(assigns)
    end
  end

  defp cta(assigns) do
    assigns = assign(assigns, :to, target(assigns) || [])

    ~H"""
    <.button
      color="mono"
      variant="solid"
      size={@btn_size}
      shape="rounded"
      trailing_icon={@icon}
      class={[@block && "w-full", @class]}
      {@to}
      {@rest}
    >{render_slot(@inner_block)}</.button>
    """
  end

  defp cta_navigate(assigns) do
    ~H"""
    <.button
      color="mono"
      variant="solid"
      size={@btn_size}
      shape="rounded"
      trailing_icon={@icon}
      class={[@block && "w-full", @class]}
      navigate={@navigate}
    >{render_slot(@inner_block)}</.button>
    """
  end

  defp cta_patch(assigns) do
    ~H"""
    <.button
      color="mono"
      variant="solid"
      size={@btn_size}
      shape="rounded"
      trailing_icon={@icon}
      class={[@block && "w-full", @class]}
      patch={@patch}
    >{render_slot(@inner_block)}</.button>
    """
  end

  defp cta_href(assigns) do
    ~H"""
    <.button
      color="mono"
      variant="solid"
      size={@btn_size}
      shape="rounded"
      trailing_icon={@icon}
      class={[@block && "w-full", @class]}
      href={@href}
    >{render_slot(@inner_block)}</.button>
    """
  end

  defp cta_button(assigns) do
    ~H"""
    <.button
      color="mono"
      variant="solid"
      size={@btn_size}
      shape="rounded"
      trailing_icon={@icon}
      class={[@block && "w-full", @class]}
    >{render_slot(@inner_block)}</.button>
    """
  end

  ## Mega menu

  attr :variant, :string, default: "default", values: ~w(default cards)
  attr :columns, :integer, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :side

  @mega "absolute top-16 grid gap-1.5 rounded-lg bg-panel p-2 text-ink shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-lg)]"

  @doc "The mega menu content (inside a `:link` of `landing_nav/1`): the features and, optionally, a side panel."
  def landing_mega(%{variant: "cards"} = assigns) do
    changed0 = assigns.__changed__
    cols = assigns.columns || min(length(assigns.inner_block), 3) |> max(1)

    assigns = assign(assigns, :style, "grid-template-columns:repeat(#{cols},1fr)")
    assigns = settle(assigns, changed0, style: [:columns, :inner_block])

    ~H"""
    <div
      data-part="landing-mega"
      class={cx([mega(), "left-0 w-[min(960px,92vw)]", @class])}
      style={@style}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  def landing_mega(assigns) do
    ~H"""
    <div
      data-part="landing-mega"
      class={cx([mega(), "left-[120px] w-[420px] grid-cols-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
      <div :if={@side != []} data-part="landing-mega-side-slot" class="col-span-full">
        {render_slot(@side)}
      </div>
    </div>
    """
  end

  defp mega, do: @mega

  attr :title, :string, required: true
  attr :name, :string, default: nil
  attr :logo, :string, default: nil
  attr :link_label, :string, default: nil
  attr :tone, :string, default: "default", values: ~w(default tint dark)
  attr :accent, :string, default: nil
  attr :mock, :boolean, default: false

  attr :compact, :boolean,
    default: false,
    doc: "A static mini card (`div`): only the title, as in the canvas menu."

  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :mark
  slot :preview

  # a card link inside the mega menu: the menu's `a` rule (padding 10, gap 10, radius 10) wins over the card's own
  @cv "flex flex-col text-[13px] [:where(&)_span]:text-muted [:where(&)_b]:text-[14px] "

  @doc "A product card of `landing_mega variant=\"cards\"`: logo and name, a large title, a link and a preview."
  def landing_product(%{compact: true} = assigns) do
    ~H"""
    <div
      data-part="landing-product"
      class={
        cx([
          cv(),
          "min-h-0 gap-1.5 rounded-xl bg-panel p-2.5",
          @tone == "default" && cv_default(),
          @class
        ])
      }
      {@rest}
    >
      <b>{@title}</b>
    </div>
    """
  end

  def landing_product(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:style, accent_style(assigns.accent))
      |> assign(:tone_cls, product_tone(assigns.tone))

    # the component's `style` wins over the one of the rest, as on `<.link style={..} {@rest}>`
    assigns =
      assign(
        assigns,
        :to,
        link_attrs(assigns, Map.put(assigns.rest, :style, assigns.style), ["data-part", "class"])
      )

    assigns =
      settle(assigns, changed0,
        style: [:accent],
        to: [:rest, :style | link_src(assigns)],
        tone_cls: [:tone]
      )

    ~H"""
    <a
      data-part="landing-product"
      class={cx([cv(), "min-h-[92px] gap-2.5 rounded-md p-2.5", @tone_cls, @class])}
      {@to}
    >
      <span data-part="landing-product-head" class="flex flex-nowrap items-center gap-2 text-inherit">
        <span
          :if={@logo || @mark != []}
          data-part="landing-product-logo"
          class="inline-grid size-8 flex-none place-items-center rounded-md bg-accent-soft text-accent-content"
        >
          <%= if @mark != [] do %>
            {render_slot(@mark)}
          <% else %>
            <.icon name={@logo} size="md" />
          <% end %>
        </span>
        <b :if={@name}>{@name}</b>
      </span>
      <b data-part="landing-product-title" class="text-[20px] leading-[26px] tracking-[-.01em]">{@title}</b>
      <span
        :if={@link_label}
        data-part="landing-product-link"
        class="inline-flex items-center gap-1 font-medium text-accent-content"
        style={@accent && "color:#{@accent}"}
      >
        {@link_label}<.icon name="arrow-right" size="sm" />
      </span>
      <div :if={@preview != []} data-part="landing-product-preview" class="mt-2">
        {render_slot(@preview)}
      </div>
      <div
        :if={@preview == [] and @mock}
        data-part="landing-product-mock"
        aria-hidden="true"
        class="mt-2 h-24 rounded-t-md bg-sunken shadow-[inset_0_0_0_1px_var(--lu-line)]"
      >
      </div>
    </a>
    """
  end

  defp cv, do: @cv
  defp cv_default, do: "shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-sm)]"

  defp product_tone("dark"), do: "bg-[#0e100f] text-[#f2f3f2]"
  defp product_tone("tint"), do: "bg-accent-soft shadow-[0_0_0_1px_var(--lu-line)]"
  defp product_tone(_), do: ["bg-panel", cv_default()]

  defp accent_style(nil), do: nil
  defp accent_style(c), do: "--color-accent-content:#{c};--lu-accent:#{c}"

  attr :icon, :string, default: nil
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "One feature of the mega menu: an icon in a box, the title and a line of description."
  def landing_feature(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :to, link_attrs(assigns, assigns.rest, ["data-part", "class"]))
    assigns = settle(assigns, changed0, to: [:rest | link_src(assigns)])

    ~H"""
    <a
      data-part="landing-feature"
      class={cx(["flex gap-2.5 rounded-md p-2.5 text-[13px] opacity-100 hover:bg-hover", @class])}
      {@to}
    >
      <span
        data-part="landing-feature-icon"
        class="inline-grid size-8 flex-none place-items-center rounded-md bg-accent-soft text-accent-content"
      >
        <.icon :if={@icon} name={@icon} size="md" />
      </span>
      <span data-part="landing-feature-text" class="flex flex-col gap-0">
        <b>{@title}</b>
        <span
          :if={@description}
          data-part="landing-feature-description"
          class="text-[12px] leading-4 text-muted"
        >{@description}</span>
      </span>
    </a>
    """
  end

  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :thumb, :boolean, default: false
  attr :link_label, :string, default: nil
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  @doc "The highlighted panel beside the features: an eyebrow, the title, the text, a thumbnail and a link."
  def landing_mega_side(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :to, link_attrs(assigns, %{}, []))
    assigns = settle(assigns, changed0, to: link_src(assigns))

    ~H"""
    <div
      data-part="landing-mega-side"
      class={cx(["flex flex-col gap-1.5 rounded-[12px] bg-accent-soft p-3.5 text-ink", @class])}
      {@rest}
    >
      <span
        :if={@eyebrow}
        data-part="landing-mega-side-eyebrow"
        class="font-mono text-[12px] leading-4 uppercase tracking-[.06em] text-accent-content"
      >{@eyebrow}</span>
      <b>{@title}</b>
      <span
        :if={@inner_block != []}
        data-part="landing-mega-side-text"
        class="text-[13px] leading-[18px] text-ink-2"
      >{render_slot(@inner_block)}</span>
      <span
        :if={@thumb}
        data-part="landing-mega-side-thumb"
        aria-hidden="true"
        class="h-14 rounded-[8px] bg-panel shadow-[inset_0_0_0_1px_var(--lu-line)]"
      ></span>
      <a
        :if={@link_label}
        data-part="landing-mega-side-link"
        {@to}
        class="p-0 font-medium text-accent-content"
      >{@link_label} →</a>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :eyebrow, :string, default: nil
  attr :link_label, :string, default: nil
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :dismissible, :boolean, default: true
  attr :close_label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The thin announcement strip above the bar; the close button hides it with `JS.hide`."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def landing_announcement(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, close_label: "common.close")

    assigns = assign(assigns, :to, link_attrs(assigns, %{}, []))
    assigns = settle(assigns, changed0, to: link_src(assigns))

    ~H"""
    <div
      id={@id}
      data-part="landing-announcement"
      class={
        cx([
          "relative flex items-center justify-center gap-2.5 bg-inverse px-4 py-2 text-[13.5px] text-on-inverse",
          @class
        ])
      }
      {@rest}
    >
      <span
        :if={@eyebrow}
        data-part="landing-announcement-eyebrow"
        class="inline-flex h-[22px] items-center gap-[5px] rounded-sm bg-[rgba(255,255,255,.14)] px-2 text-[12px] leading-none font-medium tabular-nums whitespace-nowrap text-inherit"
      >{@eyebrow}</span>
      <span>{render_slot(@inner_block)}</span>
      <a
        :if={@link_label}
        data-part="landing-announcement-link"
        {@to}
        class="font-semibold text-inherit"
      >{@link_label} →</a>
      <button
        :if={@dismissible}
        data-part="landing-announcement-button"
        type="button"
        aria-label={@close_label}
        phx-click={JS.hide(to: "##{@id}")}
        class="absolute top-1/2 right-3 grid -translate-y-1/2 cursor-pointer border-0 bg-transparent px-1.5 py-px text-inherit"
      >
        <.icon name="x" size="sm" />
      </button>
    </div>
    """
  end
end
