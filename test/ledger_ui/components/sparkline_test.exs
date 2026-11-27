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

  test "the line is drawn at 55% opacity" do
    assigns = %{}
    html = rendered_to_string(~H|<.sparkline id="s" values={[1, 2, 3]} />|)
    assert html =~ "opacity-55"
  end

  test "dot false leaves out the end dot" do
    assigns = %{}
    html = rendered_to_string(~H|<.sparkline id="s" values={[1, 2, 3]} dot={false} />|)
    refute html =~ "sparkline-dot"
    assert html =~ "<path"
  end

  test "corner variant is 96x30 at the bottom right" do
    assigns = %{}
    html = rendered_to_string(~H|<.sparkline id="s" values={[1, 2, 3]} variant="corner" />|)
    assert html =~ "h-[30px] w-24"
    assert html =~ ~s(data-part="sparkline-dot")
  end
end
