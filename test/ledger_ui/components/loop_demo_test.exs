defmodule LedgerUI.Components.LoopDemoTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Rating
  import LedgerUI.Components.ImageInput

  test "rating loop: m-loop and staggered --dl on each star, no on/off state" do
    assigns = %{}
    html = rendered_to_string(~H|<.rating id="r" loop />|)
    assert html =~ "lu-stars m-loop"
    assert html =~ "--dl:0.00s"
    assert html =~ "--dl:0.72s"
    refute html =~ "off"
  end

  test "image_input loop hover and ring" do
    assigns = %{}

    hover =
      rendered_to_string(~H|<.image_input id="a" shape="square" initials="BP" loop="hover" />|)

    assert hover =~ "m-hover"
    assert hover =~ ~s(class="ov")

    ring = rendered_to_string(~H|<.image_input id="b" initials="AN" loop="ring" />|)
    assert ring =~ "m-loop"
    assert ring =~ ~s(class="rg")
  end
end
