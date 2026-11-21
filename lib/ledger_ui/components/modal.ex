defmodule LedgerUI.Components.Modal.Support do
  @moduledoc false
  # Small helpers shared by the overlay components of group 12 (modal, drawer, popover,
  # tooltip, command palette, notification center, collapse). Not public API.

  # The floating box of a tooltip / popover / notification panel: placed next to its anchor by the
  # `data-lu-placement` the `LedgerUI.Float` hook keeps (it flips it when there is no room). The centring
  # uses `transform`, since the hook animates the separate `translate` property.
  @float "absolute z-[4] whitespace-nowrap " <>
           "data-[lu-placement^=top]:bottom-[calc(100%+8px)] data-[lu-placement^=bottom]:top-[calc(100%+8px)] " <>
           "data-[lu-placement=top]:left-1/2 data-[lu-placement=top]:[transform:translateX(-50%)] " <>
           "data-[lu-placement=bottom]:left-1/2 data-[lu-placement=bottom]:[transform:translateX(-50%)] " <>
           "data-[lu-placement=top-start]:left-0 data-[lu-placement=bottom-start]:left-0 " <>
           "data-[lu-placement=top-end]:right-0 data-[lu-placement=bottom-end]:right-0 " <>
           "data-[lu-placement^=left]:right-[calc(100%+8px)] data-[lu-placement^=right]:left-[calc(100%+8px)] " <>
           "data-[lu-placement=left]:top-1/2 data-[lu-placement=left]:[transform:translateY(-50%)] " <>
           "data-[lu-placement=right]:top-1/2 data-[lu-placement=right]:[transform:translateY(-50%)] " <>
           "data-[lu-placement=left-start]:top-0 data-[lu-placement=right-start]:top-0 " <>
           "data-[lu-placement=left-end]:bottom-0 data-[lu-placement=right-end]:bottom-0"
  @doc "Utilities of the floating box (see `data-lu-placement`)."
  def float_class, do: @float

  @doc "`\"true\"`/`\"false\"` for the `data-lu-*` flags the hooks read."
  def flag(v), do: if(v, do: "true", else: "false")

  @doc "Joins inline style fragments, dropping empties."
  def style(parts) do
    parts
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, false, ""]))
    |> Enum.map(&String.trim_trailing(&1, ";"))
    |> case do
      [] -> nil
      list -> Enum.join(list, ";")
    end
  end

  @doc """
  `{text, slot, rest}` of a component whose `title` is both: the `<:title>` slot (a list) and the
  `title="..."` string (that Phoenix leaves in the assigns, and in `rest`, as it is a global attribute).
  """
  def split_title(assigns) do
    {from_rest, rest} = Map.pop(assigns.rest, :title)

    case assigns[:title] do
      list when is_list(list) -> {from_rest, list, rest}
      text when is_binary(text) -> {text, [], rest}
      _ -> {from_rest, [], rest}
    end
  end

  @doc """
  True when the default slot has no content. A component call with only named slots still gets
  an `inner_block` holding whitespace, so look inside.
  """
  def blank?([]), do: true

  def blank?([%{inner_block: inner}]) do
    case inner do
      %Phoenix.LiveView.Rendered{static: static, dynamic: dynamic} when is_function(dynamic, 1) ->
        Enum.all?(static, &(String.trim(&1) == "")) and dynamic.(false) == []

      _ ->
        false
    end
  end

  def blank?(_), do: false

  @doc "Attribute map for an inline style: `%{}` when empty (`style={nil}` would render `style=\"\"`)."
  def st(nil), do: %{}
  def st(""), do: %{}
  def st(style) when is_binary(style), do: %{"style" => style}

  @doc "`nil` when the class string is empty (no `class=\"\"` in the HTML)."
  def class(str) when str in [nil, ""], do: nil
  def class(str), do: str

  @doc """
  Hook configuration attributes (`data-lu-*`, read by the hooks in `priv/static/ledger_ui/hooks`).
  `nil` values are dropped by the template engine.
  """
  def cfg(kind, pairs) do
    Map.new([
      {"data-lu-kind", kind} | Enum.map(pairs, fn {k, v} -> {"data-lu-" <> to_string(k), v} end)
    ])
  end

  @doc "`on_*` attrs: an event name (string) or a `%JS{}`; both are read by the hook."
  def handler(nil), do: nil
  def handler(v) when is_binary(v), do: v
  def handler(%Phoenix.LiveView.JS{} = js), do: js
end

