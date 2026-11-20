defmodule LedgerUI.Components.CashTimer do
  @moduledoc """
  Status card of a cash register shift: an icon in the colour of the state, a title and a line, the
  time the register has been open (ticking in the browser) and a balance, a difference or an action.

      <.cash_timer id="register-2" state="open" title="Caixa 2 aberto" subtitle="desde 08:00 · Marina"
        elapsed={24_130} amount="R$ 6.412,30" />

      <.cash_timer id="register-2" state="closed" title="Caixa 2 fechado" subtitle="ontem às 18:04">
        <:action><button class="lu-b c-mono v-solid s-sm">Abrir caixa</button></:action>
      </.cash_timer>

      <.cash_timer id="check-2" state="alert" title="Conferência do caixa 2" difference="− R$ 12,50">
        <:stat label="Esperado">R$ 6.412,30</:stat>
        <:stat label="Contado">R$ 6.399,80</:stat>
      </.cash_timer>

  `state` colours the icon (`open` green, `closed` neutral, `alert` amber; the `difference` takes
  the amber). `elapsed` (seconds) shows the clock, which counts up in the browser with the
  `LedgerUI.Timer` hook while the state is `open` and `running`; a new `elapsed` from the server
  resets it. `amount_label` (default `"Em caixa"`) names the balance.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Timer, only: [format: 2]

  @tones %{"open" => "pos", "closed" => nil, "alert" => "warn"}

  attr :id, :string, required: true
  attr :state, :string, default: "open", values: ~w(open closed alert)
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil

  attr :elapsed, :integer,
    default: nil,
    doc: "Seconds the register has been open: shows the clock."

  attr :running, :boolean, default: true
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
      |> assign(:classes, cx(["lu-panel lu-cash", assigns.state, assigns.class]))
      |> assign(:tile, cx(["lu-ic", @tones[assigns.state], "lg"]))
      |> assign(
        :line,
        if(assigns.subtitle, do: assigns.title <> " · " <> assigns.subtitle, else: assigns.title)
      )
      |> assign(:time, assigns.elapsed && format(assigns.elapsed, "hms"))
      |> assign(:clock_id, assigns.id <> "-clock")
      |> assign(:live?, live?)

    ~H"""
    <div
      id={@id}
      data-part="cash-timer"
      class={@classes}
      style="padding:14px 16px;display:flex;flex-wrap:wrap;align-items:center;gap:16px;max-width:520px"
      {@rest}
    >
      <span class={@tile}><.icon name="timer" size="lg" /></span>
      <div class="lu-col lu-grow" style="gap:2px">
        <span class="lu-xs lu-muted">{@line}</span>
        <b
          :if={@time && @live?}
          id={@clock_id}
          class="mono"
          style="font-size:28px;letter-spacing:-.02em"
          phx-hook="LedgerUI.Timer"
          data-lu-time-self
          data-lu-elapsed={@elapsed}
          data-lu-total="31536000"
          data-lu-running="true"
          data-lu-direction="up"
          data-lu-format="hms"
        >
          {@time}
        </b>
        <b :if={@time && !@live?} class="mono" style="font-size:28px;letter-spacing:-.02em">{@time}</b>
      </div>
      <div :if={@amount || @difference} class="lu-col" style="gap:2px;text-align:right">
        <span :if={@amount} class="lu-xs lu-muted">{@amount_label}</span>
        <b :if={@amount} class="num">{@amount}</b>
        <b :if={@difference} class="num" style="color:var(--warn)">{@difference}</b>
      </div>
      {render_slot(@action)}
      <div
        :if={@stat != []}
        style="flex-basis:100%;display:flex;gap:24px;padding-top:10px;border-top:1px solid var(--line)"
      >
        <div :for={s <- @stat} class="lu-col" style="gap:2px">
          <span class="lu-xs lu-muted">{s[:label]}</span>
          <b class="num">{render_slot(s)}</b>
        </div>
      </div>
    </div>
    """
  end
end
