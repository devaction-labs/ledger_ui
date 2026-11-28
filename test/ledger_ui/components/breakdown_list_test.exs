defmodule LedgerUI.Components.BreakdownListTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  defp r(assigns), do: rendered_to_string(assigns)

  @rows [
    %{
      id: "d",
      icon: "home",
      color: "c1",
      label: "Venda direta",
      share: 45,
      detail: "R$ 3,5 mil em trânsito",
      value: 136_000,
      delta: 0.8
    },
    %{
      id: "c",
      icon: "package",
      color: "c2",
      label: "Reposição",
      share: 27,
      value: 82_600,
      delta: -9.9
    }
  ]

  defp brl(v), do: "R$ " <> to_string(Float.round(v / 1000, 1)) <> " mil"

  test "rows: icon frame in the series colour, label, share and detail, value, delta with arrow" do
    assigns = %{rows: @rows}
    html = r(~H|<.breakdown_list rows={@rows} format={&brl/1} />|)
    assert html =~ "Venda direta"
    assert html =~ "45% · R$ 3,5 mil em trânsito"
    assert html =~ "27%"
    assert html =~ "bg-chart-1/15 text-chart-1"
    assert html =~ "bg-chart-2/15 text-chart-2"
    assert html =~ "R$ 136.0 mil"
    assert html =~ ~r/data-tone="pos"[^>]*bg-pos-soft text-pos/
    assert html =~ ~r/data-tone="neg"[^>]*bg-neg-soft text-neg/
    assert html =~ ~s(data-icon="arrow-up")
    assert html =~ ~s(data-icon="arrow-down")
    assert html =~ "+0.8%"
    assert html =~ "−9.9%"
  end

  test "numbers follow the locale" do
    assigns = %{rows: @rows}
    html = r(~H|<.breakdown_list rows={@rows} locale="pt_BR" />|)
    assert html =~ "+0,8%"
    assert html =~ "−9,9%"
    assert html =~ "136.000"
  end

  test "total row, header and footer" do
    assigns = %{rows: @rows}

    html =
      r(~H"""
      <.breakdown_list
        rows={@rows}
        label="Origem"
        delta_label="vs mês passado"
        total={%{value: 303_600, delta: -3.4}}
      >
        <:footer>Nota</:footer>
      </.breakdown_list>
      """)

    assert html =~ ~r/breakdown-head.*Origem.*vs mês passado/s
    assert html =~ ~r/breakdown-total.*Total.*303,600/s
    assert html =~ "Nota"
    pt = r(~H|<.breakdown_list rows={[]} total={%{label: nil, value: 1}} locale="pt_BR" />|)
    assert pt =~ "Total"
  end

  test "a delta_tone overrides the sign (a cost that fell is good) and delta_text the text" do
    assigns = %{
      rows: [%{label: "Custo", value: 1, delta: -2.0, delta_tone: "pos", delta_text: "menos 2"}]
    }

    html = r(~H|<.breakdown_list rows={@rows} />|)
    assert html =~ ~r/data-tone="pos"[^>]*bg-pos-soft/
    assert html =~ "menos 2"
  end

  test "a11y: the rows are a list named by the label; icons are decoration" do
    assigns = %{rows: @rows}
    html = r(~H|<.breakdown_list rows={@rows} label="Origem" />|)
    assert html =~ ~r/<ul[^>]*aria-label="Origem"/
    assert length(Regex.scan(~r/<li /, html)) == 2
    assert html =~ ~s(aria-hidden="true")
  end

  test "without ring nothing of the link is rendered" do
    assigns = %{rows: [Map.put(hd(@rows), :series, "direta")]}
    html = r(~H|<.breakdown_list rows={@rows} />|)
    refute html =~ "data-lu-ring"
    refute html =~ "data-lu-series"
    refute html =~ "tabindex"
    refute html =~ "hover:bg-hover"
  end

  test "with ring the root and the rows with a series are linked and focusable" do
    assigns = %{rows: [Map.put(hd(@rows), :series, "direta"), List.last(@rows)]}
    html = r(~H|<.breakdown_list rows={@rows} ring="receb" />|)
    assert html =~ ~s(data-lu-ring="receb")
    assert length(Regex.scan(~r/data-lu-series="direta"/, html)) == 1
    assert length(Regex.scan(~r/tabindex="0"/, html)) == 1

    for c <-
          ~w|hover:bg-hover focus-visible:bg-hover data-[active]:bg-hover duration-150 motion-reduce:transition-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)]| do
      assert html =~ c, c
    end
  end

  defp t(assigns), do: ~H|<.breakdown_list rows={@rows} ring={@ring} total={@total} />|

  test "tracking" do
    base = %{rows: [Map.put(hd(@rows), :series, "s")], ring: nil, total: %{value: 1}}
    each_source(&t/1, base, ring: "r", total: %{value: 2}, rows: @rows)
  end
end
