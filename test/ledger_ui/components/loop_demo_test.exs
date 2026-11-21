defmodule LedgerUI.Components.LoopDemoTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Rating
  import LedgerUI.Components.ImageInput

  test "rating loop: m-loop and staggered --dl on each star, no on/off state" do
    assigns = %{}
    html = rendered_to_string(~H|<.rating id="r" loop />|)
    assert html =~ "animate-[lu-starhov_4.5s_ease-in-out_var(--dl,0s)_infinite]"
    assert html =~ "--dl:0.00s"
    assert html =~ "--dl:0.72s"
    refute html =~ "off"
  end

  test "image_input loop hover and ring" do
    assigns = %{}

    hover =
      rendered_to_string(~H|<.image_input id="a" shape="square" initials="BP" loop="hover" />|)

    assert hover =~ "animate-[lu-ovloop_4s_ease-in-out_infinite]"
    assert hover =~ ~s(data-part="image-input-overlay")

    ring = rendered_to_string(~H|<.image_input id="b" initials="AN" loop="ring" />|)
    assert ring =~ "animate-[lu-slloop2_4s_linear_infinite]"
    assert ring =~ ~s(data-part="image-input-ring")
  end
end
