defmodule LedgerUI.Components.LandingNav do
  @moduledoc """
  The marketing-site top bar: the logo on the left, the links in the center (one may open a mega
  menu), Entrar and the primary button on the right.

      <.landing_nav id="site-nav" brand={%{name: "Linea", logo: "L", navigate: ~p"/"}}>
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

  `sticky` pins the bar to the top (`position: sticky`) and mounts the `LedgerUI.LandingNav` hook,
  which sets `data-stuck` after `stuck_after` px of scroll. A `:link` with inner content is a
  trigger: a button with `aria-expanded` / `aria-controls` that opens the content as the mega menu
  (`landing_mega/1`), with hover (`open_on="hover"`) or click; Escape and a click outside close it,
  arrows walk the items. The hook is mounted when there is a trigger, `sticky` or `responsive`.

  `responsive` hides the links and the primary button below 768px and shows the menu button
  (a panel listing every link and the `:actions` again, so do not put an `id` inside `:actions`).
  The `mobile` variant always has the menu button. Without a `:logo` slot the `brand` map is used.
  """
  use LedgerUI.Component

  @variants ~w(default float clear tint dark mobile)

  attr :id, :string, required: true
  attr :variant, :string, default: "default", values: @variants
  attr :open_on, :string, default: "hover", values: ~w(hover click)
  attr :sticky, :boolean, default: false
  attr :stuck_after, :integer, default: 8
  attr :responsive, :boolean, default: false, doc: "Show the phone menu button below 768px."
  attr :brand, :map, default: nil

  attr :label, :any,
    default: "Main",
    doc: "The accessible name of the links (`nil` leaves it out)."

  attr :menu_label, :string, default: "Menu"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions

  slot :link do
    attr :label, :string
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
  end

  slot :logo

  def landing_nav(assigns) do
    links =
      assigns.link
      |> Enum.with_index()
      |> Enum.map(fn {l, i} ->
        Map.merge(%{i: i, trigger: !has_target?(l) and l.inner_block != nil}, %{slot: l})
      end)

    triggers? = Enum.any?(links, & &1.trigger)
    mobile? = assigns.variant == "mobile"
    menu? = mobile? or assigns.responsive
    hook? = triggers? or assigns.sticky or menu?

    assigns =
      assigns
      |> assign(:links, links)
      |> assign(:menu?, menu?)
      |> assign(:mobile?, mobile?)
      |> assign(:hook, if(hook?, do: "LedgerUI.LandingNav"))
      |> assign(:style, nav_style(assigns))
      |> assign(:panel_target, "#{assigns.id}-mobile")
      |> assign(:interactive, assigns.link != [] or assigns.actions != [])

    ~H"""
    <nav
      id={@id}
      data-part="landing-nav"
      aria-label={@label}
      phx-hook={@hook}
      data-lu-open-on={@hook && @open_on}
      data-lu-stuck-after={@hook && @sticky && @stuck_after}
      data-lu-sticky={@sticky && ""}
      data-responsive={@responsive && ""}
      class={cx(["lu-lnav", @variant, @class])}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      <%= if @logo != [] do %>
        {render_slot(@logo)}
      <% else %>
        <.ln_brand :if={@brand} brand={@brand} />
      <% end %>
      <%= for l <- @links do %>
        <.link
          :if={has_target?(l.slot)}
          {target(l.slot)}
          aria-current={l.slot[:active] && "page"}
          {style_attr(l.slot[:active] && "opacity:1;font-weight:600")}
        >
          {l.slot[:label]}
        </.link>
        <button
          :if={l.trigger}
          type="button"
          data-lnav-trigger={l.i}
          aria-expanded="false"
          aria-controls={"#{@id}-panel-#{l.i}"}
          aria-haspopup="true"
          style="background:none;border:0;padding:0;color:inherit;font:inherit;opacity:.8;cursor:pointer"
        >
          {l.slot[:label]} ▾
        </button>
        <a :if={!has_target?(l.slot) and !l.trigger} href="#">{l.slot[:label]}</a>
      <% end %>
      <span class="lu-grow"></span>
      {render_slot(@actions)}
      <span
        :if={@menu?}
        class="ham"
        data-lnav-ham
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
          id={"#{@id}-panel-#{l.i}"}
          data-lnav-panel={l.i}
          style="display:none"
          keep-style
        >
          {render_slot(l.slot)}
        </div>
      <% end %>
      <div
        :if={@menu? and @interactive}
        id={@panel_target}
        class="lu-lnav-mobile"
        style="display:none;position:absolute;left:0;right:0;top:100%;z-index:40;flex-direction:column;gap:6px;padding:12px 16px;background:var(--bg-panel);border:1px solid var(--line);border-radius:14px;box-shadow:var(--shadow-md);color:var(--ink)"
        keep-style
      >
        <%= for l <- @links do %>
          <.link
            :if={has_target?(l.slot)}
            {target(l.slot)}
            style="padding:8px 0;color:inherit;text-decoration:none"
          >{l.slot[:label]}</.link>
          <a
            :if={!has_target?(l.slot)}
            href="#"
            style="padding:8px 0;color:inherit;text-decoration:none"
          >{l.slot[:label]}</a>
        <% end %>
        <div class="lu-col" style="gap:8px;margin-top:6px">{render_slot(@actions)}</div>
      </div>
    </nav>
    """
  end

  defp ln_brand(assigns) do
    b = assigns.brand
    assigns = assign(assigns, to: target(b), letter: b[:logo] || first_letter(b[:name]))

    ~H"""
    <.link :if={@to} {@to} class="lg">
      <.ln_logo brand={@brand} letter={@letter} />{@brand[:name]}
    </.link>
    <span :if={!@to} class="lg">
      <.ln_logo brand={@brand} letter={@letter} />{@brand[:name]}
    </span>
    """
  end

  defp ln_logo(assigns) do
    ~H"""
    <span
      :if={@brand[:src] || @brand[:logo]}
      style="display:inline-grid;place-items:center;width:28px;height:28px;border-radius:8px;background:var(--inverse);color:var(--on-inverse);font-size:13px;font-weight:700;overflow:hidden"
    >
      <img
        :if={@brand[:src]}
        src={@brand[:src]}
        alt=""
        style="width:100%;height:100%;object-fit:cover"
      />
      <%= if !@brand[:src] do %>
        {@letter}
      <% end %>
    </span>
    """
  end

  defp nav_style(%{sticky: true, rest: rest}),
    do: join_style("position:sticky;top:0;z-index:40", rest[:style])

  defp nav_style(%{rest: rest}), do: rest[:style]

  defp join_style(a, b) when a in [nil, false, ""], do: if(b in [nil, ""], do: nil, else: b)
  defp join_style(a, nil), do: a
  defp join_style(a, ""), do: a
  defp join_style(a, b), do: a <> ";" <> b

  defp has_target?(l), do: target(l) != nil

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
    assigns = assign(assigns, :to, target(assigns) || [href: "#"])

    ~H"""
    <.link {@to} class={@class} {@rest}>{render_slot(@inner_block)}</.link>
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
    assigns =
      assigns
      |> assign(:to, target(assigns))
      |> assign(
        :cls,
        cx([
          "lu-b c-mono v-solid",
          if(assigns.size == "lg", do: "s-lg", else: "s-sm"),
          "sh-rounded",
          assigns.class
        ])
      )
      |> assign(:style, join_style(assigns.block && "width:100%", assigns.rest[:style]))
      |> assign(:rest, Map.delete(assigns.rest, :style))

    ~H"""
    <.link :if={@to} {@to} class={@cls} {style_attr(@style)} {@rest}>
      {render_slot(@inner_block)}<.icon :if={@icon} name={@icon} />
    </.link>
    <button :if={!@to} type="button" class={@cls} {style_attr(@style)} {@rest}>
      {render_slot(@inner_block)}<.icon :if={@icon} name={@icon} />
    </button>
    """
  end

  ## Mega menu

  attr :variant, :string, default: "default", values: ~w(default cards)
  attr :columns, :integer, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :side

  @doc "The mega menu content (inside a `:link` of `landing_nav/1`): the features and, optionally, a side panel."
  def landing_mega(%{variant: "cards"} = assigns) do
    cols = assigns.columns || min(length(assigns.inner_block), 3) |> max(1)

    assigns =
      assign(
        assigns,
        :style,
        "grid-template-columns:repeat(#{cols},1fr);width:min(960px,92vw);left:0"
      )

    ~H"""
    <div data-part="landing-mega" class={cx(["lu-mega", @class])} {style_attr(@style)} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def landing_mega(assigns) do
    ~H"""
    <div data-part="landing-mega" class={cx(["lu-mega", @class])} {@rest}>
      {render_slot(@inner_block)}
      <div :if={@side != []} style="grid-column:1 / -1">{render_slot(@side)}</div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :name, :string, default: nil
  attr :logo, :string, default: nil
  attr :link_label, :string, default: nil
  attr :tone, :string, default: "default", values: ~w(default tint dark)
  attr :accent, :string, default: nil
  attr :mock, :boolean, default: false
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :mark
  slot :preview

  @doc "A product card of `landing_mega variant=\"cards\"`: logo and name, a large title, a link and a preview."
  def landing_product(assigns) do
    assigns =
      assigns
      |> assign(:to, target(assigns) || [href: "#"])
      |> assign(:style, product_style(assigns.tone, assigns.accent))

    ~H"""
    <.link
      {@to}
      data-part="landing-product"
      class={cx(["lu-cv", @tone == "default" && "default", @class])}
      {style_attr(@style)}
      {@rest}
    >
      <span class="lu-row" style="gap:8px;flex-wrap:nowrap;color:inherit">
        <span :if={@logo || @mark != []} class="lu-ic acc">
          <%= if @mark != [] do %>
            {render_slot(@mark)}
          <% else %>
            <.icon name={@logo} size="md" />
          <% end %>
        </span>
        <b :if={@name}>{@name}</b>
      </span>
      <b style="font-size:20px;line-height:26px;letter-spacing:-.01em">{@title}</b>
      <span
        :if={@link_label}
        style={"color:#{@accent || "var(--accent-ink)"};font-weight:500;display:inline-flex;align-items:center;gap:4px"}
      >
        {@link_label}<.icon name="arrow-right" size="sm" />
      </span>
      <div :if={@preview != []} style="margin-top:8px">{render_slot(@preview)}</div>
      <div
        :if={@preview == [] and @mock}
        aria-hidden="true"
        style="margin-top:8px;height:96px;border-radius:10px 10px 0 0;background:var(--bg-sunken);box-shadow:inset 0 0 0 1px var(--line)"
      >
      </div>
    </.link>
    """
  end

  defp product_style("dark", accent),
    do: "background:#0e100f;color:#f2f3f2;box-shadow:none;#{accent_var(accent)}"

  defp product_style("tint", accent),
    do: "background:var(--accent-soft);box-shadow:0 0 0 1px var(--line);#{accent_var(accent)}"

  defp product_style(_, accent), do: accent_var(accent)
  defp accent_var(nil), do: nil
  defp accent_var(c), do: "--accent:#{c};--accent-ink:#{c}"

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
    assigns = assign(assigns, :to, target(assigns) || [href: "#"])

    ~H"""
    <.link {@to} data-part="landing-feature" class={@class} {@rest}>
      <span class="lu-ic acc"><.icon :if={@icon} name={@icon} size="md" /></span>
      <span class="lu-col" style="gap:0">
        <b>{@title}</b>
        <span :if={@description} class="lu-xs lu-muted">{@description}</span>
      </span>
    </.link>
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
    assigns = assign(assigns, :to, target(assigns) || [href: "#"])

    ~H"""
    <div
      data-part="landing-mega-side"
      class={@class}
      style="display:flex;flex-direction:column;gap:6px;padding:14px;border-radius:12px;background:var(--accent-soft);color:var(--ink)"
      {@rest}
    >
      <span
        :if={@eyebrow}
        class="lu-xs mono"
        style="text-transform:uppercase;letter-spacing:.06em;color:var(--accent-ink)"
      >{@eyebrow}</span>
      <b>{@title}</b>
      <span :if={@inner_block != []} class="lu-small lu-ink2">{render_slot(@inner_block)}</span>
      <span
        :if={@thumb}
        aria-hidden="true"
        style="height:56px;border-radius:8px;background:var(--bg-panel);box-shadow:inset 0 0 0 1px var(--line)"
      ></span>
      <.link :if={@link_label} {@to} style="padding:0;color:var(--accent-ink);font-weight:500">{@link_label} →</.link>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :eyebrow, :string, default: nil
  attr :link_label, :string, default: nil
  attr :href, :string, default: "#"
  attr :navigate, :string, default: nil
  attr :dismissible, :boolean, default: true
  attr :close_label, :string, default: "Close"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The thin announcement strip above the bar; the close button hides it with `JS.hide`."
  def landing_announcement(assigns) do
    assigns = assign(assigns, :to, target(assigns) || [href: "#"])

    ~H"""
    <div
      id={@id}
      data-part="landing-announcement"
      class={cx(["lu-ann", @class])}
      style="display:flex;align-items:center;justify-content:center;gap:10px;padding:8px 16px;background:var(--inverse);color:var(--on-inverse);font-size:13.5px;position:relative"
      {@rest}
    >
      <span :if={@eyebrow} class="lu-badge" style="background:rgba(255,255,255,.14);color:inherit">{@eyebrow}</span>
      <span>{render_slot(@inner_block)}</span>
      <.link :if={@link_label} {@to} style="color:inherit;font-weight:600">{@link_label} →</.link>
      <button
        :if={@dismissible}
        type="button"
        aria-label={@close_label}
        phx-click={JS.hide(to: "##{@id}")}
        style="position:absolute;right:12px;top:50%;transform:translateY(-50%);background:none;border:0;color:inherit;cursor:pointer;display:grid"
      >
        <.icon name="x" size="sm" />
      </button>
    </div>
    """
  end

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
