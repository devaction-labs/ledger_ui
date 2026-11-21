defmodule LedgerUI.Components.LogoTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Logo

  test "default mark is the canvas chart glyph on a tile" do
    assigns = %{}
    html = rendered_to_string(~H|<.logo size={40} />|)
    assert html =~ ~s(data-part="logo-mark")
    assert html =~ "--s:40px"
    assert html =~ "bg-accent"
    assert html =~ ~s(<path d="m8 14 3.5-4 3 2.5L19 7")
    assert html =~ ~s(width="20")
    refute html =~ "bg-inverse"
    assert rendered_to_string(~H|<.logo tone="mono" />|) =~ "bg-inverse text-on-inverse"
  end

  test "size, tone and wordmark on the hexagon mark" do
    assigns = %{}
    html = rendered_to_string(~H|<.logo mark="hexagon" size={28} wordmark />|)
    assert html =~ ~s(width="28")
    assert html =~ "Ledger UI"
    assert html =~ "font-size:17px"
    assert rendered_to_string(~H|<.logo mark="hexagon" tone="mono" />|) =~ "fill-gray-300"
  end

  test "gradient only with id" do
    assigns = %{}
    refute rendered_to_string(~H|<.logo mark="hexagon" />|) =~ "linearGradient"
    assert rendered_to_string(~H|<.logo mark="hexagon" id="hero" />|) =~ ~s(id="hero-drop")
  end

  test "tone inverse, glyph and gap" do
    assigns = %{}
    html = rendered_to_string(~H|<.logo tone="inverse" size={36} glyph={18} gap="lg" />|)
    assert html =~ "bg-on-inverse text-inverse"
    assert html =~ ~s(width="18")
    assert html =~ "gap-2.5"
  end
end
