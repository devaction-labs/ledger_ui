defmodule LedgerUI.Components.Timer do
  @moduledoc """
  A timer that ticks in the browser: a ring with the time in the middle (a shift, a countdown, any
  stretch of time) and a small pill of it for a top bar.

      <.timer id="shift" elapsed={@shift_seconds} running={@running} kicker="Register open"
        kicker_paused="Paused" label="Register 01" on_toggle="shift_toggled">
        <:actions>
          <button phx-click={LedgerUI.Timer.toggle("shift")}>Pause</button>
          <button phx-click={LedgerUI.Timer.add("shift", 900)}>+15 min</button>
        </:actions>
      </.timer>

      <.timer id="break" direction="down" total={900} elapsed={0} color="warning" on_finish="break_over" />
      <.timer id="mini" variant="mini" elapsed={@seconds} running={@running} label="Shift time" />

  The server owns the time (`elapsed`, `running`, `total`, `direction`); the `LedgerUI.Timer`
  hook counts from there on a monotonic clock with no round trip, and a new value from the server
  replaces what the browser counted. `format` is `hms` (`03:12:45`), `hm` (`3h12`) or `hh:mm`.

  The timer is `role="timer"` named by `label`; the ticking text is not a live region. `color`
  is the ring while it runs (nothing is added by default); paused is always warning (the hook flips
  `data-state` between `running` and `paused`). Styled only with Tailwind utilities.

  Events (`on_toggle`, `on_tick`, `on_finish`) take an event name or a `%JS{}` and go to `target`.
  Browser commands live in `LedgerUI.Timer` (`pause/1`, `resume/1`, `toggle/1`, `add/2`, and the
  `socket` versions to push them from the server).
  """
  use LedgerUI.Component

  alias LedgerUI.Color

  @sizes ~w(sm md lg)
  @colors ~w(neutral primary secondary info success warning error)

  # The ring is a conic gradient up to `--lu-sp`; its colour is `--c` (paused: warning); the
  # disc inside is the `::before`.
  @ring "relative grid size-(--sz) place-items-center rounded-full bg-[conic-gradient(var(--c,var(--lu-accent-600))_var(--lu-sp),var(--lu-bg-sunken)_0)] before:absolute before:inset-[7px] before:rounded-full before:bg-panel before:content-[''] data-[state=paused]:[--c:var(--lu-warn)]"
  @ring_sizes %{"sm" => "[--sz:72px]", "md" => "[--sz:120px]", "lg" => "[--sz:160px]"}
  @mini "inline-flex h-[30px] items-center gap-2 rounded-[8px] bg-sunken px-2.5 font-mono text-[13px]"
  @dot "inline-block size-[7px] flex-none rounded-full bg-neg shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-accent)_22%,transparent)] animate-[mo-blink_1.4s_ease-in-out_infinite]"

  @doc false
  def format(seconds, fmt) do
    s = seconds |> max(0) |> trunc()
    h = div(s, 3600)
    m = div(rem(s, 3600), 60)
    sec = rem(s, 60)

    case fmt do
      "hm" -> "#{h}h#{pad(m)}"
      "hh:mm" -> "#{pad(h)}:#{pad(m)}"
      _ -> "#{pad(h)}:#{pad(m)}:#{pad(sec)}"
    end
  end

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  attr :id, :string, required: true
  attr :elapsed, :integer, default: 0
  attr :total, :integer, default: 28_800

  attr :seconds, :integer,
    default: nil,
    doc:
      "The same as `total` (`seconds={600}` with `direction=\"down\"` is a ten minute countdown)."

  attr :running, :boolean, default: true
  attr :direction, :string, default: "up", values: ~w(up down)
  attr :variant, :string, default: "ring", values: ~w(ring mini)
  attr :size, :string, default: "md", values: @sizes
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :format, :string, default: "auto", values: ~w(auto hms hm hh:mm)
  attr :kicker, :string, default: nil
  attr :kicker_paused, :string, default: nil
  attr :label, :string, default: nil
  attr :stop_at_total, :boolean, default: false
  attr :on_toggle, :any, default: nil
  attr :on_tick, :any, default: nil
  attr :on_finish, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "The controls under the ring (`ring` only)."
  slot :caption, doc: "Replaces the `label` line under the time (`ring` only)."

  def timer(assigns) do
    assigns = assign(assigns, :total, assigns.seconds || assigns.total)

    fmt =
      if assigns.format == "auto",
        do: if(assigns.variant == "mini", do: "hm", else: "hms"),
        else: assigns.format

    shown =
      if assigns.direction == "down", do: assigns.total - assigns.elapsed, else: assigns.elapsed

    assigns =
      assigns
      |> assign(:fmt, fmt)
      |> assign(:time, format(shown, fmt))
      |> assign(:attrs, timer_attrs(assigns, fmt))
      |> assign(
        :extras?,
        assigns.kicker != nil or assigns.label != nil or assigns.caption != [] or
          assigns.actions != []
      )
      |> assign(:sp, sp(assigns))
      |> assign(
        :ring_classes,
        cx([
          @ring,
          @ring_sizes[assigns.size] || @ring_sizes["md"],
          assigns.color && Color.vars(assigns.color),
          assigns.class
        ])
      )
      |> assign(:state, if(assigns.running, do: "running", else: "paused"))
      |> assign(:mini_class, cx([@mini, assigns.class]))
      |> assign(
        :time_class,
        "relative font-mono text-[length:calc(var(--sz)*.2)] tracking-[-.02em]"
      )
      |> assign(:dot_class, @dot)

    ~H"""
    <span
      :if={@variant == "mini"}
      id={@id}
      data-part="timer"
      class={@mini_class}
      phx-hook="LedgerUI.Timer"
      role="timer"
      {@attrs}
    >
      <span :if={@running} data-part="timer-dot" class={@dot_class}></span><span data-lu-time>{@time}</span>
    </span>
    <div
      :if={@variant == "ring" and not @extras?}
      id={@id}
      data-part="timer"
      data-lu-ring
      data-state={@state}
      class={@ring_classes}
      style={"--lu-sp:#{@sp}%"}
      phx-hook="LedgerUI.Timer"
      role="timer"
      {@attrs}
    >
      <b data-part="timer-time" data-lu-time class={@time_class}>{@time}</b>
    </div>
    <div
      :if={@variant == "ring" and @extras?}
      id={@id}
      data-part="timer"
      class="flex flex-col items-center gap-2.5"
      phx-hook="LedgerUI.Timer"
      role="timer"
      {@attrs}
    >
      <span
        :if={@kicker}
        data-part="timer-kicker"
        data-lu-kicker
        data-state={@state}
        class="text-xs/4 tracking-[.08em] text-pos uppercase data-[state=paused]:text-warn"
      >
        {if @running, do: @kicker, else: @kicker_paused || @kicker}
      </span>
      <div
        data-part="timer-ring"
        data-lu-ring
        data-state={@state}
        class={@ring_classes}
        style={"--lu-sp:#{@sp}%"}
      >
        <b data-part="timer-time" data-lu-time class={@time_class}>{@time}</b>
      </div>
      <span
        :if={@caption == [] and @label}
        data-part="timer-label"
        class="text-[13px] leading-[18px] text-muted"
      >{@label}</span>
      {render_slot(@caption)}
      <div :if={@actions != []} data-part="timer-actions" class="flex flex-wrap items-center gap-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  defp sp(a) do
    value = if a.direction == "down", do: a.total - a.elapsed, else: a.elapsed

    if a.total > 0,
      do: Float.round(min(max(value / a.total, 0.0), 1.0) * 100, 1) |> trim(),
      else: 0
  end

  defp trim(f) do
    if f == Float.round(f), do: f |> round() |> Integer.to_string(), else: Float.to_string(f)
  end

  defp timer_attrs(a, fmt) do
    a.rest
    |> Map.merge(%{
      :"data-lu-elapsed" => a.elapsed,
      :"data-lu-total" => a.total,
      :"data-lu-running" => to_string(a.running),
      :"data-lu-direction" => a.direction,
      :"data-lu-format" => fmt,
      :"aria-label" => a.label || "Timer"
    })
    |> put_if(a.stop_at_total, :"data-lu-stop-at-total", "true")
    |> put_if(a.kicker, :"data-lu-kicker", a.kicker)
    |> put_if(a.kicker_paused, :"data-lu-kicker-paused", a.kicker_paused)
    |> put_if(a.target, :"phx-target", a.target)
    |> put_event(:"data-lu-on-toggle", a.on_toggle)
    |> put_event(:"data-lu-on-tick", a.on_tick)
    |> put_event(:"data-lu-on-finish", a.on_finish)
  end

  defp put_if(map, nil, _key, _value), do: map
  defp put_if(map, false, _key, _value), do: map
  defp put_if(map, _, key, value), do: Map.put(map, key, value)

  defp put_event(map, _key, nil), do: map
  defp put_event(map, key, %JS{} = js), do: Map.put(map, :"#{key}-js", Jason.encode!(js))
  defp put_event(map, key, event) when is_binary(event), do: Map.put(map, key, event)
end

defmodule LedgerUI.Timer do
  @moduledoc """
  Commands for a `<.timer>` (see `LedgerUI.Components.Timer`).

  In the browser, with no round trip (`phx-click`):

      phx-click={LedgerUI.Timer.pause("shift")}
      phx-click={LedgerUI.Timer.resume("shift")}
      phx-click={LedgerUI.Timer.toggle("shift")}
      phx-click={LedgerUI.Timer.add("shift", 900)}

  From the server: `LedgerUI.Timer.add(socket, "shift", 900)`, `pause/2`, `resume/2`, `toggle/2`.
  `add` takes time away with a negative number.
  """
  alias Phoenix.LiveView
  alias Phoenix.LiveView.JS

  @event "ledger:timer"

  for op <- ~w(pause resume toggle)a do
    @doc "Browser command: #{op} the timer `id`."
    def unquote(op)(id) when is_binary(id),
      do: dispatch(%JS{}, id, unquote(Atom.to_string(op)), %{})

    @doc "Server command: #{op} the timer `id`."
    def unquote(op)(%LiveView.Socket{} = socket, id),
      do: push(socket, id, unquote(Atom.to_string(op)), %{})
  end

  @doc "Browser command: adds `seconds` to the elapsed time of the timer `id`."
  def add(id, seconds) when is_binary(id), do: dispatch(%JS{}, id, "add", %{"seconds" => seconds})

  @doc "Server command: adds `seconds` to the elapsed time of the timer `id`."
  def add(%LiveView.Socket{} = socket, id, seconds),
    do: push(socket, id, "add", %{"seconds" => seconds})

  defp dispatch(js, id, op, extra),
    do: JS.dispatch(js, @event, to: "#" <> id, detail: Map.put(extra, "op", op))

  defp push(socket, id, op, extra),
    do: LiveView.push_event(socket, @event, extra |> Map.put("op", op) |> Map.put("id", id))
end
