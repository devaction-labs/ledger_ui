defmodule LedgerUI.Components.CashTimerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.CashTimer

  test "open register ticks with the hook" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.cash_timer
  id="r"
  state="open"
  title="Caixa 2"
  subtitle="desde 08:00"
  elapsed={24130}
  amount="R$ 6.412,30"
/>|)

    for c <- [
          "bg-panel",
          ~s(data-part="icon-box"),
          "size-12",
          "Caixa 2 · desde 08:00",
          "animate-[mo-blink_1.4s_ease-in-out_infinite]",
          "data-lu-time",
          "06:42:10",
          ~s(phx-hook="LedgerUI.Timer"),
          ~s(data-lu-elapsed="24130"),
          "Em caixa",
          "R$ 6.412,30"
        ],
        do: assert(html =~ c)
  end

  test "closed and paused registers show a static clock" do
    assigns = %{}

    closed =
      rendered_to_string(~H|<.cash_timer id="r" state="closed" title="T" elapsed={3600} />|)

    assert closed =~ "01:00:00"
    refute closed =~ "phx-hook"
    assert closed =~ "opacity-70"
    paused = rendered_to_string(~H|<.cash_timer id="r" title="T" elapsed={60} running={false} />|)
    refute paused =~ "phx-hook"
    refute rendered_to_string(~H|<.cash_timer id="r" title="T" />|) =~ "opacity-70"
  end

  test "alert state: difference, stats, action" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.cash_timer id="r" state="alert" title="Check" difference="− R$ 12,50" amount_label="Contado">
        <:stat label="Esperado">R$ 6.412,30</:stat>
        <:stat label="Contado">R$ 6.399,80</:stat>
        <:action><button>Open</button></:action>
      </.cash_timer>
      """)

    for c <- [
          "shadow-[0_0_0_1px_var(--lu-warn),0_0_0_4px_var(--lu-warn-soft)]",
          "flex-wrap",
          "size-12",
          "− R$ 12,50",
          "text-warn",
          "Esperado",
          "R$ 6.399,80",
          "<button>Open</button>"
        ],
        do: assert(html =~ c)
  end

  test "static keeps the clock without the hook" do
    assigns = %{}
    html = rendered_to_string(~H|<.cash_timer id="c" title="Caixa" elapsed={60} static />|)
    assert html =~ "00:01:00"
    refute html =~ "phx-hook"
  end
end
