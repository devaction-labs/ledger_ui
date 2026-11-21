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

  test "value draws the initial choice on the server" do
    assigns = %{}
    seg = rendered_to_string(~H|<.theme_switch id="t" value="dark" />|)
    assert seg =~ ~s(data-lu-default="dark")
    assert [_, light, dark, system] = String.split(seg, ~s(role="radio"))
    assert light =~ ~s(aria-checked="false")
    assert dark =~ ~s(aria-checked="true")
    assert system =~ ~s(aria-checked="false")
    assert dark =~ ~s(tabindex="0")

    # no `system`: the value falls back to light
    assert rendered_to_string(~H|<.theme_switch id="t" value="system" system={false} />|) =~
             ~r/role="radio"[^>]*aria-checked="true"/

    assert rendered_to_string(~H|<.theme_switch id="t" />|) =~ ~s(aria-checked="true")
  end

  test "switch variant: value dark checks it; the icon slot replaces the label" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.theme_switch id="t" variant="switch" value="dark" dark_label="Escuro">
        <:icon><svg data-icon="moon" /></:icon>
      </.theme_switch>
      """)

    assert html =~ ~s(aria-checked="true")
    assert html =~ ~s(data-icon="moon")
    refute html =~ "Escuro</span>"

    assert rendered_to_string(~H|<.theme_switch id="t" variant="switch" />|) =~
             ~s(aria-checked="false")
  end

  describe "theme_script nonce" do
    test "puts the nonce on the script" do
      assigns = %{}
      html = rendered_to_string(~H|<.theme_script nonce="abc" />|)
      assert html =~ ~s(<script nonce="abc">)
    end

    test "without nonce the output is the same as before" do
      assigns = %{}
      html = rendered_to_string(~H|<.theme_script theme="ocean" />|)
      body = LedgerUI.Components.ThemeSwitch.script_body("system", "ocean")
      assert html == "<script>\n  " <> body <> "\n</script>"
      refute html =~ "nonce"
    end
  end
end
