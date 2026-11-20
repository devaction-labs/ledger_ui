defmodule LedgerUI.Components.LandingNavTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.LandingNav

  test "variants, links and actions" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.landing_nav id="n" variant="float" brand={%{name: "Linea", logo: "L"}}>
  <:link label="Prices" href="/p" active /><:actions>
    <.landing_login>Entrar</.landing_login><.landing_cta href="/s">Go</.landing_cta>
  </:actions>
</.landing_nav>|
      )

    assert html =~ "lu-lnav float"
    assert html =~ ~s(aria-current="page")
    assert html =~ "lu-b c-mono v-solid s-sm sh-rounded"
    assert html =~ "Linea"
    refute html =~ "phx-hook"
  end

  test "a link with content is a mega menu trigger" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.landing_nav id="n">
  <:link label="Product"><.landing_mega>
    <.landing_feature icon="kanban" title="Projects" description="d" />
  </.landing_mega></:link>
</.landing_nav>|)

    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="n-panel-0")
    assert html =~ "lu-mega"
    assert html =~ "LedgerUI.LandingNav"
  end

  test "sticky and mobile" do
    assigns = %{}

    assert rendered_to_string(~H|<.landing_nav id="n" sticky stuck_after={20}>x</.landing_nav>|) =~
             "position:sticky"

    assert rendered_to_string(~H|<.landing_nav id="n" variant="mobile" />|) =~ ~s(class="ham")
  end

  test "cta size, block, button fallback and announcement" do
    assigns = %{}
    cta = rendered_to_string(~H|<.landing_cta size="lg" block>Go</.landing_cta>|)
    assert cta =~ "s-lg"
    assert cta =~ "<button"

    ann =
      rendered_to_string(
        ~H|<.landing_announcement id="a" eyebrow="New" link_label="See">Text</.landing_announcement>|
      )

    assert ann =~ "Text"
    assert ann =~ ~s(aria-label="Close")
  end

  test "mega cards and product" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.landing_mega variant="cards">
  <.landing_product title="Cloud" name="Linea" tone="dark" mock />
</.landing_mega>|)

    assert html =~ "repeat(1,1fr)"
    assert html =~ "#0e100f"
  end
end