defmodule LedgerUI.Components.Modal do
  @moduledoc """
  Modal dialog for short tasks and confirmations (`<.modal>`).

      <.button phx-click={LedgerUI.open("export")}>Export</.button>

      <.modal id="export" title="Export report" description="October 2026" icon="download" size="sm">
        <p>Choose a format.</p>
        <:footer>
          <.button variant="ghost" phx-click={LedgerUI.close("export")}>Cancel</.button>
          <.button variant="primary">Export</.button>
        </:footer>
      </.modal>

  The title is either `title="Export report"` or the `<:title>` slot (markup); the footer is `<:footer>`
  or `<:actions>`; `show` is `open` under the name of Phoenix's generated `modal`.

  It opens and closes in the browser (`LedgerUI.open/close/toggle("export")`, no round trip),
  from the server (`LedgerUI.open(socket, "export")`) or from the `open` assign. The
  `LedgerUI.Overlay` hook (`priv/static/ledger_ui/hooks/overlay.js`) keeps the focus inside, closes on
  Esc and on a click on the backdrop (unless `prevent_close`), returns the focus to the trigger and
  locks the page's scroll. `on_open` / `on_close` run however it opened or closed; as event names
  they push `%{"id" => id}` to the LiveView (or `target`).

  The root carries `data-lu-overlay`: use `LedgerUI.DOM.onBeforeElUpdated` (see the README) so patches
  keep the browser's state.

  `inline` renders the dialog in the page flow, always visible and without the hook: a static preview.

  `layout="page"` is the dialog of the app templates: only while `open`, a dim `lu-overlay` and a
  `div.lu-modal` (`header`, `.bd`, `footer`) laid over the closest positioned ancestor, no hook;
  the page owns the state and the overlay, Esc and × push `on_close`. The `:header` slot is then
  the content before the ×. With `phx-submit` or `phx-change` in the attributes the dialog itself
  is a `<form>` (so its controls validate and submit); `phx-target` goes to the form.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  # width of the card (px) and the placement of the dialog in its backdrop
  @sizes %{
    "xs" => "w-[320px] rounded-[18px]",
    "sm" => "w-[620px] rounded-[18px]",
    "md" => "w-[560px] rounded-[18px]",
    "lg" => "w-[720px] rounded-[18px]",
    "xl" => "w-[960px] rounded-[18px]",
    "full" => "h-full w-full rounded-none"
  }
  @align %{"top" => "items-start", "center" => "items-center", "bottom" => "items-end"}
  @tones %{
    "neutral" => "neutral",
    "accent" => "acc",
    "success" => "pos",
    "error" => "neg",
    "warning" => "warn",
    "info" => "info",
    "lime" => "lime"
  }

  # the backdrop: closed = `hidden`; open (the `open` class LedgerUI.open sets, or data-state="open") and
  # closing (the hook plays the leave animation while it is `closing`) are `flex`
  @scrim_hooked "fixed inset-0 z-[var(--ledger-z-modal,60)] hidden overflow-hidden rounded-none bg-overlay p-7 " <>
                  "data-[state=open]:flex data-[state=closing]:pointer-events-none data-[state=closing]:flex [&.open]:flex"
  @scrim_inline "relative flex justify-center overflow-hidden rounded-lg bg-overlay p-7"

  # the card, as the canvas draws it over its backdrop: centred by `transform` (the hook animates the
  # separate `translate` / `scale` properties, so they compose with it). With only the corner ×
  # (no header) it stays a flex item of the backdrop instead, which centres it.
  @card "absolute left-1/2 z-[41] flex max-h-[calc(100%-64px)] max-w-full flex-col overflow-hidden border border-line bg-panel " <>
          "shadow-[0_30px_80px_rgba(0,0,0,.24),0_2px_8px_rgba(0,0,0,.08)]"

  # where the absolute card sits: centred, or against the top / bottom edge with the 12px margin of the
  # canvas drawers (`placement`); the transform only centres the horizontal axis then
  @card_at %{
    "center" => "top-1/2 [transform:translate(-50%,-50%)]",
    "top" => "top-3 [transform:translate(-50%,0)]",
    "bottom" => "bottom-3 [transform:translate(-50%,0)]"
  }
  @page_card_at %{
    "center" => "top-1/2 [transform:translate(-50%,-50%)_var(--lu-m,)]",
    "top" => "top-3 [transform:translate(-50%,0)_var(--lu-m,)]",
    "bottom" => "bottom-3 [transform:translate(-50%,0)_var(--lu-m,)]"
  }
  @card_corner "relative z-[41] flex max-h-[calc(100%-64px)] max-w-full flex-col overflow-hidden border border-line bg-panel " <>
                 "shadow-[0_30px_80px_rgba(0,0,0,.24),0_2px_8px_rgba(0,0,0,.08)]"

  @header "flex items-start gap-3 px-5 pt-5 pb-1.5"
  @title "m-0 text-[18px]/[26px] font-semibold tracking-[-.01em]"
  @desc "mt-1 mb-0 text-[14px] text-muted"
  @body "flex flex-col gap-3.5 px-5 py-3.5"
  @footer "flex justify-end gap-2 border-t border-line bg-tray px-5 py-3.5"
  @x "ml-auto grid size-8 flex-none cursor-pointer place-items-center rounded-[9px] border-0 bg-transparent text-muted hover:bg-hover hover:text-ink"

  # `layout="page"`: the dialog of the app templates
  @overlay "absolute inset-0 z-40 bg-[rgba(12,14,14,.38)] backdrop-blur-[2px] dark:bg-[rgba(0,0,0,.55)]"
  @page_card "absolute left-1/2 z-[41] flex max-h-[calc(100%-64px)] w-[620px] max-w-full flex-col overflow-hidden rounded-[18px] border border-line bg-panel " <>
               "shadow-[0_30px_80px_rgba(0,0,0,.24),0_2px_8px_rgba(0,0,0,.08)] " <>
               "[&>[data-part=modal-body]>*]:shrink-0"
  @page_header "flex items-start gap-3 px-[22px] pt-5 pb-3.5 [&_h3]:m-0 [&_h3]:font-display [&_h3]:text-[18px] [&_h3]:font-[650] [&_h3]:tracking-[-.02em] " <>
                 "[&_p]:mt-[3px] [&_p]:mb-0 [&_p]:text-[13.5px] [&_p]:text-muted"
  @page_body "flex flex-1 flex-col gap-[18px] overflow-auto px-[22px] pt-1 pb-5"
  @page_footer "flex items-center justify-end gap-2 border-t border-line bg-panel px-[22px] py-3.5"

  # enter / leave of the page dialog (the vitrine's timings): the backdrop fades .22s; the card's opacity
  # takes .2s (ease) and its transform .28s, on cubic-bezier(.2,.8,.2,1). Leaving mirrors entering.
  @fade "transition-opacity duration-200 ease"
  @move "transition-[opacity,transform] duration-[200ms,280ms] ease-[ease,cubic-bezier(.2,.8,.2,1)]"
  @sheet_move "transition-transform duration-[280ms] ease-[cubic-bezier(.2,.8,.2,1)]"
  @motion %{
    "fade" => {@fade, "opacity-0", "opacity-100"},
    "scale" => {@move, "opacity-0 [--lu-m:scale(.9)]", "opacity-100 [--lu-m:scale(1)]"},
    "shift-down" =>
      {@move, "opacity-0 [--lu-m:translateY(-22px)]", "opacity-100 [--lu-m:translateY(0)]"},
    "shift-up" =>
      {@move, "opacity-0 [--lu-m:translateY(22px)]", "opacity-100 [--lu-m:translateY(0)]"},
    "sheet" => {@sheet_move, "[--lu-m:translateY(100vh)]", "[--lu-m:translateY(0)]"}
  }

  attr :id, :string, required: true

  attr :layout, :string,
    default: nil,
    values: [nil, "", "page"],
    doc:
      "`page`: the canvas-v2 dialog (a dim overlay + a dialog with `header`, `.bd`, `footer`), " <>
        "shown only while `open` and closed by `on_close` (a LiveView event or `%JS{}`)."

  attr :open, :boolean,
    default: false,
    doc: "The server's state; the browser can still open and close it."

  attr :show, :boolean,
    default: false,
    doc: "The same as `open` (the name of Phoenix's generated `modal`); either one opens it."

  attr :animation, :string, default: "fade", values: ~w(fade scale sheet shift-down shift-up)
  attr :size, :string, default: "lg", values: ~w(full lg md sm xl xs)
  attr :placement, :string, default: "center", values: ~w(bottom center top)
  attr :origin, :string, default: "center", values: ~w(bottom center top)
  attr :blur, :boolean, default: false
  attr :backdrop_class, :any, default: nil
  attr :prevent_close, :boolean, default: false
  attr :close_button, :boolean, default: true
  attr :close_variant, :string, default: "plain", values: ~w(plain chip)
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :close_label, :string, default: "Close"
  attr :role, :string, default: "dialog", values: ~w(dialog alertdialog)
  attr :description, :string, default: nil
  attr :body_class, :any, default: nil
  attr :class, :any, default: nil, doc: "Merged into the card."
  attr :icon, :string, default: nil, doc: "An icon tile before the title (needs `title`)."
  attr :icon_tone, :string, default: "neutral", values: Map.keys(@tones)

  attr :card_style, :string,
    default: nil,
    doc: "Inline style of the card (overrides the `size` width)."

  attr :inline, :boolean,
    default: false,
    doc: "Static preview: in the page flow, always open, no hook."

  attr :rest, :global

  slot :title,
    doc:
      "The dialog's title (the `title=\"...\"` attribute, a plain string, does the same); draws the header."

  slot :actions, doc: "The footer's buttons; the same as `:footer`."

  slot :header do
    attr :variant, :string
    attr :class, :any
    attr :style, :string
  end

  slot :footer do
    attr :class, :any
    attr :style, :string
  end

  slot :inner_block

  def modal(assigns) do
    # `title` is a slot, and the string form is a global HTML attribute
    {text, slot, rest} = Support.split_title(assigns)

    assigns
    |> assign(:rest, rest)
    |> assign(:title_text, text)
    |> assign(:title, slot)
    |> assign(:titled?, text != nil or slot != [])
    |> assign(:open, assigns.open or assigns.show)
    |> assign(:footer, assigns.footer ++ assigns.actions)
    |> render_modal()
  end

  defp title_text(assigns) do
    ~H"""
    <h3 id={@id} data-part="modal-title" class={@class}>
      {if @title != [], do: render_slot(@title), else: @text}
    </h3>
    """
  end

  defp render_modal(%{layout: "page"} = assigns) do
    form? = Map.has_key?(assigns.rest, :"phx-submit") or Map.has_key?(assigns.rest, :"phx-change")
    {move, from, to} = Map.get(@motion, assigns.animation, @motion["fade"])
    backdrop = @fade <> " duration-[220ms]"

    assigns =
      assigns
      |> assign(:tag, if(form?, do: "form", else: "div"))
      |> assign(:overlay, @overlay)
      |> assign(:page_header, @page_header)
      |> assign(:page_footer, @page_footer)
      |> assign(:x, @x)
      |> assign(:card_class, cx([@page_card, @page_card_at[assigns.placement], assigns.class]))
      |> assign(:body_class_s, cx([@page_body, assigns.body_class]))
      |> assign(
        :enter,
        JS.transition(JS.focus_first(to: "#" <> assigns.id), {move, from, to}, time: 280)
      )
      |> assign(:leave, JS.hide(transition: {move, to, from}, time: 280))
      |> assign(:overlay_enter, JS.transition({backdrop, "opacity-0", "opacity-100"}, time: 220))
      |> assign(
        :overlay_leave,
        JS.hide(transition: {backdrop, "opacity-100", "opacity-0"}, time: 220)
      )

    ~H"""
    <div
      :if={@open}
      data-part="modal-overlay"
      class={@overlay}
      phx-mounted={@overlay_enter}
      phx-remove={@overlay_leave}
      phx-click={@on_close}
      phx-target={@target}
    >
    </div>
    <.dynamic_tag
      :if={@open}
      tag_name={@tag}
      id={@id}
      data-part="modal"
      data-lu-animation={@animation}
      class={@card_class}
      phx-mounted={@enter}
      phx-remove={@leave}
      role={@role}
      aria-modal="true"
      aria-labelledby={@titled? && @id <> "-title"}
      tabindex="-1"
      phx-window-keydown={@on_close}
      phx-key="Escape"
      {@rest}
    >
      <header data-part="modal-header" class={@page_header}>
        <%= if @header == [] do %>
          <div data-part="modal-heading">
            <.title_text id={@id <> "-title"} title={@title} text={@title_text} class={nil} />
            <p :if={@description} data-part="modal-description">{@description}</p>
          </div>
        <% else %>
          <%= for h <- @header do %>
            {render_slot(h)}
          <% end %>
        <% end %>
        <button
          :if={@close_button}
          data-part="modal-close"
          type="button"
          class={@x}
          aria-label={@close_label}
          phx-click={@on_close}
          phx-target={@target}
        >
          <.icon name="x" />
        </button>
      </header>
      <div data-part="modal-body" class={@body_class_s}>{render_slot(@inner_block)}</div>
      <footer :for={f <- @footer} data-part="modal-footer" class={@page_footer}>
        {render_slot(f)}
      </footer>
    </.dynamic_tag>
    """
  end

  defp render_modal(assigns) do
    inline = assigns.inline
    corner? = has_corner?(assigns)

    # ARIA is always rendered (also in the inline preview); only the modal behavior differs.
    card_attrs =
      %{
        "role" => assigns.role,
        "aria-modal" => if(!inline, do: "true"),
        "aria-labelledby" => if(assigns.titled?, do: assigns.id <> "-title"),
        "aria-describedby" =>
          if(assigns.description && assigns.header == [], do: assigns.id <> "-desc"),
        "tabindex" => if(!inline, do: "-1")
      }

    cfg =
      if inline,
        do: %{},
        else:
          Support.cfg("modal",
            animation: assigns.animation,
            origin: assigns.origin,
            open: Support.flag(assigns.open),
            "prevent-close": Support.flag(assigns.prevent_close),
            "lock-scroll": "true",
            "on-open": Support.handler(assigns.on_open),
            "on-close": Support.handler(assigns.on_close),
            target: assigns.target
          )

    assigns =
      assigns
      |> assign(
        :root_class,
        cx([
          if(inline,
            do: @scrim_inline,
            else: [@scrim_hooked, assigns.blur && "backdrop-blur-[4px]"]
          ),
          @align[assigns.placement],
          assigns.backdrop_class
        ])
      )
      |> assign(:state, if(assigns.open, do: "open", else: "closed"))
      |> assign(
        :card_class,
        cx([
          if(corner?, do: @card_corner, else: [@card, @card_at[assigns.placement]]),
          @sizes[assigns.size],
          assigns.class
        ])
      )
      |> assign(:card_attrs, card_attrs)
      |> assign(:header_class, @header)
      |> assign(:title_class, @title)
      |> assign(:desc_class, @desc)
      |> assign(:x_class, @x)
      |> assign(:body_class_s, @body)
      |> assign(:footer_class, @footer)
      |> assign(:cfg, cfg)
      |> assign(:hook, if(inline, do: nil, else: "LedgerUI.Overlay"))
      |> assign(:icon_tone_s, @tones[assigns.icon_tone])
      |> assign(:blank?, Support.blank?(assigns.inner_block))
      |> assign(:corner?, corner?)
      |> assign(:corner_class, corner_class(assigns.close_variant))
      |> assign(:close_js, LedgerUI.close(assigns.id))

    ~H"""
    <div
      id={@id}
      data-part="modal-overlay"
      class={@root_class}
      phx-hook={@hook}
      data-lu-overlay={!@inline && ""}
      data-state={!@inline && @state}
      {@cfg}
      {@rest}
    >
      <div
        data-part="modal"
        class={@card_class}
        {Support.st(@card_style)}
        {@card_attrs}
      >
        <div
          :if={@header != [] or @titled?}
          data-part="modal-header"
          class={cx([@header_class, header_class(@header)])}
          {Support.st(header_style(@header))}
        >
          <.icon :if={@icon} name={@icon} boxed tone={@icon_tone_s} />
          <div :if={@header == []} data-part="modal-heading">
            <.title_text id={@id <> "-title"} title={@title} text={@title_text} class={@title_class} />
            <p
              :if={@description}
              id={@id <> "-desc"}
              data-part="modal-description"
              class={@desc_class}
            >
              {@description}
            </p>
          </div>
          <%= for h <- @header do %>
            {render_slot(h)}
          <% end %>
          <button
            :if={@close_button}
            data-part="modal-close"
            aria-label={@close_label}
            class={@x_class}
            type="button"
            phx-click={@close_js}
          >
            <.icon name="x" size="md" />
          </button>
        </div>
        <button
          :if={@corner?}
          data-part="modal-close"
          aria-label={@close_label}
          class={@corner_class}
          type="button"
          phx-click={@close_js}
        >
          <.icon name="x" size="md" />
        </button>
        <div :if={!@blank?} data-part="modal-body" class={cx([@body_class_s, @body_class])}>
          {render_slot(@inner_block)}
        </div>
        <div
          :for={f <- @footer}
          data-part="modal-footer"
          class={cx([@footer_class, f[:class]])}
          {Support.st(f[:style])}
        >
          {render_slot(f)}
        </div>
      </div>
    </div>
    """
  end

  defp has_corner?(a), do: a.close_button and a.header == [] and not a.titled?

  defp corner_class("chip"),
    do:
      "absolute top-2.5 right-2.5 m-0 grid size-8 flex-none cursor-pointer place-items-center rounded-full border-0 bg-[rgba(0,0,0,.35)] text-white"

  defp corner_class(_),
    do:
      "absolute top-2.5 right-2.5 m-0 grid size-8 flex-none cursor-pointer place-items-center rounded-[9px] border-0 bg-transparent text-muted hover:bg-hover hover:text-ink"

  defp header_class([h | _]), do: h[:class]
  defp header_class(_), do: nil
  defp header_style([h | _]), do: h[:style]
  defp header_style(_), do: nil
end
