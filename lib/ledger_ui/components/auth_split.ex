defmodule LedgerUI.Components.AuthSplit do
  @moduledoc """
  The sign in and sign up screen in two halves, as the canvas draws it: on the left a centered column (the
  brand mark, the title and subtitle, the `:providers` buttons and the divider, the form and a line under
  it) and, on the right, either a picture filling its half with a testimonial over its lower part or the
  `:aside` panel (tray background, content centered: a badge, a headline, a KPI card).

      <.auth_split title="Criar conta" subtitle="Preencha seus dados." src={~p"/images/auth.jpg"}>
        <:brand><img src={~p"/images/logo.svg"} width="28" /> Acme</:brand>
        <:providers>
          <.oauth_button provider="google" href={~p"/auth/google"}>Google</.oauth_button>
        </:providers>
        <.form for={@form} phx-submit="save">...</.form>
        <:quote author="Marina Costa" role="Gerente" rating={5}>Em uma semana a equipe inteira estava usando.</:quote>
        <:footer>Já tem conta? <.link navigate={~p"/users/log-in"}>Entrar</.link></:footer>
      </.auth_split>

  The picture is `src` or the `:art` slot; without either and without `:aside`, the form takes the
  whole card. `variant`: `card` (default, the framed app) or `full` (the whole screen). The
  `:brand` slot is the content of the 40px brand tile (`brand_href` makes it a link); `oauth_button`
  takes `block` for the full-width provider button of the canvas.
  For the canvas-v2 screen (brand tile, tinted art with floating cards) see `auth_page/1` and
  `auth_art/1`. Under 1024px the right half goes away. The other states of the screen: `auth_sent/1` (link sent),
  `auth_alert/1` (errors) and `auth_submit/1` (sending).
  """
  use LedgerUI.Component

  import LedgerUI.Components.Button, only: [button: 1]
  import LedgerUI.Components.Shell, only: [spinner_classes: 0]

  alias LedgerUI.Components.Button
  alias LedgerUI.Components.Illustration
  import LedgerUI.Components.Avatar, only: [avatar: 1]

  @provider_icons %{"google" => "google", "apple" => "apple", "github" => "github"}

  # the card frame of the canvas app; the teal glow follows the accent (a darker step in the dark mode)
  @card "min-h-[600px] rounded-2xl border border-line shadow-[0_30px_80px_-30px_color-mix(in_oklab,var(--lu-accent-700)_25%,transparent)] dark:shadow-[0_30px_80px_-30px_color-mix(in_oklab,var(--lu-accent-300)_25%,transparent)]"

  attr :title, :string, default: nil, doc: "Plain title; the `:heading` slot replaces it."
  attr :subtitle, :string, default: nil
  attr :src, :string, default: nil
  attr :alt, :string, default: ""
  attr :variant, :string, default: "card", values: ~w(card full)
  attr :glow, :boolean, default: false, doc: "Deprecated: the canvas has no glow; ignored."
  attr :divider_label, :string, default: nil
  attr :brand_href, :string, default: nil, doc: "Makes the brand mark a link."

  attr :form_width, :integer,
    default: nil,
    doc:
      "The width of the form column in px (default 360). Sets `--lu-auth-form-w` on the form column."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :art
  slot :aside
  slot :brand
  slot :footer
  slot :heading, doc: "The title with markup (highlight, `<br>`); replaces `title`."
  slot :top, doc: "A strip over the form half (brand on the left, a link on the right)."
  slot :page_footer, doc: "The bottom of the form half (terms, privacy, help), small muted text."
  slot :inner_block, required: true
  slot :providers

  slot :quote do
    attr :author, :string
    attr :role, :string
    attr :rating, :integer
  end

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def auth_split(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, divider_label: "auth_split.or")

    right? = assigns.src != nil or assigns.art != [] or assigns.aside != []
    full? = assigns.variant == "full"

    assigns =
      assigns
      |> assign(:right?, right?)
      |> assign(:full?, full?)
      |> assign(
        :brand_link,
        assigns.brand_href && LedgerUI.LinkAttrs.resolve(href: assigns.brand_href)
      )
      |> assign(:style_attrs, style_attrs(assigns.form_width, assigns.rest[:style]))
      |> assign(
        :logo_cls,
        "grid size-10 place-items-center rounded-md bg-inverse text-on-inverse"
      )
      |> assign(
        :classes,
        cx([
          # `overflow-clip`: a drawer sliding in over the screen is clipped, never scrolled
          "flex overflow-clip bg-shell",
          if(full?, do: "min-h-screen", else: @card),
          assigns.class
        ])
      )

    # A new heading or body must not send the classes again.
    assigns =
      settle(assigns, changed0,
        brand_link: [:brand_href],
        right?: [:src, :art, :aside],
        full?: [:variant],
        style_attrs: [:form_width, :rest],
        logo_cls: [],
        classes: [:variant, :class]
      )

    ~H"""
    <div data-part="auth-split" class={@classes} {@style_attrs} {Map.delete(@rest, :style)}>
      <div data-part="auth-split-form-side" class="flex flex-1 flex-col bg-page">
        <div
          :if={@top != []}
          data-part="auth-split-top"
          class="flex items-center justify-between gap-4 px-10 pt-7"
        >
          {render_slot(@top)}
        </div>
        <div class="flex flex-1 items-center justify-center p-8">
          <div
            data-part="auth-split-form"
            class="flex w-(--lu-auth-form-w,360px) flex-col gap-4"
          >
            <a
              :if={@brand != [] and @brand_href}
              {@brand_link}
              data-part="auth-brand"
              class={@logo_cls}
            >
              {render_slot(@brand)}
            </a>
            <span :if={@brand != [] and !@brand_href} data-part="auth-brand" class={@logo_cls}>
              {render_slot(@brand)}
            </span>
            <div :if={@title || @heading != [] || @subtitle}>
              <div
                :if={@title || @heading != []}
                data-part="auth-split-title"
                role="heading"
                aria-level="1"
                class={[
                  "text-[26px] font-semibold tracking-[-.02em]",
                  @heading != [] && "leading-[1.15]"
                ]}
              >
                <%= if @heading != [] do %>
                  {render_slot(@heading)}
                <% else %>
                  {@title}
                <% end %>
              </div>
              <div :if={@subtitle} data-part="auth-split-subtitle" class="text-muted">
                {@subtitle}
              </div>
            </div>
            {render_slot(@providers)}
            <div
              :if={@providers != []}
              data-part="auth-split-divider"
              class="flex flex-wrap items-center gap-3"
            >
              <hr
                data-part="auth-split-divider-line"
                class="m-0 h-px min-w-0 flex-1 border-0 bg-line"
              />
              <span data-part="auth-split-divider-label" class="text-[12px] leading-4 text-muted">{@divider_label}</span>
              <hr
                data-part="auth-split-divider-line"
                class="m-0 h-px min-w-0 flex-1 border-0 bg-line"
              />
            </div>
            {render_slot(@inner_block)}
            <span
              :if={@footer != []}
              data-part="auth-split-footer"
              class="text-center text-[13px] leading-[18px] text-muted"
            >
              {render_slot(@footer)}
            </span>
          </div>
        </div>
        <div
          :if={@page_footer != []}
          data-part="auth-split-page-footer"
          class="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 px-10 pb-7 text-[12.5px] text-muted"
        >
          {render_slot(@page_footer)}
        </div>
      </div>
      <div
        :if={@aside != []}
        data-part="auth-split-aside"
        data-lu-auth-right
        class="flex flex-1 flex-col justify-center gap-[18px] border-l border-line bg-tray p-10 max-lg:hidden!"
      >
        {render_slot(@aside)}
      </div>
      <div
        :if={@aside == [] and (@src != nil or @art != [])}
        data-part="auth-split-art-side"
        data-lu-auth-right
        class="relative min-w-0 flex-1 overflow-hidden border-l border-line bg-tray max-lg:hidden!"
      >
        <img
          :if={@src}
          data-part="auth-split-img"
          src={@src}
          alt={@alt}
          class="absolute inset-0 size-full object-cover"
        />
        <div :if={@art != []} data-part="auth-split-art" class="absolute inset-0">
          {render_slot(@art)}
        </div>
        <figure
          :for={q <- @quote}
          data-part="auth-split-figure"
          class="absolute inset-x-0 bottom-0 m-0 bg-[linear-gradient(to_top,rgba(0,0,0,.7),transparent)] px-8 pb-8 pt-12 text-white"
        >
          <div
            :if={q[:rating]}
            data-part="auth-split-rating"
            aria-label={I18n.t("auth_split.rating", @locale, rating: q.rating)}
            class="mb-2 tracking-[2px] text-star"
          >
            {String.duplicate("★", q.rating)}{String.duplicate("☆", max(5 - q.rating, 0))}
          </div>
          <blockquote
            data-part="auth-split-blockquote"
            class="m-0 mb-3 text-[20px] leading-7 font-medium"
          >
            {render_slot(q)}
          </blockquote>
          <figcaption data-part="auth-split-figcaption" class="text-[13.5px]">
            <b>{q[:author]}</b><span
              :if={q[:role]}
              data-part="auth-split-quote-role"
              class="opacity-75"
            > · {q.role}</span>
          </figcaption>
        </figure>
      </div>
    </div>
    """
  end

  defp style_attrs(width, style) do
    [width && "--lu-auth-form-w: #{width}px", style]
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Enum.join(";")
    |> then(&if(&1 == "", do: [], else: [style: &1]))
  end

  attr :brand, :string, default: "Ledger", doc: "The product name beside the mark."
  attr :mark, :string, default: "L", doc: "The letter (or text) inside the brand tile."

  attr :form_id, :string,
    default: nil,
    doc:
      "Id of the column's `<form>` (with `on_submit`/`on_change`). Default: the `id` of the page plus `-form`; with `on_change` and no id at all the form gets `phx-ignore-missing-id`."

  attr :on_submit, :any,
    default: nil,
    doc: "Makes the column a `<form>` with this `phx-submit`."

  attr :on_change, :any,
    default: nil,
    doc: "Makes the column a `<form>` with this `phx-change`."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true, doc: "The form column: title, fields, buttons."
  slot :footer, doc: "The line under the column: one `<span>` per side (copyright, links)."
  slot :art, doc: "The right half; usually `auth_art/1`."

  # the column reads the plain markup of its content: `<h1>`, `<p class="sub">`, `<div class="or">`
  # and the links (a zero-specificity rule, so a utility on a link wins)
  @column "m-auto flex w-full max-w-[380px] flex-col gap-4 " <>
            "[&_h1]:m-0 [&_h1]:font-display [&_h1]:text-[30px] [&_h1]:leading-[1.15] [&_h1]:font-[650] [&_h1]:tracking-[-.035em] " <>
            "[&_.sub]:-mt-1.5 [&_.sub]:mb-1.5 [&_.sub]:text-[14.5px] [&_.sub]:leading-normal [&_.sub]:text-muted " <>
            "[&_.or]:flex [&_.or]:items-center [&_.or]:gap-3 [&_.or]:text-[12.5px] [&_.or]:text-muted " <>
            "[&_.or]:before:h-px [&_.or]:before:flex-1 [&_.or]:before:bg-line [&_.or]:before:content-[''] " <>
            "[&_.or]:after:h-px [&_.or]:after:flex-1 [&_.or]:after:bg-line [&_.or]:after:content-['']"

  @doc """
  The sign in / sign up / recovery screen of the canvas: on the left the brand, a
  centered column (max 380px, `inner_block`) and a footer line; on the right the rounded art
  (`:art`, see `auth_art/1`). It fills its parent (`height: 100%`), so give the parent the screen's
  height.

      <.auth_page brand="Ledger">
        <h1>Entrar no Ledger</h1>
        <p class="sub">Pedidos, notas e financeiro num lugar só.</p>
        ...fields...
        <:footer><span>© 2026 Acme</span><span>Privacidade · Termos</span></:footer>
        <:art><.auth_art id="login-art">...</.auth_art></:art>
      </.auth_page>

  With `on_submit` or `on_change` the column is a `<form>` (the layout is the same), so the fields
  validate and submit through LiveView.

  Inside the column use `<h1>`, `<p class="sub">` and a `<div class="or">ou com e-mail</div>`
  divider: the column styles them with descendant utilities. Under 1024px there is one column and the
  art goes away.
  """
  def auth_page(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:tag, if(assigns.on_submit || assigns.on_change, do: "form", else: "div"))
      |> assign(:fid, form_id(assigns))
      |> assign(
        :column,
        @column <>
          " [:where(&)_a]:font-medium [:where(&)_a]:text-accent-content [:where(&)_a]:no-underline"
      )
      |> then(
        &settle(&1, changed0,
          tag: [:on_submit, :on_change],
          fid: [:form_id, :on_change, :rest],
          column: []
        )
      )

    ~H"""
    <div
      data-part="auth-page"
      class={
        cx([
          "relative grid h-full w-full grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)] gap-3 bg-page p-3 max-lg:grid-cols-[minmax(0,1fr)]",
          @class
        ])
      }
      {@rest}
    >
      <div data-part="auth-page-header" class="flex flex-col px-10 py-7">
        <div
          data-part="auth-page-brand"
          class="flex items-center gap-2.5 font-display text-[16px] font-[650] tracking-[-.02em]"
        >
          <span
            data-part="auth-page-mark"
            class="grid size-[30px] place-items-center rounded-md bg-inverse font-sans text-[15px] leading-normal font-bold text-panel"
          >{@mark}</span>{@brand}
        </div>
        <.dynamic_tag
          data-part="auth-page-dynamic_tag"
          tag_name={@tag}
          id={@fid}
          class={@column}
          phx-submit={@on_submit}
          phx-change={@on_change}
          phx-ignore-missing-id={@on_change && is_nil(@fid) && true}
        >
          {render_slot(@inner_block)}
        </.dynamic_tag>
        <div
          :if={@footer != []}
          data-part="auth-page-footer"
          class="flex justify-between text-[12.5px] text-muted"
        >
          {render_slot(@footer)}
        </div>
      </div>
      <div
        :if={@art != []}
        data-part="auth-art-box"
        class="relative overflow-hidden rounded-2xl bg-sunken max-lg:hidden"
      >
        {render_slot(@art)}
      </div>
    </div>
    """
  end

  attr :id, :string, default: "auth-art", doc: "Prefix of the SVG's gradient ids; one per page."

  attr :tone, :string,
    default: "teal",
    doc: "Kept for compatibility; the palette follows the theme."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :chip, doc: "A floating card over the picture (`top`, `right` in px or any CSS length)." do
    attr :top, :string
    attr :right, :string
    attr :left, :string
    attr :bottom, :string
  end

  slot :quote, doc: "The glass testimonial at the bottom." do
    attr :author, :string, required: true
    attr :role, :string
    attr :initials, :string
    attr :tone, :string, doc: "Avatar tone, `t1`..`t5`."
  end

  @doc """
  The art half of `auth_page/1`: the mountain landscape (`Illustration.summit/1`), floating `:chip`
  cards and a glass `:quote`. The landscape paints with the `--lu-hero-*` tokens, so it follows the
  theme (light, dark, palette).
  """
  def auth_art(assigns) do
    ~H"""
    <Illustration.summit
      id={@id}
      tone={@tone}
      class={cx(["absolute inset-0 size-full", @class])}
      {@rest}
    />
    <div
      :for={c <- @chip}
      data-part="auth-chip"
      class="absolute flex items-center gap-2.5 rounded-lg border border-line bg-panel py-2.5 pr-3.5 pl-2.5 text-[13px] shadow-[0_12px_30px_rgba(0,0,0,.12)] [&_b]:block [&_b]:text-[15px] [&_b]:tabular-nums [&_small]:[&_small]:text-muted"
      style={chip_style(c)}
    >
      {render_slot(c)}
    </div>
    <div
      :for={q <- @quote}
      data-part="auth-glass"
      class="absolute inset-x-8 bottom-8 flex flex-col gap-3.5 rounded-xl border border-[color-mix(in_srgb,var(--lu-line)_80%,transparent)] bg-[color-mix(in_srgb,var(--lu-bg-panel)_82%,transparent)] px-6 py-[22px] backdrop-blur-[14px]"
    >
      <q
        data-part="auth-art-q"
        class="text-[17px] leading-normal tracking-[-.01em] text-ink [quotes:'“'_'”']"
      >{render_slot(q)}</q>
      <div data-part="auth-art-author" class="flex flex-wrap items-center gap-2.5">
        <.avatar :if={q[:initials]} initials={q[:initials]} color={q[:tone] || "t1"} size="34" />
        <span data-part="auth-art-author-text" class="flex flex-col leading-[1.3]">
          <b data-part="auth-art-author-name" class="text-[13.5px]">{q.author}</b>
          <small
            :if={q[:role]}
            data-part="auth-art-author-role"
            class="text-muted"
          >{q.role}</small>
        </span>
      </div>
    </div>
    """
  end

  defp chip_style(c) do
    [:top, :right, :bottom, :left]
    |> Enum.filter(&c[&1])
    |> Enum.map_join(";", &"#{&1}:#{c[&1]}")
  end

  attr :provider, :string, default: nil, values: [nil, "", "google", "apple", "github"]
  attr :href, :string, default: nil

  attr :block, :boolean,
    default: false,
    doc: "The full-width provider button (`size=\"lg\"`, the whole row)."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(type disabled form name value)
  slot :icon
  slot :inner_block, required: true

  @doc "A sign in button for an identity provider: the icon and the label, as a link (`href`) or a button."
  def oauth_button(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:icon_name, @provider_icons[assigns.provider || ""])
      |> assign(:to, if(assigns.href, do: [href: assigns.href], else: []))
      |> assign(:btn_type, assigns.rest[:type] || "button")
      |> assign(:rest, Map.delete(assigns.rest, :type))
      |> then(
        &settle(&1, changed0,
          rest: [],
          icon_name: [:provider],
          to: [:href],
          btn_type: [:rest]
        )
      )

    oauth(assigns)
  end

  # A call of `<.button>` with a spread (`{@rest}`, `{@to}`) is never "unchanged": it sends the
  # whole button when only the label changes. With no extra attributes (the usual case) it is
  # called with the attributes written out (`<.button href={nil}>` would be a link, hence one
  # clause per case).
  defp oauth(%{rest: rest, block: block, href: href} = assigns) when map_size(rest) == 0 do
    case {block, is_binary(href)} do
      {true, true} -> oauth_block_link(assigns)
      {true, false} -> oauth_block(assigns)
      {false, true} -> oauth_link(assigns)
      {false, false} -> oauth_plain(assigns)
    end
  end

  defp oauth(assigns) do
    ~H"""
    <.button
      :if={@block}
      canvas
      size="lg"
      type={@btn_type}
      data-part="oauth-button"
      class={["w-full", @class]}
      {@to}
      {@rest}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </.button>
    <.button
      :if={!@block}
      color="neutral"
      variant="outline"
      size="md"
      shape="rounded"
      type={@btn_type}
      data-part="oauth-button"
      class={@class}
      {@to}
      {@rest}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </.button>
    """
  end

  defp oauth_block_link(assigns) do
    ~H"""
    <.button
      canvas
      size="lg"
      type={@btn_type}
      data-part="oauth-button"
      class={["w-full", @class]}
      href={@href}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </.button>
    """
  end

  defp oauth_block(assigns) do
    ~H"""
    <.button
      canvas
      size="lg"
      type={@btn_type}
      data-part="oauth-button"
      class={["w-full", @class]}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </.button>
    """
  end

  defp oauth_link(assigns) do
    ~H"""
    <.button
      color="neutral"
      variant="outline"
      size="md"
      shape="rounded"
      type={@btn_type}
      data-part="oauth-button"
      class={@class}
      href={@href}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </.button>
    """
  end

  defp oauth_plain(assigns) do
    ~H"""
    <.button
      color="neutral"
      variant="outline"
      size="md"
      shape="rounded"
      type={@btn_type}
      data-part="oauth-button"
      class={@class}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </.button>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon
  slot :inner_block, required: true

  @doc "The \"link sent\" block: a tile with a mail icon and the message beside it (`role=\"status\"`)."
  def auth_sent(assigns) do
    ~H"""
    <div
      data-part="auth-sent"
      role="status"
      class={cx(["flex flex-nowrap items-start gap-3", @class])}
      {@rest}
    >
      <span
        data-part="auth-sent-icon"
        class="inline-grid size-11 flex-none place-items-center rounded-lg bg-accent-soft text-accent-content"
      >
        <%= if @icon != [] do %>
          {render_slot(@icon)}
        <% else %>
          <.icon name="mail" size="md" />
        <% end %>
      </span>
      <div data-part="auth-sent-text" class="min-w-0 flex-1 text-ink-2">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The notice on top of a form with errors: a cross icon and the message (`role=\"alert\"`)."
  def auth_alert(assigns) do
    ~H"""
    <div
      data-part="auth-alert"
      role="alert"
      class={
        cx([
          "flex items-start gap-2.5 rounded-md border border-transparent bg-neg-soft px-3 py-2.5 text-[13.5px]",
          @class
        ])
      }
      {@rest}
    >
      <.icon name="x-circle" size="md" class="mt-px text-neg" />
      <span data-part="auth-alert-text" class="min-w-0 flex-1 text-ink-2">{render_slot(@inner_block)}</span>
    </div>
    """
  end

  attr :loading, :boolean, default: false
  attr :loading_label, :string, default: nil
  attr :type, :string, default: "submit"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  @doc "The form's submit button, full width and accent. With `loading` it disables itself and shows the spinner."
  def auth_submit(assigns) do
    changed0 = assigns.__changed__

    assigns =
      settle(assign(assigns, :cls, Button.canvas_classes("lg", "primary")), changed0, cls: [])

    ~H"""
    <button
      type={@type}
      data-part="auth-submit"
      class={cx([@cls, "w-full", @class])}
      disabled={@loading or @rest[:disabled]}
      aria-busy={@loading && "true"}
      {Map.delete(@rest, :disabled)}
    >
      <span
        :if={@loading}
        data-part="auth-submit-spinner"
        class={spinner_classes()}
        aria-hidden="true"
      ></span>
      <%= if @loading and @loading_label do %>
        {@loading_label}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  # `phx-change` needs an id on the form (form recovery): `form_id`, else the page's id plus `-form`.
  defp form_id(%{form_id: id}) when is_binary(id), do: id
  defp form_id(%{on_change: change, rest: %{id: id}}) when change != nil, do: "#{id}-form"
  defp form_id(_), do: nil
end
