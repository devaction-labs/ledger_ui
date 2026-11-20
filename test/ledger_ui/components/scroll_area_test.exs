defmodule LedgerUI.Components.ScrollAreaTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ScrollArea

  test "orientation and scrollbar" do
    assigns = %{}

    assert rendered_to_string(~H|<.scroll_area orientation="horizontal">x</.scroll_area>|) =~
             "overflow-x:auto"

    assert rendered_to_string(~H|<.scroll_area scrollbar="hidden">x</.scroll_area>|) =~
             "scrollbar-width:none"
  end

  test "focusable region" do
    assigns = %{}
    html = rendered_to_string(~H|<.scroll_area focusable label="Notes">x</.scroll_area>|)
    assert html =~ ~s(tabindex="0")
    assert html =~ ~s(role="region")
    assert html =~ ~s(aria-label="Notes")
  end

  test "stick_bottom needs an id and mounts the hook" do
    assigns = %{}

    assert rendered_to_string(~H|<.scroll_area id="m" stick_bottom>x</.scroll_area>|) =~
             "LedgerUI.ScrollBottom"

    assert_raise ArgumentError, fn ->
      rendered_to_string(~H|<.scroll_area stick_bottom>x</.scroll_area>|)
    end
  end
end
