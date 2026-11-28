defmodule LedgerUI.Components.ThemePickerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ThemePicker

  test "grid marks the default theme" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.theme_picker id="p" variant="grid" themes={~w(ledger noite)} />|)

    assert html =~ ~s(aria-checked="true")
    assert html =~ ~s(data-lu-theme="ledger")
    assert html =~ "Noite"
    assert html =~ ~s(data-lu-theme="noite")
  end

  test "the built-in list has the crepusculo palette" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.theme_picker id="p" variant="grid" themes={~w(ledger crepusculo)} />|
      )

    assert html =~ ~s(data-lu-theme="crepusculo")
    assert html =~ "Crepúsculo"
    assert html =~ "#3d5fd6"
    assert Enum.any?(LedgerUI.Components.ThemePicker.themes(), &(&1.id == "crepusculo"))
  end

  test "the built-in list has the classic palette (the one from before Aurora)" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.theme_picker id="p" variant="grid" themes={~w(ledger classic crepusculo)} />|
      )

    assert html =~ ~s(data-lu-theme="classic")
    assert html =~ "Classic"
    assert Enum.any?(LedgerUI.Components.ThemePicker.themes(), &(&1.id == "classic"))
  end

  test "menu has a trigger and hidden list" do
    assigns = %{}
    html = rendered_to_string(~H|<.theme_picker id="p" default="areia" on_change="theme" />|)
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(role="menuitemradio")
    assert html =~ ~s(data-part="theme-picker-pop")
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

  test "menu open is a static preview: pop shown, in the flow, no trigger" do
    assigns = %{}

    closed =
      rendered_to_string(~H|<.theme_picker id="p" variant="menu" themes={~w(ledger noite)} />|)

    assert closed =~ "theme-picker-button"
    assert closed =~ "absolute top-[calc(100%+6px)]"
    assert closed =~ ~r/data-part="theme-picker-pop"[^>]*hidden/

    open =
      rendered_to_string(
        ~H|<.theme_picker id="p" variant="menu" open themes={~w(ledger noite)} />|
      )

    refute open =~ "theme-picker-button"
    refute open =~ "absolute top-[calc(100%+6px)]"
    refute open =~ ~r/data-part="theme-picker-pop"[^>]*\shidden/
    assert open =~ ~s(aria-checked="true")
  end
end
