defmodule LedgerUI.Components.TooltipTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Tooltip

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  test "renders trigger and a hidden hint" do
    html =
      html(fn assigns -> ~H|<.tooltip id="t" text="Save"><button>Save</button></.tooltip>| end)

    assert html =~ ~s(data-part="tooltip")
    assert html =~ "relative inline-flex"
    assert html =~ ~s(phx-hook="LedgerUI.Float")
    assert html =~ ~s(data-lu-placement="top")
    assert html =~ "data-lu-fl"
    assert html =~ "bg-tip text-white"
    assert html =~ "hidden"
    assert html =~ "<button>Save</button>"
    assert html =~ "Save"
  end

  defp tooltip_for(color) do
    assigns = %{color: color}
    rendered_to_string(~H|<.tooltip id="t" text="x" color={@color}>b</.tooltip>|)
  end

  test "neutral and dark tooltips use the tip token, r10, no loose hex" do
    for color <- ~w(neutral dark) do
      html =
        tooltip_for(color)

      assert html =~ "bg-tip text-white"
      assert html =~ "rounded-[10px]"
      refute html =~ ~r/#[0-9a-fA-F]{3,8}/
    end
  end

  test "color, placement and open" do
    html =
      html(fn assigns ->
        ~H|<.tooltip id="t" text="x" color="success" placement="bottom-end" open>b</.tooltip>|
      end)

    assert html =~ "bg-(--c) text-(--c-on)"
    assert html =~ "[--c:var(--lu-pos)]"
    assert html =~ ~s(data-lu-placement="bottom-end")
    refute html =~ " hidden"
    assert html =~ ~s(data-lu-open="true")
  end

  test "trigger, delay, follow_cursor, arrow settings go to the hook" do
    html =
      html(fn assigns ->
        ~H|<.tooltip id="t" text="x" trigger="click" delay={300} follow_cursor="both" arrow={false}>
  b
</.tooltip>|
      end)

    assert html =~ ~s(data-lu-trigger="click")
    assert html =~ ~s(data-lu-delay="300")
    assert html =~ ~s(data-lu-follow="both")
    assert html =~ ~s(data-lu-arrow="false")
  end

  test ":content replaces the text, without padding, and is interactive" do
    html =
      html(fn assigns ->
        ~H"""
        <.tooltip id="t" text="ignored">
          b
          <:content>
            <p>rich</p>
          </:content>
        </.tooltip>
        """
      end)

    assert html =~ "<p>rich</p>"
    refute html =~ "ignored"
    assert html =~ " p-0"
    assert html =~ ~s(data-lu-interactive="true")
  end

  test "events and tip_class" do
    html =
      html(fn assigns ->
        ~H|<.tooltip id="t" text="x" on_open="shown" on_close="hidden" target="#lv" tip_class="big">
  b
</.tooltip>|
      end)

    assert html =~ ~s(data-lu-on-open="shown")
    assert html =~ ~s(data-lu-on-close="hidden")
    assert html =~ ~s(data-lu-target="#lv")
    assert html =~ "big"
  end
end
