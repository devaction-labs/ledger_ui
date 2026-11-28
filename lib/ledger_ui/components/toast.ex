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
      socket |> update_toast("nfe-42", replace: true, kind: :success, title: "Sent")
      socket |> dismiss_toast("nfe-42")
      socket |> clear_toasts()

  `put_toast/3` goes through the flash (it survives a redirect and the standard `:info`/`:error`
  flash messages are drawn too); `send_toast/3` pushes to the page at once. From the browser,
  with no round trip (both go through a `ledger:toast` event the toaster hook listens to):

      <button phx-click={show_toast("Copied", color: "info")}>Copy</button>
      <button phx-click={dismiss_toast("nfe-42")}>Hide</button>

  Options: `id` (the same id updates a toast in place), `title` (`**object**` is drawn in bold in the
  status pill), `description`, `kind` (the format, `:status` or `:card`, or the colour kind `neutral info
  success warning error loading`), `status` (`run queue ok err`, the compact dark pill; `:queue` is the
  dashed ring of a task waiting), `color`, `position`, `duration` (ms; `0` or `:infinity` keeps it until
  closed), `close`, `timer`, `template` (id of a `<template>` whose first element is shown), `actions`
  (`[label:, event:, value:, target:, href:, navigate:, patch:, js:, dismiss:, variant:, color:]`), `aura` (`true :dual :glow`,
  with `aura_size`/`aura_color`), `progress` (0..100, also `value`; `bar: true` draws a line instead of the
  fill), `steps`/`step` and `invert`.

  ## Two formats

    * **status**: the dark pill (bottom centre by default). The icon fills with `progress`, or is the
      dashed ring with `status: :queue`; it carries at most one action and the progress in %. It goes
      away in 5 s, 8 s with an action, and stays while it works (`kind: :loading`, `status: :run`,
      `progress` under 100).
    * **card**: description, any number of actions, progress and `steps`. It stays while it has actions;
      with `persist_errors` an error or a warning card stays until closed.

  The pill's action is a filled button; `variant: :ghost` draws it as text only (no background), the way
  "Hide" and "Undo" read in the design. `action:` is one action, `actions:` a list (the pill shows the first):

      socket |> send_toast("Cancelling **PUB-1005279**", status: :queue, action: %{label: "Undo", event: "undo", variant: :ghost})
      socket |> send_toast("Batch **#118** issued", action: [label: "View", href: "/notes"])
      socket |> send_toast("Order **ORD-7** sent", action: [label: "View order", navigate: ~p"/orders/7"])

  `href` is a plain link (the page reloads). `navigate:` and `patch:` are LiveView links (`data-phx-link`):
  the screen changes with no reload, and the toast closes on the click. They take a path of this site only
  (`/orders/7`, `/orders?tab=open`): a URL with a host, `//host`, `javascript:` or a backslash is dropped from
  the action. This holds for `send_toast`, `put_toast`, `update_toast`, `show_toast` and the flash. In
  `status_toast/1` an `:action` slot takes the same `href`/`navigate`/`patch`; in `toast_card/1` write a
  `<.link navigate={...}>` inside the `:action` slot.

  In a card with `progress`, `icon` keeps the document-type icon (PDF, NF-e...) and the tile's background fills
  from 0 to 100% with the progress (instead of the spinning ring); `update_toast` moves the level.

  `kind: :status | :card` forces the format. Otherwise a description, an aura, `steps`, `progress` or
  more than one action make a card, and everything else a pill. Each format has its own place:
  `<.toaster position="center-bottom" card_position="right-top" />` (`status_position` is the pill's
  when it must differ from `position`), and a toast's own `position:` wins.

  ## Queue and updates

  Each stack shows `max_visible` toasts (three, the blades of the pile); the rest wait in a queue and
  come in as the others leave, their time counting from then. A toast sent with an id already on screen
  (or in the queue) updates that toast. `update_toast/3` changes only the options it is given; with
  `replace: true` it swaps the whole toast (the way a loading toast turns into its result, even in the
  other format) and starts its time again:

      socket |> send_toast("Importing **orders.csv**", id: "imp", status: :run, progress: 10)
      socket |> update_toast("imp", progress: 64)
      socket |> update_toast("imp", replace: true, kind: :status, color: :success, title: "Imported **orders.csv**")

  The client side is the `LedgerUI.Toaster` hook (`priv/static/ledger_ui/hooks/toaster.js`).

  `toast_card/1` and `status_toast/1` draw the same cards where they are written. For docs and design
  reviews, `toast_card progress_loop` fills and counts by itself, and `toast_loop/1` plays the toaster's
  loops (toasts piling up, or a loading toast giving way to its answer) with CSS only.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Aura
  import LedgerUI.Components.Spinner, only: [spinner: 1]
  alias Phoenix.LiveView

  @flash_key "ledger_toast"
  @event "ledger:toast"
  @default_toaster "ledger-toaster"

  @positions ~w(left-top left-bottom center-top center-bottom right-top right-bottom)

  @toast_keys ~w(id title description kind status color position duration close timer template actions
                 aura aura_size aura_color value progress bar steps step invert icon message replace action)
  @action_keys ~w(label event value target href navigate patch dismiss variant color js)
  @flash_kinds %{
    "info" => "info",
    "error" => "error",
    "warning" => "warning",
    "success" => "success"
  }

  # ---------------------------------------------------------------------------
  # classes (Tailwind utilities). The toasts the hook draws in the browser use the same strings: they
  # travel to it as JSON in `data-lu-cls` (see `hook_classes/0`), so there is one source for both.
  # ---------------------------------------------------------------------------

  @toaster_fixed "pointer-events-none fixed inset-0 z-[var(--ledger-z-toast,60)]"
  @toaster_contained "relative h-[230px] overflow-hidden rounded-xl border border-line bg-tray"

  # where the stack sits, by `position` (the stack is `absolute` inside the toaster)
  @stack_pos %{
    "center-bottom" => "bottom-4 left-1/2 -translate-x-1/2 flex-col-reverse items-center",
    "center-top" => "top-4 left-1/2 -translate-x-1/2 flex-col items-center",
    "right-bottom" => "right-4 bottom-4 flex-col-reverse items-end",
    "right-top" => "top-4 right-4 flex-col items-end",
    "left-bottom" => "bottom-4 left-4 flex-col-reverse items-start",
    "left-top" => "top-4 left-4 flex-col items-start"
  }

  # what happens to the toasts of a stack: they enter, stack as blades behind the newest (3 visible)
  # and open when the pointer is over the stack
  @stack_kids "[&>*]:[transition:transform_.3s_cubic-bezier(.3,.7,.4,1),opacity_.3s,margin_.3s] " <>
                "[&>*]:animate-[lu-tin_.3s_cubic-bezier(.3,.7,.4,1)] " <>
                "[&:not(:hover)>:nth-child(n+4)]:hidden [&:hover>*+*]:mb-2 " <>
                "[&:not(:hover)>:nth-child(2)]:[transform:scale(.94)] [&:not(:hover)>:nth-child(2)]:opacity-85 " <>
                "[&:not(:hover)>:nth-child(3)]:[transform:scale(.88)] [&:not(:hover)>:nth-child(3)]:opacity-60 " <>
                "motion-reduce:[&>*]:animate-none motion-reduce:[&>*]:transition-none"
  @stack_bottom "[&:not(:hover)>:nth-child(2)]:-mb-[42px] [&:not(:hover)>:nth-child(3)]:-mb-[42px]"
  @stack_top "[&:not(:hover)>:nth-child(2)]:-mt-[42px] [&:not(:hover)>:nth-child(3)]:-mt-[42px]"

  # the card
  @card "relative flex w-full items-start gap-3 overflow-hidden rounded-xl border p-3 text-sm leading-5 shadow-lg"
  @card_light "border-line bg-panel text-ink"
  @card_dark "border-[rgba(255,255,255,.08)] bg-navy text-white"
  @card_fail "border-[color-mix(in_oklab,var(--lu-neg)_30%,transparent)] bg-neg-soft"
  @tile "relative grid size-[30px] flex-none place-items-center rounded-md"
  @tile_light "bg-(--c-soft) text-(--c-ink)"
  @tile_dark "bg-[rgba(255,255,255,.1)] text-white"
  @body "relative flex min-w-0 flex-1 flex-col gap-0.5 pt-1 [&_b]:font-semibold"
  @desc_light "text-[13px] leading-[18px] text-muted"
  @desc_dark "text-[13px] leading-[18px] text-[rgba(255,255,255,.65)]"
  @close "relative grid size-[26px] flex-none cursor-pointer place-items-center rounded-md border-0 bg-transparent p-0 text-muted hover:bg-hover"
  @fill "absolute inset-0 origin-left transition-transform duration-500"
  # the type icon of a card in progress: the tile's background fills from the bottom with the progress
  @tile_filling "isolate overflow-hidden"
  @tile_fill "absolute inset-0 -z-10 origin-bottom bg-[color-mix(in_oklab,currentColor_24%,transparent)] transition-transform duration-500 motion-reduce:transition-none"
  @fill_run "bg-[color-mix(in_oklab,var(--lu-accent-500)_10%,transparent)]"
  @fill_done "bg-[color-mix(in_oklab,var(--lu-pos)_12%,transparent)]"
  @pct "relative self-center text-[12.5px] font-semibold tabular-nums text-muted"
  @fill_loop "absolute inset-0 origin-left animate-[lu-fill_5s_cubic-bezier(.4,.1,.3,1)_infinite] motion-reduce:animate-none"
  @pct_loop "[counter-reset:n_var(--n)] animate-[lu-pct_5s_cubic-bezier(.4,.1,.3,1)_infinite] after:content-[counter(n)_'%'] motion-reduce:animate-none"
  @segs "mt-2 flex gap-[3px]"
  @seg "h-1 flex-1 rounded-[2px] bg-sunken"
  @seg_done "h-1 flex-1 rounded-[2px] bg-accent-500"
  @seg_cur "h-1 flex-1 rounded-[2px] bg-(--lu-violet) animate-[lu-pulse_1.2s_infinite]"
  @wrap "w-[380px] max-w-full"

  # the status toast: compact and dark in both themes. The surface (`--stp`) is the kit's ink (light theme)
  # or page (dark theme) darkened; every shade is white mixed over it: no loose colour.
  @stoast "inline-flex w-auto [--stp:color-mix(in_oklab,var(--lu-ink-2),black_70%)] dark:[--stp:color-mix(in_oklab,var(--lu-bg-page),black_30%)] max-w-[440px] items-center gap-3 rounded-lg bg-(--stp) py-2.5 pr-2.5 pl-3.5 text-sm leading-5 " <>
            "text-[color-mix(in_oklab,white_62%,var(--stp))] " <>
            "shadow-[0_0_0_1px_color-mix(in_oklab,white_10%,var(--stp)),0_12px_28px_-6px_rgb(0_0_0_/_.35),0_2px_6px_rgb(0_0_0_/_.18)] " <>
            "[&_b]:font-[550] [&_b]:text-[color-mix(in_oklab,white_95%,var(--stp))]"
  @msg "min-w-0 flex-1 text-[color-mix(in_oklab,white_62%,var(--stp))]"
  @act "box-border inline-flex h-8 flex-none cursor-pointer items-center rounded-md border-0 px-3.5 text-sm leading-5 font-medium text-[color-mix(in_oklab,white_95%,var(--stp))] " <>
         "bg-[color-mix(in_oklab,white_12%,var(--stp))] " <>
         "shadow-[inset_0_0_0_1px_color-mix(in_oklab,white_18%,var(--stp))] " <>
         "hover:bg-[color-mix(in_oklab,white_18%,var(--stp))]"
  @act_ghost "box-border inline-flex h-8 flex-none cursor-pointer items-center rounded-md border-0 bg-transparent px-2 text-sm leading-5 font-medium shadow-none " <>
               "text-[color-mix(in_oklab,white_80%,var(--stp))] " <>
               "hover:bg-[color-mix(in_oklab,white_10%,var(--stp))]"
  @st_pct "flex-none font-mono text-xs font-medium tabular-nums text-[color-mix(in_oklab,white_62%,var(--stp))]"
  @dot "m-1 size-2.5 flex-none rounded-full"
  @dot_ok "bg-[color-mix(in_oklab,var(--lu-pos)_70%,white)] shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-pos)_22%,transparent)]"
  @dot_warn "bg-[color-mix(in_oklab,var(--lu-warn)_70%,white)] shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-warn)_22%,transparent)]"
  @dot_err "bg-[color-mix(in_oklab,var(--lu-neg)_70%,white)] shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-neg)_22%,transparent)]"

  # the lead of a running status toast: a ring with liquid waves that fill it (`--lu-stp` is the level).
  # The level moves the waves with `translate` (no layout; #131), not `top`: a percentage of `translate-y` is of the
  # element's own height (240% of the 12px disc = 28.8px), so `stp / 2.4` moves it by `stp` of the disc, as `top` did.
  @st "relative box-border size-[18px] flex-none rounded-full shadow-[inset_0_0_0_1.5px_var(--stc)] " <>
        "[--stc:color-mix(in_oklab,white_55%,var(--stp))] " <>
        "[--stw:color-mix(in_oklab,white_45%,var(--stp))] " <>
        "transition-[--lu-stp] duration-500 motion-reduce:transition-none"
  @st_auto "animate-[lu-st-fill_3.2s_ease-in-out_infinite] motion-reduce:animate-[lu-st-fill_6s_ease-in-out_infinite]"
  @st_queue "relative box-border size-[18px] flex-none rounded-full border-[1.5px] border-dashed border-[color-mix(in_oklab,white_45%,var(--stp))]"
  @st_liquid "absolute inset-[3px] overflow-hidden rounded-full bg-[color-mix(in_oklab,white_5%,transparent)] " <>
               "before:absolute before:top-full before:translate-y-[calc(var(--lu-stp,0%)_/_-2.4)] before:left-1/2 before:-ml-[120%] before:aspect-square before:w-[240%] before:rounded-[42%] before:bg-(--stw) before:content-[''] before:animate-[lu-st-wave_1.6s_linear_infinite] motion-reduce:before:animate-[lu-st-wave_4s_linear_infinite] " <>
               "after:absolute after:top-full after:translate-y-[calc(var(--lu-stp,0%)_/_-2.4)] after:left-1/2 after:-ml-[120%] after:-mt-[1.5px] after:aspect-square after:w-[240%] after:rounded-[38%] after:bg-[color-mix(in_srgb,var(--stw)_55%,transparent)] after:content-[''] after:animate-[lu-st-wave_2.3s_linear_infinite_reverse] motion-reduce:after:animate-[lu-st-wave_4s_linear_infinite_reverse]"

  @kind_colors ~w(neutral primary secondary info success warning error)
  @action_colors ~w(neutral primary error)
  @action_variants ~w(outline solid soft ghost)

  # The class strings of the toasts the browser draws (the `LedgerUI.Toaster` hook); they go to it
  # as JSON in `data-lu-cls`. The names are the hook's. Everything in it is a constant (module
  # attributes and pure functions of the other components' class tables), so it is built, and
  # encoded, once at compile time (#87): a render does not rebuild the ~20 KB JSON.
  aura = LedgerUI.Components.Aura.parts()

  @hook_classes %{
    "stack" => %{
      "kids" => @stack_kids,
      "bottom" => @stack_bottom,
      "top" => @stack_top
    },
    "wrap" => @wrap,
    "card" => @card,
    "light" => @card_light,
    "dark" => @card_dark,
    "fail" => @card_fail,
    "tile" => @tile,
    "tile_filling" => @tile_filling,
    "tile_fill" => @tile_fill,
    "tile_light" => @tile_light,
    "tile_dark" => @tile_dark,
    "body" => @body,
    "desc_light" => @desc_light,
    "desc_dark" => @desc_dark,
    "close" => @close,
    "fill" => @fill,
    "fill_run" => @fill_run,
    "fill_done" => @fill_done,
    "pct" => @pct,
    "segs" => @segs,
    "seg" => @seg,
    "seg_done" => @seg_done,
    "seg_cur" => @seg_cur,
    "counter" => @desc_light,
    "bar" =>
      "absolute inset-x-0 bottom-0 h-[3px] bg-[color-mix(in_oklab,currentColor_15%,transparent)]",
    "bar_fill" => "block h-full bg-current",
    "colors" => Map.new(@kind_colors, &{&1, LedgerUI.Color.vars(&1)}),
    "spinner" => LedgerUI.Components.Spinner.classes("primary", "border", "sm") <> " self-center",
    "spinner_tile" => LedgerUI.Components.Spinner.classes("primary", "border", "sm"),
    "buttons" =>
      for(
        c <- @action_colors,
        v <- @action_variants,
        into: %{},
        do: {c <> ":" <> v, cx(LedgerUI.Components.Button.classes(c, v, "sm", "rounded"))}
      ),
    "icon" =>
      "inline flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round] align-middle",
    "icon_sm" => "size-3.5",
    "icon_md" => "size-4",
    "aura" => %{
      "base" => aura.base <> " w-[380px] [--r:15px]",
      "modes" => aura.modes,
      "tones" => aura.tones,
      "widths" => aura.widths,
      "shadow" => aura.shadow
    },
    "stoast" => @stoast,
    "msg" => @msg,
    "act" => @act,
    "act_ghost" => @act_ghost,
    "st_pct" => @st_pct,
    "dot_ok" => @dot <> " " <> @dot_ok,
    "dot_err" => @dot <> " " <> @dot_err,
    "dot_warn" => @dot <> " " <> @dot_warn,
    "st_auto" => @st <> " " <> @st_auto,
    "st_set" => @st,
    "st_queue" => @st_queue,
    "st_liquid" => @st_liquid
  }

  @hook_classes_json Jason.encode!(@hook_classes)

  @doc false
  def hook_classes, do: @hook_classes

  # ---------------------------------------------------------------------------
  # toaster
  # ---------------------------------------------------------------------------

  attr :id, :string, default: @default_toaster
  attr :flash, :map, default: %{}, doc: "The `@flash`, where `put_toast/3` leaves its toasts."
  attr :position, :string, default: "center-bottom", values: @positions
  attr :duration, :integer, default: 5000

  attr :status_position, :string,
    default: nil,
    values: [nil | @positions],
    doc: "Where the status pill goes; `position` when `nil`."

  attr :card_position, :string,
    default: nil,
    values: [nil | @positions],
    doc: "Where the card goes (`\"right-top\"` is the usual); `position` when `nil`."

  attr :max_visible, :integer,
    default: 3,
    doc:
      "Toasts in view at once, per stack; the rest wait in a queue and enter as the others leave. " <>
        "With `stack` (the blades) three is the most that fits."

  attr :stack, :boolean, default: true
  attr :persist_errors, :boolean, default: false
  attr :timer, :boolean, default: true
  attr :invert, :boolean, default: false
  attr :close_label, :string, default: nil
  attr :loading_label, :string, default: nil

  attr :contained, :boolean,
    default: false,
    doc: "Draw the toaster inside its parent (a demo panel) instead of over the page."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block,
    doc: "Toasts already on screen at render time (a static preview), in the stack."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def toaster(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, close_label: "common.close", loading_label: "common.loading")

    assigns =
      assigns
      |> assign(:attrs, toaster_attrs(assigns))
      |> assign(:root_cls, if(assigns.contained, do: @toaster_contained, else: @toaster_fixed))
      |> assign(
        :stack_cls,
        cx([
          "absolute flex gap-0",
          @stack_pos[assigns.position],
          @stack_kids,
          if(String.ends_with?(assigns.position, "top"), do: @stack_top, else: @stack_bottom),
          !assigns.contained && "pointer-events-none"
        ])
      )

    # `close_label` and `loading_label` are filled by `I18n.texts/3`, which marks them as changed
    # when `locale` changes. `data-lu-cls` is not an assign: the call has no variable, so the
    # LiveView sends it once, with the first render.
    assigns =
      settle(assigns, changed0,
        attrs: [
          :card_position,
          :close_label,
          :duration,
          :flash,
          :invert,
          :loading_label,
          :locale,
          :max_visible,
          :persist_errors,
          :rest,
          :stack,
          :status_position,
          :timer
        ],
        root_cls: [:contained],
        stack_cls: [:position, :contained]
      )

    ~H"""
    <div
      id={@id}
      data-part="toaster"
      class={[@root_cls, @class]}
      data-pos={@position}
      phx-hook="LedgerUI.Toaster"
      data-lu-cls={hook_classes_json()}
      {@attrs}
    >
      <div data-part="toast-stack" class={@stack_cls} id={@id <> "-stack"} phx-update="ignore">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc false
  def hook_classes_json, do: @hook_classes_json

  # Only non-default settings are rendered; the hook has the defaults. `data-lu-cls` is not in
  # this map: it is a separate attribute of the template, so the ~20 KB string is not part of what
  # a new flash changes (the map is one dynamic: it goes whole when any of its values changes).
  defp toaster_attrs(a) do
    %{}
    |> put_if(a.duration != 5000, :"data-lu-duration", a.duration)
    |> put_if(a.max_visible != 3, :"data-lu-max-visible", a.max_visible)
    |> put_if(a.status_position != nil, :"data-lu-status-position", a.status_position)
    |> put_if(a.card_position != nil, :"data-lu-card-position", a.card_position)
    |> put_if(not a.stack, :"data-lu-stack", "false")
    |> put_if(not a.timer, :"data-lu-timer", "false")
    |> put_if(a.invert, :"data-lu-invert", "true")
    |> put_if(a.persist_errors, :"data-lu-persist-errors", "true")
    |> put_if(
      I18n.non_default(a.close_label, "common.close") != nil,
      :"data-lu-close-label",
      a.close_label
    )
    |> put_if(
      I18n.non_default(a.loading_label, "common.loading") != nil,
      :"data-lu-loading-label",
      a.loading_label
    )
    |> put_if(flash_json(a.flash) != nil, :"data-lu-flash", flash_json(a.flash))
    |> Map.merge(Map.delete(a.rest, :"data-lu-cls"))
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
      {key, normalize_value(key, value)}
    end
    |> progress_as_value()
    |> single_action()
    |> icon_shapes()
  end

  # The hook only knows a handful of icons; the shapes of the one a toast names (`icon:`) travel with it.
  defp icon_shapes(%{"icon" => name} = payload) when is_binary(name) and name != "" do
    assigns = %{name: name}

    html =
      ~H|<.icon name={@name} size="md" />|
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    case svg_inner(html) do
      shapes when shapes not in [nil, ""] -> Map.put(payload, "icon_shapes", shapes)
      _ -> payload
    end
  end

  defp icon_shapes(payload), do: payload

  # What `<svg[^>]*>(.*)</svg>` captured: from the `>` that closes the first `<svg` to the last `</svg>`.
  defp svg_inner(html) do
    with {start, _} <- :binary.match(html, "<svg"),
         rest = binary_part(html, start, byte_size(html) - start),
         {gt, 1} <- :binary.match(rest, ">"),
         [_ | _] = closes <- :binary.matches(rest, "</svg>"),
         {last, _} = List.last(closes),
         true <- last > gt do
      binary_part(rest, gt + 1, last - gt - 1)
    else
      _ -> nil
    end
  end

  # `action:` is one action (a map or a keyword); it joins `actions` (first)
  defp single_action(%{"action" => action} = payload) do
    payload |> Map.delete("action") |> Map.update("actions", [action], &[action | &1])
  end

  defp single_action(payload), do: payload

  # `progress` is the name the apps use; the toast draws it as `value`
  defp progress_as_value(%{"progress" => progress} = payload),
    do: payload |> Map.delete("progress") |> Map.put_new("value", progress)

  defp progress_as_value(payload), do: payload

  defp normalize_value("actions", value), do: Enum.map(value, &normalize_action/1)
  defp normalize_value("action", value), do: normalize_action(value)
  defp normalize_value(_key, value), do: norm(value)

  defp normalize_action(action) do
    for {key, value} <- action, to_string(key) in @action_keys, into: %{} do
      key = to_string(key)
      {key, if(key == "js", do: LedgerUI.Helpers.js_json(value), else: norm(value))}
    end
    |> drop_unsafe_links()
  end

  # `navigate`/`patch` only take a path of this site; anything else is dropped (the hook checks again).
  defp drop_unsafe_links(action) do
    Enum.reduce(~w(navigate patch), action, fn key, acc ->
      case acc do
        %{^key => value} -> if local_path?(value), do: acc, else: Map.delete(acc, key)
        _ -> acc
      end
    end)
  end

  defp local_path?("/" <> rest = path) when is_binary(path) do
    not String.starts_with?(rest, "/") and not String.contains?(path, "\\") and
      not control_char?(path)
  end

  defp local_path?(_), do: false

  defp control_char?(<<c, _::binary>>) when c <= 0x1F or c == 0x7F, do: true
  defp control_char?(<<_, rest::binary>>), do: control_char?(rest)
  defp control_char?(<<>>), do: false

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
  attr :close_label, :string, default: nil
  attr :on_dismiss, :any, default: nil
  attr :busy, :boolean, default: false

  attr :busy_label, :string,
    default: nil,
    doc: "Accessible name of the spinner (none when `nil`)."

  attr :progress, :integer, default: nil
  attr :progress_state, :string, default: "run", values: ~w(run done fail)

  attr :progress_loop, :boolean,
    default: false,
    doc:
      "Demo: the fill and the % go from 4 to 100 by themselves, in a 5s loop (`lu-fill`/`lu-pct`); it wins over `progress`."

  attr :steps, :integer,
    default: nil,
    doc: "Number of steps: draws one segment per step under the text (the hook's `steps`)."

  attr :step, :integer,
    default: 0,
    doc: "Steps done; the next segment is the current one (violet, pulsing). `steps` is required."

  attr :steps_loop, :boolean,
    default: false,
    doc: "Demo: the segments advance by themselves, in a 6s loop (up to 5 steps)."

  attr :aura, :string, default: nil, values: [nil, "", "spin", "dual", "glow"]
  attr :aura_tone, :string, default: "accent", values: ~w(accent ai info pos warn neg violet)
  attr :aura_width, :string, default: "default", values: ~w(xs sm default lg)
  attr :aura_shadow, :boolean, default: true

  attr :aura_style, :string,
    default: nil,
    doc: "Inline style of the aura wrapper (e.g. a fixed width); it is full width by default."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "Buttons between the text and the close button."
  slot :icon_tile, doc: "Replaces the icon inside the tile."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def toast_card(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, close_label: "common.close")

    loop? = assigns.progress_loop
    assigns = if loop?, do: assign(assigns, :progress, nil), else: assigns
    state = if assigns.progress || loop?, do: assigns.progress_state
    aura? = assigns.aura not in [nil, ""]
    dark? = assigns.tone == "dark"
    kind = card_kind(state, assigns.kind)
    aura_parts = Aura.parts()

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          @card,
          LedgerUI.Color.vars(kind),
          if(state == "fail",
            do: [@card_fail, if(dark?, do: "text-white", else: "text-ink")],
            else: if(dark?, do: @card_dark, else: @card_light)
          )
        ])
      )
      |> assign(:tile_cls, [
        @tile,
        if(dark?, do: @tile_dark, else: @tile_light),
        tile_fill(state, assigns) && @tile_filling
      ])
      |> assign(:desc_cls, if(dark?, do: @desc_dark, else: @desc_light))
      |> assign(:body_cls, @body)
      |> assign(:close_cls, @close)
      |> assign(:tile_fill_cls, @tile_fill)
      |> assign(:segs, segs(assigns))
      |> assign(:segs_cls, @segs)
      |> assign(:pct_cls, [
        @pct,
        if(state == "done", do: "text-pos"),
        loop? && state == "run" && @pct_loop
      ])
      |> assign(:state, state)
      |> assign(:aura?, aura?)
      |> assign(:fill, fill(state, assigns.progress, loop?))
      |> assign(:tile_level, tile_fill(state, assigns))
      |> assign(:spin, assigns.busy or (state == "run" and !tile_fill(state, assigns)))
      |> assign(:pct, pct(state, assigns.progress, loop?))
      |> assign(
        :aura_classes,
        cx([
          aura_parts.base,
          "w-full [--r:15px]",
          aura_parts.modes[assigns.aura],
          aura_parts.tones[assigns.aura_tone],
          aura_parts.widths[assigns.aura_width],
          assigns.aura_shadow && aura_parts.shadow
        ])
      )
      |> assign(:dismiss_js, dismiss_card(assigns, aura?))

    # `state` is read from `progress`, `progress_state` and `progress_loop`; the pieces that are
    # constants (`body_cls`, `close_cls`...) have no source and go with the first render only.
    # `close_label` is not listed: `I18n.texts/3` already marks it when `locale` changes.
    assigns =
      settle(assigns, changed0,
        classes: [:kind, :tone, :progress, :progress_state, :progress_loop],
        tile_cls: [:tone, :progress, :progress_state, :progress_loop, :icon, :icon_tile],
        desc_cls: [:tone],
        body_cls: [],
        close_cls: [],
        tile_fill_cls: [],
        segs: [:steps, :step, :steps_loop],
        segs_cls: [],
        pct_cls: [:progress, :progress_state, :progress_loop],
        state: [:progress, :progress_state, :progress_loop],
        aura?: [:aura],
        fill: [:progress, :progress_state, :progress_loop],
        tile_level: [:progress, :progress_state, :progress_loop, :icon, :icon_tile],
        spin: [:busy, :progress, :progress_state, :progress_loop, :icon, :icon_tile],
        pct: [:progress, :progress_state, :progress_loop],
        aura_classes: [:aura, :aura_tone, :aura_width, :aura_shadow],
        dismiss_js: [:dismissible, :on_dismiss, :aura]
      )

    ~H"""
    <span :if={@aura?} data-part="toast-aura" class={@aura_classes} style={@aura_style}>
      <.toast_card_body
        action={@action}
        body_cls={@body_cls}
        busy_label={@busy_label}
        class={@class}
        classes={@classes}
        close_cls={@close_cls}
        close_label={@close_label}
        desc_cls={@desc_cls}
        description={@description}
        dismiss_js={@dismiss_js}
        dismissible={@dismissible}
        fill={@fill}
        icon={@icon}
        icon_tile={@icon_tile}
        id={@id}
        pct={@pct}
        pct_cls={@pct_cls}
        rest={@rest}
        segs={@segs}
        segs_cls={@segs_cls}
        spin={@spin}
        step={@step}
        steps={@steps}
        tile_cls={@tile_cls}
        tile_fill_cls={@tile_fill_cls}
        tile_level={@tile_level}
        title={@title}
      />
    </span>
    <.toast_card_body
      :if={!@aura?}
      action={@action}
      body_cls={@body_cls}
      busy_label={@busy_label}
      class={@class}
      classes={@classes}
      close_cls={@close_cls}
      close_label={@close_label}
      desc_cls={@desc_cls}
      description={@description}
      dismiss_js={@dismiss_js}
      dismissible={@dismissible}
      fill={@fill}
      icon={@icon}
      icon_tile={@icon_tile}
      id={@id}
      pct={@pct}
      pct_cls={@pct_cls}
      rest={@rest}
      segs={@segs}
      segs_cls={@segs_cls}
      spin={@spin}
      step={@step}
      steps={@steps}
      tile_cls={@tile_cls}
      tile_fill_cls={@tile_fill_cls}
      tile_level={@tile_level}
      title={@title}
    />
    """
  end

  @seg_loop %{
    1 => "animate-[lu-seg_6s_steps(1)_infinite]",
    2 => "animate-[lu-seg2_6s_steps(1)_infinite]",
    3 => "animate-[lu-seg3_6s_steps(1)_infinite]",
    4 => "animate-[lu-seg4_6s_steps(1)_infinite]",
    5 => "animate-[lu-seg5_6s_steps(1)_infinite]"
  }

  # the segments of a stepped card: a list of `class` (nil when the card has no steps)
  defp segs(%{steps: n}) when not is_integer(n) or n < 1, do: nil

  defp segs(%{steps: n, step: step, steps_loop: loop?}) do
    for i <- 1..n do
      cond do
        loop? and Map.has_key?(@seg_loop, i) -> [@seg, @seg_loop[i]]
        i <= step -> @seg_done
        i == step + 1 -> @seg_cur
        true -> @seg
      end
    end
  end

  # the type icon of a card in progress: the tile's background fills (instead of the spinning ring)
  defp tile_fill("run", %{icon: icon, icon_tile: [], progress: p})
       when is_binary(icon) and is_integer(p),
       do: "transform:scaleY(#{scale(p)})"

  defp tile_fill(_, _), do: nil

  defp card_kind("done", _), do: "success"
  defp card_kind("fail", _), do: "error"
  defp card_kind(_, kind), do: kind

  # the fill behind the card: `{class, style}` (the width is a value, so it is a style)
  defp fill(nil, _, _), do: nil

  defp fill("run", _, true),
    do: {[@fill_loop, @fill_run], "transform:scaleX(.04)"}

  defp fill("run", p, _), do: {[@fill, @fill_run], "transform:scaleX(#{scale(p)})"}
  defp fill("done", _, _), do: {[@fill, @fill_done], "transform:none"}
  defp fill("fail", _, _), do: nil

  # `.42`, `1`: the fill's scale, without the leading zero.
  defp scale(p) do
    case Float.round(max(0, min(100, p)) / 100, 2) do
      1.0 -> "1"
      f -> f |> Float.to_string() |> String.replace_prefix("0.", ".")
    end
  end

  # in the loop the number is a counter drawn by CSS (`--n` runs from 4 to 100)
  defp pct("run", _, true), do: ""
  defp pct("run", p, _), do: "#{p}%"
  defp pct("done", _, _), do: "100%"
  defp pct(_, _, _), do: nil

  defp dismiss_card(%{dismissible: false}, _), do: nil

  defp dismiss_card(%{on_dismiss: on_dismiss}, aura?) do
    hide =
      JS.hide(
        to: {:closest, if(aura?, do: "[data-part=toast-aura]", else: "[data-part=toast-card]")}
      )

    case on_dismiss do
      %JS{} = js -> JS.concat(hide, js)
      _ -> hide
    end
  end

  defp toast_card_body(assigns) do
    ~H"""
    <div data-part="toast-card" id={@id} class={[@classes, @class]} {@rest}>
      <span :if={@fill} data-part="toast-fill" class={elem(@fill, 0)} style={elem(@fill, 1)}></span>
      <span :if={@icon || @icon_tile != []} data-part="toast-tile" class={@tile_cls}>
        <span
          :if={@tile_level}
          data-part="toast-tile-fill"
          class={@tile_fill_cls}
          style={@tile_level}
        ></span>{if @icon_tile == [], do: icon_tag(@icon), else: render_slot(@icon_tile)}
      </span>
      <div data-part="toast-body" class={@body_cls}>
        <b data-part="toast-title">{@title}</b>
        <span :if={@description} data-part="toast-description" class={@desc_cls}>{@description}</span>
        <div
          :if={@segs}
          data-part="toast-segs"
          class={@segs_cls}
          role="progressbar"
          aria-valuemin="0"
          aria-valuemax={@steps}
          aria-valuenow={@step}
        >
          <i :for={cls <- @segs} data-part="toast-seg" class={cls}></i>
        </div>
      </div>
      {render_slot(@action)}
      <.spinner
        :if={@spin}
        variant="border"
        size="sm"
        color="primary"
        label={@busy_label}
        class="self-center"
      />
      <span :if={@pct} data-part="toast-pct" class={@pct_cls}>{@pct}</span>
      <button
        :if={@dismissible}
        type="button"
        data-part="toast-close"
        class={@close_cls}
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

  attr :status, :string,
    default: nil,
    values: [nil, "run", "queue", "ok", "err"],
    doc: "The same as `state`; it wins when given."

  attr :percent, :integer, default: nil
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(action action_variant),
    doc:
      "`title=\"...\"` is the message when there is no inner block; `action=\"Cancel\"` is a text button after it " <>
        "(the `:action` slot takes real ones); `action_variant=\"ghost\"` draws it as text only, without a background."

  slot :action do
    attr :ghost, :boolean
    attr :variant, :string, doc: "`\"ghost\"`: text only, no background (the same as `ghost`)."
    attr :on_click, :any
    attr :id, :string
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
  end

  slot :inner_block

  def status_toast(assigns) do
    changed0 = assigns.__changed__
    {title, rest} = Map.pop(assigns.rest, :title)
    {action_rest, rest} = Map.pop(rest, :action)
    {action_variant, rest} = Map.pop(rest, :action_variant)
    # `action` is a slot; the string form is left in the assigns by Phoenix
    {action, actions} =
      case assigns.action do
        text when is_binary(text) -> {text, []}
        list when is_list(list) -> {action_rest, list}
        _ -> {action_rest, []}
      end

    assigns = assign(assigns, state: assigns.status || assigns.state, action: actions)

    assigns =
      assigns
      |> assign(:attrs, Map.put_new(rest, :role, "status"))
      |> assign(:title_text, title)
      |> assign(:action_text, action)
      |> assign(:action_ghost?, to_string(action_variant) == "ghost")
      |> assign(:custom_msg?, !LedgerUI.Components.Modal.Support.blank?(assigns.inner_block))
      |> assign(:stoast, @stoast)
      |> assign(:msg_cls, @msg)
      |> assign(:act, @act)
      |> assign(:act_ghost, @act_ghost)
      |> assign(:lead, lead(assigns.state, assigns.percent))
      |> assign(:dot_ok, @dot <> " " <> @dot_ok)
      |> assign(:dot_err, @dot <> " " <> @dot_err)
      |> assign(:liquid, @st_liquid)

    # A new message or action text does not send the classes again.
    assigns =
      settle(assigns, changed0,
        attrs: [:rest],
        title_text: [:rest],
        action_text: [:rest, :action],
        action_ghost?: [:rest],
        custom_msg?: [:inner_block],
        stoast: [],
        msg_cls: [],
        act: [],
        act_ghost: [],
        lead: [:state, :status, :percent],
        dot_ok: [],
        dot_err: [],
        liquid: []
      )

    ~H"""
    <div data-part="status-toast" class={[@stoast, @class]} {@attrs}>
      <span
        :if={@state in ["run", "queue"]}
        data-part="status-toast-lead"
        class={elem(@lead, 0)}
        {lead_attrs(@lead)}
      ><i
        :if={@state == "run"}
        data-part="status-toast-liquid"
        class={@liquid}
      ></i><i :if={@state == "queue"} data-part="status-toast-liquid" class="hidden"></i></span>
      <span :if={@state == "ok"} data-part="status-toast-dot" class={@dot_ok}></span>
      <span :if={@state == "err"} data-part="status-toast-dot" class={@dot_err}></span>
      <span data-part="status-toast-msg" class={@msg_cls}>{if @custom_msg?,
        do: render_slot(@inner_block),
        else: @title_text}</span>
      <button
        :if={@action_text}
        type="button"
        data-part="status-toast-action"
        class={if @action_ghost? or @state in ["run", "queue"], do: @act_ghost, else: @act}
      >{@action_text}</button>
      <%= for a <- @action do %>
        <.link
          :if={a[:href] || a[:navigate] || a[:patch]}
          id={a[:id]}
          data-part="status-toast-action"
          class={if ghost?(a), do: @act_ghost, else: @act}
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
          data-part="status-toast-action"
          class={if ghost?(a), do: @act_ghost, else: @act}
          phx-click={click(a[:on_click])}
        >
          {render_slot(a)}
        </button>
      <% end %>
    </div>
    """
  end

  # the lead of a running toast fills by itself, unless the level is known (`percent`)
  defp lead_attrs({_, nil}), do: %{}
  defp lead_attrs({_, style}), do: %{style: style}

  defp lead("queue", _), do: {@st_queue, nil}
  defp lead("run", nil), do: {@st <> " " <> @st_auto, nil}
  defp lead("run", percent), do: {@st, "--lu-stp:#{percent}%"}
  defp lead(_, _), do: {@st, nil}

  defp ghost?(a), do: !!a[:ghost] or to_string(a[:variant]) == "ghost"

  defp click(nil), do: nil
  defp click(%JS{} = js), do: js
  defp click(event) when is_binary(event), do: JS.push(event)

  # ---------------------------------------------------------------------------
  # toast_loop
  # ---------------------------------------------------------------------------

  @loop_stack [
    "animate-[lu-ts1_9s_cubic-bezier(.3,.7,.4,1)_infinite] motion-reduce:animate-none",
    "animate-[lu-ts2_9s_cubic-bezier(.3,.7,.4,1)_infinite] opacity-0 motion-reduce:animate-none",
    "animate-[lu-ts3_9s_cubic-bezier(.3,.7,.4,1)_infinite] opacity-0 motion-reduce:animate-none"
  ]
  @loop_swap [
    "animate-[lu-swapa_5s_ease_infinite] motion-reduce:animate-none",
    "animate-[lu-swapb_5s_ease_infinite] opacity-0 motion-reduce:animate-none"
  ]

  attr :mode, :string,
    default: "stack",
    values: ~w(stack swap),
    doc:
      "`stack`: up to three toasts come in one after the other and pile up (9s loop); `swap`: the first one " <>
        "(a loading toast) gives way to the second (its answer), in the same place (5s loop)."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :toast,
    required: true,
    doc:
      "A toast (`toast_card/1`, `status_toast/1`...): three at most for `stack`, two for `swap`."

  @doc """
  The loop of the toaster, for docs and design reviews (CSS only, no hook, no behaviour): the toasts
  of the `:toast` slots enter and pile up (`mode="stack"`) or swap in place (`mode="swap"`).

      <.toast_loop mode="swap" class="w-[380px]">
        <:toast><.toast_card kind="primary" icon="sparkles" title="Issuing NF-e…" busy /></:toast>
        <:toast><.toast_card kind="success" icon="check-circle" title="NF-e authorised" /></:toast>
      </.toast_loop>
  """
  def toast_loop(%{mode: "swap"} = assigns) do
    assigns = assign(assigns, :anims, Enum.zip(assigns.toast, @loop_swap))

    ~H"""
    <div
      data-part="toast-loop"
      data-mode="swap"
      class={["grid *:col-start-1 *:row-start-1", @class]}
      {@rest}
    >
      <div :for={{toast, anim} <- @anims} data-part="toast-loop-slot" class={anim}>
        {render_slot(toast)}
      </div>
    </div>
    """
  end

  def toast_loop(assigns) do
    assigns = assign(assigns, :anims, Enum.zip(Enum.take(assigns.toast, 3), @loop_stack))

    ~H"""
    <div data-part="toast-loop" data-mode="stack" class={["relative h-24", @class]} {@rest}>
      <div
        :for={{toast, anim} <- @anims}
        data-part="toast-loop-slot"
        class={["absolute inset-x-0 bottom-0", anim]}
      >
        {render_slot(toast)}
      </div>
    </div>
    """
  end
end
