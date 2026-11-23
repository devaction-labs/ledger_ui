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

  test "hero: transparent, dark scope, pills, wrapped start and actions" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.landing_nav id="n" variant="hero" brand={%{name: "Nexus", logo: "N"}}>
  <:link label="Recursos" href="#recursos" /><:actions>
    <.landing_login>Entrar</.landing_login>
  </:actions>
</.landing_nav>|
      )

    assert html =~ ~s(data-lu-variant="hero")
    assert html =~ ~s(data-theme="dark")
    assert html =~ "bg-transparent"
    assert html =~ "h-20 items-center"
    assert html =~ "px-16 max-lg:px-7"
    refute html =~ "h-[60px]"
    assert html =~ ~s(data-part="landing-nav-start")
    assert html =~ ~s(data-part="landing-nav-actions")
    assert html =~ "rounded-full px-3.5 py-2"
    refute html =~ "landing-nav-spacer"
    refute html =~ "phx-hook"
    refute html =~ "-mb-20"
  end

  test "hero theme: dark by default, auto follows the page, light is explicit" do
    assigns = %{}

    auto = rendered_to_string(~H|<.landing_nav id="n" variant="hero" theme="auto" />|)
    refute auto =~ "data-theme"
    assert auto =~ "bg-transparent"
    assert auto =~ "data-[stuck]:bg-panel"

    assert rendered_to_string(~H|<.landing_nav id="n" variant="hero" theme="light" />|) =~
             ~s(data-theme="light")

    assert rendered_to_string(~H|<.landing_nav id="n" variant="hero" />|) =~
             ~s(data-theme="dark")

    # theme is a hero-only attr
    refute rendered_to_string(~H|<.landing_nav id="n" theme="light" />|) =~ "data-theme"
  end

  test "align center adds a leading spacer; the default HTML is unchanged" do
    assigns = %{}

    centered =
      rendered_to_string(
        ~H|<.landing_nav id="n" variant="clear" align="center"><:link label="A" href="#a" /></.landing_nav>|
      )

    assert length(String.split(centered, ~s(data-part="landing-nav-spacer"))) == 3

    plain =
      rendered_to_string(
        ~H|<.landing_nav id="n" variant="clear"><:link label="A" href="#a" /></.landing_nav>|
      )

    assert length(String.split(plain, ~s(data-part="landing-nav-spacer"))) == 2

    hero =
      rendered_to_string(~H|<.landing_nav id="n" variant="hero" align="center" />|)

    refute hero =~ "landing-nav-spacer"
  end

  test "hero sticky overlays the hero; autohide and spy set the hook and the data attributes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.landing_nav id="n" variant="hero" sticky autohide spy spy_offset={90}>
  <:link label="Recursos" href="#recursos" />
</.landing_nav>|
      )

    assert html =~ "-mb-20"
    assert html =~ "data-[hidden]:-translate-y-full"
    assert html =~ "motion-reduce:transition-none"
    assert html =~ ~s(data-lu-autohide)
    assert html =~ ~s(data-lu-spy)
    assert html =~ ~s(data-lu-spy-offset="90")
    assert html =~ ~s(phx-hook="LedgerUI.LandingNav")
    assert html =~ "aria-[current=true]:font-semibold"

    # spy alone mounts the hook; autohide without sticky does nothing
    spy =
      rendered_to_string(
        ~H|<.landing_nav id="n" spy><:link label="A" href="#a" /></.landing_nav>|
      )

    assert spy =~ ~s(phx-hook="LedgerUI.LandingNav")
    refute spy =~ "data-lu-autohide"

    plain = rendered_to_string(~H|<.landing_nav id="n" autohide />|)
    refute plain =~ "data-lu-autohide"
    refute plain =~ "translate-y-full"
  end

  test "signed_in replaces the actions in the bar and in the mobile panel" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.landing_nav id="n" responsive>
  <:link label="A" href="/a" />
  <:actions>
    <.landing_login>Entrar</.landing_login>
  </:actions>
  <:signed_in>
    <.landing_cta href="/dashboard">Dashboard</.landing_cta>
  </:signed_in>
</.landing_nav>|)

    assert html =~ "Dashboard"
    refute html =~ "Entrar"

    only_actions =
      rendered_to_string(~H|<.landing_nav id="n">
  <:actions>
    <.landing_login>Entrar</.landing_login>
  </:actions>
</.landing_nav>|)

    assert only_actions =~ "Entrar"
  end

  test "without the new options the markup has no trace of them" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.landing_nav id="n" sticky responsive><:link label="A" href="#a" active /></.landing_nav>|
      )

    for t <-
          ~w(data-theme data-lu-autohide data-lu-spy landing-nav-start landing-nav-actions -mb-20) do
      refute html =~ t
    end

    assert html =~ ~s(class="font-semibold opacity-100")
  end

  test "cta size, block, button fallback and announcement" do
    assigns = %{}
    cta = rendered_to_string(~H|<.landing_cta size="lg" block>Go</.landing_cta>|)
    assert cta =~ "h-10"
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
    assert compact =~ "min-h-0 gap-1.5 rounded-[16px] bg-panel p-2.5"
    refute compact =~ "<a"
  end
end
