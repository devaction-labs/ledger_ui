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
  whole card. `variant`: `card` (default, the framed app `lu-app`) or `full` (the whole screen). The
  `:brand` slot is the content of the 40px brand tile (`brand_href` makes it a link); `oauth_button`
  takes `block` for the full-width provider button of the canvas.
  For the canvas-v2 screen (brand tile, tinted art with floating cards) see `auth_page/1` and
  `auth_art/1`. Under 1024px the right half goes away. The other states of the screen: `auth_sent/1` (link sent),
  `auth_alert/1` (errors) and `auth_submit/1` (sending).
  """
  use LedgerUI.Component

  @provider_icons %{"google" => "google", "apple" => "apple", "github" => "github"}

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :src, :string, default: nil
  attr :alt, :string, default: ""
  attr :variant, :string, default: "card", values: ~w(card full)
  attr :glow, :boolean, default: false, doc: "Deprecated: the canvas has no glow; ignored."
  attr :divider_label, :string, default: "Or"
  attr :brand_href, :string, default: nil, doc: "Makes the brand mark a link."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :art
  slot :aside
  slot :brand
  slot :footer
  slot :inner_block, required: true
  slot :providers

  slot :quote do
    attr :author, :string
    attr :role, :string
    attr :rating, :integer
  end

  def auth_split(assigns) do
    right? = assigns.src != nil or assigns.art != [] or assigns.aside != []
    full? = assigns.variant == "full"

    assigns =
      assigns
      |> assign(:right?, right?)
      |> assign(:full?, full?)
      |> assign(
        :logo_style,
        "width:40px;height:40px;border-radius:11px;background:var(--inverse);color:var(--on-inverse);display:grid;place-items:center"
      )
      |> assign(
        :app_style,
        if(full?,
          do: "min-height:100vh;border-radius:0;border:0;box-shadow:none",
          else: "min-height:600px"
        )
      )

    ~H"""
    <div
      data-part="auth-split"
      class={cx(["lu-app", @full? && "full", @class])}
      style={@app_style}
      {@rest}
    >
      <div style="flex:1;display:flex;align-items:center;justify-content:center;background:var(--bg-page);padding:32px">
        <div class="lu-col" style="width:360px;gap:16px">
          <.link
            :if={@brand != [] and @brand_href}
            href={@brand_href}
            class="logo"
            style={@logo_style}
          >
            {render_slot(@brand)}
          </.link>
          <span :if={@brand != [] and !@brand_href} class="logo" style={@logo_style}>
            {render_slot(@brand)}
          </span>
          <div>
            <div
              role="heading"
              aria-level="1"
              style="font-size:26px;font-weight:600;letter-spacing:-.02em"
            >
              {@title}
            </div>
            <div :if={@subtitle} class="lu-muted">{@subtitle}</div>
          </div>
          {render_slot(@providers)}
          <div :if={@providers != []} class="lu-row" style="gap:12px">
            <hr class="lu-sep lu-grow" />
            <span class="lu-xs lu-muted">{@divider_label}</span>
            <hr class="lu-sep lu-grow" />
          </div>
          {render_slot(@inner_block)}
          <span :if={@footer != []} class="lu-small lu-muted" style="text-align:center">
            {render_slot(@footer)}
          </span>
        </div>
      </div>
      <div
        :if={@aside != []}
        data-lu-auth-right
        style="flex:1;background:var(--bg-tray);border-left:1px solid var(--line);padding:40px;display:flex;flex-direction:column;justify-content:center;gap:18px"
      >
        {render_slot(@aside)}
      </div>
      <div
        :if={@aside == [] and (@src != nil or @art != [])}
        data-lu-auth-right
        style="flex:1;min-width:0;position:relative;overflow:hidden;background:var(--bg-tray);border-left:1px solid var(--line)"
      >
        <img
          :if={@src}
          src={@src}
          alt={@alt}
          style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"
        />
        <div :if={@art != []} style="position:absolute;inset:0">{render_slot(@art)}</div>
        <figure
          :for={q <- @quote}
          style="position:absolute;left:0;right:0;bottom:0;margin:0;padding:48px 32px 32px;color:#fff;background:linear-gradient(to top,rgba(0,0,0,.7),transparent)"
        >
          <div
            :if={q[:rating]}
            aria-label={"#{q.rating} of 5"}
            style="letter-spacing:2px;color:#f5b301;margin-bottom:8px"
          >
            {String.duplicate("★", q.rating)}{String.duplicate("☆", max(5 - q.rating, 0))}
          </div>
          <blockquote style="margin:0 0 12px;font-size:20px;line-height:28px;font-weight:500">
            {render_slot(q)}
          </blockquote>
          <figcaption style="font-size:13.5px">
            <b>{q[:author]}</b><span :if={q[:role]} style="opacity:.75"> · {q.role}</span>
          </figcaption>
        </figure>
      </div>
    </div>
    """
  end

  attr :brand, :string, default: "Ledger", doc: "The product name beside the mark."
  attr :mark, :string, default: "L", doc: "The letter (or text) inside the brand tile."

  attr :form_id, :string,
    default: nil,
    doc: "Id of the column's `<form>` (with `on_submit`/`on_change`)."

  attr :on_submit, :any,
    default: nil,
    doc: "Makes the column (`.in`) a `<form>` with this `phx-submit`."

  attr :on_change, :any,
    default: nil,
    doc: "Makes the column (`.in`) a `<form>` with this `phx-change`."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true, doc: "The form column (`.in`): title, fields, buttons."
  slot :footer, doc: "The line under the column: one `<span>` per side (copyright, links)."
  slot :art, doc: "The right half (`.art`); usually `auth_art/1`."

  @doc """
  The sign in / sign up / recovery screen of the canvas (`lu-auth`): on the left the brand, a
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
  divider: `lu-auth` styles them. The art goes away under the grid's narrow width by CSS.
  """
  def auth_page(assigns) do
    assigns =
      assign(assigns, :tag, if(assigns.on_submit || assigns.on_change, do: "form", else: "div"))

    ~H"""
    <div data-part="auth-page" class={cx(["lu-auth", @class])} {@rest}>
      <div class="fm">
        <div class="lu-brand"><span class="mk">{@mark}</span>{@brand}</div>
        <.dynamic_tag
          tag_name={@tag}
          id={@form_id}
          class="in"
          phx-submit={@on_submit}
          phx-change={@on_change}
        >
          {render_slot(@inner_block)}
        </.dynamic_tag>
        <div :if={@footer != []} class="ft">{render_slot(@footer)}</div>
      </div>
      <div :if={@art != []} class="art">{render_slot(@art)}</div>
    </div>
    """
  end

  attr :id, :string, default: "auth-art", doc: "Prefix of the SVG's gradient ids; one per page."
  attr :tone, :string, default: "teal", doc: "Modifier of `lu-summit` (the palette)."
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
  The art half of `auth_page/1`: the mountain landscape (`lu-summit`), floating `:chip` cards and a
  glass `:quote`. The landscape paints with the `--hero-*` tokens of `.lu-auth .art`, so it follows
  the light and dark themes.
  """
  def auth_art(assigns) do
    ~H"""
    <svg
      data-part="auth-art"
      class={cx(["lu-summit", @tone, @class])}
      viewBox="0 0 520 300"
      preserveAspectRatio="xMidYMid slice"
      aria-hidden="true"
      {@rest}
    >
      <defs>
        <linearGradient id={@id <> "-sky"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-sky1)"></stop>
          <stop offset="1" stop-color="var(--hero-sky2)"></stop>
        </linearGradient>
        <linearGradient id={@id <> "-m1"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m1a)"></stop>
          <stop offset="1" stop-color="var(--hero-m1b)"></stop>
        </linearGradient>
        <linearGradient id={@id <> "-m2"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m2a)"></stop>
          <stop offset="1" stop-color="var(--hero-m2b)"></stop>
        </linearGradient>
        <linearGradient id={@id <> "-m3"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="var(--hero-m3a)"></stop>
          <stop offset="1" stop-color="var(--hero-m3b)"></stop>
        </linearGradient>
        <radialGradient id={@id <> "-sun"} cx=".5" cy=".5" r=".5">
          <stop offset="0" stop-color="var(--hero-sun)"></stop>
          <stop offset="1" stop-color="var(--hero-sun)" stop-opacity="0"></stop>
        </radialGradient>
      </defs>
      <rect width="520" height="300" fill={"url(##{@id}-sky)"}></rect>
      <circle class="sun" cx="350" cy="110" r="90" fill={"url(##{@id}-sun)"}></circle>
      <circle class="sun-c" cx="350" cy="110" r="26" fill="var(--hero-sun)" opacity=".9"></circle>
      <g class="st">
        <circle cx="90" cy="40" r="1.2"></circle>
        <circle cx="160" cy="70" r="1"></circle>
        <circle cx="430" cy="34" r="1.3"></circle>
        <circle cx="470" cy="80" r="1"></circle>
        <circle cx="250" cy="28" r="1"></circle>
      </g>
      <path
        class="m3"
        d="M0 205 L70 150 L120 175 L190 110 L250 160 L310 120 L380 170 L450 125 L520 160 V300 H0 Z"
        fill={"url(##{@id}-m3)"}
      >
      </path>
      <path
        class="m2"
        d="M0 235 L60 200 L130 225 L210 170 L270 210 L340 185 L420 225 L520 190 V300 H0 Z"
        fill={"url(##{@id}-m2)"}
      >
      </path>
      <path
        class="m1"
        d="M0 268 L90 238 L170 258 L260 228 L350 262 L440 240 L520 258 V300 H0 Z"
        fill={"url(##{@id}-m1)"}
      >
      </path>
      <path
        class="ln"
        d="M180 300 C 230 270, 300 268, 330 250 S 400 230, 430 238"
        fill="none"
        stroke="var(--hero-line)"
        stroke-width="1.5"
        stroke-dasharray="3 5"
        pathLength="1"
      >
      </path>
    </svg>
    <div :for={c <- @chip} class="chip" style={chip_style(c)}>{render_slot(c)}</div>
    <div :for={q <- @quote} class="glass">
      <q>{render_slot(q)}</q>
      <div class="lu-row" style="gap:10px">
        <span :if={q[:initials]} class={"lu-av #{q[:tone] || "t1"}"} style="--s:34px">
          {q[:initials]}
        </span>
        <span style="display:flex;flex-direction:column;line-height:1.3">
          <b style="font-size:13.5px">{q.author}</b>
          <small :if={q[:role]} class="lu-muted">{q.role}</small>
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
    doc: "The full-width provider button (`lu-btn block lg`)."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(type disabled form name value)
  slot :icon
  slot :inner_block, required: true

  @doc "A sign in button for an identity provider: the icon and the label, as a link (`href`) or a button."
  def oauth_button(assigns) do
    assigns =
      assigns
      |> assign(:icon_name, @provider_icons[assigns.provider || ""])
      |> assign(
        :btn_class,
        if(assigns.block, do: "lu-btn block lg", else: "lu-b c-neutral v-outline s-md sh-rounded")
      )

    ~H"""
    <.link
      :if={@href}
      href={@href}
      data-part="oauth-button"
      class={cx([@btn_class, @class])}
      {@rest}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={!@href}
      type={@rest[:type] || "button"}
      data-part="oauth-button"
      class={cx([@btn_class, @class])}
      {Map.delete(@rest, :type)}
    >
      <%= if @icon != [] do %>
        {render_slot(@icon)}
      <% else %>
        <.icon :if={@icon_name} name={@icon_name} />
      <% end %>
      {render_slot(@inner_block)}
    </button>
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
      class={cx(["lu-row", @class])}
      style="flex-wrap:nowrap;align-items:flex-start;gap:12px"
      {@rest}
    >
      <span class="lu-ic acc lg">
        <%= if @icon != [] do %>
          {render_slot(@icon)}
        <% else %>
          <.icon name="mail" size="md" />
        <% end %>
      </span>
      <div class="lu-ink2" style="flex:1;min-width:0">{render_slot(@inner_block)}</div>
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
      class={cx(["lu-alert neg", @class])}
      {@rest}
    >
      <.icon name="x-circle" size="md" />
      <span>{render_slot(@inner_block)}</span>
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
    ~H"""
    <button
      type={@type}
      data-part="auth-submit"
      class={cx(["lu-btn primary block lg", @class])}
      disabled={@loading or @rest[:disabled]}
      aria-busy={@loading && "true"}
      {Map.delete(@rest, :disabled)}
    >
      <span :if={@loading} class="lu-spin" aria-hidden="true"></span>
      <%= if @loading and @loading_label do %>
        {@loading_label}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end
end
