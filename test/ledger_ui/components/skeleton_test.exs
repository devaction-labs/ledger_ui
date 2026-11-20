defmodule LedgerUI.Components.SkeletonTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Skeleton

  test "animation and shape classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.skeleton animation="pulse" shape="circle" class="size-4" />|)
    for c <- ~w(lu-sk a-pulse sh-circle size-4), do: assert(html =~ c)
    assert rendered_to_string(~H|<.skeleton />|) =~ "a-wave"
  end

  test "no animation class with nil, a-none with none, span with tag" do
    assigns = %{}
    refute rendered_to_string(~H|<.skeleton animation={nil} />|) =~ ~r/ a-/
    assert rendered_to_string(~H|<.skeleton animation="none" />|) =~ "a-none"
    html = rendered_to_string(~H|<.skeleton tag="span" />|)
    assert html =~ "<span"
    assert html =~ "</span>"
  end

  test "lineone has the 3px corner" do
    assigns = %{}
    assert rendered_to_string(~H|<.skeleton variant="lineone" />|) =~ "border-radius:3px"
  end

  test "group is a busy status with a screen reader label" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.skeleton_group label="Loading orders"><.skeleton /></.skeleton_group>|
      )

    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-busy="true")
    assert html =~ "Loading orders"
  end
end
