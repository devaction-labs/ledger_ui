defmodule LedgerUI.Components.ErrorPage do
  @moduledoc """
  The canvas's error screens: the whole page an `ErrorHTML` renders (`error_page/1`), the error
  inside the app (`error_state/1`) and the list of links under the actions (`error_links/1`).

      <.error_page code={404} request_id={@request_id}>
        <:brand><b>Acme</b></:brand>
        <:status href="https://status.acme.com">All systems operational</:status>
        <:actions><a class="lu-b c-primary v-solid s-lg" href="/">Back home</a></:actions>
        <.error_links title="Maybe you were looking for">
          <:link navigate="/orders" icon="receipt" description="Every order">Orders</:link>
        </.error_links>
        <:footer><a href="/help">Help center</a></:footer>
      </.error_page>

      <.error_state code={404} title="Order #2499 not found">
        It may have been deleted or belong to another branch.
      </.error_state>

  `code` is the HTTP status (or text, `"OFF"` for offline). It picks the colour of the big code
  (`tone`: `neutral` 404, `error` 5xx, `warning` 403/429/offline, `accent` 401/419/503) and the
  English defaults of `label`, `title` and `description`; pass them translated.

  The copy button of the request id uses an inline `onclick` (`navigator.clipboard`), so it works
  on a plain `ErrorHTML` page with no LiveView or hook. `back_label` adds a `history.back()` button.
  """
  use LedgerUI.Component

  @tones %{
    "neutral" => "var(--ink-2)",
    "error" => "var(--neg)",
    "warning" => "var(--warn)",
    "accent" => "var(--accent)"
  }

  @status_dot %{"ok" => "var(--pos)", "warning" => "var(--warn)", "down" => "var(--neg)"}

  # code => {tone, icon, label, title, description}
  @defaults %{
    "404" =>
      {"neutral", "search", "Page not found", "We could not find that page",
       "The address may have changed or the page was removed."},
    "500" =>
      {"error", "alert", "Server error", "Something went wrong on our side",
       "We were notified and are looking into it. Try again in a moment."},
    "403" =>
      {"warning", "lock", "Forbidden", "You do not have access",
       "Ask the owner of the workspace to grant you access."},
    "401" =>
      {"accent", "lock", "Sign in required", "Sign in to continue",
       "Your session ended or you are not signed in."},
    "419" =>
      {"accent", "refresh", "Page expired", "This page expired", "Reload it and try again."},
    "429" =>
      {"warning", "timer", "Too many requests", "Slow down a little",
       "You made too many requests. Try again in a moment."},
    "503" =>
      {"accent", "alert", "Unavailable", "We are back soon", "The service is under maintenance."},
    "OFF" =>
      {"warning", "wifi", "Offline", "You are offline",
       "Check your connection; we will reload when it is back."}
  }
  @fallback {"error", "alert", "Error", "Something went wrong", "Try again in a moment."}

  @copy_js "navigator.clipboard&&navigator.clipboard.writeText(this.dataset.copy);var b=this;b.dataset.copied='';setTimeout(function(){delete b.dataset.copied},2000)"

  defp defaults(code), do: Map.get(@defaults, to_string(code), @fallback)

  @doc false
  def tone_for(code), do: elem(defaults(code), 0)

  attr :code, :any, required: true
  attr :tone, :string, default: nil, values: [nil, "", "neutral", "error", "warning", "accent"]
  attr :label, :string, default: nil
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :request_id, :string, default: nil
  attr :request_id_label, :string, default: "Request ID"
  attr :copy_label, :string, default: "Copy request ID"
  attr :copy, :boolean, default: true
  attr :back_label, :string, default: nil
  attr :timestamp, :string, default: nil
  attr :id, :string, default: "error-page"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :brand
  slot :card
  slot :footer
  slot :inner_block

  slot :status do
    attr :href, :string
    attr :status, :string
  end

  def error_page(assigns) do
    {tone, _icon, label, title, description} = defaults(assigns.code)
    tone = if assigns.tone in [nil, ""], do: tone, else: assigns.tone

    assigns =
      assigns
      |> assign(:classes, cx(["lu-err", assigns.class]))
      |> assign(:color, @tones[tone])
      |> assign(:tone_name, tone)
      |> assign(:label_t, assigns.label || label)
      |> assign(:title_t, assigns.title || title)
      |> assign(:description_t, assigns.description || description)
      |> assign(:dots, @status_dot)
      |> assign(:copy_js, @copy_js)

    ~H"""
    <main
      id={@id}
      data-part="error-page"
      data-tone={@tone_name}
      class={@classes}
      aria-labelledby={@id <> "-title"}
      {@rest}
    >
      <header :if={@brand != [] or @status != []}>
        <div class="lu-row" style="gap:8px">{render_slot(@brand)}</div>
        <a
          :for={s <- @status}
          class="lu-row lu-small lu-muted"
          style="gap:8px;text-decoration:none"
          href={s[:href]}
        >
          <span class="lu-dot" style={"color:" <> (@dots[s[:status] || "ok"] || "var(--pos)")}></span>{render_slot(
            s
          )}
        </a>
      </header>
      <div style="flex:1;display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:48px;align-items:center;padding:32px;max-width:1200px;width:100%;margin:0 auto">
        <div class="lu-col" style="gap:14px;align-items:flex-start">
          <span class="lu-row lu-small" style="gap:8px">
            <span class="lu-badge mono" style={"color:" <> @color}>{@code}</span>
            <span class="lu-muted">{@label_t}</span>
          </span>
          <h1 id={@id <> "-title"}>{@title_t}</h1>
          <p class="lu-muted" style="margin:0;max-width:460px">{@description_t}</p>
          <div :if={@actions != [] || @back_label} class="lu-row" style="gap:10px;margin-top:6px">
            {render_slot(@actions)}
            <button
              :if={@back_label}
              type="button"
              class="lu-b c-neutral v-outline s-md sh-rounded"
              onclick="history.back()"
            >
              {@back_label}
            </button>
          </div>
          {render_slot(@inner_block)}
        </div>
        <aside
          aria-hidden="true"
          style="position:relative;min-height:320px;display:grid;place-items:center;border-radius:24px;overflow:hidden;background-image:radial-gradient(var(--line-strong) 1px,transparent 1px);background-size:18px 18px;background-color:var(--bg-tray)"
        >
          <span
            class="mono"
            style={"font-size:230px;font-weight:700;letter-spacing:-.06em;line-height:1;color:transparent;-webkit-text-stroke:1.5px " <> @color <> ";opacity:.55"}
          >
            {@code}
          </span>
          <div :if={@card != []} style="position:absolute;left:24px;right:24px;bottom:24px">
            {render_slot(@card)}
          </div>
        </aside>
      </div>
      <footer
        :if={@request_id || @timestamp || @footer != []}
        class="lu-row lu-small lu-muted"
      >
        <span class="lu-row" style="gap:8px">
          <span :if={@request_id}>
            {@request_id_label}: <code class="mono" style="user-select:all">{@request_id}</code>
          </span>
          <button
            :if={@request_id && @copy}
            type="button"
            class="lu-btn icon ghost sm"
            aria-label={@copy_label}
            data-copy={@request_id}
            onclick={@copy_js}
          >
            <.icon name="copy" />
          </button>
          <span :if={@timestamp}>{@timestamp}</span>
        </span>
        <span class="lu-row" style="gap:12px">{render_slot(@footer)}</span>
      </footer>
    </main>
    """
  end

  attr :code, :any, required: true
  attr :tone, :string, default: nil, values: [nil, "", "neutral", "error", "warning", "accent"]
  attr :icon, :string, default: nil
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :inner_block, doc: "The description, instead of `description`."
  slot :more, doc: "Under the actions, full width."

  def error_state(assigns) do
    {tone, icon, _label, title, description} = defaults(assigns.code)
    tone = if assigns.tone in [nil, ""], do: tone, else: assigns.tone
    title_id = (assigns.id || "err-#{assigns.code}") <> "-title"

    assigns =
      assigns
      |> assign(:classes, cx(["lu-col", assigns.class]))
      |> assign(:color, @tones[tone])
      |> assign(:icon_t, assigns.icon || icon)
      |> assign(:title_t, assigns.title || title)
      |> assign(:description_t, assigns.description || description)
      |> assign(:title_id, title_id)

    ~H"""
    <section
      data-part="error-state"
      class={@classes}
      aria-labelledby={@title_id}
      style="align-items:center;gap:8px;padding:20px;text-align:center"
      {@rest}
    >
      <span
        class="lu-errnum"
        aria-hidden="true"
        style={"font-size:150px;background:none;-webkit-text-fill-color:currentColor;color:" <> @color}
      >
        {@code}
      </span>
      <.icon name={@icon_t} boxed box_size="lg" />
      <b id={@title_id}>{@title_t}</b>
      <span class="lu-small lu-muted">
        {if @inner_block == [], do: @description_t, else: render_slot(@inner_block)}
      </span>
      <div :if={@actions != []} class="lu-row" style="gap:10px;margin-top:6px">
        {render_slot(@actions)}
      </div>
      <div :if={@more != []} style="width:100%;margin-top:12px">{render_slot(@more)}</div>
    </section>
    """
  end

  attr :title, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :link, required: true do
    attr :href, :string
    attr :navigate, :string
    attr :icon, :string
    attr :description, :string
  end

  def error_links(assigns) do
    assigns = assign(assigns, :classes, cx(["lu-col", assigns.class]))

    ~H"""
    <nav
      data-part="error-links"
      aria-label={@title}
      class={@classes}
      style="gap:6px;width:100%;max-width:460px"
      {@rest}
    >
      <span :if={@title} class="lu-xs lu-muted" style="text-transform:uppercase;letter-spacing:.06em">
        {@title}
      </span>
      <%= for l <- @link do %>
        <.link
          :if={l[:navigate]}
          navigate={l[:navigate]}
          class="lu-row lu-panel"
          style="gap:12px;padding:10px 12px;text-decoration:none;color:inherit"
        >
          {link_body(l, render_slot(l))}
        </.link>
        <.link
          :if={!l[:navigate]}
          href={l[:href] || "#"}
          class="lu-row lu-panel"
          style="gap:12px;padding:10px 12px;text-decoration:none;color:inherit"
        >
          {link_body(l, render_slot(l))}
        </.link>
      <% end %>
    </nav>
    """
  end

  defp link_body(l, label) do
    assigns = %{l: l, label: label}

    ~H"""
    <.icon :if={@l[:icon]} name={@l[:icon]} boxed />
    <span class="lu-col lu-grow" style="gap:0">
      <b>{@label}</b>
      <span :if={@l[:description]} class="lu-xs lu-muted">{@l[:description]}</span>
    </span>
    <.icon name="chevron-right" size="sm" />
    """
  end
end
