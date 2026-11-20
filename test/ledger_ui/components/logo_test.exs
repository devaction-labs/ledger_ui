defmodule LedgerUI.Components.LogoTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Logo

  test "size, tone and wordmark" do
    assigns = %{}
    html = rendered_to_string(~H|<.linea_logo size={28} wordmark />|)
    assert html =~ ~s(width="28")
    assert html =~ "Ledger UI"
    assert html =~ "font-size:17px"
    assert rendered_to_string(~H|<.linea_logo tone="mono" />|) =~ "#d9dde0"
  end

  test "gradient only with id" do
    assigns = %{}
    refute rendered_to_string(~H|<.linea_logo />|) =~ "linearGradient"
    assert rendered_to_string(~H|<.linea_logo id="hero" />|) =~ ~s(id="hero-drop")
  end
end
