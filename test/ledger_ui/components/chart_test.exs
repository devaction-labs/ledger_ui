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

  describe "bar_chart y axis" do
    alias LedgerUI.Components.Chart

    test "nice_ticks" do
      assert Chart.nice_ticks(95) == [0, 25, 50, 75, 100]
      assert Chart.nice_ticks(1.7) == [0, 0.5, 1, 1.5, 2]
      assert Chart.nice_ticks(2) == [0, 0.5, 1, 1.5, 2]
      assert Chart.nice_ticks(12_000) == [0, 5000, 10_000, 15_000]
      assert Chart.nice_ticks(0) == [0, 1]
    end

    test "without the attrs the HTML has no axis" do
      assigns = %{}
      html = rendered_to_string(~H|<.bar_chart values={[10, 50]} labels={~w(a b)} />|)
      refute html =~ "bar-chart-y-axis"
      refute html =~ "bar-chart-frame"
      assert html =~ "height:50%"
      assert html =~ ~s(data-part="bar-chart")
    end

    test "y_axis: ticks at their height, bars relative to the top tick" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.bar_chart y_axis values={[0.5, 1.7]} labels={~w(a b)} />|)

      assert html =~ ~s(data-part="bar-chart-y-axis")
      assert html =~ "bottom:100%"
      assert html =~ "bottom:50%"
      assert html =~ "0,5"
      assert html =~ "height:85%"
      assert html =~ "height:25%"
      refute html =~ "bar-chart-grid-line"
    end

    test "y_ticks, y_grid and y_format" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.bar_chart y_ticks={[0, 1, 2]} y_grid y_format={&"US$ #{&1}"} values={[1]} />|
        )

      assert html =~ "US$ 2"
      assert html =~ "height:50%"
      assert length(String.split(html, "bar-chart-grid-line")) == 4

      html =
        rendered_to_string(~H|<.bar_chart y_axis y_format="brl_thousands" values={[12_000]} />|)

      assert html =~ "R$ 5 mil"
    end
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

  test "generic chart serializes band, markers, curve and dash options, and ships the node classes" do
    assigns = %{
      opts: %{
        chart: %{type: "line"},
        series: [%{name: "A", data: [1, nil, 3]}],
        annotations: %{xaxis: [%{x: "a", x2: "b", tone: "neg", label: %{text: "Ruptura"}}]},
        markers: %{size: [4]},
        stroke: %{curve: "straight", dashArray: [6]}
      }
    }

    html = rendered_to_string(~H|<.chart id="bd" options={@opts} />|)

    assert [_, json] = Regex.run(~r/data-options="([^"]*)"/, html)
    opts = json |> unescape() |> Jason.decode!()
    assert [%{"tone" => "neg", "x2" => "b"}] = opts["annotations"]["xaxis"]
    assert opts["markers"] == %{"size" => [4]}
    assert opts["stroke"] == %{"curve" => "straight", "dashArray" => [6]}
    assert hd(opts["series"])["data"] == [1, nil, 3]

    assert [_, cls] = Regex.run(~r/data-lu-cls="([^"]*)"/, html)
    cls = cls |> unescape() |> Jason.decode!()
    assert cls["marker"] =~ "stroke-panel"
    assert Map.has_key?(cls, "band")
    # what the shared tooltip builds comes from the same classes as the line chart's tooltip
    for k <- ~w(tip tip_title tip_row tip_name tip_value tip_dot tip_total guide hit) do
      assert is_binary(cls[k]) and cls[k] != "", "missing class #{k}"
    end

    assert cls["tip"] =~ "pointer-events-none"
  end

  describe "pt-BR formatters" do
    test "thousands_br" do
      assert format_thousands_br(12_000) == "12 mil"
      assert format_thousands_br(1_500) == "1,5 mil"
      assert format_thousands_br(999) == "999"
      assert format_thousands_br(-12_000) == "-12 mil"
      assert format_thousands_br(0) == "0"
    end

    test "k" do
      assert format_k(12_000) == "12k"
      assert format_k(1_500) == "1,5k"
      assert format_k(1_500.0) == "1,5k"
      assert format_k(250) == "250"
    end

    test "brl_thousands" do
      assert format_brl_thousands(12_000) == "R$ 12 mil"
      assert format_brl_thousands(1_500) == "R$ 1,5 mil"
      assert format_brl_thousands(500) == "R$ 500"
    end

    test "brl_full" do
      assert format_brl_full(1234.56) == "R$ 1.234,56"
      assert format_brl_full(12_000) == "R$ 12.000,00"
      assert format_brl_full(5) == "R$ 5,00"
      assert format_brl_full(0.5) == "R$ 0,50"
      assert format_brl_full(-1234.5) == "-R$ 1.234,50"
      assert format_brl_full(1_234_567.891) == "R$ 1.234.567,89"
    end

    test "usable as line_chart axis and value formats" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.line_chart
  id="fm"
  labels={~w(a b)}
  series={[%{name: "x", values: [1500, 12000]}]}
  axis_format={&format_k/1}
  value_format={&format_brl_thousands/1}
