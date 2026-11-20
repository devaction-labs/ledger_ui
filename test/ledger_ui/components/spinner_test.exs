defmodule LedgerUI.Components.SpinnerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Spinner

  test "defaults are labelled as a status" do
    assigns = %{}
    html = rendered_to_string(~H|<.spinner />|)
    assert html =~ ~s(data-part="spinner")
    # canvas ring, 16px, neutral colour
    assert html =~ "[--s:16px]"
    assert html =~ "lu-spin_.8s_linear"
    assert html =~ "[--c:var(--lu-ink)]"
    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-label="Loading")
  end

  test "nil label is decorative" do
    assigns = %{}
    refute rendered_to_string(~H|<.spinner label={nil} />|) =~ "role"
  end

  test "variants animate" do
    assigns = %{}
    assert rendered_to_string(~H|<.spinner variant="border" />|) =~ "lu-spin_.7s_linear"
    assert rendered_to_string(~H|<.spinner variant="soft" />|) =~ "lu-spin_1s_ease-in-out"
    assert rendered_to_string(~H|<.spinner variant="grow" />|) =~ "lu-grow_.9s"
  end

  test "svg variant draws the arc and turns it" do
    assigns = %{}
    html = rendered_to_string(~H|<.spinner variant="svg" size="xl" />|)
    assert html =~ "<svg"
    assert html =~ ~s(data-part="spinner-icon")
    assert html =~ "[--s:40px]"
    assert html =~ "[&amp;&gt;svg]:animate-[lu-spin_1.2s_linear_infinite]"
  end

  test "white and current set the colour variable, elastic swaps the easing" do
    assigns = %{}
    assert rendered_to_string(~H|<.spinner color="white" />|) =~ "[--c:#fff]"
    assert rendered_to_string(~H|<.spinner color="current" />|) =~ "[--c:currentColor]"
    assert rendered_to_string(~H|<.spinner elastic />|) =~ "cubic-bezier(.68,-.55,.27,1.55)"
    refute rendered_to_string(~H|<.spinner />|) =~ "cubic-bezier"
  end

  test "classes/4 is the string the toast hook uses" do
    assert classes("primary", "border", "sm") =~ "lu-spin_.7s_linear"
  end
end
