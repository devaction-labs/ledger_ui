defmodule LedgerUI.Components.ScrollTargetTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ScrollTarget

  test "target, block and scope" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.scroll_target id="st" target="contracts" block="center" scope="#detail" />|
      )

    assert html =~ ~s(phx-hook="LedgerUI.ScrollTarget")
    assert html =~ ~s(data-lu-target="contracts")
    assert html =~ ~s(data-lu-block="center")
    assert html =~ ~s(data-lu-scope="#detail")
  end

  test "defaults: nearest, whole document, no target" do
    assigns = %{}
    html = rendered_to_string(~H|<.scroll_target id="st" target={nil} />|)
    assert html =~ ~s(data-lu-block="nearest")
    refute html =~ "data-lu-target"
    refute html =~ "data-lu-scope"
  end

  test "LedgerUI.scroll_to/3 pushes ledger:scroll" do
    socket = %Phoenix.LiveView.Socket{}
    socket = LedgerUI.scroll_to(socket, "#a", block: "start", scope: "#box")

    assert %{private: %{live_temp: %{push_events: [["ledger:scroll", payload]]}}} = socket
    assert payload == %{selector: "#a", block: "start", scope: "#box"}

    socket = LedgerUI.scroll_to(%Phoenix.LiveView.Socket{}, "#a")

    assert %{
             private: %{
               live_temp: %{push_events: [["ledger:scroll", %{block: "nearest", scope: nil}]]}
             }
           } =
             socket

    assert_raise ArgumentError, fn -> LedgerUI.scroll_to(socket, "#a", block: "middle") end
  end
end
