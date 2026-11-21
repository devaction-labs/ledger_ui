defmodule LedgerUI.Components.HotkeyTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Hotkey
  alias Phoenix.LiveView.JS

  test "event name, target and keys" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.hotkey id="hk" keys="Mod+j, Mod+Shift+k" on_press="toggle" target="#panel" />|
      )

    assert html =~ ~s(id="hk")
    assert html =~ ~s(phx-hook="LedgerUI.Hotkey")
    assert html =~ ~s(data-lu-keys="Mod+j, Mod+Shift+k")
    assert html =~ ~s(data-lu-on-press="toggle")
    assert html =~ ~s(data-lu-target="#panel")
    assert html =~ "hidden"
    refute html =~ "data-lu-on-press-js"
    refute html =~ "data-lu-in-inputs"
  end

  test "a %JS{} is encoded and in_inputs is a flag" do
    assigns = %{js: JS.push("aw_toggle", target: "#x")}

    html =
      rendered_to_string(~H|<.hotkey id="hk" keys="Mod+j" on_press={@js} in_inputs />|)

    assert html =~ "data-lu-on-press-js="
    assert html =~ "aw_toggle"
    refute html =~ "data-lu-on-press="
    assert html =~ ~s(data-lu-in-inputs="true")
  end
end
