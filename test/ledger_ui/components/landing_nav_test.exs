defmodule LedgerUI.Components.LandingNavTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.LandingNav

  test "variants, links and actions" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.landing_nav id="n" variant="float" brand={%{name: "Ledger", logo: "L"}}>
  <:link label="Prices" href="/p" active /><:actions>
    <.landing_login>Entrar</.landing_login><.landing_cta href="/s">Go</.landing_cta>
  </:actions>
</.landing_nav>|
      )

    assert html =~ "shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-md)]"
    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(data-part="button")
    assert html =~ "Ledger"
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
    assert html =~ ~s(data-part="landing-mega")
    assert html =~ "LedgerUI.LandingNav"
  end

  test "sticky and mobile" do
    assigns = %{}

    assert rendered_to_string(~H|<.landing_nav id="n" sticky stuck_after={20}>x</.landing_nav>|) =~
             "sticky top-0 z-40"

    assert rendered_to_string(~H|<.landing_nav id="n" variant="mobile" />|) =~
             ~s(data-part="landing-nav-ham")
  end

  test "cta size, block, button fallback and announcement" do
    assigns = %{}
    cta = rendered_to_string(~H|<.landing_cta size="lg" block>Go</.landing_cta>|)
    assert cta =~ "h-11"
    assert cta =~ "w-full"
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
  <.landing_product title="Cloud" name="Ledger" tone="dark" mock />
</.landing_mega>|)

    assert html =~ "repeat(1,1fr)"
    assert html =~ "#0e100f"
  end

  test "brand icon, caret links and compact products" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.landing_nav id="n" brand={%{name: "Signetum", icon: "grid"}}>
  <:link label="Produto" caret />
  <:link label="Preços" />
</.landing_nav>|)

    assert html =~ ~s(data-icon="grid")
    assert html =~ "Produto ▾"
    assert html =~ ~s(data-part="landing-brand")
    refute html =~ "Preços ▾"

    mobile = rendered_to_string(~H|<.landing_nav id="m" variant="mobile" brand={%{name: "S"}} />|)
    refute mobile =~ "min-w-0 flex-1"
    assert mobile =~ ~s(data-part="landing-nav-ham")

    compact = rendered_to_string(~H|<.landing_product compact title="NF-e" />|)
    assert compact =~ ~s(<b>NF-e</b>)
    assert compact =~ "min-h-0 bg-panel p-2.5"
    refute compact =~ "<a"
  end
end
