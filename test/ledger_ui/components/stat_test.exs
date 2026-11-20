defmodule LedgerUI.Components.StatTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Stat

  test "item: label, value, unit" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="Prazo" value="18" unit="dias" />|)
    assert html =~ ~s(class="lu-stat")
    assert html =~ ~s(<span class="l">Prazo</span>)
    assert html =~ ~s(<span class="v">18<small>dias</small></span>)
    refute html =~ ~s(class="f")
    refute html =~ "style="
  end

  test "item: tone and size" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.stat_item label="a" value="1" tone="accent" size="sm" class="z" />|)

    assert html =~ ~s(class="lu-stat accent sm z")
  end

  test "item: icon before the label" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="Pedidos" value="1" icon="cart" />|)
    assert html =~ ~r|<span class="l"><svg class="lu-i sm"[^>]*data-icon="cart"|
  end

  test "item: change direction and tone" do
    assigns = %{}

    up = rendered_to_string(~H|<.stat_item label="a" value="1" change="12%" note="vs. mês" />|)
    assert up =~ ~s(class="lu-chg pos")
    assert up =~ "M6 9.5V2.5M2.8 5.6 6 2.5l3.2 3.1"
    assert up =~ "<span>vs. mês</span>"

    bad = rendered_to_string(~H|<.stat_item label="a" value="1" change="6%" change_tone="neg" />|)
    assert bad =~ ~s(class="lu-chg neg")

    down = rendered_to_string(~H|<.stat_item label="a" value="1" change="1" trend="down" />|)
    assert down =~ ~s(class="lu-chg pos")
    assert down =~ "M6 2.5v7M2.8 6.4 6 9.5l3.2-3.1"

    flat = rendered_to_string(~H|<.stat_item label="a" value="1" change="0%" trend="flat" />|)
    assert flat =~ ~s(class="lu-chg flat")
    assert flat =~ "M2.5 6h7"
  end

  test "item: meter is a progressbar" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="Meta" value="1" meter={74} />|)
    assert html =~ ~s(class="lu-smeter")
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-label="Meta")
    assert html =~ ~s(aria-valuenow="74")
    assert html =~ "--sp:74%"
  end

  test "item: sparkline path, last point and tone" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.stat_item label="a" value="1" sparkline={[0, 10, 22]} sparkline_tone="pos" />|
      )

    assert html =~ ~s(class="lu-spk pos")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ~s(d="M0.0 27.0 L60.0 17.0 L120.0 5.0")
    assert html =~ ~s(d="M0.0 27.0 L60.0 17.0 L120.0 5.0 L120 30 L0 30 Z")
    assert html =~ ~s(cx="120.0" cy="5.0" r="2.6")
  end

  test "item: a flat or short series does not break" do
    assigns = %{}
    flat = rendered_to_string(~H|<.stat_item label="a" value="1" sparkline={[3, 3, 3]} />|)
    assert flat =~ "M0.0 27.0 L60.0 27.0 L120.0 27.0"
    short = rendered_to_string(~H|<.stat_item label="a" value="1" sparkline={[3]} />|)
    refute short =~ "lu-spk"
  end

  test "group: card, sunken, bare and animated" do
    assigns = %{}

    card = rendered_to_string(~H|<.stat_group><.stat_item label="a" value="1" /></.stat_group>|)
    assert card =~ ~s(class="lu-stats")

    sunken =
      rendered_to_string(
        ~H|<.stat_group variant="sunken"><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert sunken =~ ~s(class="lu-stats sunken")

    bare =
      rendered_to_string(
        ~H|<.stat_group card={false} animated class="k"><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert bare =~ ~s(class="lu-stats bare mo-stats k")
  end
end
