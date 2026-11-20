defmodule LedgerUI.Components.MaskTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Mask

  test "a block mask with shape, size and content" do
    assigns = %{}
    html = rendered_to_string(~H|<.mask shape="hexagon" size="56">BP</.mask>|)
    assert html =~ "sh-hexagon"
    assert html =~ "--s:56px"
    assert html =~ "BP"
  end

  test "default shape is squircle" do
    assigns = %{}
    assert rendered_to_string(~H|<.mask>x</.mask>|) =~ "sh-squircle"
  end

  test "an image mask takes src and alt" do
    assigns = %{}
    html = rendered_to_string(~H|<.mask shape="heart" src="/a.jpg" alt="Jane" />|)
    assert html =~ ~s(src="/a.jpg")
    assert html =~ ~s(alt="Jane")
    assert html =~ "sh-heart"
  end

  test "label names a block mask" do
    assigns = %{}
    html = rendered_to_string(~H|<.mask shape="star" label="Favorite" />|)
    assert html =~ ~s(role="img")
    assert html =~ ~s(aria-label="Favorite")
  end
end
