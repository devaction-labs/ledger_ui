defmodule LedgerUI.Components.HeroCardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.HeroCard

  test "eyebrow, title, description and heading tag" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.hero_card eyebrow="Bem-vindo" title="Metas" description="Do ano" heading="h1" />|
      )

    assert html =~ "Bem-vindo"
    assert html =~ ~r/<h1[^>]*>Metas<\/h1>/
    assert html =~ "Do ano"
  end

  test "variant and size" do
    assigns = %{}
    html = rendered_to_string(~H|<.hero_card title="x" variant="panel" size="lg" />|)
    assert html =~ "lu-cv default"
    assert html =~ "padding:24px"
    assert rendered_to_string(~H|<.hero_card title="x" />|) =~ "soft c-primary"
  end

  test "picture from src or art, actions and icon slots" do
    assigns = %{}
    html = rendered_to_string(~H|<.hero_card title="x" src="/h.jpg" position="right" />|)
    assert html =~ ~s(src="/h.jpg")
    assert html =~ "object-position:right"

    html =
      rendered_to_string(~H"""
      <.hero_card title="x" eyebrow="e">
        <:icon><i id="ic"></i></:icon>
        <:actions><button id="go">go</button></:actions>
        <:art><svg id="art"></svg></:art>
      </.hero_card>
      """)

    assert html =~ ~s(id="ic")
    assert html =~ ~s(id="go")
    assert html =~ ~s(id="art")
  end
end
