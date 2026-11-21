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

    assert html =~ ~s(data-part="kpi-delta")
    # a bad-news increase: red with an up triangle
    assert html =~ "text-neg"
    assert html =~ "before:border-b-[6px]"
    assert html =~ ~s(data-part="kpi-arrow")
    assert html =~ ~s(data-part="sparkline")
    assert html =~ "k-spark-fill"
    refute html =~ ~r/class="[^"]*\blu-(kpi|card|delta|badge|spark)/
  end

  test "badge variant counts and colors" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.kpi_card variant="badge" color="neutral" label="A" count={5} delta="1" trend="down" />|
      )

    assert html =~ "--to:5"
    assert html =~ ~s(data-part="badge")
    assert html =~ "bg-neg-soft"
    assert html =~ "↘"
  end

  test "progress and loading" do
    assigns = %{}

    assert rendered_to_string(~H|<.kpi_card label="A" progress={40} caption="c" />|) =~
             "width:40%"

    assert rendered_to_string(~H|<.kpi_card loading />|) =~ "aria-busy"
  end

  test "footer slot and value_id are opt-in" do
    assigns = %{}
    base = rendered_to_string(~H|<.kpi_card label="a" value="1" />|)
    refute base =~ "kpi-footer"
    refute base =~ " id="

    html =
      rendered_to_string(~H"""
      <.kpi_card label="a" value="1" value_id="v1">
        <:footer><a href="/r">ver</a></:footer>
      </.kpi_card>
      """)

    assert html =~ ~r/data-part="kpi-value"\s+id="v1"/
    assert html =~ ~s(data-part="kpi-footer")
    assert html =~ ~s(<a href="/r">ver</a>)

    badge =
      rendered_to_string(~H|<.kpi_card variant="badge" label="a" value="1" value_id="v2" />|)

    assert badge =~ ~s(id="v2")
  end
end
