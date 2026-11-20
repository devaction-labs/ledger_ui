defmodule LedgerUI.Components.TooltipTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Tooltip

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  test "renders trigger and a hidden hint" do
    html =
      html(fn assigns -> ~H|<.tooltip id="t" text="Save"><button>Save</button></.tooltip>| end)

    assert html =~ ~s(class="lu-anc")
    assert html =~ ~s(phx-hook="LedgerUI.Float")
    assert html =~ "fl p-top"
    assert html =~ "lu-tip2 c-neutral"
    assert html =~ "hidden"
    assert html =~ "<button>Save</button>"
    assert html =~ "Save"
  end

  test "color, placement and open" do
    html =
      html(fn assigns ->
        ~H|<.tooltip id="t" text="x" color="success" placement="bottom-end" open>b</.tooltip>|
      end)

    assert html =~ "c-success"
    assert html =~ "p-bottom-end"
    refute html =~ " hidden"
    assert html =~ ~s(phx-lu-open="true")
  end

  test "trigger, delay, follow_cursor, arrow settings go to the hook" do
    html =
      html(fn assigns ->
        ~H|<.tooltip id="t" text="x" trigger="click" delay={300} follow_cursor="both" arrow={false}>
  b
</.tooltip>|
      end)

    assert html =~ ~s(phx-lu-trigger="click")
    assert html =~ ~s(phx-lu-delay="300")
    assert html =~ ~s(phx-lu-follow="both")
    assert html =~ ~s(phx-lu-arrow="false")
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
    assert html =~ "padding:0"
    assert html =~ ~s(phx-lu-interactive="true")
  end

  test "events and tip_class" do
    html =
      html(fn assigns ->
        ~H|<.tooltip id="t" text="x" on_open="shown" on_close="hidden" target="#lv" tip_class="big">
  b
</.tooltip>|
      end)

    assert html =~ ~s(phx-lu-on-open="shown")
    assert html =~ ~s(phx-lu-on-close="hidden")
    assert html =~ ~s(phx-lu-target="#lv")
    assert html =~ "big"
  end
end
