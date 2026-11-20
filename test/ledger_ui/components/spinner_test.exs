defmodule LedgerUI.Components.SpinnerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Spinner

  test "defaults are labelled as a status" do
    assigns = %{}
    html = rendered_to_string(~H|<.spinner />|)
    for c <- ~w(lu-sp v-canvas s-sm c-neutral), do: assert(html =~ c)
    assert html =~ ~s(role="status")
    assert html =~ ~s(aria-label="Loading")
  end

  test "nil label is decorative" do
    assigns = %{}
    refute rendered_to_string(~H|<.spinner label={nil} />|) =~ "role"
  end

  test "svg variant draws the arc" do
    assigns = %{}
    assert rendered_to_string(~H|<.spinner variant="svg" size="xl" />|) =~ "<svg"
  end

  test "white and current use the text colour, elastic sets the timing" do
    assigns = %{}
    assert rendered_to_string(~H|<.spinner color="white" />|) =~ "--c:#fff"
    assert rendered_to_string(~H|<.spinner color="current" />|) =~ "--c:currentColor"
    assert rendered_to_string(~H|<.spinner elastic />|) =~ "animation-timing-function"
  end
end
