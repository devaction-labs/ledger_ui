defmodule LedgerUI.Components.ErrorPage do
  @moduledoc """
  The canvas's error screens (styled only with Tailwind utilities): the whole page an `ErrorHTML` renders (`error_page/1`), the error
  inside the app (`error_state/1`) and the list of links under the actions (`error_links/1`).

      <.error_page code={404} request_id={@request_id}>
        <:brand><b>Acme</b></:brand>
        <:status href="https://status.acme.com">All systems operational</:status>
        <:actions><.button navigate="/" size="lg">Back home</.button></:actions>
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

  There is no inline handler (a page with CSP `script-src 'self'` and no LiveView is fine): the back link
  (`back_label`, a link to `back_href` or `/`, `data-lu-back`) and the copy button of the request id
  (`data-lu-error-copy`) are served by delegated click listeners of `ledger_ui.esm.js`, which registers
  them when it is imported (`import "ledger_ui"` is enough, no LiveSocket needed; the page must load
  that bundle). Without JS the back link just goes to `back_href` and the copy button stays hidden
  (it shows once the script has set `data-lu-js` on `<html>`).
  """
  use LedgerUI.Component

  # the colour of the code: a variable the page and the parts read
  @tones %{
    "neutral" => "[--tone:var(--lu-ink-2)]",
    "error" => "[--tone:var(--lu-neg)]",
    "warning" => "[--tone:var(--lu-warn)]",
    "accent" => "[--tone:var(--lu-accent)]"
  }

  @status_dot %{"ok" => "text-pos", "warning" => "text-warn", "down" => "text-neg"}

  @row "flex flex-wrap items-center"
  @small "text-[13px] leading-[18px]"

  # code => {tone, icon}; the texts (label, title, description) are `error_page.<code>.*` in I18n
  @defaults %{
    "404" => {"neutral", "search"},
    "500" => {"error", "alert"},
    "403" => {"warning", "lock"},
    "401" => {"accent", "lock"},
    "419" => {"accent", "refresh"},
    "429" => {"warning", "timer"},
    "503" => {"accent", "alert"},
    "OFF" => {"warning", "wifi"}
  }
  @fallback {"error", "alert"}

  defp blank?(slot), do: LedgerUI.Components.Modal.Support.blank?(slot)

  defp defaults(code, locale \\ nil) do
    key = to_string(code)

    {tone, icon} = Map.get(@defaults, key, @fallback)
    k = if Map.has_key?(@defaults, key), do: String.downcase(key), else: "fallback"

    {tone, icon, I18n.t("error_page.#{k}.label", locale), I18n.t("error_page.#{k}.title", locale),
     I18n.t("error_page.#{k}.description", locale)}
  end

  @doc false
  def tone_for(code), do: elem(defaults(code), 0)

  attr :code, :any, required: true
  attr :tone, :string, default: nil, values: [nil, "", "neutral", "error", "warning", "accent"]
  attr :label, :string, default: nil
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :request_id, :string, default: nil
  attr :request_id_label, :string, default: nil
  attr :copy_label, :string, default: nil
  attr :copy, :boolean, default: true
  attr :back_label, :string, default: nil

  attr :back_href, :string,
    default: "/",
    doc: "Where the back link goes without JS (or with no history to go back to)."

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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def error_page(assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        request_id_label: "error_page.request_id",
        copy_label: "error_page.copy_id"
      )

    {tone, _icon, label, title, description} = defaults(assigns.code, assigns.locale)
    tone = if assigns.tone in [nil, ""], do: tone, else: assigns.tone

    assigns =
      assigns
      |> assign(:tone_cls, @tones[tone])
      |> assign(:tone_name, tone)
      |> assign(:label_t, assigns.label || label)
      |> assign(:title_t, assigns.title || title)
      |> assign(:description_t, assigns.description || description)
      |> assign(:dots, @status_dot)
      |> assign(:row, @row)
      |> assign(:small, @small)
      |> assign(
        :back_cls,
        LedgerUI.Components.Button.classes("neutral", "outline", "md", "rounded")
      )

    # The default texts come from the locale: they are sent every time. The classes are not.
    assigns =
      settle(assigns, changed0,
        tone_cls: [:code, :tone],
        tone_name: [:code, :tone],
        dots: [],
        row: [],
        small: [],
        back_cls: []
      )

    ~H"""
    <main
      id={@id}
      data-part="error-page"
      data-tone={@tone_name}
      class={[
        "flex min-h-screen flex-col bg-page text-ink",
        @tone_cls,
        @class
      ]}
      aria-labelledby={@id <> "-title"}
      {@rest}
    >
      <header
        :if={@brand != [] or @status != []}
        data-part="error-header"
        class="flex items-center justify-between gap-4 px-8 py-5 max-md:px-4"
      >
        <div data-part="error-brand" class={[@row, "gap-2"]}>{render_slot(@brand)}</div>
        <a
          :for={s <- @status}
          data-part="error-status"
          class={[@row, @small, "gap-2 text-muted no-underline"]}
          href={s[:href]}
        >
          <span
            data-part="error-status-dot"
            class={[
              "inline-block size-[7px] flex-none rounded-full bg-current",
              @dots[s[:status] || "ok"] || "text-pos"
            ]}
          ></span>{render_slot(s)}
        </a>
      </header>
      <div
        data-part="error-body"
        class="mx-auto grid w-full max-w-[1200px] flex-1 grid-cols-[repeat(auto-fit,minmax(320px,1fr))] items-center gap-12 p-8"
      >
        <div data-part="error-main" class="flex flex-col items-start gap-3.5">
          <span data-part="error-heading" class={[@row, @small, "gap-2"]}>
            <span
              data-part="error-code"
              class="inline-flex h-[22px] items-center gap-[5px] rounded-sm bg-sunken px-2 font-mono text-xs leading-none font-medium whitespace-nowrap text-(--tone) tabular-nums"
            >{@code}</span>
            <span data-part="error-label" class="text-muted">{@label_t}</span>
          </span>
          <h1
            id={@id <> "-title"}
            data-part="error-title"
            class="m-0 text-[36px] leading-[1.1] font-bold tracking-[-.02em] max-md:text-[28px]"
          >
            {@title_t}
          </h1>
          <p data-part="error-description" class="m-0 max-w-[460px] text-muted">{@description_t}</p>
          <div
            :if={@actions != [] || @back_label}
            data-part="error-actions"
            class={[@row, "mt-1.5 gap-2.5"]}
          >
            {render_slot(@actions)}
            <a
              :if={@back_label}
              href={@back_href}
              data-part="error-back"
              data-lu-back
              class={@back_cls}
            >
              {@back_label}
            </a>
          </div>
          {render_slot(@inner_block)}
        </div>
        <aside
          aria-hidden="true"
          data-part="error-art"
          class="relative grid min-h-80 place-items-center overflow-hidden rounded-2xl bg-tray bg-[radial-gradient(var(--lu-line-strong)_1px,transparent_1px)] bg-[size:18px_18px]"
        >
          <span
            data-part="error-numeral"
            class="font-mono text-[230px] leading-none font-bold tracking-[-.06em] text-transparent opacity-55 [-webkit-text-stroke:1.5px_var(--tone)]"
          >
            {@code}
          </span>
          <div :if={@card != []} data-part="error-card" class="absolute inset-x-6 bottom-6">
            {render_slot(@card)}
          </div>
        </aside>
      </div>
      <footer
        :if={@request_id || @timestamp || @footer != []}
        data-part="error-footer"
        class={[
          @row,
          @small,
          "justify-between gap-4 border-t border-line px-8 py-4 text-muted max-md:px-4"
        ]}
      >
        <span data-part="error-request" class={[@row, "gap-2"]}>
          <span :if={@request_id} data-part="error-request-id">
            {@request_id_label}: <code class="font-mono select-all">{@request_id}</code>
          </span>
          <button
            :if={@request_id && @copy}
            type="button"
            data-part="error-copy"
            class="[:root:not([data-lu-js])_&]:hidden inline-flex size-[30px] cursor-pointer items-center justify-center rounded-[8px] border border-transparent bg-transparent p-0 text-ink-2 hover:bg-hover hover:text-ink"
            aria-label={@copy_label}
            data-copy={@request_id}
            data-lu-error-copy={@request_id}
          >
            <.icon name="copy" size="md" />
          </button>
          <span :if={@timestamp} data-part="error-timestamp">{@timestamp}</span>
        </span>
        <span data-part="error-links-footer" class={[@row, "gap-3"]}>{render_slot(@footer)}</span>
      </footer>
    </main>
    """
  end

  attr :code, :any, required: true
  attr :tone, :string, default: nil, values: [nil, "", "neutral", "error", "warning", "accent"]
  attr :icon, :string, default: nil

  attr :compact, :boolean,
    default: false,
    doc:
      "The small one: a 72px number in a gradient (ink to line), no icon tile; only the code, the title and the description."

  attr :float, :boolean, default: false, doc: "The code floats up and down (4s loop)."
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :inner_block, doc: "The description, instead of `description`."
  slot :more, doc: "Under the actions, full width."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def error_state(assigns) do
    changed0 = assigns.__changed__
    {tone, icon, _label, title, description} = defaults(assigns.code, assigns.locale)
    tone = if assigns.tone in [nil, ""], do: tone, else: assigns.tone
    title_id = (assigns.id || "err-#{assigns.code}") <> "-title"

    assigns =
      assigns
      |> assign(:tone_cls, @tones[tone])
      |> assign(:icon_t, assigns.icon || icon)
      |> assign(:title_t, assigns.title || title)
      |> assign(:description_t, assigns.description || description)
      |> assign(:title_id, title_id)
      |> assign(:row, @row)
      |> assign(
        :code_cls,
        cx([
          if(assigns.compact,
            do:
              "text-[72px] bg-linear-to-b from-ink to-line-strong bg-clip-text text-transparent",
            else: "text-[150px] text-(--tone)"
          ),
          "leading-none font-bold tracking-[-.05em]",
          assigns.float && "animate-[mo-float_4s_ease-in-out_infinite]"
        ])
      )

    assigns =
      settle(assigns, changed0,
        tone_cls: [:code, :tone],
        icon_t: [:icon, :code],
        title_id: [:id, :code],
        row: [],
        code_cls: [:compact, :float]
      )

    ~H"""
    <section
      data-part="error-state"
      class={["flex flex-col items-center gap-2 p-5 text-center", @tone_cls, @class]}
      aria-labelledby={@title_id}
      {@rest}
    >
      <span
        data-part="error-state-code"
        class={@code_cls}
        aria-hidden="true"
      >
        {@code}
      </span>
      <.icon :if={!@compact} name={@icon_t} boxed box_size="lg" />
      <b id={@title_id} data-part="error-state-title">{@title_t}</b>
      <span data-part="error-state-description" class="text-[13px] leading-[18px] text-muted">
        {if blank?(@inner_block), do: @description_t, else: render_slot(@inner_block)}
      </span>
      <div :if={@actions != []} data-part="error-state-actions" class={[@row, "mt-1.5 gap-2.5"]}>
        {render_slot(@actions)}
      </div>
      <div :if={@more != []} data-part="error-state-more" class="mt-3 w-full">
        {render_slot(@more)}
      </div>
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

  @link_cls "flex flex-wrap items-center gap-3 rounded-lg border border-line bg-panel px-3 py-2.5 text-inherit no-underline"

  def error_links(assigns) do
    changed0 = assigns.__changed__
    assigns = settle(assign(assigns, :link_cls, @link_cls), changed0, link_cls: [])

    ~H"""
    <nav
      data-part="error-links"
      aria-label={@title}
      class={["flex w-full max-w-[460px] flex-col gap-1.5", @class]}
      {@rest}
    >
      <span
        :if={@title}
        data-part="error-links-title"
        class="text-xs uppercase tracking-[.06em] text-muted"
      >
        {@title}
      </span>
      <%= for l <- @link do %>
        <.link :if={l[:navigate]} navigate={l[:navigate]} data-part="error-link" class={@link_cls}>
          {link_body(l, render_slot(l))}
        </.link>
        <.link :if={!l[:navigate]} href={l[:href] || "#"} data-part="error-link" class={@link_cls}>
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
    <span data-part="error-link-text" class="flex min-w-0 flex-1 flex-col gap-0">
      <b>{@label}</b>
      <span :if={@l[:description]} data-part="error-link-description" class="text-xs text-muted">{@l[
        :description
      ]}</span>
    </span>
    <.icon name="chevron-right" size="sm" />
    """
  end
end
