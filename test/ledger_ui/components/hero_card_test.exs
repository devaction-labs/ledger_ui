defmodule LedgerUI.Components.HeroCardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.HeroCard

  test "text on the left, summit on the right" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.hero_card id="h" eyebrow="Painel" title="Pedidos" description="48 hoje" />|
      )

    assert html =~ ~s(data-part="hero-card")
    assert html =~ "min-h-[230px] bg-sunken"
    assert html =~ ~s(data-part="hero-eyebrow")
    assert html =~ ~r|data-part="hero-eyebrow" class="[^"]*font-mono[^"]*uppercase|
    assert html =~ ~r|<h2 id="h-title" [^>]*>\s*Pedidos\s*</h2>|
    assert html =~ "48 hoje"
    assert html =~ ~s(data-part="hero-art")
    assert html =~ ~s(data-part="summit")
    assert html =~ ~s(id="h-art-sky")
    assert html =~ ~s(aria-labelledby="h-title")
    assert html =~ ~s(aria-hidden="true")
    refute html =~ ~s(data-part="hero-extra")
    refute html =~ ~s(data-part="hero-actions")
    refute html =~ "style="
  end

  test "size, variant and heading" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.hero_card title="T" size="lg" variant="panel" heading="h1" class="x" data-k="1" />|
      )

    assert html =~ "min-h-[300px]"
    assert html =~ "border border-line bg-panel shadow-xs"
    assert html =~ ~r|class="[^"]* x"|
    assert html =~ ~r|<h1 [^>]*text-\[34px\][^>]*>\s*T\s*</h1>|
    assert html =~ ~s(data-k="1")

    ai = rendered_to_string(~H|<.hero_card title="T" variant="ai" animated />|)
    assert ai =~ "lu-hero-in_7s"
    assert ai =~ "lu-hero-fill_7s"
  end

  test "actions and icon slots" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hero_card eyebrow="IA" title="T">
        <:icon><svg id="ic" /></:icon>
        <:actions><button>Ok</button></:actions>
      </.hero_card>
      """)

    assert html =~ ~r|data-part="hero-eyebrow"[^>]*><svg id="ic"\s*/?>(</svg>)?IA</span>|
    assert html =~ ~r|data-part="hero-actions"[^>]*>\s*<button>Ok</button>\s*</div>|
    refute html =~ ~s(data-part="hero-extra")
  end

  test "meta and meter" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.hero_card title="T" meta="Meta" meta_value="R$ 1 de R$ 2" meter={74} picture="none" />|
      )

    assert html =~ ~s(data-part="hero-extra")
    assert html =~ ~s(data-part="hero-meta")
    assert html =~ "<span>Meta</span>"
    assert html =~ "R$ 1 de R$ 2</b>"
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-valuenow="74")
    assert html =~ ~s(--lu-sp:74%)
    refute html =~ ~s(data-part="summit")
  end

  test "steps" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hero_card
        title="T"
        steps={[%{label: "A", state: "done"}, %{label: "B", state: "current"}, %{label: "C"}]}
      />
      """)

    assert html =~ ~s(data-part="hero-steps")
    assert html =~ ~r|before:bg-pos"[^>]*>A</span>|
    assert html =~ ~r|before:bg-accent-500[^"]*" aria-current="step">B</span>|
    assert html =~ ~r|before:bg-line-strong"[^>]*>C</span>|
  end

  test "inner_block opens the extra box" do
    assigns = %{}
    html = rendered_to_string(~H|<.hero_card title="T">a note</.hero_card>|)
    assert html =~ ~r|data-part="hero-extra"[^>]*>\s*a note\s*</div>|
  end

  test "src replaces the landscape, position moves the crop" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.hero_card title="T" src="/h.jpg" alt="Hills" position="70% center" />|
      )

    assert html =~ ~s(src="/h.jpg")
    assert html =~ ~s(alt="Hills")
    assert html =~ "object-position:70% center"
    refute html =~ ~s(data-part="summit")
  end

  test "art slot replaces the landscape" do
    assigns = %{}
    html = rendered_to_string(~H|<.hero_card title="T">
  <:art><i id="mine" /></:art>
</.hero_card>|)
    assert html =~ ~s(data-part="hero-art")
    assert html =~ ~s(id="mine")
    refute html =~ ~s(data-part="summit")
  end

  test "hero_summit follows the theme tokens and prefixes its ids" do
    assigns = %{}
    html = rendered_to_string(~H|<.hero_summit id="s9" />|)
    assert html =~ ~s(id="s9-sky")
    assert html =~ "url(#s9-m3)"
    assert html =~ "var(--lu-hero-sun)"
    assert html =~ ~s(viewBox="0 0 520 300")
  end
end
