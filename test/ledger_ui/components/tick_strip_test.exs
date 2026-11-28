defmodule LedgerUI.Components.TickStripTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  defp r(assigns), do: rendered_to_string(assigns)

  @skus Enum.map(~w(pos pos pos warn warn neg), &%{status: &1, name: "SKU"})

  test "draws one stroke per item, coloured by the tone of by" do
    assigns = %{skus: @skus}
    html = r(~H|<.tick_strip items={@skus} by={& &1.status} />|)
    assert length(Regex.scan(~r/data-part="tick"/, html)) == 6
    assert length(Regex.scan(~r/stroke-series-1/, html)) == 3
    assert length(Regex.scan(~r/stroke-series-3/, html)) == 2
    assert length(Regex.scan(~r/stroke-series-4/, html)) == 1
    refute html =~ "#"
  end

  test "is an image with a translated summary" do
    assigns = %{skus: @skus}
    html = r(~H|<.tick_strip items={@skus} by={& &1.status} />|)
    assert html =~ ~s(role="img")
    assert html =~ ~s(aria-label="6 items: 3 good, 2 warning, 1 critical")
    pt = r(~H|<.tick_strip items={@skus} by={& &1.status} locale="pt_BR" />|)
    assert pt =~ ~s(aria-label="6 itens: 3 bom, 2 atenção, 1 crítico")
    custom = r(~H|<.tick_strip items={@skus} by={& &1.status} label="Estoque" />|)
    assert custom =~ ~s(aria-label="Estoque")
  end

  test "an item is its own tone, or has :tone/:status; long names and unknown tones are read" do
    assigns = %{}
    html = r(~H|<.tick_strip items={["success", "error", "weird", %{tone: "c2"}]} />|)
    assert html =~ "stroke-series-1"
    assert html =~ "stroke-series-4"
    assert html =~ "stroke-line-strong"
    assert html =~ "stroke-series-2"
  end

  test "item_title and :name give the native tooltip" do
    assigns = %{skus: @skus}
    assert r(~H|<.tick_strip items={@skus} />|) =~ "<title>SKU</title>"
    html = r(~H|<.tick_strip items={@skus} item_title={fn i -> "x " <> i.status end} />|)
    assert html =~ "<title>x neg</title>"
  end

  test "no items, one item" do
    assigns = %{}
    assert r(~H|<.tick_strip items={[]} />|) =~ "0 items"
    assert r(~H|<.tick_strip items={["pos"]} />|) =~ ~s(x1="150")
  end

  defp t(assigns), do: ~H|<.tick_strip items={@items} by={& &1} label={@l} />|

  test "items and label are tracked and only the changed one travels" do
    each_source(&t/1, %{items: ~w(pos neg), l: "a"}, items: ~w(pos pos), l: "b")
    p = patch(&t/1, %{items: ~w(pos neg), l: "a"}, l: "b")
    refute p =~ "stroke-series-1"
  end
end
