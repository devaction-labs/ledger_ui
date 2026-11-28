defmodule LedgerUI.Components.TargetSparklineTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  defp r(assigns), do: rendered_to_string(assigns)

  @taxa [97.0, 96.5, 96.0, 95.2, 94.0, 93.5, 94.1, 95.8]

  test "line, fill, dashed target and label" do
    assigns = %{taxa: @taxa}

    html =
      r(~H|<.target_sparkline id="t" values={@taxa} target={95.0} target_label="Meta 95,0%" />|)

    assert html =~ ~s(data-part="target-sparkline-line")
    assert html =~ ~s(data-part="target-sparkline-area")
    assert html =~ ~s(stroke-dasharray="3 3")
    assert html =~ "Meta 95,0%"
    assert html =~ "url(#t-fill)"
    assert html =~ "text-chart-1"
    refute html =~ "Meta 95,0%</span>x"
  end

  test "points under the target are warn dots; better=lower flips it" do
    assigns = %{taxa: @taxa}
    html = r(~H|<.target_sparkline id="t" values={@taxa} target={95.0} />|)
    assert length(Regex.scan(~r/target-sparkline-dot/, html)) == 3
    assert html =~ "bg-chart-3"
    low = r(~H|<.target_sparkline id="t" values={@taxa} target={95.0} better="lower" />|)
    assert length(Regex.scan(~r/target-sparkline-dot/, low)) == 5
  end

  test "a11y: image with a summary in the locale; dots carry their value" do
    assigns = %{taxa: @taxa}
    html = r(~H|<.target_sparkline id="t" values={@taxa} target={95.0} />|)
    assert html =~ ~s(role="img")
    assert html =~ "8 points, last 95.8, target 95, 3 off target"
    pt = r(~H|<.target_sparkline id="t" values={@taxa} target={95.5} locale="pt_BR" />|)
    assert pt =~ "8 pontos, último 95,8, meta 95,5, 4 fora da meta"
    assert pt =~ ~s(title="95,2")
    f = r(~H|<.target_sparkline id="t" values={@taxa} target={95.0} format={&"#{&1}%"} />|)
    assert f =~ "last 95.8%"
  end

  test "empty values draw no svg" do
    assigns = %{}
    html = r(~H|<.target_sparkline id="t" values={[]} target={95} target_label="Meta" />|)
    refute html =~ "<svg"
    refute html =~ "Meta"
  end

  defp t(assigns), do: ~H|<.target_sparkline id="t" values={@v} target={@t} target_label={@l} />|

  test "tracking: each source shows; a new label does not resend the paths" do
    base = %{v: [1.0, 2.0, 3.0], t: 2.0, l: "a"}
    each_source(&t/1, base, v: [3.0, 2.0, 1.0], t: 2.5, l: "b")
    refute patch(&t/1, base, l: "b") =~ "M2"
  end
end
