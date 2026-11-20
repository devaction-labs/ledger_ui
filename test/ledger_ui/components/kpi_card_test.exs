defmodule LedgerUI.Components.KpiCardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.KpiCard

  test "canvas card with delta tone and spark" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.kpi_card
  id="k"
  label="Churn"
  value="2.1"
  unit="%"
  delta="0.4"
  trend="up"
  delta_tone="error"
  spark={[1, 3, 2]}
/>|)

    assert html =~ "lu-delta bad-up"
    assert html =~ "arr neg"
    assert html =~ "lu-kpi-spark"
    assert html =~ "k-spark-fill"
  end

  test "badge variant counts and colors" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.kpi_card variant="badge" color="neutral" label="A" count={5} delta="1" trend="down" />|
      )

    assert html =~ "c-neutral"
    assert html =~ "--to:5"
    assert html =~ "lu-badge neg"
    assert html =~ "↘"
  end

  test "progress and loading" do
    assigns = %{}

    assert rendered_to_string(~H|<.kpi_card label="A" progress={40} caption="c" />|) =~
             "width:40%"

    assert rendered_to_string(~H|<.kpi_card loading />|) =~ "aria-busy"
  end
end
