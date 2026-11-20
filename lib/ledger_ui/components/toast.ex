defmodule LedgerUI.Components.Toast do
  @moduledoc """
  Notifications: the toaster, toasts pushed by the server, and the cards drawn in the page.

  Mount the toaster once, in the layout every LiveView renders (it reads the flash):

      <.toaster flash={@flash} />

  Then, from the server:

      conn |> put_toast("Saved", color: "success") |> redirect(to: ~p"/orders")
      socket |> put_toast("Saved", color: "success") |> push_navigate(to: ~p"/orders")
      socket |> send_toast("Copied", color: "info", position: "center-top")
      socket |> send_toast("Sending…", id: "nfe-42", kind: :loading)
      socket |> update_toast("nfe-42", kind: :success, title: "Sent")
      socket |> dismiss_toast("nfe-42")
      socket |> clear_toasts()

  `put_toast/3` goes through the flash (it survives a redirect and the standard `:info`/`:error`
  flash messages are drawn too); `send_toast/3` pushes to the page at once. From the browser,
  with no round trip (both go through a `ledger:toast` event the toaster hook listens to):

      <button phx-click={show_toast("Copied", color: "info")}>Copy</button>
      <button phx-click={dismiss_toast("nfe-42")}>Hide</button>

  Options: `id` (the same id updates a toast in place), `title`, `description`, `kind`
  (`neutral info success warning error loading`), `status` (`run queue ok err`, the compact dark
  card), `color`, `position`, `duration` (ms; `0` or `:infinity` keeps it until closed), `close`,
  `timer`, `template` (id of a `<template>` whose first element is shown), `actions`
  (`[label:, event:, value:, target:, href:, js:, dismiss:, variant:, color:]`), `aura`
  (`true :dual :glow`, with `aura_size`/`aura_color`), `value` (0..100 progress, `bar: true`),
  `steps`/`step` and `invert`.

  The client side is the `LedgerUI.Toaster` hook (`priv/static/ledger_ui/hooks/toaster.js`).

  `toast_card/1` and `status_toast/1` draw the same cards where they are written.
  """
  use LedgerUI.Component

  alias Phoenix.LiveView

  @flash_key "ledger_toast"
  @event "ledger:toast"
  @default_toaster "ledger-toaster"

  @positions ~w(left-top left-bottom center-top center-bottom right-top right-bottom)

  @toast_keys ~w(id title description kind status color position duration close timer template actions
                 aura aura_size aura_color value bar steps step invert icon message)
  @action_keys ~w(label event value target href dismiss variant color js)
  @flash_kinds %{
    "info" => "info",
    "error" => "error",
    "warning" => "warning",
    "success" => "success"
  }

  @fixed_style "position:fixed;inset:0;height:auto;border:0;border-radius:0;background:none;overflow:visible;pointer-events:none;z-index:var(--ledger-z-toast,60)"
  @stack_fixed "pointer-events:none"

  # ---------------------------------------------------------------------------
  # toaster
  # ---------------------------------------------------------------------------

  attr :id, :string, default: @default_toaster
  attr :flash, :map, default: %{}, doc: "The `@flash`, where `put_toast/3` leaves its toasts."
  attr :position, :string, default: "center-bottom", values: @positions
  attr :duration, :integer, default: 5000
  attr :stack, :boolean, default: true
  attr :persist_errors, :boolean, default: false
  attr :timer, :boolean, default: true
  attr :invert, :boolean, default: false
  attr :close_label, :string, default: "Close"
  attr :loading_label, :string, default: "Loading"

  attr :contained, :boolean,
    default: false,
    doc: "Draw the toaster inside its parent (a demo panel) instead of over the page."

  attr :rest, :global

  slot :inner_block,
    doc: "Toasts already on screen at render time (a static preview), in the stack."

  def toaster(assigns) do
    assigns =
      assigns
      |> assign(:attrs, toaster_attrs(assigns))
      |> assign(:stack_attrs, if(assigns.contained, do: %{}, else: %{style: @stack_fixed}))

    ~H"""
    <div id={@id} class="lu-toaster" data-pos={@position} phx-hook="LedgerUI.Toaster" {@attrs}>
      <div class="stack" id={@id <> "-stack"} phx-update="ignore" {@stack_attrs}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # Only non-default settings are rendered; the hook has the defaults.
  defp toaster_attrs(a) do
    %{}
    |> put_if(not a.contained, :style, @fixed_style)
    |> put_if(a.duration != 5000, :"data-lu-duration", a.duration)
    |> put_if(not a.stack, :"data-lu-stack", "false")
    |> put_if(not a.timer, :"data-lu-timer", "false")
    |> put_if(a.invert, :"data-lu-invert", "true")
    |> put_if(a.persist_errors, :"data-lu-persist-errors", "true")
    |> put_if(a.close_label != "Close", :"data-lu-close-label", a.close_label)
    |> put_if(a.loading_label != "Loading", :"data-lu-loading-label", a.loading_label)
    |> put_if(flash_json(a.flash) != nil, :"data-lu-flash", flash_json(a.flash))
    |> Map.merge(a.rest)
  end

  defp put_if(map, true, key, value), do: Map.put(map, key, value)
  defp put_if(map, _, _key, _value), do: map

  defp flash_json(flash) when is_map(flash) do
    from_key =
      case Map.get(flash, @flash_key) do
        json when is_binary(json) -> decode_list(json)
        _ -> []
      end

    standard =
      for {key, kind} <- @flash_kinds, msg = Map.get(flash, key), is_binary(msg) and msg != "" do
        %{"title" => msg, "kind" => kind, "_k" => "flash:#{key}:#{:erlang.phash2(msg)}"}
      end

    case from_key ++ standard do
      [] -> nil
      list -> Jason.encode!(list)
    end
  end

  defp flash_json(_), do: nil

  defp decode_list(json) do
    case Jason.decode(json) do
      {:ok, list} when is_list(list) -> list
      _ -> []
    end
  end

  # ---------------------------------------------------------------------------
  # Server API
  # ---------------------------------------------------------------------------

  @doc """
  Leaves a toast in the flash (survives a redirect). Works on a `Plug.Conn` and on a socket.

      conn |> put_toast("Saved", color: "success") |> redirect(to: "/")
  """
  def put_toast(conn_or_socket, message, opts \\ [])

  def put_toast(%Plug.Conn{} = conn, message, opts) do
    json = append_flash(conn.assigns[:flash], toast_payload(message, opts))
    Phoenix.Controller.put_flash(conn, @flash_key, json)
  end

  def put_toast(%LiveView.Socket{} = socket, message, opts) do
    json = append_flash(socket.assigns[:flash], toast_payload(message, opts))
    LiveView.put_flash(socket, @flash_key, json)
  end

  defp append_flash(flash, payload) do
    existing =
      case flash && Map.get(flash, @flash_key) do
        json when is_binary(json) -> decode_list(json)
        _ -> []
      end

    Jason.encode!(existing ++ [payload])
  end

  @doc """
  Pushes a toast to the page at once. The message is the title, or pass `title:` in the options.

      send_toast(socket, "Copied", color: "info")
      send_toast(socket, id: "x", kind: :loading, title: "Working…")
  """
  def send_toast(socket, message_or_opts, opts \\ [])

  def send_toast(%LiveView.Socket{} = socket, opts, []) when is_list(opts),
    do: push(socket, "show", toast_payload(nil, opts))

  def send_toast(%LiveView.Socket{} = socket, message, opts),
    do: push(socket, "show", toast_payload(message, opts))

  @doc "Changes only the given options of the toast `id`, keeping the rest."
  def update_toast(%LiveView.Socket{} = socket, id, opts) do
    push(socket, "update", Map.put(normalize(opts), "id", to_string(id)))
  end

  @doc """
  Removes a toast. On a socket it pushes to the page; on a `%JS{}` (or alone) it is the browser
  command (see `dismiss_toast/1`).
  """
  def dismiss_toast(%LiveView.Socket{} = socket, id),
    do: push(socket, "dismiss", %{"id" => to_string(id)})

  def dismiss_toast(%JS{} = js, id), do: dismiss_js(js, id)

  @doc "Removes every toast of the page."
  def clear_toasts(%LiveView.Socket{} = socket), do: push(socket, "clear", %{})

  defp push(socket, op, payload),
    do: LiveView.push_event(socket, @event, Map.put(payload, "op", op))

  # ---------------------------------------------------------------------------
  # Browser commands
  # ---------------------------------------------------------------------------

  @doc """
  JS command that shows a toast in the browser, with no round trip.

      <button phx-click={show_toast("Copied", color: "info")}>Copy</button>

  Takes the options of `send_toast/3` plus `to:` (the toaster selector, `"#ledger-toaster"`).
  """
  def show_toast(message, opts \\ [])

  def show_toast(%JS{} = js, message) when is_binary(message), do: show_toast(js, message, [])
  def show_toast(message, opts) when is_list(opts), do: show_toast(%JS{}, message, opts)

  def show_toast(%JS{} = js, message, opts) do
    {to, opts} = Keyword.pop(opts, :to, "#" <> @default_toaster)
    payload = message |> toast_payload(opts) |> Map.put("op", "show")
    JS.dispatch(js, @event, to: to, detail: payload)
  end

  @doc "JS command that removes the toast `id` in the browser."
  def dismiss_toast(id) when is_binary(id), do: dismiss_js(%JS{}, id)

  defp dismiss_js(js, id),
    do:
      JS.dispatch(js, @event,
        to: "#" <> @default_toaster,
        detail: %{"op" => "dismiss", "id" => to_string(id)}
      )

  @doc false
  def toast_payload(message, opts) do
    payload = normalize(opts)
    payload = if message, do: Map.put_new(payload, "title", to_string(message)), else: payload
    Map.put_new(payload, "id", "toast-" <> Integer.to_string(System.unique_integer([:positive])))
  end

  @doc false
  def normalize(opts) do
    for {key, value} <- opts, to_string(key) in @toast_keys, into: %{} do
      key = to_string(key)
      {key, if(key == "actions", do: Enum.map(value, &normalize_action/1), else: norm(value))}
    end
  end

  defp normalize_action(action) do
    for {key, value} <- action, to_string(key) in @action_keys, into: %{} do
      key = to_string(key)
      {key, if(key == "js", do: Jason.encode!(value), else: norm(value))}
    end
  end

  defp norm(:infinity), do: "infinity"
  defp norm(v) when v in [true, false, nil], do: v
  defp norm(v) when is_atom(v), do: Atom.to_string(v)
  defp norm(v), do: v

  # ---------------------------------------------------------------------------
  # toast_card
  # ---------------------------------------------------------------------------

  @kinds ~w(neutral primary success warning error info)

  attr :id, :string, default: nil
  attr :tone, :string, default: "light", values: ~w(light dark)
  attr :kind, :string, default: "neutral", values: @kinds
  attr :icon, :string, default: nil
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :dismissible, :boolean, default: true
  attr :close_label, :string, default: "Close"
  attr :on_dismiss, :any, default: nil
  attr :busy, :boolean, default: false

  attr :busy_label, :string,
    default: nil,
    doc: "Accessible name of the spinner (none when `nil`)."

  attr :progress, :integer, default: nil
  attr :progress_state, :string, default: "run", values: ~w(run done fail)
  attr :aura, :string, default: nil, values: [nil, "", "spin", "dual", "glow"]
  attr :aura_tone, :string, default: "accent", values: ~w(accent ai info pos warn neg violet)
  attr :aura_width, :string, default: "default", values: ~w(xs sm default lg)
  attr :aura_shadow, :boolean, default: true

  attr :aura_style, :string,
    default: "width:100%;--r:15px",
    doc: "Inline style of the aura wrapper (its width, the card's corner `--r`)."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "Buttons between the text and the close button."
  slot :icon_tile, doc: "Replaces the icon inside the tile."

  def toast_card(assigns) do
    state = if assigns.progress, do: assigns.progress_state
    aura? = assigns.aura not in [nil, ""]

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-tcard",
          "c-" <>
            if(state == "done",
              do: "success",
              else: if(state == "fail", do: "error", else: assigns.kind)
            ),
          assigns.tone == "dark" && "dark",
          state == "done" && "done",
          state == "fail" && "fail",
          assigns.class
        ])
      )
      |> assign(:state, state)
      |> assign(:aura?, aura?)
      |> assign(:fill, fill_style(state, assigns.progress))
      |> assign(:spin, assigns.busy or state == "run")
      |> assign(:spin_attrs, spin_attrs(assigns.busy_label))
      |> assign(:pct, pct(state, assigns.progress))
      |> assign(:pct_attrs, if(state == "done", do: %{style: "color:var(--pos)"}, else: %{}))
      |> assign(
        :aura_classes,
        cx([
          "lu-aura",
          "m-" <> to_string(assigns.aura),
          "t-" <> assigns.aura_tone,
          "w-" <> assigns.aura_width,
          assigns.aura_shadow && "shadow"
        ])
      )
      |> assign(:dismiss_js, dismiss_card(assigns, aura?))

    ~H"""
    <span :if={@aura?} data-part="toast-aura" class={@aura_classes} style={@aura_style}>
      <.toast_card_body {assigns} />
    </span>
    <.toast_card_body :if={!@aura?} {assigns} />
    """
  end

  defp fill_style(nil, _), do: nil
  defp fill_style("run", p), do: "transform:scaleX(#{scale(p)})"
  defp fill_style("done", _), do: "transform:none"
  defp fill_style("fail", _), do: nil

  # `.42`, `1`: the fill's scale, without the leading zero.
  defp scale(p) do
    case Float.round(max(0, min(100, p)) / 100, 2) do
      1.0 -> "1"
      f -> f |> Float.to_string() |> String.replace_prefix("0.", ".")
    end
  end

  defp pct("run", p), do: "#{p}%"
  defp pct("done", _), do: "100%"
  defp pct(_, _), do: nil

  defp spin_attrs(nil), do: %{}
  defp spin_attrs(label), do: %{:role => "status", :"aria-label" => label}

  defp dismiss_card(%{dismissible: false}, _), do: nil

  defp dismiss_card(%{on_dismiss: on_dismiss}, aura?) do
    hide = JS.hide(to: {:closest, if(aura?, do: ".lu-aura", else: ".lu-tcard")})

    case on_dismiss do
      %JS{} = js -> JS.concat(hide, js)
      _ -> hide
    end
  end

  defp toast_card_body(assigns) do
    ~H"""
    <div data-part="toast-card" id={@id} class={@classes} style="width:100%" {@rest}>
      <span :if={@fill} class="fill" style={@fill}></span>
      <span :if={@icon || @icon_tile != []} class="tile">
        {if @icon_tile == [], do: icon_tag(@icon), else: render_slot(@icon_tile)}
      </span>
      <div class="t">
        <b>{@title}</b>
        <span :if={@description}>{@description}</span>
      </div>
      {render_slot(@action)}
      <span :if={@spin} class="lu-sp v-border s-sm c-primary" style="align-self:center" {@spin_attrs}></span>
      <span :if={@pct} class="pct" {@pct_attrs}>{@pct}</span>
      <button
        :if={@dismissible}
        type="button"
        class="x"
        aria-label={@close_label}
        phx-click={@dismiss_js}
      >
        <.icon name="x" size="sm" />
      </button>
    </div>
    """
  end

  defp icon_tag(name) do
    assigns = %{name: name}
    ~H|<.icon name={@name} size="md" />|
  end

  # ---------------------------------------------------------------------------
  # status_toast
  # ---------------------------------------------------------------------------

  attr :state, :string, default: "run", values: ~w(run queue ok err)
  attr :percent, :integer, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action do
    attr :ghost, :boolean
    attr :on_click, :any
    attr :id, :string
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
  end

  slot :inner_block, required: true

  def status_toast(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-stoast", assigns.class]))
      |> assign(:attrs, Map.put_new(assigns.rest, :role, "status"))
      |> assign(:lead_class, if(assigns.state == "queue", do: "lu-st queue", else: "lu-st"))
      |> assign(
        :lead_style,
        if(assigns.state == "run" and assigns.percent, do: "--stp:#{assigns.percent}%")
      )

    ~H"""
    <div data-part="status-toast" class={@classes} {@attrs}>
      <span :if={@state in ["run", "queue"]} class={@lead_class} {lead_attrs(@lead_style)}><i></i></span>
      <span :if={@state == "ok"} class="dot ok"></span>
      <span :if={@state == "err"} class="dot err"></span>
      <span class="msg">{render_slot(@inner_block)}</span>
      <%= for a <- @action do %>
        <.link
          :if={a[:href] || a[:navigate] || a[:patch]}
          id={a[:id]}
          class={cx(["act", a[:ghost] && "ghost"])}
          href={a[:href]}
          navigate={a[:navigate]}
          patch={a[:patch]}
        >
          {render_slot(a)}
        </.link>
        <button
          :if={!(a[:href] || a[:navigate] || a[:patch])}
          id={a[:id]}
          type="button"
          class={cx(["act", a[:ghost] && "ghost"])}
          phx-click={click(a[:on_click])}
        >
          {render_slot(a)}
        </button>
      <% end %>
    </div>
    """
  end

  defp lead_attrs(nil), do: %{}
  defp lead_attrs(style), do: %{style: style}

  defp click(nil), do: nil
  defp click(%JS{} = js), do: js
  defp click(event) when is_binary(event), do: JS.push(event)
end
