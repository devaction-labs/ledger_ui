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
    assert html =~ "sticky top-0 z-20 bg-page"
    refute html =~ "data-[stuck]:shadow"
  end

  test "without a stuck class the stuck state draws the bottom line" do
    assigns = %{}
    html = rendered_to_string(~H|<.sticky id="bar">x</.sticky>|)
    assert html =~ "data-[stuck]:shadow-[0_1px_0_var(--lu-line)]"
  end

  test "preview draws the canvas frame" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.sticky
        id="s"
        preview
        body_class="animate-[mo-scroll_8s_ease-in-out_infinite]"
        body_style="--sy:-160px"
      >
        <:header>Head</:header>
        <i style="width:90%"></i>
      </.sticky>
      """)

    assert html =~ "h-[220px] overflow-hidden"
    assert html =~ ~s(data-part="sticky-header")
    assert html =~ "Head"
    assert html =~ "animate-[mo-scroll_8s_ease-in-out_infinite]"
    refute html =~ ~r{(?<!-)\blu-[a-z]}
    refute html =~ "phx-hook"
  end
end
