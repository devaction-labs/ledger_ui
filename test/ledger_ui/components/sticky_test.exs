defmodule LedgerUI.Components.StickyTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Sticky

  test "hook config and sticky style" do
    assigns = %{}
    html = rendered_to_string(~H|<.sticky id="bar" offset={8} stuck_class="shadow">x</.sticky>|)
    assert html =~ ~s(phx-hook="LedgerUI.Sticky")
    assert html =~ ~s(data-offset="8")
    assert html =~ ~s(data-stuck-class="shadow")
    assert html =~ "position:sticky"
  end
end