/>|)

      assert html =~ "12k"
      assert html =~ "R$ 12 mil"
    end
  end

  describe "line_chart with nil points" do
    defp nil_chart(extra \\ []) do
      assigns = %{extra: extra}

      rendered_to_string(~H|<.line_chart
  id="ln"
  labels={~w(a b c d)}
  pin={2}
  series={[
    %{name: "Real", values: [10, 20, nil, 40], area: true},
    %{name: "Meta", values: [nil, nil, nil, nil]},
    %{name: "Proj", values: [5, 6, 7, 8], dashed: true}
  ]}
  {@extra}
/>|)
    end

    test "breaks the line and the area at the hole, never at zero" do
      html = nil_chart()

      [d] =
        Regex.run(~r/data-part="line-chart-line"[^>]*? d="([^"]*)"/, html,
          capture: :all_but_first
        )

      assert length(String.split(d, "M")) == 3
      assert [_, area] = Regex.run(~r/data-part="line-chart-area"[^>]*? d="([^"]*)"/, html)
      assert length(String.split(area, "Z")) == 3

      # the axis range ignores the holes: 5..40, not 0..40
      assert html =~ "&quot;min&quot;:5"
      assert html =~ "&quot;grid_labels&quot;:[&quot;$5&quot;"
    end

    test "tooltip shows an em dash and the pinned dots of empty series are hidden" do
      html = nil_chart()
      assert html =~ ~s(<em data-part="line-chart-tip-value")
      assert html =~ "\u2014"
      # chart data for the hook: null values and null ys
      assert [_, json] = Regex.run(~r/data-lu-chart-data="([^"]*)"/, html)
      data = json |> String.replace("&quot;", ~s(")) |> Jason.decode!()
      assert Enum.at(data["values"], 0) == [10, 20, nil, 40]
      assert Enum.at(data["ys"], 1) == [nil, nil, nil, nil]
      assert hd(Enum.at(data["tips"], 2)["rows"]) == ["Real", "\u2014", "acc"]
      assert html =~ ~s(style="display:none")
    end

    test "a series with only nils has a hidden endpoint" do
      html = nil_chart()

      assert html =~
               ~r/data-part="line-chart-endpoint"[^>]*style="display:none"|style="display:none"[^>]*data-part="line-chart-endpoint"/
    end

    test "without nil the markup keeps its endpoint visible" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.line_chart id="l2" labels={~w(a b)} series={[%{values: [1, 2]}]} />|
        )

      assert html =~ ~r/<circle[^>]*line-chart-endpoint[^>]*cx=/
    end
  end

  test "generic chart passes the tooltip formatter name and total flag" do
    assigns = %{opts: %{chart: %{type: "bar", stacked: true}, tooltip: %{total: true}}}

    html =
      rendered_to_string(
        ~H|<.chart id="tp" options={@opts} formatters={%{"tooltip.y.formatter" => "brl_thousands"}} />|
      )

    assert [_, json] = Regex.run(~r/data-options="([^"]*)"/, html)
    assert (json |> unescape() |> Jason.decode!())["tooltip"] == %{"total" => true}
    assert [_, f] = Regex.run(~r/data-formatters="([^"]*)"/, html)
    assert f |> unescape() |> Jason.decode!() == %{"tooltip.y.formatter" => "brl_thousands"}
  end

  defp unescape(s) do
    s
    |> String.replace("&quot;", ~s("))
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
  end
end
