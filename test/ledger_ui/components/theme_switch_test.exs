defmodule LedgerUI.Components.ThemeSwitchTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ThemeSwitch

  test "segmented, icons, sizes" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_switch id="t" />|)
    assert html =~ "lu-ts"
    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(data-icon="monitor")

    assert rendered_to_string(~H|<.theme_switch id="t" variant="icons" size="sm" />|) =~
             "lu-ts icons sm"

    refute rendered_to_string(~H|<.theme_switch id="t" system={false} />|) =~ "monitor"
  end

  test "switch variant" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_switch id="t" variant="switch" dark_label="Escuro" />|)
    assert html =~ "lu-sw"
    assert html =~ ~s(role="switch")
    assert html =~ "Escuro"
  end

  test "theme_script is inline and sets data-theme" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_script theme="ocean" />|)
    assert html =~ "<script>"
    assert html =~ "data-theme"
    assert html =~ "localStorage"
    assert html =~ "ocean"
  end

  test "theme_toggle" do
    assigns = %{}
    assert rendered_to_string(~H|<.theme_toggle />|) =~ "LedgerUI.ThemeSwitch"
  end
end
