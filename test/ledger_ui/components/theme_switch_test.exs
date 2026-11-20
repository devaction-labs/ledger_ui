defmodule LedgerUI.Components.ThemeSwitchTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ThemeSwitch

  test "segmented, icons, sizes" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_switch id="t" />|)
    assert html =~ "bg-sunken"
    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(data-icon="monitor")

    assert rendered_to_string(~H|<.theme_switch id="t" variant="icons" size="sm" />|) =~
             "h-[22px] w-[26px]"

    refute rendered_to_string(~H|<.theme_switch id="t" system={false} />|) =~ "monitor"
  end

  test "switch variant" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_switch id="t" variant="switch" dark_label="Escuro" />|)
    assert html =~ "group-aria-checked:bg-accent"
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

  test "theme_script applies the stored palette (ledger-palette) and falls back to the given one" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_script theme="crepusculo" />|)
    assert html =~ ~s|localStorage.getItem("ledger-palette")|
    assert html =~ ~s(data-palette)
    assert html =~ "crepusculo"
  end

  test "theme_toggle" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_toggle />|)
    assert html =~ "LedgerUI.ThemeSwitch"
    assert html =~ "dark:hidden"
    assert html =~ ~s(data-icon="sun")
  end
end
