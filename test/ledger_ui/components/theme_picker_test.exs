defmodule LedgerUI.Components.ThemePickerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ThemePicker

  test "grid marks the default theme" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.theme_picker id="p" variant="grid" themes={~w(ledger noite)} />|)

    assert html =~ "lu-themebox on"
    assert html =~ "Noite"
    assert html =~ ~s(data-lu-theme="noite")
  end

  test "menu has a trigger and hidden list" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_picker id="p" default="areia" on_change="theme" />|)
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ "lu-menu-item sel"
    assert html =~ ~s(data-lu-on-change="theme")
  end

  test "custom themes as maps" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.theme_picker id="p" variant="grid" themes={[%{id: "acme", label: "Acme", accent: "#123456"}]} />|
      )

    assert html =~ "Acme"
    assert html =~ "#123456"
  end
end
