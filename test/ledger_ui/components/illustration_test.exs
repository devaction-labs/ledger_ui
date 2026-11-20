defmodule LedgerUI.Components.IllustrationTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Illustration

  test "presets read the colour of the tone" do
    assigns = %{}
    html = rendered_to_string(~H|<.illustration name="success" />|)
    assert html =~ "[--c-soft:var(--lu-pos-soft)]"
    assert html =~ "bg-(--c-soft)"
    assert html =~ "text-(--c-ink)"
    assert html =~ ~s(data-icon="check-circle")
    html = rendered_to_string(~H|<.illustration name="empty-inbox" />|)
    assert html =~ "[--c-soft:var(--lu-bg-sunken)]"
    assert html =~ ~s(data-icon="inbox")
  end

  test "the sketch is a card, two lines and a badge" do
    assigns = %{}
    html = rendered_to_string(~H|<.illustration class="mx-auto" />|)
    assert html =~ "h-[90px] w-[120px]"
    assert html =~ "mx-auto"
    assert html =~ ~s(data-part="illustration-card")
    assert length(String.split(html, ~s(data-part="illustration-line"))) == 3
    assert html =~ ~s(data-part="illustration-badge")
    refute html =~ ~r/class="(?:[^"]*\s)?lu-/
  end

  test "tone, color and icon override" do
    assigns = %{}
    html = rendered_to_string(~H|<.illustration tone="primary" icon="star" />|)
    assert html =~ "[--c-soft:var(--lu-accent-soft)]"
    assert html =~ ~s(data-icon="star")
    html = rendered_to_string(~H|<.illustration color="error" />|)
    assert html =~ "[--c-soft:var(--lu-neg-soft)]"
  end

  test "empty_box takes its colours from the tokens" do
    assigns = %{}
    html = rendered_to_string(~H|<.empty_box />|)
    assert html =~ ~s(class="h-36")
    assert html =~ "fill-sunken"
    assert html =~ "stroke-line-strong"
    assert html =~ "fill-accent-500"
    refute html =~ "var(--"
  end

  test "summit and scene" do
    assigns = %{}
    html = rendered_to_string(~H|<.summit id="s2" />|)
    assert html =~ ~s(id="s2-sky")
    assert html =~ "url(#s2-sky)"
    assert html =~ ~s(data-part="summit")
    assert html =~ "var(--lu-hero-sky1)"

    # one drawing: hero_summit/1 and auth_art/1 delegate to it
    strip = &(&1 |> String.replace(~r/data-part="[^"]*"/, "") |> String.replace(~r/\s+/, " "))
    hero = rendered_to_string(~H|<LedgerUI.Components.HeroCard.hero_summit id="s2" />|)

    auth =
      rendered_to_string(~H|<LedgerUI.Components.AuthSplit.auth_art id="s2" />|)
      |> String.split("</svg>")
      |> hd()
      |> Kernel.<>("</svg>")

    assert strip.(hero) == strip.(html)
    assert strip.(auth) == strip.(html)

    for name <- ~w(voyage lighthouse balloons aurora) do
      assigns = %{name: name}
      html = rendered_to_string(~H|<.scene name={@name} position="xMidYMax" label="Foto" />|)
      assert html =~ ~s(data-scene="#{name}")
      assert html =~ ~s(preserveAspectRatio="xMidYMax slice")
      assert html =~ ~s(aria-label="Foto")
    end

    assigns = %{}
    assert rendered_to_string(~H|<.scene name="voyage" />|) =~ ~s(aria-hidden="true")
  end
end
