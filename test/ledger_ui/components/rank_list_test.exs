defmodule LedgerUI.Components.RankListTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  defp r(assigns), do: rendered_to_string(assigns)

  @rows [
    %{
      id: "cafe",
      icon: "package",
      color: "#8a5a3c",
      label: "Café",
      value: 238_800,
      units: 5191,
      delta: 45.5
    },
    %{
      id: "audio",
      icon: "monitor",
      color: "var(--lu-chart-2)",
      label: "Áudio",
      value: 212_700,
      units: 1558,
      delta: -12.0
    },
    %{id: "x", label: "Zeta", detail: "sem dados"}
  ]

  defp brl(v), do: "R$ " <> to_string(Float.round(v / 1000, 1)) <> " mil"

  test "rows: thumb over its colour, name, value and units, delta with trend arrow" do
    assigns = %{rows: @rows}
    html = r(~H|<.rank_list rows={@rows} format={&brl/1} units_label="un" />|)
    assert html =~ "Café"
    assert html =~ "R$ 238.8 mil · 5,191 un"
    assert html =~ ~s(style="background:#8a5a3c")
    assert html =~ ~s|style="background:var(--lu-chart-2)"|
    assert length(Regex.scan(~r/data-icon="arrow-up-right"/, html)) == 2
    assert length(Regex.scan(~r/rotate-90/, html)) == 1
    refute html =~ "trend-"
    assert html =~ "45.5%"
    assert html =~ "12.0%"
    assert r(~H|<.rank_list rows={@rows} delta_decimals={0} />|) =~ ~r/12%\s*</
    refute html =~ "-12"
    assert html =~ ~r/data-tone="pos"[^>]*bg-pos-soft text-pos/
    assert html =~ ~r/data-tone="neg"[^>]*bg-neg-soft text-neg/
  end

  test "the letter stands in for a missing icon; detail replaces the second line; no colour is inverse" do
    assigns = %{rows: @rows}
    html = r(~H|<.rank_list rows={@rows} />|)
    assert html =~ ">Z</span>"
    assert html =~ "sem dados"
    assert html =~ "bg-inverse text-on-inverse"
  end

  test "an unsafe colour is dropped" do
    assigns = %{rows: [%{label: "A", color: "red;x{y}", value: 1}]}
    html = r(~H|<.rank_list rows={@rows} />|)
    refute html =~ "red;x"
    assert html =~ "bg-inverse"
  end

  test "numbers and units follow the locale" do
    assigns = %{rows: @rows}
    html = r(~H|<.rank_list rows={@rows} locale="pt_BR" />|)
    assert html =~ "238.800"
    assert html =~ "45,5%"
    assert html =~ "5.191 un"
    en = r(~H|<.rank_list rows={@rows} />|)
    assert en =~ "5,191 units"
  end

  test "header, action and footer" do
    assigns = %{rows: @rows}

    html =
      r(~H"""
      <.rank_list
        rows={@rows}
        title="Principais categorias"
        subtitle="Receita"
        footer="8 de 12 categorias"
        note="vs 4 semanas anteriores"
      >
        <:action><button>Ver todas</button></:action>
      </.rank_list>
      """)

    assert html =~ "Principais categorias"
    assert html =~ ~r/rank-action.*Ver todas/s
    assert html =~ ~r/rank-footer.*8 de 12 categorias.*vs 4 semanas anteriores/s
    refute r(~H|<.rank_list rows={[]} />|) =~ "rank-head"
    assert r(~H|<.rank_list rows={[]} />|) =~ "rounded-[18px]"
    refute r(~H|<.rank_list rows={[]} bare />|) =~ "rounded-[18px]"
  end

  test "a11y: a list named by the title with an li per row" do
    assigns = %{rows: @rows}
    html = r(~H|<.rank_list rows={@rows} title="Categorias" />|)
    assert html =~ ~r/<ul[^>]*aria-label="Categorias"/
    assert length(Regex.scan(~r/<li /, html)) == 3
  end

  defp t(assigns), do: ~H|<.rank_list rows={@rows} title={@title} footer={@f} />|

  test "tracking" do
    each_source(&t/1, %{rows: @rows, title: "a", f: "x"}, rows: [hd(@rows)], title: "b", f: "y")
    refute patch(&t/1, %{rows: @rows, title: "a", f: "x"}, f: "y") =~ "Café"
  end
end
