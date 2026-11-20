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

  `sticky` pins the bar to the top (`position: sticky`) and mounts the `LedgerUI.LandingNav` hook,
  which sets `data-stuck` after `stuck_after` px of scroll. A `:link` with inner content is a
  trigger: a button with `aria-expanded` / `aria-controls` that opens the content as the mega menu
  (`landing_mega/1`), with hover (`open_on="hover"`) or click; Escape and a click outside close it,
  arrows walk the items. The hook is mounted when there is a trigger, `sticky` or `responsive`.

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

  @variants ~w(default float clear tint dark mobile)

  # The bar: its anchors (links, the login, the CTA) are `text-inherit no-underline opacity-80`
  # through a zero-specificity descendant rule, so any utility on an anchor wins over it.
  # below 768px a `responsive` bar keeps only the logo and the menu button
  @bar "[:where(&)_a]:text-inherit [:where(&)_a]:no-underline [:where(&)_a]:opacity-80 " <>
         "flex h-[60px] items-center rounded-[14px] px-5 text-[14px] " <>
         "data-[stuck]:border-b data-[stuck]:border-line data-[stuck]:bg-panel data-[stuck]:shadow-md " <>
         "max-md:[&[data-responsive]:not([data-variant=mobile])>:is(a:not([data-part=landing-brand]),button,[data-lnav-trigger])]:hidden! " <>
         "max-md:[&[data-responsive]>[data-lnav-panel]]:hidden!"
  @looks %{
    "default" => "gap-[22px] rounded-none border-b border-line",
    "float" => "gap-[22px] bg-panel shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-md)]",
    "clear" => "gap-[22px] bg-transparent",
    "tint" => "gap-[22px] bg-accent-soft",
    "dark" => "gap-[22px] bg-[#0e100f] text-[#f2f3f2]",
    "mobile" => "gap-2.5"
  }

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

    attr :caret, :boolean,
      doc: "Adds the ▾ after the label, for a link that has its mega menu apart."
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
      |> assign(
        :classes,
        cx([
          @bar,
          @looks[assigns.variant],
          if(assigns.sticky, do: "sticky top-0 z-40", else: "relative"),
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
      |> assign(:interactive, assigns.link != [] or assigns.actions != [])

    ~H"""
    <nav
      id={@id}
      data-part="landing-nav"
      data-variant={@variant}
      aria-label={@label}
      phx-hook={@hook}
      data-lu-open-on={@hook && @open_on}
      data-lu-stuck-after={@hook && @sticky && @stuck_after}
      data-lu-sticky={@sticky && ""}
      data-responsive={@responsive && ""}
      class={@classes}
      {@rest}
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
          class={l.slot[:active] && "font-semibold opacity-100"}
        >
          {l.slot[:label]}{l.slot[:caret] && " ▾"}
        </.link>
        <button
          :if={l.trigger}
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
      <span :if={!@mobile?} class="min-w-0 flex-1"></span>
      {render_slot(@actions)}
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
        class="absolute left-0 right-0 top-full z-40 hidden flex-col gap-1.5 rounded-[14px] border border-line bg-panel px-4 py-3 text-ink shadow-md md:hidden!"
        keep-style
      >
        <%= for l <- @links do %>
          <.link
            :if={has_target?(l.slot)}
            {target(l.slot)}
            class="py-2 text-inherit no-underline"
          >{l.slot[:label]}</.link>
          <a :if={!has_target?(l.slot)} href="#" class="py-2 text-inherit no-underline">{l.slot[
            :label
          ]}</a>
        <% end %>
        <div class="mt-1.5 flex flex-col gap-2">{render_slot(@actions)}</div>
      </div>
    </nav>
    """
  end

  defp ln_brand(assigns) do
    b = assigns.brand
    assigns = assign(assigns, to: target(b), letter: b[:logo] || first_letter(b[:name]))

    ~H"""
    <.link
      :if={@to}
      {@to}
      data-part="landing-brand"
      class="flex items-center gap-2 font-bold opacity-100"
    >
      <.ln_logo brand={@brand} letter={@letter} />{@brand[:name]}
    </.link>
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
      class="inline-grid size-7 place-items-center overflow-hidden rounded-[8px] bg-inverse text-[13px] font-bold text-on-inverse"
    >
      <img :if={@brand[:src]} src={@brand[:src]} alt="" class="size-full object-cover" />
      <%= if !@brand[:src] do %>
        {@letter}
      <% end %>
    </span>
    """
  end

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
      |> assign(:to, target(assigns) || [])
      |> assign(:btn_size, if(assigns.size == "lg", do: "lg", else: "sm"))

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

  ## Mega menu

  attr :variant, :string, default: "default", values: ~w(default cards)
  attr :columns, :integer, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :side

  @mega "absolute top-16 grid gap-1.5 rounded-[14px] bg-panel p-2 text-ink shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-lg)]"

  @doc "The mega menu content (inside a `:link` of `landing_nav/1`): the features and, optionally, a side panel."
  def landing_mega(%{variant: "cards"} = assigns) do
    cols = assigns.columns || min(length(assigns.inner_block), 3) |> max(1)

    assigns = assign(assigns, :style, "grid-template-columns:repeat(#{cols},1fr)")

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
      <div :if={@side != []} class="col-span-full">{render_slot(@side)}</div>
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

  @cv "flex flex-col gap-1.5 rounded-[16px] text-[13px] [:where(&)_span]:text-muted [:where(&)_b]:text-[14px] "

  @doc "A product card of `landing_mega variant=\"cards\"`: logo and name, a large title, a link and a preview."
  def landing_product(%{compact: true} = assigns) do
    ~H"""
    <div
      data-part="landing-product"
      class={cx([cv(), "min-h-0 bg-panel p-2.5", @tone == "default" && cv_default(), @class])}
      {@rest}
    >
      <b>{@title}</b>
    </div>
    """
  end

  def landing_product(assigns) do
    assigns =
      assigns
      |> assign(:to, target(assigns) || [href: "#"])
      |> assign(:style, accent_style(assigns.accent))
      |> assign(:tone_cls, product_tone(assigns.tone))

    ~H"""
    <.link
      {@to}
      data-part="landing-product"
      class={cx([cv(), "min-h-[92px] p-3.5", @tone_cls, @class])}
      style={@style}
      {@rest}
    >
      <span class="flex flex-nowrap items-center gap-2 text-inherit">
        <span
          :if={@logo || @mark != []}
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
      <b class="text-[20px] leading-[26px] tracking-[-.01em]">{@title}</b>
      <span
        :if={@link_label}
        class="inline-flex items-center gap-1 font-medium text-accent-content"
        style={@accent && "color:#{@accent}"}
      >
        {@link_label}<.icon name="arrow-right" size="sm" />
      </span>
      <div :if={@preview != []} class="mt-2">{render_slot(@preview)}</div>
      <div
        :if={@preview == [] and @mock}
        aria-hidden="true"
        class="mt-2 h-24 rounded-t-[10px] bg-sunken shadow-[inset_0_0_0_1px_var(--lu-line)]"
      >
      </div>
    </.link>
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
    assigns = assign(assigns, :to, target(assigns) || [href: "#"])

    ~H"""
    <.link
      {@to}
      data-part="landing-feature"
      class={cx(["flex gap-2.5 rounded-[10px] p-2.5 text-[13px] opacity-100 hover:bg-hover", @class])}
      {@rest}
    >
      <span class="inline-grid size-8 flex-none place-items-center rounded-md bg-accent-soft text-accent-content">
        <.icon :if={@icon} name={@icon} size="md" />
      </span>
      <span class="flex flex-col gap-0">
        <b>{@title}</b>
        <span :if={@description} class="text-[12px] leading-4 text-muted">{@description}</span>
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
      class={cx(["flex flex-col gap-1.5 rounded-[12px] bg-accent-soft p-3.5 text-ink", @class])}
      {@rest}
    >
      <span
        :if={@eyebrow}
        class="font-mono text-[12px] leading-4 uppercase tracking-[.06em] text-accent-content"
      >{@eyebrow}</span>
      <b>{@title}</b>
      <span :if={@inner_block != []} class="text-[13px] leading-[18px] text-ink-2">{render_slot(
        @inner_block
      )}</span>
      <span
        :if={@thumb}
        aria-hidden="true"
        class="h-14 rounded-[8px] bg-panel shadow-[inset_0_0_0_1px_var(--lu-line)]"
      ></span>
      <.link :if={@link_label} {@to} class="p-0 font-medium text-accent-content">{@link_label} →</.link>
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
        class="inline-flex h-[22px] items-center gap-[5px] rounded-sm bg-[rgba(255,255,255,.14)] px-2 text-[12px] leading-none font-medium tabular-nums whitespace-nowrap text-inherit"
      >{@eyebrow}</span>
      <span>{render_slot(@inner_block)}</span>
      <.link :if={@link_label} {@to} class="font-semibold text-inherit">{@link_label} →</.link>
      <button
        :if={@dismissible}
        type="button"
        aria-label={@close_label}
        phx-click={JS.hide(to: "##{@id}")}
        class="absolute top-1/2 right-3 grid -translate-y-1/2 cursor-pointer border-0 bg-transparent text-inherit"
      >
        <.icon name="x" size="sm" />
      </button>
    </div>
    """
  end
end
