defmodule LedgerUI.Components.CashTimer do
  @moduledoc """
  Status card of a cash register shift: an icon in the colour of the state, a title and a line, the
  time the register has been open (ticking in the browser) and a balance, a difference or an action.

      <.cash_timer id="register-2" state="open" title="Caixa 2 aberto" subtitle="desde 08:00 · Marina"
        elapsed={24_130} amount="R$ 6.412,30" />

      <.cash_timer id="register-2" state="closed" title="Caixa 2 fechado" subtitle="ontem às 18:04">
        <:action><.button color="mono" size="sm">Abrir caixa</.button></:action>
      </.cash_timer>

      <.cash_timer id="check-2" state="alert" title="Conferência do caixa 2" difference="− R$ 12,50">
        <:stat label="Esperado">R$ 6.412,30</:stat>
        <:stat label="Contado">R$ 6.399,80</:stat>
      </.cash_timer>

  `state` styles the card (`closed` dimmed, `alert` ringed in amber; the `difference` takes the
  amber); the icon tile is always the accent colour. `elapsed` (seconds) shows the clock, which counts up in the browser with the
  `LedgerUI.Timer` hook while the state is `open` and `running`; a new `elapsed` from the server
  resets it. `amount_label` (default `"Em caixa"`) names the balance. Styled only with Tailwind
  utilities.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Timer, only: [format: 2]

  @card "flex max-w-[520px] items-center gap-4 rounded-lg border border-line bg-panel px-4 py-3.5"
  @states %{
    "open" => nil,
    "closed" => "opacity-70",
    "alert" => "shadow-[0_0_0_1px_var(--lu-warn),0_0_0_4px_var(--lu-warn-soft)]"
  }
  @clock "font-mono text-[28px] tracking-[-.02em]"

  attr :id, :string, required: true
  attr :state, :string, default: "open", values: ~w(open closed alert)
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil

  attr :elapsed, :integer,
    default: nil,
    doc: "Seconds the register has been open: shows the clock."

  attr :running, :boolean, default: true

  attr :static, :boolean,
    default: false,
    doc: "No hook: the open clock stays on `elapsed` (it only blinks), as in the canvas samples."

  attr :amount, :string, default: nil
  attr :amount_label, :string, default: "Em caixa"
  attr :difference, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "A button at the right."

  slot :stat, doc: "A figure in the row under the head." do
    attr :label, :string
  end

  def cash_timer(assigns) do
    live? = assigns.state == "open" and assigns.running and assigns.elapsed != nil

    assigns =
      assigns
      |> assign(
        :classes,
        cx([@card, assigns.stat != [] && "flex-wrap", @states[assigns.state], assigns.class])
      )
      |> assign(
        :line,
        if(assigns.subtitle, do: assigns.title <> " · " <> assigns.subtitle, else: assigns.title)
      )
      |> assign(:time, assigns.elapsed && format(assigns.elapsed, "hms"))
      |> assign(:clock_id, assigns.id <> "-clock")
      |> assign(:clock_class, @clock)
      |> assign(:live?, live?)

    ~H"""
    <div id={@id} data-part="cash-timer" class={@classes} {@rest}>
      <.icon boxed tone="accent" box_size="lg" name="timer" size="lg" />
      <div data-part="cash-timer-body" class="flex min-w-0 flex-1 flex-col gap-0.5">
        <span data-part="cash-timer-line" class="text-xs/4 text-muted">{@line}</span>
        <b
          :if={@time && @live?}
          id={@clock_id}
          data-part="cash-timer-clock"
          class={@clock_class}
          phx-hook={!@static && "LedgerUI.Timer"}
          data-lu-elapsed={@elapsed}
          data-lu-total="31536000"
          data-lu-running="true"
          data-lu-direction="up"
          data-lu-format="hms"
        >
          <span
            data-part="cash-timer-time"
            class="animate-[mo-blink_1.4s_ease-in-out_infinite]"
            data-lu-time
          >{@time}</span>
        </b>
        <b :if={@time && !@live?} data-part="cash-timer-clock" class={@clock_class}>{@time}</b>
      </div>
      <div
        :if={@amount || @difference}
        data-part="cash-timer-amount"
        class="flex flex-col gap-0.5 text-right"
      >
        <span :if={@amount} data-part="cash-timer-amount-label" class="text-xs/4 text-muted">
          {@amount_label}
        </span>
        <b :if={@amount} data-part="cash-timer-amount-value" class="tabular-nums">{@amount}</b>
        <b :if={@difference} data-part="cash-timer-difference" class="tabular-nums text-warn">
          {@difference}
        </b>
      </div>
      {render_slot(@action)}
      <div
        :if={@stat != []}
        data-part="cash-timer-stats"
        class="flex basis-full gap-6 border-t border-line pt-2.5"
      >
        <div :for={s <- @stat} data-part="cash-timer-stat" class="flex flex-col gap-0.5">
          <span data-part="cash-timer-stat-label" class="text-xs/4 text-muted">{s[:label]}</span>
          <b data-part="cash-timer-stat-value" class="tabular-nums">{render_slot(s)}</b>
        </div>
      </div>
    </div>
    """
  end
end
