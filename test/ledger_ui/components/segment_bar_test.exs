defmodule LedgerUI.Components.SegmentBarTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  defp r(assigns), do: rendered_to_string(assigns)

  @segs [
    %{value: 3, tone: "neg", label: "sem estoque"},
    %{value: 3, tone: "c3", label: "em encomenda"}
  ]

  test "one segment per value, as wide as its share, tinted by its tone" do
    assigns = %{
      segs: [%{value: 3, tone: "neg"}, %{value: 1, tone: "warn"}, %{value: 0, tone: "pos"}]
    }

    html = r(~H|<.segment_bar segments={@segs} />|)
    assert length(Regex.scan(~r/data-part="segment"/, html)) == 2
    assert html =~ "flex:3"
    assert html =~ "flex:1"
    assert html =~ "bg-series-4"
    assert html =~ "bg-series-3"
    refute html =~ "bg-series-1"
  end

  test "series colours and long tone names" do
    assigns = %{segs: [%{value: 1, tone: "c3"}, %{value: 1, tone: "error"}]}
    html = r(~H|<.segment_bar segments={@segs} />|)
    assert html =~ "bg-series-3"
    assert html =~ "bg-series-4"
  end

  test "a11y: image whose label lists the segments" do
    assigns = %{segs: @segs}
    html = r(~H|<.segment_bar segments={@segs} />|)
    assert html =~ ~s(role="img")
    assert html =~ ~s(aria-label="3 sem estoque, 3 em encomenda")
    plain = r(~H|<.segment_bar segments={[%{value: 2, tone: "warn"}]} locale="pt_BR" />|)
    assert plain =~ ~s(aria-label="2 atenção")
    assert r(~H|<.segment_bar segments={@segs} label="Rupturas" />|) =~ ~s(aria-label="Rupturas")
  end

  defp t(assigns), do: ~H|<.segment_bar segments={@s} label={@l} />|

  test "tracking" do
    each_source(&t/1, %{s: @segs, l: "a"}, s: [%{value: 1, tone: "pos"}], l: "b")
    refute patch(&t/1, %{s: @segs, l: "a"}, l: "b") =~ "bg-series-4"
  end
end
