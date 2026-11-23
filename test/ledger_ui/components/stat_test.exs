defmodule LedgerUI.Components.StatTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Stat

  test "item: label, value, unit" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="Prazo" value="18" unit="dias" />|)
    assert html =~ ~s(data-part="stat")
    assert html =~ ~r|whitespace-nowrap text-muted">\s*Prazo\s*</span>|
    assert html =~ ~r|>\s*18<small data-part="stat-unit" class="[^"]*">dias</small>\s*</span>|
    refute html =~ "inline-flex h-5"
    refute html =~ "style="
  end

  test "item: tone and size" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.stat_item label="a" value="1" tone="accent" size="sm" class="z" />|)

    assert html =~ "text-accent-content"
    assert html =~ "text-lg tracking-[-.02em]"
    assert html =~ "before:bg-accent-500"
    assert html =~ " z"
  end

  test "item: icon before the label" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="Pedidos" value="1" icon="cart" />|)
    assert html =~ ~r|<svg class="[^"]*size-3.5 text-ink"[^>]*data-icon="cart"|
  end

  test "item: change direction and tone" do
    assigns = %{}

    up = rendered_to_string(~H|<.stat_item label="a" value="1" change="12%" note="vs. mês" />|)
    assert up =~ "bg-pos-soft text-pos"
    assert up =~ "M6 9.5V2.5M2.8 5.6 6 2.5l3.2 3.1"
    assert up =~ ~s(<span data-part="stat-hint">vs. mês</span>)

    bad = rendered_to_string(~H|<.stat_item label="a" value="1" change="6%" change_tone="neg" />|)
    assert bad =~ "bg-neg-soft text-neg"

    down = rendered_to_string(~H|<.stat_item label="a" value="1" change="1" trend="down" />|)
    assert down =~ "bg-pos-soft text-pos"
    assert down =~ "M6 2.5v7M2.8 6.4 6 9.5l3.2-3.1"

    flat = rendered_to_string(~H|<.stat_item label="a" value="1" change="0%" trend="flat" />|)
    assert flat =~ "bg-sunken text-muted"
    assert flat =~ "M2.5 6h7"
  end

  test "item: meter is a progressbar" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="Meta" value="1" meter={74} />|)
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-label="Meta")
    assert html =~ ~s(aria-valuenow="74")
    assert html =~ "width:74%"
  end

  test "item: sparkline path, last point and tone" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.stat_item label="a" value="1" sparkline={[0, 10, 22]} sparkline_tone="pos" />|
      )

    assert html =~ "[--s:var(--lu-pos)]"
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
    refute short =~ "viewBox=\"0 0 120 30\""
  end

  test "group: card, sunken, bare and animated" do
    assigns = %{}

    card = rendered_to_string(~H|<.stat_group><.stat_item label="a" value="1" /></.stat_group>|)
    assert card =~ ~s(data-part="stat-group")
    assert card =~ ~s(data-lu-variant="default" data-lu-card="true" data-lu-animated="false")
    assert card =~ "rounded-lg border border-line bg-panel shadow-xs"

    sunken =
      rendered_to_string(
        ~H|<.stat_group variant="sunken"><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert sunken =~ ~s(data-lu-variant="sunken")
    assert sunken =~ "border-transparent bg-sunken"

    bare =
      rendered_to_string(
        ~H|<.stat_group card={false} animated class="k"><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert bare =~ ~s(data-lu-card="false" data-lu-animated="true")
    refute bare =~ "rounded-[16px]"
    assert bare =~ " k"
  end

  test "slots and value_id are opt-in" do
    assigns = %{}
    base = rendered_to_string(~H|<.stat_item label="a" value="1" />|)
    refute base =~ "stat-content"
    refute base =~ "stat-footer"
    refute base =~ " id="

    html =
      rendered_to_string(~H"""
      <.stat_item label="a" value="1" value_id="v1">
        <b id="extra">x</b>
        <:footer><a href="/r">ver</a></:footer>
      </.stat_item>
      """)

    assert html =~ ~r/data-part="stat-value"\s+id="v1"/
    assert html =~ ~s(data-part="stat-content")
    assert html =~ ~s(<b id="extra">x</b>)
    assert html =~ ~s(data-part="stat-footer")
    assert html =~ ~s(<a href="/r">ver</a>)
  end

  test "item: badge beside the label, with tone and a pulsing dot" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.stat_item label="Estoque" value="12" badge="Ao vivo" badge_dot="live" />|
      )

    assert html =~ ~s(data-part="stat-badge")

    assert html =~ "Ao vivo"
    refute html =~ "uppercase"
    assert html =~ "bg-accent-soft"
    assert html =~ "animate-[mo-blink_1.4s_ease-in-out_infinite]"

    tone =
      rendered_to_string(~H|<.stat_item label="a" value="1" badge="Beta" badge_tone="warning" />|)

    assert tone =~ "bg-warn-soft"
    refute tone =~ "badge-dot"
  end

  test "item: badge slot replaces the text" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.stat_item label="a" value="1" badge="texto">
        <:label_badge>custom</:label_badge>
      </.stat_item>
      """)

    assert html =~ "custom"
    refute html =~ "texto"
  end

  test "item: prefix before the figure; the figure id stays" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.stat_item label="Lotes" value="2,4" prefix="R$" value_id="v" />|)

    assert html =~ ~r|<sup\s+data-part="stat-prefix"[^>]*>R\$</sup>2,4|
    assert html =~ ~s(id="v")
  end

  test "item: without badge or prefix nothing new is rendered" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="a" value="1" />|)
    refute html =~ "stat-badge"
    refute html =~ "stat-prefix"
    refute html =~ "<sup"
  end

  describe "tile group (#62)" do
    test "a grid of cols columns with a 10px gap, not framed" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.stat_group variant="tile"><.stat_item label="a" value="1" /></.stat_group>|
        )

      assert html =~ ~s(data-lu-variant="tile")
      assert html =~ ~s(data-lu-card="false")
      assert html =~ "grid-cols-2"
      assert html =~ "gap-2.5"
      refute html =~ "grid-flow-col"
      refute html =~ "rounded-[16px]"

      four =
        rendered_to_string(
          ~H|<.stat_group variant="tile" cols={4}><.stat_item label="a" value="1" /></.stat_group>|
        )

      assert four =~ "grid-cols-4"
    end

    test "the items read the tile variant; accent paints the figure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.stat_group variant="tile">
          <.stat_item tone="accent" label="Proj" value="R$ 2,90 mi" note="faixa" />
        </.stat_group>
        """)

      assert html =~ "group-data-[lu-variant=tile]/stats:bg-sunken"
      refute html =~ "uppercase"
      assert html =~ "text-[32px]"
      assert html =~ "text-accent-content"
      assert html =~ "tabular-nums"
    end

    test "the default group is still a framed strip" do
      assigns = %{}
      html = rendered_to_string(~H|<.stat_group><.stat_item label="a" value="1" /></.stat_group>|)
      assert html =~ "grid-flow-col"
      assert html =~ ~s(data-lu-card="true")
      refute html =~ "gap-2.5"
    end
  end
end
