defmodule LedgerUI.Components.LogoTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Logo

  test "default mark is the canvas chart glyph on a tile" do
    assigns = %{}
    html = rendered_to_string(~H|<.logo size={40} />|)
    assert html =~ "lu-logomark"
    assert html =~ "--s:40px"
    assert html =~ ~s(<path d="m8 14 3.5-4 3 2.5L19 7")
    assert html =~ ~s(width="18")
    refute html =~ "lu-logomark mono"
    assert rendered_to_string(~H|<.logo tone="mono" />|) =~ "lu-logomark mono"
  end

  test "size, tone and wordmark on the hexagon mark" do
    assigns = %{}
    html = rendered_to_string(~H|<.logo mark="hexagon" size={28} wordmark />|)
    assert html =~ ~s(width="28")
    assert html =~ "Ledger UI"
    assert html =~ "font-size:17px"
    assert rendered_to_string(~H|<.logo mark="hexagon" tone="mono" />|) =~ "#d9dde0"
  end

  test "gradient only with id" do
    assigns = %{}
    refute rendered_to_string(~H|<.logo mark="hexagon" />|) =~ "linearGradient"
    assert rendered_to_string(~H|<.logo mark="hexagon" id="hero" />|) =~ ~s(id="hero-drop")
  end
end
