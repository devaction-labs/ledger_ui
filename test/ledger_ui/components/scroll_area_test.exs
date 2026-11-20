defmodule LedgerUI.Components.ScrollAreaTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ScrollArea

  test "orientation and scrollbar" do
    assigns = %{}

    html = rendered_to_string(~H|<.scroll_area orientation="horizontal">x</.scroll_area>|)
    assert html =~ ~s(data-orientation="horizontal")
    refute html =~ "style="

    assert rendered_to_string(~H|<.scroll_area scrollbar="hidden">x</.scroll_area>|) =~
             ~s(data-scrollbar="hidden")
  end

  test "panel variant is the canvas card with the inline scroll style" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.scroll_area variant="panel" orientation="both" style="height:240px">x</.scroll_area>|
      )

    assert html =~ ~s(class="lu-panel")
    assert html =~ "overflow:auto"
    assert html =~ "height:240px"
  end

  test "preview variant draws the canvas frame and the thumb" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.scroll_area variant="preview" scrollbar="always" style="height:200px">x</.scroll_area>|
      )

    assert html =~ ~s(class="lu-sa")
    assert html =~ ~s(<span class="bar mo">)
    refute html =~ "barx"

    horizontal =
      rendered_to_string(
        ~H|<.scroll_area variant="preview" orientation="horizontal" scrollbar="hidden">x</.scroll_area>|
      )

    assert horizontal =~ "lu-sa hidden"
    assert horizontal =~ "barx mo"
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
