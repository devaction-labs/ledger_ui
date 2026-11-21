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
    assert html =~ ~s(data-state="closed")
    assert html =~ ~s(phx-hook="LedgerUI.Overlay")
    assert html =~ ~s(data-part="drawer")
    assert html =~ ~s(data-lu-side="left")
    assert html =~ "top-3 bottom-3 left-2"
    assert html =~ "<nav>menu</nav>"
    refute html =~ "drawer-body"
    assert html =~ ~s(data-lu-lock-scroll="false")
  end

  test "placement overrides side; size sets the width; flush glues it" do
    html =
      html(fn assigns ->
        ~H|<.drawer id="d" side="left" placement="right" size="md" variant="flush">x</.drawer>|
      end)

    refute html =~ "left-2"
    assert html =~ "w-[520px]"
    assert html =~ "inset-y-0 right-0 rounded-none border-0 border-l"
    assert html =~ "drawer-body"
  end

  test "bottom is the phone's sheet with a grab handle" do
    html = html(fn assigns -> ~H|<.drawer id="d" placement="bottom">x</.drawer>| end)
    assert html =~ ~s(data-lu-side="bottom")
    assert html =~ "inset-x-2 bottom-2"
    assert html =~ "drawer-grab"
    assert html =~ "h-[78%]"
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

    assert html =~ "New customer"
    assert html =~ "Who buys"
    assert html =~ "BACK"
    assert html =~ "ACTIONS"
    assert html =~ "drawer-header"
    assert html =~ "drawer-body"
    assert html =~ "drawer-footer"
    assert html =~ "FOOT"
    assert html =~ ~s(data-lu-lock-scroll="true")
    assert html =~ ~s(aria-labelledby="d-title")
  end

  test "overlay false drops the backdrop; prevent_close is a flag" do
    html = html(fn assigns -> ~H|<.drawer id="d" overlay={false} prevent_close>x</.drawer>| end)
    assert html =~ "pointer-events-none bg-transparent"
    assert html =~ ~s(data-lu-prevent-close="true")
    assert html =~ ~s(data-lu-overlay="false")
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

    assert html =~ "drawer-header"
    assert html =~ "Edit"
    assert html =~ "drawer-close"
    assert html =~ "flex-1 flex-col gap-3.5 overflow-auto"
    assert html =~ "drawer-footer"
  end

  test "sheet_header without a drawer id closes the closest overlay" do
    html = html(fn assigns -> ~H|<.sheet_header title="Edit" />| end)
    assert html =~ "closest"
    assert html =~ "data-lu-overlay"
  end

  test "on_close and inline" do
    html = html(fn assigns -> ~H|<.drawer id="d" on_close="cancel" target="#t">x</.drawer>| end)
    assert html =~ ~s(data-lu-on-close="cancel")
    inline = html(fn assigns -> ~H|<.drawer id="d" inline>x</.drawer>| end)
    refute inline =~ "phx-hook"
    refute inline =~ "fixed inset-0"
  end

  test "layout page: overlay + aside only while open, closed by on_close" do
    closed =
      html(fn assigns ->
        ~H|<.drawer id="d" layout="page" on_close="close">x</.drawer>|
      end)

    refute closed =~ ~s(data-part="drawer")

    open =
      html(fn assigns ->
        ~H|<.drawer
  id="d"
  layout="page"
  open
  on_close="close"
  title="Pedido"
  description="d"
  close_label="Fechar"
>
  body
  <:footer>foot</:footer>
</.drawer>|
      end)

    assert open =~ ~s(data-part="drawer-overlay")
    assert open =~ ~s(phx-click="close")
    assert open =~ ~r/<aside[^>]*data-part="drawer"/
    assert open =~ ~s(role="dialog")
    assert open =~ ~s(phx-window-keydown="close")
    assert open =~ ~s(data-part="drawer-body")
    assert open =~ ~r/<footer data-part="drawer-footer"/
    assert open =~ ~s(aria-label="Fechar")
    refute open =~ "phx-hook"

    custom =
      html(fn assigns ->
        ~H|<.drawer id="d" layout="page" open on_close="close"><:header><div>H</div></:header>x</.drawer>|
      end)

    assert custom =~ ~r/<header[^>]*>\s*<div>H<\/div>/
  end

  describe "size=\"auto\" and width" do
    test "auto: w-max, the sm width as minimum, the screen as maximum, full height kept" do
      html =
        html(fn assigns ->
          ~H|<.drawer id="d" placement="right" size="auto" title="T">x</.drawer>|
        end)

      assert html =~ "w-max min-w-[min(400px,calc(100%-16px))] max-w-[calc(100%-16px)]"
      assert html =~ "top-3 right-3 bottom-3"
      refute html =~ "w-[400px]"
      refute html =~ "--lu-panel-w"
    end

    test "auto flush uses the whole screen as maximum" do
      html =
        html(fn assigns ->
          ~H|<.drawer id="d" placement="right" size="auto" variant="flush">x</.drawer>|
        end)

      assert html =~ "w-max"
      assert html =~ "max-w-full"
    end

    test "integer width is px, through the css variable" do
      html = html(fn assigns -> ~H|<.drawer id="d" placement="right" width={900}>x</.drawer>| end)
      assert html =~ "w-(--lu-panel-w)"
      assert html =~ "max-w-[calc(100%-16px)]"
      assert html =~ ~s(style="--lu-panel-w: 900px")
    end

    test "string width is a css value, and wins over size" do
      html =
        html(fn assigns ->
          ~H|<.drawer id="d" placement="right" size="xl" width="min(90vw, 900px)">x</.drawer>|
        end)

      assert html =~ ~s|style="--lu-panel-w: min(90vw, 900px)"|
      assert html =~ "w-(--lu-panel-w)"
      refute html =~ "w-[1080px]"
    end

    test "an invalid width is ignored" do
      for bad <- ["10px; color: red", "1px}body{x", "url(\"x\")", "calc(1px", "", 0, -3, :x] do
        html =
          html(fn _ ->
            assigns = %{bad: bad}
            ~H|<.drawer id="d" placement="right" size="md" width={@bad}>x</.drawer>|
          end)

        refute html =~ "--lu-panel-w"
        assert html =~ "w-[520px]"
      end
    end

    test "the page layout merges the variable with its style" do
      html =
        html(fn assigns ->
          ~H|<.drawer id="d" layout="page" open width="56rem" style="color:red">x</.drawer>|
        end)

      assert html =~ ~s(style="--lu-panel-w: 56rem;color:red")
      assert html =~ "w-(--lu-panel-w)"
      refute html =~ "w-[500px]"

      auto =
        html(fn assigns -> ~H|<.drawer id="d" layout="page" open size="auto">x</.drawer>| end)

      assert auto =~ "w-max"
    end

    test "sheet takes the same, and the default is unchanged" do
      html = html(fn assigns -> ~H|<.sheet id="s" placement="right" size="auto">x</.sheet>| end)
      assert html =~ "w-max"

      default = html(fn assigns -> ~H|<.drawer id="d" placement="right">x</.drawer>| end)
      assert default =~ "w-[500px] max-w-[80%]"
      refute default =~ "style="
    end
  end
end
