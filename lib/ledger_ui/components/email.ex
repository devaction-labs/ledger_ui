defmodule LedgerUI.Components.Email do
  @moduledoc """
  Ledger UI's transactional e-mail: one layout for the e-mails a system sends (a sign-in code, a reset
  link, an order update): the logo, a card with an icon badge, an eyebrow, a title, text, a block of
  code, facts or steps, a main button with its address spelled out, a note and a footer. 520px wide.

      <.email_layout subject="Your code" preheader="Valid for 10 minutes" brand="Acme"
                     logo_url="https://acme.com/logo.png" eyebrow="Confirm your access" title="Your verification code">
        <:body>
          <.email_p>Hi <b>Ana</b>. Type this code on the sign-in screen.</.email_p>
          <.email_code value="482913" />
        </:body>
        <:action href="https://app.acme.com/confirm?token=7f3a9c">Sign in</:action>
        <:note>Not you? Ignore this e-mail.</:note>
        <:footer>Acme Ltda</:footer>
      </.email_layout>

  It renders a whole HTML document built for mail clients: tables for the structure, every style inline,
  web-safe font stacks, no script. The only `<style>` carries the resets, the mobile padding and the
  dark mode: with `theme={:auto}` (the default) the e-mail follows `prefers-color-scheme`; `:light` and
  `:dark` fix it. Every color is also on a hook class (`em-*`) that the dark block overrides with
  `!important`. Icons and logos are images with an absolute URL.

  Deliver it as the `html_body` of your mailer (`Phoenix.HTML.Safe.to_iodata/1` of the rendered
  component). The helpers (`email_p/1`, `email_code/1`, `email_facts/1`, `email_steps/1`) draw the
  light palette; with a fixed `theme={:dark}` layout pass `theme={:dark}` to them too.

  ## `variant="preview"`

  The default `variant="document"` is the mail document above. `variant="preview"` is the canvas picture of
  an e-mail for the documentation and the showcase: a page fragment (not a document, no tables) with a
  tray background, a panel with the brand mark and `brand`, the `title`, the `:body`, the `:action` as a
  primary button, a line and the `:footer` in small muted text. It is styled with Tailwind utilities
  and the theme tokens, so it follows the theme of the page; do not send it as an e-mail.

  ## Inline styles on purpose

  The `document` variant is the one exception to "only utilities": a mail client does not load a
  stylesheet built by Tailwind and many ignore classes, so the structure is tables, every colour is
  an inline hex (a fixed light and dark palette, not the page tokens) and the only `<style>` carries
  the resets, the mobile padding and the dark mode. This is a rule of the medium, not of the kit.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Button, only: [button: 1]

  @light %{
    bg: "#f4f4f2",
    card: "#ffffff",
    ink: "#141514",
    text: "#3b3d3b",
    muted: "#6b6e6b",
    line: "#e6e6e3",
    panel: "#f4f4f2",
    accent: "#1f9282",
    on_accent: "#ffffff"
  }
  @dark %{
    bg: "#0e100f",
    card: "#1b1e1d",
    ink: "#f2f3f2",
    text: "#c9cdca",
    muted: "#8d928f",
    line: "#2a2e2c",
    panel: "#161918",
    accent: "#2fa792",
    on_accent: "#0e100f"
  }
  @font "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif"
  @mono "ui-monospace,SFMono-Regular,Menlo,Consolas,monospace"

  defp pal(:dark), do: @dark
  defp pal(_), do: @light

  @dark_css """
  @media (prefers-color-scheme: dark){
  .em-bg{background:#0e100f!important}.em-card{background:#1b1e1d!important;border-color:#2a2e2c!important}
  .em-ink{color:#f2f3f2!important}.em-text{color:#c9cdca!important}.em-muted{color:#8d928f!important}
  .em-line{border-color:#2a2e2c!important}.em-panel{background:#161918!important;border-color:#2a2e2c!important}
  .em-accent{background:#2fa792!important;color:#0e100f!important}.em-accent-text{color:#2fa792!important}
  .em-box{background:#161918!important;border-color:#2a2e2c!important;color:#f2f3f2!important}
  .em-logo-light{display:none!important}.em-logo-dark{display:inline-block!important}
  .em-btn-ink{background:#f2f3f2!important;color:#141514!important}
  }
  """

  attr :subject, :string, required: true
  attr :preheader, :string, default: nil
  attr :brand, :string, default: nil
  attr :logo_url, :string, default: nil
  attr :logo_dark_url, :string, default: nil
  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]

  attr :lang, :string,
    default: nil,
    doc: "The `lang` of the document; default: the locale (`en`, `pt-BR`)."

  attr :alt_text, :any,
    default: :default,
    doc:
      "The line before the button's address; `nil`/`false` for none, `:default` for the locale's text."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :button, :string, default: "accent", values: ~w(accent ink)
  attr :footer_style, :string, default: "panel", values: ~w(panel plain)
  attr :title_size, :integer, default: 22
  attr :compact, :boolean, default: false

  attr :variant, :string,
    default: "document",
    values: ~w(document preview),
    doc: "`preview` is the canvas picture of an e-mail (a page fragment, not for sending)."

  slot :action do
    attr :href, :string, required: true
  end

  slot :badge
  slot :body, required: true
  slot :footer

  slot :note do
    attr :icon, :string
  end

  slot :secondary do
    attr :href, :string
  end

  def email_layout(%{variant: "preview"} = assigns) do
    assigns = email_texts(assigns)
    assigns = assign(assigns, :action, List.first(assigns.action))

    ~H"""
    <div data-part="email-preview" class="rounded-xl bg-shell p-6">
      <div
        data-part="email-preview-card"
        class="mx-auto flex max-w-[560px] flex-col gap-4 rounded-lg border border-line bg-panel p-7"
      >
        <div :if={@brand} data-part="email-preview-brand" class="flex flex-wrap items-center gap-2.5">
          <span
            data-part="email-preview-logo"
            class="grid size-7 place-items-center rounded-[8px] bg-inverse text-on-inverse"
          >
            <svg
              aria-hidden="true"
              class="size-[18px] fill-none stroke-current stroke-2 [stroke-linecap:round] [stroke-linejoin:round]"
              viewBox="0 0 24 24"
            >
              <path d="M4 19V5"></path>
              <path d="M4 19h16"></path>
              <path d="m8 14 3.5-4 3 2.5L19 7"></path>
            </svg>
          </span><b>{@brand}</b>
        </div>
        <div data-part="email-preview-title" class="text-[24px] font-semibold tracking-[-.02em]">
          {@title}
        </div>
        {render_slot(@body)}
        <.button :if={@action} canvas appearance="primary" size="lg">{render_slot(@action)}</.button>
        <hr :if={@footer != []} data-part="email-preview-line" class="m-0 h-px border-0 bg-line" />
        <span
          :if={@footer != []}
          data-part="email-preview-footer"
          class="text-xs leading-4 text-muted"
        >
          {render_slot(@footer)}
        </span>
      </div>
    </div>
    """
  end

  def email_layout(assigns) do
    assigns = email_texts(assigns)

    p = pal(assigns.theme)
    outer = if assigns.compact, do: 20, else: 32
    inner = if assigns.compact, do: 22, else: 32

    assigns =
      assigns
      |> assign(:p, p)
      |> assign(:font, @font)
      |> assign(:mono, @mono)
      |> assign(:outer, outer)
      |> assign(:inner, inner)
      |> assign(:dark_css, if(assigns.theme == :auto, do: @dark_css, else: ""))
      |> assign(:color_scheme, color_scheme(assigns.theme))
      |> assign(:action, List.first(assigns.action))
      |> assign(:dark_logo?, assigns.theme == :dark)

    ~H"""
    <!DOCTYPE html>
    <html lang={@lang} xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="color-scheme" content={@color_scheme} />
        <meta name="supported-color-schemes" content={@color_scheme} />
        <title>{@subject}</title>
        <style>
          body{margin:0;padding:0;-webkit-text-size-adjust:100%}table{border-collapse:collapse}img{border:0;display:block}
          .em-logo-dark{display:none}
          @media (max-width:560px){.em-pad{padding:20px 16px!important}.em-card-in{padding:22px 18px!important}}
          <%= Phoenix.HTML.raw(@dark_css) %>
        </style>
      </head>
      <body class="em-bg" style={"margin:0;padding:0;background:#{@p.bg};font-family:#{@font}"}>
        <div
          :if={@preheader}
          style="display:none;max-height:0;overflow:hidden;opacity:0;font-size:1px;line-height:1px"
        >
          {@preheader}
        </div>
        <table
          role="presentation"
          width="100%"
          cellpadding="0"
          cellspacing="0"
          class="em-bg"
          style={"background:#{@p.bg}"}
        >
          <tr>
            <td align="center" class="em-pad" style={"padding:#{@outer}px 16px"}>
              <table
                role="presentation"
                width="520"
                cellpadding="0"
                cellspacing="0"
                style="width:100%;max-width:520px"
              >
                <tr :if={@logo_url || @brand}>
                  <td style="padding:0 0 16px 4px">
                    <table role="presentation" cellpadding="0" cellspacing="0">
                      <tr>
                        <td :if={@logo_url} style="padding-right:10px">
                          <img
                            :if={!@dark_logo? or !@logo_dark_url}
                            class="em-logo-light"
                            src={@logo_url}
                            alt={@brand || ""}
                            height="28"
                            style="height:28px;width:auto"
                          />
                          <img
                            :if={@logo_dark_url}
                            class="em-logo-dark"
                            src={@logo_dark_url}
                            alt={@brand || ""}
                            height="28"
                            style={"height:28px;width:auto;#{if @dark_logo?, do: "display:inline-block", else: "display:none"}"}
                          />
                        </td>
                        <td
                          :if={@brand}
                          class="em-ink"
                          style={"font-family:#{@font};font-size:16px;font-weight:700;color:#{@p.ink}"}
                        >
                          {@brand}
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td
                    class="em-card em-card-in"
                    style={"background:#{@p.card};border:1px solid #{@p.line};border-radius:16px;padding:#{@inner}px"}
                  >
                    <div
                      :if={@badge != []}
                      style={"width:48px;height:48px;border-radius:12px;background:#{@p.panel};margin-bottom:16px;text-align:center"}
                      class="em-panel"
                    >
                      <div style="padding-top:12px;display:inline-block">{render_slot(@badge)}</div>
                    </div>
                    <div
                      :if={@eyebrow}
                      class="em-accent-text"
                      style={"font-family:#{@font};font-size:12px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;color:#{@p.accent};margin-bottom:6px"}
                    >
                      {@eyebrow}
                    </div>
                    <h1
                      class="em-ink"
                      style={"margin:0 0 12px;font-family:#{@font};font-size:#{@title_size}px;line-height:1.25;font-weight:600;color:#{@p.ink}"}
                    >
                      {@title}
                    </h1>
                    {render_slot(@body)}
                    <table
                      :if={@action}
                      role="presentation"
                      cellpadding="0"
                      cellspacing="0"
                      style="margin-top:22px"
                    >
                      <tr>
                        <td>
                          <a
                            href={@action.href}
                            class={if @button == "ink", do: "em-btn-ink", else: "em-accent"}
                            {style_attr(button_style(@button, @p, @font))}
                          >
                            {render_slot(@action)}{if @button == "accent", do: " →"}
                          </a>
                        </td>
                        <td :for={s <- @secondary} style="padding-left:10px">
                          <a
                            href={s[:href]}
                            class="em-box"
                            style={"display:inline-block;padding:12px 20px;border:1px solid #{@p.line};border-radius:#{if @button == "ink", do: 999, else: 10}px;font-family:#{@font};font-size:14px;font-weight:600;color:#{@p.ink};text-decoration:none"}
                          >
                            {render_slot(s)}
                          </a>
                        </td>
                      </tr>
                    </table>
                    <div
                      :if={@action && @alt_text}
                      class="em-muted"
                      style={"margin-top:16px;font-family:#{@font};font-size:12.5px;line-height:1.5;color:#{@p.muted}"}
                    >
                      {@alt_text}<br />
                      <a
                        href={@action.href}
                        class="em-accent-text"
                        style={"color:#{@p.accent};word-break:break-all"}
                      >{@action.href}</a>
                    </div>
                    <div
                      :for={n <- @note}
                      class="em-panel"
                      style={"margin-top:20px;padding:12px 14px;border-radius:10px;background:#{@p.panel};font-family:#{@font};font-size:12.5px;line-height:1.5;color:#{@p.muted}"}
                    >
                      <img
                        :if={n[:icon]}
                        src={n.icon}
                        width="16"
                        height="16"
                        alt=""
                        style="display:inline-block;vertical-align:-3px;margin-right:6px"
                      />{render_slot(n)}
                    </div>
                  </td>
                </tr>
                <tr :if={@footer != []}>
                  <td
                    class={if @footer_style == "panel", do: "em-panel em-muted", else: "em-muted"}
                    {style_attr(footer_style(@footer_style, @p, @font))}
                  >
                    {render_slot(@footer)}
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  defp color_scheme(:auto), do: "light dark"
  defp color_scheme(:light), do: "light"
  defp color_scheme(:dark), do: "dark"

  defp button_style("ink", p, font),
    do:
      "display:inline-block;padding:12px 24px;border-radius:999px;background:#{p.ink};color:#{p.card};font-family:#{font};font-size:14px;font-weight:600;text-decoration:none"

  defp button_style(_, p, font),
    do:
      "display:inline-block;padding:12px 22px;border-radius:10px;background:#{p.accent};color:#{p.on_accent};font-family:#{font};font-size:14px;font-weight:600;text-decoration:none"

  defp footer_style("plain", p, font),
    do:
      "padding:16px 8px 0;text-align:center;font-family:#{font};font-size:12px;line-height:1.5;color:#{p.muted}"

  defp footer_style(_, p, font),
    do:
      "margin-top:16px;padding:16px;border-radius:12px;background:#{p.panel};font-family:#{font};font-size:12px;line-height:1.5;color:#{p.muted};display:block"

  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]
  attr :muted, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A paragraph of the e-mail body, styled for mail clients."
  def email_p(assigns) do
    p = pal(assigns.theme)

    assigns =
      assigns
      |> assign(:style, p_style(assigns.muted, p))
      |> assign(:cls, if(assigns.muted, do: "em-muted", else: "em-text"))

    ~H"""
    <p class={@cls} {style_attr(@style)} {@rest}>{render_slot(@inner_block)}</p>
    """
  end

  defp p_style(true, p),
    do: "margin:0 0 14px;font-family:#{@font};font-size:13.5px;line-height:1.55;color:#{p.muted}"

  defp p_style(false, p),
    do: "margin:0 0 14px;font-family:#{@font};font-size:15px;line-height:1.6;color:#{p.text}"

  attr :value, :string, required: true
  attr :hint, :string, default: nil
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]

  @doc "A verification code, one box per character."
  def email_code(assigns) do
    p = pal(assigns.theme)

    assigns =
      assign(assigns, p: p, chars: String.graphemes(assigns.value), font: @font, mono: @mono)

    ~H"""
    <div
      :if={@hint}
      class="em-muted"
      style={"margin:4px 0 8px;font-family:#{@font};font-size:13px;color:#{@p.muted}"}
    >
      {@hint}
    </div>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:8px 0 18px">
      <tr>
        <td
          :for={c <- @chars}
          class="em-box"
          align="center"
          style={"width:42px;height:52px;padding:0;margin:0 4px;border:1px solid #{@p.line};border-radius:10px;background:#{@p.panel};font-family:#{@mono};font-size:24px;font-weight:600;color:#{@p.ink}"}
        >
          {c}
        </td>
      </tr>
    </table>
    """
  end

  attr :rows, :list, required: true
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]
  attr :variant, :string, default: "panel", values: ~w(panel table)
  attr :header, :any, default: nil

  @doc "Rows of label and value: `{label, value}`, `{label, value, :mono}` or `{label, value, :total}`."
  def email_facts(assigns) do
    assigns = assign(assigns, p: pal(assigns.theme), font: @font, mono: @mono)

    ~H"""
    <table
      role="presentation"
      width="100%"
      cellpadding="0"
      cellspacing="0"
      class={@variant == "panel" && "em-panel"}
      {style_attr(if @variant == "panel",
          do: "margin:6px 0 16px;background:#{@p.panel};border-radius:12px",
          else: "margin:6px 0 16px")}
    >
      <tr :if={@header}>
        <td
          class="em-muted"
          style={"padding:8px 14px;font-family:#{@font};font-size:11.5px;color:#{@p.muted}"}
        >
          {elem(@header, 0)}
        </td>
        <td
          class="em-muted"
          align="right"
          style={"padding:8px 14px;font-family:#{@font};font-size:11.5px;color:#{@p.muted}"}
        >
          {elem(@header, 1)}
        </td>
      </tr>
      <tr :for={row <- @rows}>
        <td class="em-text em-line" {style_attr(fact_cell(row, @variant, @p, @font, false))}>
          {elem(row, 0)}
        </td>
        <td
          class="em-ink em-line"
          align="right"
          {style_attr(fact_cell(row, @variant, @p, @font, true) <> mono_style(row, @mono))}
        >
          {elem(row, 1)}
        </td>
      </tr>
    </table>
    """
  end

  defp fact_cell(row, variant, p, font, value?) do
    total? = tuple_size(row) > 2 and elem(row, 2) == :total
    border = if variant == "table", do: "border-top:1px solid #{p.line};", else: ""
    color = if value? or total?, do: p.ink, else: p.text
    weight = if total?, do: 700, else: if(value?, do: 600, else: 400)

    "padding:10px 14px;#{border}font-family:#{font};font-size:14px;font-weight:#{weight};color:#{color};"
  end

  defp mono_style(row, mono) when tuple_size(row) > 2 and elem(row, 2) == :mono,
    do: "font-family:#{mono};"

  defp mono_style(_, _), do: ""

  attr :steps, :list, required: true
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]

  @doc "A row of steps: `{label, done?}` pairs, in order. Done ones are filled with a check."
  def email_steps(assigns) do
    assigns = assign(assigns, p: pal(assigns.theme), font: @font)

    ~H"""
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:8px 0 18px">
      <tr>
        <td
          :for={{label, done} <- @steps}
          align="center"
          style={"font-family:#{@font};font-size:12px;color:#{if done, do: @p.ink, else: @p.muted}"}
        >
          <div
            class={if done, do: "em-accent", else: "em-box"}
            style={"width:26px;height:26px;line-height:26px;border-radius:13px;margin:0 auto 6px;font-size:13px;font-weight:700;text-align:center;#{if done, do: "background:#{@p.accent};color:#{@p.on_accent}", else: "background:#{@p.panel};border:1px solid #{@p.line};color:#{@p.muted}"}"}
          >
            {if done, do: "✓", else: "·"}
          </div>
          {label}
        </td>
      </tr>
    </table>
    """
  end

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]

  defp email_texts(assigns) do
    locale = I18n.locale(assigns.locale)

    assigns
    |> Map.put(:locale, locale)
    |> Map.update!(:lang, &(&1 || if(locale == "pt_BR", do: "pt-BR", else: "en")))
    |> Map.update!(:alt_text, fn
      :default -> I18n.t("email.alt", locale)
      other -> other
    end)
  end
end
