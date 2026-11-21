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

    assert html =~ ~s(data-part="line-chart-line")
    assert html =~ "data-chart"
    assert html =~ ~s(data-part="line-chart-tip")
    assert html =~ "LedgerUI.LineChart"
    # utilities, never the legacy classes; the hook gets the classes of the nodes it builds
    assert html =~ "stroke-chart-grid"
    assert html =~ "fill-accent-500"
    assert html =~ "data-lu-config"
    refute html =~ "lu-line"
    refute html =~ "lu-tip"
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

    assert html =~ "75%"
    assert html =~ ~s(data-part="donut-chart-row")
    # the ring pivot (transform-box/origin) of the 0.2.0 fix and the chart token colours
    assert html =~ "[transform-box:view-box]"
    assert html =~ "var(--lu-chart-1)"
    assert html =~ "var(--lu-chart-2)"
    refute html =~ "lu-plan-row"
  end

  test "waterfall_chart loop grows the bars with the mo-bar animation instead of a one-shot transition" do
    assigns = %{}

    once =
      rendered_to_string(
        ~H|<.waterfall_chart steps={[%{name: "a", value: 1000, label: "+1k"}]} />|
      )

    loop =
      rendered_to_string(
        ~H|<.waterfall_chart loop steps={[%{name: "a", value: 1000, label: "+1k"}]} />|
      )

    assert once =~ "starting:scale-y-0"
    refute loop =~ "starting:scale-y-0"
    assert loop =~ "animate-[mo-bar_6s_cubic-bezier(.2,.8,.2,1)_infinite]"
    assert loop =~ "animation-delay:"
  end

  test "waterfall, bars, cohort, bar_list and heatmap" do
    assigns = %{}

    assert rendered_to_string(
             ~H|<.waterfall_chart steps={[%{name: "a", value: 1000, label: "+1k"}]} />|
           ) =~ ~s(data-part="waterfall-chart-label")

    html = rendered_to_string(~H|<.bar_chart values={[10, 20]} />|)
    assert html =~ "bg-accent-500"
    assert html =~ "bg-chart-5"

    html =
      rendered_to_string(
        ~H|<.cohort_heatmap columns={~w(M0)} rows={[%{label: "J", values: [100, nil]}]} />|
      )

    assert html =~ "bg-accent-600"

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

  test "line_chart sub_delta adds the colored change after the muted text" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.line_chart
  id="l"
  labels={~w(a b)}
  head="R$ 1"
  sub="no mês"
  sub_delta="+12%"
  series={[%{name: "x", values: [1, 2]}]}
/>|)

    assert html =~ "no mês"
    assert html =~ "text-pos"
    assert html =~ "+12%"
  end

  test "series colours given with the canvas names read the lu tokens" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.line_chart
  id="l"
  labels={~w(a b)}
  series={[
    %{values: [1, 2], dashed: true, color: "var(--chart-ghost)"},
    %{values: [2, 1], color: "var(--chart-3)"}
  ]}
/>|)

    assert html =~ "stroke:var(--lu-chart-ghost)"
    assert html =~ "stroke:var(--lu-chart-3)"
    refute html =~ "var(--chart-"
    assert LedgerUI.Components.Chart.tok("var(--lu-chart-2)") == "var(--lu-chart-2)"
    assert LedgerUI.Components.Chart.tok("#fff") == "#fff"
  end

  test "the line chart is drawn once, without a looping redraw" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.line_chart id="l" labels={~w(a b)} series={[%{values: [1, 2], area: true}]} />|
      )

    assert html =~ "starting:"
    refute html =~ "infinite"
    refute html =~ "mo-line"
  end

  test "the generic chart hands the hook its utility classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.chart id="c" options={%{chart: %{type: "line"}}} />|)
    assert html =~ "data-lu-cls"
    assert html =~ "stroke-chart-grid"
  end

  test "generic chart serializes the stacked options for the hook" do
    assigns = %{
      opts: %{
        chart: %{type: "bar", stacked: true},
        plotOptions: %{bar: %{horizontal: true}},
        series: [%{name: "A", data: [1, 2]}, %{name: "B", data: [3, nil]}]
      }
    }

    html = rendered_to_string(~H|<.chart id="st" options={@opts} />|)

    assert html =~ "LedgerUI.Chart"
    assert [_, json] = Regex.run(~r/data-options="([^"]*)"/, html)
    opts = json |> unescape() |> Jason.decode!()
    assert opts["chart"]["stacked"] == true
    assert opts["plotOptions"]["bar"]["horizontal"] == true
    assert [%{"data" => [3, nil]} | _] = Enum.drop(opts["series"], 1)
  end

  defp unescape(s) do
    s
    |> String.replace("&quot;", ~s("))
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
  end
end
