defmodule LedgerUI.Components.SparklineTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Sparkline

  test "draws a line and handles flat series" do
    assigns = %{}
    html = rendered_to_string(~H|<.sparkline id="s" values={[1, 2, 3]} color="primary" />|)
    assert html =~ "var(--lu-accent-500)"
    assert html =~ ~s(data-part="sparkline-dot")
    refute html =~ "lu-spark"
    assert rendered_to_string(~H|<.sparkline id="f" values={[5, 5]} />|) =~ "<path"
    refute rendered_to_string(~H|<.sparkline id="e" values={[]} />|) =~ "<svg"
  end
end
