defmodule LedgerUI.Components.Modal.Support do
  @moduledoc false
  # Small helpers shared by the overlay components of group 12 (modal, drawer, popover,
  # tooltip, command palette, notification center, collapse). Not public API.

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

  @sizes %{
    "xs" => "width:320px",
    "sm" => nil,
    "md" => "width:560px",
    "lg" => "width:720px",
    "xl" => "width:960px",
    "full" => "width:100%;height:100%;border-radius:0"
  }
  @align %{"top" => "align-items:flex-start", "center" => nil, "bottom" => "align-items:flex-end"}
  @tones %{
    "neutral" => nil,
    "accent" => "acc",
    "success" => "pos",
    "error" => "neg",
    "warning" => "warn",
    "info" => "info",
    "lime" => "lime"
  }
  @fixed "position:fixed;inset:0;z-index:var(--ledger-z-modal,60);border-radius:0"

  attr :id, :string, required: true

  attr :layout, :string,
    default: nil,
    values: [nil, "", "page"],
    doc:
      "`page`: the canvas-v2 dialog (`lu-overlay` + `div.lu-modal` with `header`, `.bd`, `footer`), " <>
        "shown only while `open` and closed by `on_close` (a LiveView event or `%JS{}`)."

  attr :open, :boolean,
    default: false,
    doc: "The server's state; the browser can still open and close it."

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
  attr :title, :string, default: nil
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

  def modal(%{layout: "page"} = assigns) do
    form? = Map.has_key?(assigns.rest, :"phx-submit") or Map.has_key?(assigns.rest, :"phx-change")
    assigns = assign(assigns, :tag, if(form?, do: "form", else: "div"))

    ~H"""
    <div
      :if={@open}
      data-part="modal-overlay"
      class="lu-overlay"
      phx-remove={JS.hide(transition: {"lu-leave", "", ""}, time: 200)}
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
      class={cx(["lu-modal", @class])}
      phx-remove={
        JS.hide(transition: {"lu-leave", "", ""}, time: if(@animation == "sheet", do: 240, else: 160))
      }
      role={@role}
      aria-modal="true"
      aria-labelledby={@title && @id <> "-title"}
      tabindex="-1"
      phx-mounted={JS.focus_first(to: "#" <> @id)}
      phx-window-keydown={@on_close}
      phx-key="Escape"
      {@rest}
    >
      <header>
        <%= if @header == [] do %>
          <div>
            <h3 id={@id <> "-title"}>{@title}</h3>
            <p :if={@description}>{@description}</p>
          </div>
        <% else %>
          <%= for h <- @header do %>
            {render_slot(h)}
          <% end %>
        <% end %>
        <button
          :if={@close_button}
          type="button"
          class="lu-x"
          aria-label={@close_label}
          phx-click={@on_close}
          phx-target={@target}
        >
          <.icon name="x" />
        </button>
      </header>
      <div class={cx(["bd", @body_class])}>{render_slot(@inner_block)}</div>
      <footer :for={f <- @footer}>{render_slot(f)}</footer>
    </.dynamic_tag>
    """
  end

  def modal(assigns) do
    inline = assigns.inline
    rest = assigns.rest
    user_style = rest[:style]

    root_style =
      if inline do
        user_style
      else
        Support.style([
          @fixed,
          @align[assigns.placement],
          assigns.blur && "backdrop-filter:blur(4px)",
          user_style
        ])
      end

    card_style =
      Support.style([
        assigns.card_style || @sizes[assigns.size],
        has_corner?(assigns) && "position:relative"
      ])

    # ARIA is always rendered (also in the inline preview); only the modal behavior differs.
    card_attrs =
      %{
        "role" => assigns.role,
        "aria-modal" => if(!inline, do: "true"),
        "aria-labelledby" => if(assigns.title, do: assigns.id <> "-title"),
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
      |> assign(:rest, Map.delete(rest, :style))
      |> assign(:root_class, Support.class(cx(["lu-scrim", assigns.backdrop_class])))
      |> assign(:root_style, root_style)
      |> assign(:state, if(assigns.open, do: "open", else: "closed"))
      |> assign(:card_class, cx(["lu-modal", assigns.class]))
      |> assign(:card_style_s, card_style)
      |> assign(:card_attrs, card_attrs)
      |> assign(:cfg, cfg)
      |> assign(:hook, if(inline, do: nil, else: "LedgerUI.Overlay"))
      |> assign(:icon_class, cx(["lu-ic", @tones[assigns.icon_tone]]))
      |> assign(:blank?, Support.blank?(assigns.inner_block))
      |> assign(:corner?, has_corner?(assigns))
      |> assign(:corner_style, corner_style(assigns.close_variant))
      |> assign(:close_js, LedgerUI.close(assigns.id))

    ~H"""
    <div
      id={@id}
      class={@root_class}
      {Support.st(@root_style)}
      phx-hook={@hook}
      data-lu-overlay={!@inline && ""}
      data-state={!@inline && @state}
      {@cfg}
      {@rest}
    >
      <div class={@card_class} {Support.st(@card_style_s)} {@card_attrs}>
        <div
          :if={@header != [] or @title != nil}
          class={cx(["lu-modal-h", header_class(@header)])}
          {Support.st(header_style(@header))}
        >
          <span :if={@icon} class={@icon_class}><.icon name={@icon} /></span>
          <div :if={@header == []}>
            <h3 id={@id <> "-title"}>{@title}</h3>
            <p :if={@description} id={@id <> "-desc"}>{@description}</p>
          </div>
          <%= for h <- @header do %>
            {render_slot(h)}
          <% end %>
          <button
            :if={@close_button}
            aria-label={@close_label}
            class="lu-x"
            type="button"
            phx-click={@close_js}
          >
            <.icon name="x" size="md" />
          </button>
        </div>
        <button
          :if={@corner?}
          aria-label={@close_label}
          class="lu-x"
          type="button"
          {Support.st(@corner_style)}
          phx-click={@close_js}
        >
          <.icon name="x" size="md" />
        </button>
        <div :if={!@blank?} class={cx(["lu-modal-b", @body_class])}>
          {render_slot(@inner_block)}
        </div>
        <div :for={f <- @footer} class={cx(["lu-modal-f", f[:class]])} {Support.st(f[:style])}>
          {render_slot(f)}
        </div>
      </div>
    </div>
    """
  end

  defp has_corner?(a), do: a.close_button and a.header == [] and a.title == nil

  defp corner_style("chip"),
    do:
      "position:absolute;top:10px;right:10px;margin:0;background:rgba(0,0,0,.35);color:#fff;border-radius:999px"

  defp corner_style(_), do: "position:absolute;top:10px;right:10px;margin:0"

  defp header_class([h | _]), do: h[:class]
  defp header_class(_), do: nil
  defp header_style([h | _]), do: h[:style]
  defp header_style(_), do: nil
end
