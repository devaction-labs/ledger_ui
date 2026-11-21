defmodule LedgerUI.Components.SkeletonTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Skeleton

  test "animation and shape utilities" do
    assigns = %{}
    html = rendered_to_string(~H|<.skeleton animation="pulse" shape="circle" class="size-4" />|)
    assert html =~ ~s(data-part="skeleton")
    assert html =~ "lu-pulse"
    assert html =~ "rounded-[50%]"
    assert html =~ "size-4"
    assert rendered_to_string(~H|<.skeleton />|) =~ "lu-wave"
  end

  test "the base block is 12px high unless the class has a height" do
    assigns = %{}
    assert rendered_to_string(~H|<.skeleton />|) =~ "h-3"
    html = rendered_to_string(~H|<.skeleton class="h-8 w-20" />|)
    refute html =~ "h-3"
    assert html =~ "h-8 w-20"
    refute rendered_to_string(~H|<.skeleton class="size-10" />|) =~ "h-3"
  end

  test "nil and none leave the block still, span with tag" do
    assigns = %{}
    refute rendered_to_string(~H|<.skeleton animation={nil} />|) =~ "animate-"
    refute rendered_to_string(~H|<.skeleton animation="none" />|) =~ "animate-"
    html = rendered_to_string(~H|<.skeleton tag="span" />|)
    assert html =~ "<span"
    assert html =~ "</span>"
  end

  test "lineone has the 3px corner" do
    assigns = %{}
    assert rendered_to_string(~H|<.skeleton variant="lineone" />|) =~ "rounded-[3px]"
  end

  test "group is a busy status with a screen reader label" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.skeleton_group label="Loading orders"><.skeleton /></.skeleton_group>|
      )

    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-busy="true")
    assert html =~ "sr-only"
    assert html =~ "Loading orders"
  end
end
