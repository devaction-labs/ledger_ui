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

  test "refined look: one surface, 32px figure, plain label, footer rule" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.kpi_card id="k" label="MRR" value="1" delta="2%" spark={[1, 3, 2]} />|
      )

    assert html =~ "rounded-lg border border-line bg-panel shadow-xs"
    refute html =~ "bg-tray"
    refute html =~ "uppercase"
    assert html =~ "text-[32px]"
    assert html =~ "border-t border-line"
    assert html =~ "opacity-55"
  end

  describe "extension points" do
    test "without the new attrs the card has none of their markup" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card label="MRR" value="1" delta="8" compare="x" spark={[1, 2]} />|
        )

      refute html =~ "kpi-label-extra"
      refute html =~ ~s(data-part="kpi-number")
      refute html =~ "flex-col items-start"
      assert html =~ "w-[40%]"
      assert html =~ ~s(data-part="sparkline-dot")
      assert html =~ ~s(data-part="kpi-arrow")
    end

    test "label_extra sits at the end of the label row" do
      assigns = %{}

      canvas =
        rendered_to_string(~H"""
        <.kpi_card label="MRR" value="1" live>
          <:label_extra><button>Ver</button></:label_extra>
        </.kpi_card>
        """)

      badge =
        rendered_to_string(~H"""
        <.kpi_card variant="badge" label="MRR" value="1">
          <:label_extra><button>Ver</button></:label_extra>
        </.kpi_card>
        """)

      for html <- [canvas, badge] do
        assert html =~ ~r/data-part="kpi-label-extra" class="ml-auto"><button>Ver<\/button>/
      end
    end

    test "value_tone paints only the figure" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card label="A" prefix="R$" value="9" unit="k" value_tone="warning" />|
        )

      assert html =~ ~r/data-part="kpi-number" class="text-warn">9</
      assert html =~ ~r/data-part="kpi-prefix" class="[^"]*text-subtle/

      err = rendered_to_string(~H|<.kpi_card label="A" value="9" value_tone="error" />|)
      assert err =~ ~r/data-part="kpi-number" class="text-neg">9</

      badge =
        rendered_to_string(
          ~H|<.kpi_card variant="badge" label="A" value="9" value_tone="error" />|
        )

      assert badge =~ ~r/data-part="kpi-number" class="font-semibold text-neg"/
    end

    test "footer_layout stack puts the footer in a column" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.kpi_card label="A" value="1" delta="2" compare="x" open_label="Open" footer_layout="stack">
          <:footer>f</:footer>
        </.kpi_card>
        """)

      assert html =~ ~r/data-part="kpi-footer" class="flex flex-col items-start gap-2/
      refute html =~ ~s(min-w-0 flex-1"></span>)
      assert html =~ "self-end"
    end

    test "spark_variant corner is small, in the corner and without the dot" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card id="c" label="A" value="1" spark={[1, 3, 2]} spark_variant="corner" />|
        )

      assert html =~ "h-[30px] w-24"
      refute html =~ "w-[40%]"
      refute html =~ "sparkline-dot"
    end

    test "arrow false drops the arrow beside the figure in both variants" do
      assigns = %{}

      canvas = rendered_to_string(~H|<.kpi_card label="A" value="1" delta="2" arrow={false} />|)
      refute canvas =~ "kpi-arrow"
      assert canvas =~ "kpi-delta"

      badge =
        rendered_to_string(
          ~H|<.kpi_card variant="badge" label="A" value="1" delta="2" arrow={false} />|
        )

      refute badge =~ "kpi-arrow"
    end

    test "loading still draws the skeleton in the same card" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.kpi_card loading spark_variant="corner" value_tone="error" arrow={false} footer_layout="stack" />|
        )

      assert html =~ "aria-busy"
      assert html =~ "kpi-skeleton"
    end
  end
end
