defmodule LedgerUI.Components.ChartTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Chart

  test "line chart is server rendered with a pinned tooltip" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.line_chart
  id="l"
  labels={~w(a b c)}
  pin={1}
  head="+1"
  series={[%{name: "x", values: [1, 2, 3], area: true}]}
/>|)

    assert html =~ "lu-line"
    assert html =~ "data-chart"
    assert html =~ "lu-tip"
    assert html =~ "LedgerUI.LineChart"
  end

  test "empty line chart renders only the container" do
    assigns = %{}
    html = rendered_to_string(~H|<.line_chart id="l" />|)
    refute html =~ "<svg"
  end

  test "donut shares and rows" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.donut_chart id="d" segments={[%{name: "A", value: 3}, %{name: "B", value: 1}]} />|
      )

    assert html =~ "75.0%"
    assert html =~ "lu-plan-row"
  end

  test "waterfall, bars, cohort, bar_list and heatmap" do
    assigns = %{}

    assert rendered_to_string(
             ~H|<.waterfall_chart steps={[%{name: "a", value: 1000, label: "+1k"}]} />|
           ) =~ "lu-wf-l"

    assert rendered_to_string(~H|<.bar_chart values={[10, 20]} />|) =~ "class=\"on\""

    html =
      rendered_to_string(
        ~H|<.cohort_heatmap columns={~w(M0)} rows={[%{label: "J", values: [100, nil]}]} />|
      )

    assert html =~ "c l5"

    html = rendered_to_string(~H|<.bar_list>
  <:item label="a" value="1" amount={5} /><:item label="b" value="2" amount={10} />
</.bar_list>|)
    assert html =~ "width:50%"

    assert rendered_to_string(~H|<.heatmap levels={[0, 4]} label="x" less="a" more="b" />|) =~
             "role=\"img\""
  end

  test "generic chart wraps options for the hook" do
    assigns = %{}
    html = rendered_to_string(~H|<.chart id="c" options={%{chart: %{type: "bar"}}} />|)
    assert html =~ "LedgerUI.Chart"
    assert html =~ "phx-update=\"ignore\""
  end
end
