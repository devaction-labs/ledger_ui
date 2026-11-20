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
          "lu-cash open",
          "lu-ic acc lg",
          "Caixa 2 · desde 08:00",
          "mo-blink",
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
    assert closed =~ "lu-cash closed"
    paused = rendered_to_string(~H|<.cash_timer id="r" title="T" elapsed={60} running={false} />|)
    refute paused =~ "phx-hook"
    assert rendered_to_string(~H|<.cash_timer id="r" title="T" />|) =~ "lu-cash open"
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
          "lu-cash alert",
          "lu-ic acc lg",
          "− R$ 12,50",
          "var(--warn)",
          "Esperado",
          "R$ 6.399,80",
          "<button>Open</button>"
        ],
        do: assert(html =~ c)
  end
end
