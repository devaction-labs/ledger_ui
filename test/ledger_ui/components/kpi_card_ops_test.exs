defmodule LedgerUI.Components.KpiCardOpsTest do
  # The operation panel additions of `kpi_card` (`subtitle`, `suffix`, slots `:status`, `:detail`,
  # `:viz`, `:legend`): the calls that do not use them render byte for byte as before.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  @fixture Path.expand("../../fixtures/kpi_card_before_ops.html", __DIR__)
  @external_resource @fixture

  defp r(assigns), do: rendered_to_string(assigns)

  test "the calls without the new attrs and slots render as before (byte for byte)" do
    assigns = %{}

    html =
      Enum.join(
        [
          r(~H|<.kpi_card
  label="MRR"
  value="184,320"
  prefix="$"
  delta="8.8%"
  compare="vs $169,460 in Sep"
  live
  spark={[1, 3, 2, 5]}
  open_label="Open"
  on_open="open_report"
/>|),
          r(~H|<.kpi_card
  label="Churn"
  value="2.1"
  unit="%"
  delta="0.4 pts"
  trend="up"
  delta_tone="error"
  id="k1"
/>|),
          r(~H|<.kpi_card label="A" value="1" />|),
          r(~H|<.kpi_card label="A" value="1" progress={40} caption="cap" tone="dark" />|),
          r(~H|<.kpi_card label="A" value="1" loading />|),
          r(~H|<.kpi_card label="A" value="12" variant="badge" count={12} delta="3%">
  <:icon><.icon name="layers" /></:icon>
</.kpi_card>|),
          r(~H|<.kpi_card label="A" value="12" variant="badge" layout="inline" delta="3%">
  <:icon><.icon name="layers" /></:icon><:label_extra>x</:label_extra>
</.kpi_card>|),
          r(~H|<.kpi_card
  label="A"
  value="12"
  tone="highlight"
  delta="3%"
  trend="down"
  footer_layout="stack"
  spark={[1, 2]}
  spark_variant="corner"
>
  <:icon><.icon name="layers" /></:icon><:label_extra>x</:label_extra><:footer>link</:footer>
</.kpi_card>|),
          r(~H|<.kpi_card
  label="A"
  value="12"
  tone="positive"
  value_tone="error"
  gap={false}
  icon_tone="pos"
  layout="stack"
>
  <:icon><.icon name="layers" /></:icon>
</.kpi_card>|)
        ],
        "\n=====\n"
      )

    assert html == File.read!(@fixture)
  end

  test "subtitle sits under the label, in the muted tone of the card" do
    assigns = %{}

    html = r(~H|<.kpi_card label="SKUs em estoque" subtitle="6 zerados" value="23" />|)
    assert html =~ ~s(data-part="kpi-title" class="text-sm text-ink">SKUs em estoque</span>)
    assert html =~ ~s(data-part="kpi-subtitle")
    assert html =~ "6 zerados"
    assert html =~ "text-muted"

    dark = r(~H|<.kpi_card label="A" subtitle="s" value="1" tone="dark" />|)
    assert dark =~ "text-on-inverse/60"

    refute r(~H|<.kpi_card label="A" value="1" />|) =~ "kpi-subtitle"
  end

  test "suffix follows the figure in a small muted text and the figure sits on the baseline" do
    assigns = %{}
    html = r(~H|<.kpi_card label="A" value="23" suffix="de 29" />|)
    assert html =~ ~r/data-part="kpi-suffix"[^>]*text-muted[^>]*>de 29</
    assert html =~ "items-baseline"
    refute r(~H|<.kpi_card label="A" value="23" />|) =~ "items-baseline"
  end

  test "status goes beside the figure" do
    assigns = %{}

    html =
      r(~H|<.kpi_card label="A" value="96,3%">
  <:status>
    <.badge color="success">Na meta</.badge>
  </:status>
</.kpi_card>|)

    assert html =~ ~r/data-part="kpi-status".*Na meta/s
  end

  test "detail and viz render under the figure; the viz is pushed to the bottom" do
    assigns = %{}

    html =
      r(~H"""
      <.kpi_card label="Rupturas" value="6">
        <:detail>Pior <b>Apex</b></:detail>
        <:viz><.countdown_bar value={0.7} /></:viz>
      </.kpi_card>
      """)

    assert html =~ ~r/data-part="kpi-detail"[^>]*>Pior <b>Apex<\/b>/
    assert html =~ ~r/data-part="kpi-viz"[^>]*mt-auto[^>]*>.*countdown-bar/s
    assert html =~ "flex-1"
    # the detail comes before the chart
    {d, _} = :binary.match(html, "kpi-detail")
    {v, _} = :binary.match(html, "kpi-viz")
    assert d < v
  end

  test "legend writes a coloured mark and a label per entry, in the footer" do
    assigns = %{}

    html =
      r(~H"""
      <.kpi_card label="SKUs" value="23">
        <:legend tone="pos" label="15 em estoque" />
        <:legend tone="warn" label="8 baixos" shape="dot" />
        <:legend tone="neg" label="6 zerados" />
        <:legend tone="c3" label="3 em encomenda" />
      </.kpi_card>
      """)

    assert html =~ ~s(data-part="kpi-footer")
    assert html =~ ~r/data-tone="pos" class="[^"]*bg-series-1[^"]*"><\/i>15 em estoque/

    assert html =~
             ~r/data-tone="warn" class="[^"]*size-1\.5 rounded-full bg-series-3[^"]*"><\/i>8 baixos/

    assert html =~ ~r/data-tone="neg" class="[^"]*bg-series-4[^"]*"><\/i>6 zerados/
    assert html =~ ~r/data-tone="c3" class="[^"]*bg-series-3[^"]*"><\/i>3 em encomenda/
    assert html =~ "h-2.5 w-[3px]"
  end

  test "the four KPIs of the operation panel render" do
    assigns = %{skus: for(s <- ~w(pos pos warn neg), do: %{status: s})}

    html =
      r(~H"""
      <.kpi_card label="SKUs em estoque" subtitle="6 zerados" value="23" suffix="de 29">
        <:icon><.icon name="layers" /></:icon>
        <:viz><.tick_strip items={@skus} by={& &1.status} /></:viz>
        <:legend tone="pos" label="15 em estoque" />
      </.kpi_card>
      <.kpi_card label="Taxa em estoque" subtitle="40.852 de 42.432 posições" value="96,3%">
        <:status>
          <.badge color="success">Na meta</.badge>
        </:status>
        <:viz>
          <.target_sparkline id="t" values={[96, 95, 94]} target={95.0} target_label="Meta 95,0%" />
        </:viz>
      </.kpi_card>
      <.kpi_card label="Rupturas" subtitle="em 4 fornecedores" value="6">
        <:detail>Pior <b>Apex Indústria</b><span class="ml-auto">2 de 6</span></:detail>
        <:viz><.segment_bar segments={[%{value: 3, tone: "neg"}, %{value: 3, tone: "c3"}]} /></:viz>
      </.kpi_card>
      <.kpi_card
        label="Próxima entrega"
        subtitle="3 nos próximos 3 dias"
        value="em 20h"
        suffix="25 nov, 08:00"
      >
        <:viz><.countdown_bar value={0.7} /></:viz>
        <:footer><span>22 nov</span> <b>Em trânsito</b></:footer>
      </.kpi_card>
      """)

    for part <- ~w(tick-strip target-sparkline segment-bar countdown-bar) do
      assert html =~ ~s(data-part="#{part}")
    end
  end

  # -- diff: only the value travels ---------------------------------------------------------

  defp viz_card(assigns) do
    ~H"""
    <.kpi_card label="SKUs" subtitle="sub" value={@value} suffix={@suffix}>
      <:viz><.segment_bar segments={[%{value: 3, tone: "neg"}, %{value: 3, tone: "warn"}]} /></:viz>
      <:legend tone="pos" label="15 em estoque" />
    </.kpi_card>
    """
  end

  test "a new value or suffix does not send the card, the viz or the legend again" do
    base = %{value: "23", suffix: "de 29"}

    value_patch = patch(&viz_card/1, base, value: "24")
    assert value_patch =~ "24"
    refute value_patch =~ "kpi-viz"
    refute value_patch =~ "rounded-[18px]"
    refute value_patch =~ "15 em estoque"
    refute value_patch =~ "segment-bar"
    assert byte_size(value_patch) < 160

    suffix_patch = patch(&viz_card/1, base, suffix: "de 30")
    refute suffix_patch =~ "rounded-[18px]"
    refute suffix_patch =~ "segment-bar"

    # the figure's classes travel with the suffix (they depend on whether there is one), nothing else
    assert byte_size(suffix_patch) < 300
  end

  test "every source is reflected in the page" do
    each_source(&viz_card/1, %{value: "23", suffix: "de 29"}, value: "24", suffix: "de 30")
  end

  defp legend_card(assigns) do
    ~H"""
    <.kpi_card label="A" value="1" tone={@tone}>
      <:legend tone="pos" label={@l} />
    </.kpi_card>
    """
  end

  test "tone and legend label are tracked" do
    each_source(&legend_card/1, %{tone: "default", l: "x"}, tone: "dark", l: "y")
  end

  defp sub_card(assigns) do
    ~H|<.kpi_card label="A" value="1" subtitle={@s} tone={@tone} />|
  end

  test "subtitle and its tone are tracked" do
    each_source(&sub_card/1, %{s: "a", tone: "default"}, s: "b", tone: "dark")
  end
end
