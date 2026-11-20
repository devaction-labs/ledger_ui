defmodule LedgerUI.Components.BulkBarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.BulkBar

  test "hidden at zero" do
    assigns = %{}
    assert rendered_to_string(~H|<.bulk_bar id="b" count={0} />|) == ""
  end

  test "pill with separators, plural label and close" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.bulk_bar
  id="b"
  count={3}
  label="item"
  label_plural="items"
  floating={false}
  on_clear="clear"
  show_esc
>
  <:action icon="file" phx-click="a">A</:action>
  <:action variant="danger" phx-click="d">D</:action>
</.bulk_bar>|)

    assert html =~ "3 items"
    assert html =~ "lu-selbar"
    assert length(String.split(html, "class=\"sep\"")) == 3
    assert html =~ "Esc"
    assert html =~ "phx-window-keydown"
  end

  test "disabled actions drop phx attrs, confirm opens a card" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.bulk_bar id="b" count={1} variant="solid">
  <:action disabled phx-click="x">X</:action>
  <:action phx-click="del" confirm="Sure?" confirm_text="t" confirm_label="Yes" cancel_label="No">
    Del
  </:action>
</.bulk_bar>|)

    assert html =~ "aria-disabled=\"true\""
    refute html =~ "phx-click=\"x\""
    assert html =~ "Sure?"
    assert html =~ "alertdialog"
    assert html =~ "position:fixed"
  end

  test "progress and inline variants" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.bulk_bar id="b" count={12} label="Emitindo" progress={5} progress_max={12} />|
      )

    assert html =~ "5/12"

    html =
      rendered_to_string(
        ~H|<.bulk_bar id="b" count={2} total={10} variant="inline" on_select_all="all" />|
      )

    assert html =~ "lu-panel"
    assert html =~ "Select all 10"
  end
end
