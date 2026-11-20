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
    assert html =~ "lu-sticky-bar"
  end

  test "preview draws the canvas frame" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.sticky id="s" preview body_class="mo-scroll" body_style="--sy:-160px">
        <:header>Head</:header>
        <i style="width:90%"></i>
      </.sticky>
      """)

    assert html =~ ~s(class="lu-sticky")
    assert html =~ ~s(<div class="hd">Head</div>)
    assert html =~ ~s(class="body mo-scroll")
    refute html =~ "phx-hook"
  end
end
