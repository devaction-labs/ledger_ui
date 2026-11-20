defmodule LedgerUI.Components.PopoverTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Popover

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  test "trigger, title and content in a dialog card" do
    html =
      html(fn assigns ->
        ~H"""
        <.popover id="p">
          <:trigger><button>Open</button></:trigger>
          <:title>Group</:title>
          <p>Body</p>
        </.popover>
        """
      end)

    assert html =~ ~s(data-part="popover")
    assert html =~ "relative inline-flex"
    assert html =~ "<button>Open</button>"
    assert html =~ ~s(data-lu-placement="right-start")
    assert html =~ "data-lu-fl"
    assert html =~ "rounded-lg border border-line bg-panel p-3.5"
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-labelledby="p-title")
    assert html =~ ~r/<b data-part="popover-title" id="p-title">Group<\/b>/
    assert html =~ "--w:272px"
    assert html =~ "w-(--w)"
    assert html =~ "hidden"
    assert html =~ ~s(data-lu-fallbacks="bottom,top")
    assert html =~ ~s(data-lu-offset="12")
  end

  test "label names the dialog without a title; width and class" do
    html =
      html(fn assigns ->
        ~H|<.popover id="p" label="Info" width="12rem" class="x"><:trigger>t</:trigger>b</.popover>|
      end)

    assert html =~ ~s(aria-label="Info")
    refute html =~ "aria-labelledby"
    assert html =~ "--w:12rem"
    assert html =~ ~r/class="[^"]*\bx"/
  end

  test "placement, trigger_on, open and events" do
    html =
      html(fn assigns ->
        ~H|<.popover id="p" placement="top" trigger_on="hover" open on_close="closed" arrow={false}>
  <:trigger>t</:trigger>b
</.popover>|
      end)

    assert html =~ ~s(data-lu-placement="top")
    assert html =~ ~s(data-lu-trigger="hover")
    assert html =~ ~s(data-lu-on-close="closed")
    assert html =~ ~s(data-lu-arrow="false")
    refute html =~ " hidden"
  end
end
