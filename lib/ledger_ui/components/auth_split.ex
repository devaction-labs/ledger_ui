defmodule LedgerUI.Components.AuthSplit do
  @moduledoc """
  The sign in and sign up screen in two halves: the form on the left (brand in the corner, a soft glow
  at the top, the title, the subtitle, the form and a line under it) and, on the right, a picture
  filling its half with a testimonial over its lower part.

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
  whole card. `variant`: `card` (default, floating on a dotted canvas) or `full` (the whole screen).
  Under 1024px the right half goes away. The other states of the screen: `auth_sent/1` (link sent),
  `auth_alert/1` (errors) and `auth_submit/1` (sending).
  """
  use LedgerUI.Component

  @provider_icons %{"google" => "google", "apple" => "apple", "github" => "github"}

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :src, :string, default: nil
  attr :alt, :string, default: ""
  attr :variant, :string, default: "card", values: ~w(card full)
  attr :glow, :boolean, default: true
  attr :divider_label, :string, default: "Or"
  attr :brand_href, :string, default: "/"
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
        :canvas_style,
        if(full?,
          do: nil,
          else:
            "padding:32px;background-color:var(--bg-tray);background-image:radial-gradient(var(--line-strong) 1px,transparent 1px);background-size:18px 18px"
        )
      )
      |> assign(
        :app_style,
        if(full?,
          do: "min-height:100vh;border-radius:0;border:0;box-shadow:none",
          else: "min-height:640px;max-width:1100px;margin:0 auto"
        )
      )

    ~H"""
    <div data-part="auth-split" class={cx(["lu-auth", @class])} {style_attr(@canvas_style)} {@rest}>
      <div class={cx(["lu-app", @full? && "full"])} {style_attr(@app_style)}>
        <div style="flex:1;min-width:0;display:flex;align-items:center;justify-content:center;background:var(--bg-page);padding:32px;position:relative;overflow:hidden">
          <div
            :if={@glow}
            aria-hidden="true"
            style="position:absolute;left:50%;top:-120px;width:520px;height:260px;margin-left:-260px;border-radius:50%;background:radial-gradient(closest-side,var(--teal-100),transparent);opacity:.8;pointer-events:none"
          >
          </div>
          <a
            :if={@brand != []}
            href={@brand_href}
            style="position:absolute;left:24px;top:22px;display:inline-flex;align-items:center;gap:8px;font-weight:600;color:var(--ink);text-decoration:none"
          >
            {render_slot(@brand)}
          </a>
          <div class="lu-col" style="width:100%;max-width:360px;gap:16px;position:relative">
            <div>
              <h1 style="margin:0;font-size:26px;font-weight:600;letter-spacing:-.02em">{@title}</h1>
              <div :if={@subtitle} class="lu-muted">{@subtitle}</div>
            </div>
            <div :if={@providers != []} class="lu-col" style="gap:8px">
              {render_slot(@providers)}
              <div class="lu-row" style="gap:12px;flex-wrap:nowrap">
                <hr class="lu-sep lu-grow" />
                <span class="lu-xs lu-muted">{@divider_label}</span>
                <hr class="lu-sep lu-grow" />
              </div>
            </div>
            {render_slot(@inner_block)}
            <div :if={@footer != []} class="lu-small lu-muted" style="text-align:center">
              {render_slot(@footer)}
            </div>
          </div>
        </div>
        <div
          :if={@right?}
          class="lu-auth-right"
          style="flex:1;min-width:0;position:relative;overflow:hidden;background:var(--bg-tray);border-left:1px solid var(--line)"
        >
          <%= cond do %>
            <% @aside != [] -> %>
              {render_slot(@aside)}
            <% true -> %>
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
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :provider, :string, default: nil, values: [nil, "", "google", "apple", "github"]
  attr :href, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(type disabled form name value)
  slot :icon
  slot :inner_block, required: true

  @doc "A sign in button for an identity provider: the icon and the label, as a link (`href`) or a button."
  def oauth_button(assigns) do
    assigns = assign(assigns, :icon_name, @provider_icons[assigns.provider || ""])

    ~H"""
    <.link
      :if={@href}
      href={@href}
      data-part="oauth-button"
      class={cx(["lu-b c-neutral v-outline s-md sh-rounded", @class])}
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
      class={cx(["lu-b c-neutral v-outline s-md sh-rounded", @class])}
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
      style="display:flex;align-items:flex-start;gap:10px;padding:10px 12px;border-radius:10px;background:var(--neg-soft);color:var(--neg);font-size:13.5px"
      {@rest}
    >
      <.icon name="x-circle" size="md" />
      <span style="flex:1;min-width:0">{render_slot(@inner_block)}</span>
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
      class={cx(["lu-btn accent block lg", @class])}
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

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
