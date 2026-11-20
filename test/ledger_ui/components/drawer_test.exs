defmodule LedgerUI.Components.DrawerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Drawer

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  test "bare drawer: closed, left by default, content straight in the panel" do
    html = html(fn assigns -> ~H|<.drawer id="d">
  <nav>menu</nav>
</.drawer>| end)
    assert html =~ "display:none"
    assert html =~ ~s(phx-hook="LedgerUI.Overlay")
    assert html =~ "lu-drawer"
    assert html =~ "left:8px"
    assert html =~ "<nav>menu</nav>"
    refute html =~ "lu-modal-b"
    assert html =~ ~s(phx-lu-lock-scroll="false")
  end

  test "placement overrides side; size sets the width; flush glues it" do
    html =
      html(fn assigns ->
        ~H|<.drawer id="d" side="left" placement="right" size="md" variant="flush">x</.drawer>|
      end)

    refute html =~ "left:8px"
    assert html =~ "width:520px"
    assert html =~ "edge"
    assert html =~ "lu-modal-b"
  end

  test "bottom is the phone's sheet with a grab handle" do
    html = html(fn assigns -> ~H|<.drawer id="d" placement="bottom">x</.drawer>| end)
    assert html =~ "lu-sheet"
    assert html =~ ~s(class="grab")
    assert html =~ "height:78%"
  end

  test "title, description, actions, back and footer make a sheet" do
    html =
      html(fn assigns ->
        ~H"""
        <.drawer id="d" title="New customer" description="Who buys" open lock_scroll>
          <:back>BACK</:back>
          <:actions>ACTIONS</:actions>
          body
          <:footer>FOOT</:footer>
        </.drawer>
        """
      end)

    refute html =~ "display:none"
    assert html =~ "New customer"
    assert html =~ "Who buys"
    assert html =~ "BACK"
    assert html =~ "ACTIONS"
    assert html =~ "lu-modal-h"
    assert html =~ "lu-modal-b"
    assert html =~ "lu-modal-f"
    assert html =~ "FOOT"
    assert html =~ ~s(phx-lu-lock-scroll="true")
    assert html =~ ~s(aria-labelledby="d-title")
  end

  test "overlay false drops the backdrop; prevent_close is a flag" do
    html = html(fn assigns -> ~H|<.drawer id="d" overlay={false} prevent_close>x</.drawer>| end)
    assert html =~ "pointer-events:none"
    assert html =~ ~s(phx-lu-prevent-close="true")
    assert html =~ ~s(phx-lu-overlay="false")
  end

  test "sheet parts" do
    html =
      html(fn assigns ->
        ~H"""
        <.sheet_header title="Edit" description="Since 2025" drawer="d" />
        <.sheet_body>B</.sheet_body>
        <.sheet_footer>F</.sheet_footer>
        """
      end)

    assert html =~ "lu-modal-h"
    assert html =~ "Edit"
    assert html =~ "lu-x"
    assert html =~ "flex:1;overflow:auto"
    assert html =~ "lu-modal-f"
  end

  test "sheet_header without a drawer id closes the closest overlay" do
    html = html(fn assigns -> ~H|<.sheet_header title="Edit" />| end)
    assert html =~ "closest"
    assert html =~ "data-lu-overlay"
  end

  test "on_close and inline" do
    html = html(fn assigns -> ~H|<.drawer id="d" on_close="cancel" target="#t">x</.drawer>| end)
    assert html =~ ~s(phx-lu-on-close="cancel")
    inline = html(fn assigns -> ~H|<.drawer id="d" inline>x</.drawer>| end)
    refute inline =~ "phx-hook"
    refute inline =~ "position:fixed"
  end
end
