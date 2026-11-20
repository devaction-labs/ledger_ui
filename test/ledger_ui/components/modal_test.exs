defmodule LedgerUI.Components.ModalTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Modal

  defp html(assigns, fun), do: assigns |> fun.() |> rendered_to_string()

  test "closed by default: hidden, with hook and a11y attributes" do
    html =
      html(%{}, fn assigns ->
        ~H"""
        <.modal id="m" title="Export">body</.modal>
        """
      end)

    assert html =~ ~s(id="m")
    assert html =~ ~s(data-state="closed")
    refute html =~ "display:none"
    assert html =~ "position:fixed"
    assert html =~ ~s(phx-hook="LedgerUI.Overlay")
    assert html =~ "data-lu-overlay"
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-modal="true")
    assert html =~ ~s(aria-labelledby="m-title")
    assert html =~ ~s(data-lu-open="false")
  end

  test "open renders without display:none" do
    html =
      html(%{}, fn assigns ->
        ~H"""
        <.modal id="m" open>body</.modal>
        """
      end)

    refute html =~ "display:none"
    assert html =~ ~s(data-state="open")
    assert html =~ ~s(data-lu-open="true")
  end

  test "size, placement, blur, role and prevent_close" do
    html =
      html(%{}, fn assigns ->
        ~H"""
        <.modal
          id="m"
          size="md"
          placement="top"
          blur
          role="alertdialog"
          prevent_close
          animation="scale"
          origin="top"
        >
          x
        </.modal>
        """
      end)

    assert html =~ "width:560px"
    assert html =~ "align-items:flex-start"
    assert html =~ "backdrop-filter"
    assert html =~ ~s(role="alertdialog")
    assert html =~ ~s(data-lu-prevent-close="true")
    assert html =~ ~s(data-lu-animation="scale")
    assert html =~ ~s(data-lu-origin="top")
  end

  test "title, description, icon and footer" do
    html =
      html(%{}, fn assigns ->
        ~H"""
        <.modal id="m" title="Delete?" description="Sure?" icon="trash" icon_tone="error">
          x
          <:footer>buttons</:footer>
        </.modal>
        """
      end)

    assert html =~ "lu-modal-h"
    assert html =~ "<h3"
    assert html =~ "Delete?"
    assert html =~ "Sure?"
    assert html =~ "lu-ic neg"
    assert html =~ "lu-modal-b"
    assert html =~ "lu-modal-f"
    assert html =~ "buttons"
  end

  test "without a header the close button sits in the corner; chip variant has a backdrop" do
    plain = html(%{}, fn assigns -> ~H|<.modal id="m">x</.modal>| end)
    chip = html(%{}, fn assigns -> ~H|<.modal id="m" close_variant="chip">x</.modal>| end)
    none = html(%{}, fn assigns -> ~H|<.modal id="m" close_button={false}>x</.modal>| end)

    assert plain =~ "position:absolute;top:10px;right:10px"
    refute plain =~ "rgba(0,0,0,.35)"
    assert chip =~ "rgba(0,0,0,.35)"
    refute none =~ "lu-x"
  end

  test "the close button closes the modal by id" do
    html = html(%{}, fn assigns -> ~H|<.modal id="m" title="T">x</.modal>| end)
    assert html =~ "remove_class"
    assert html =~ "#m"
  end

  test "on_open / on_close: event names and JS commands, target" do
    html =
      html(%{}, fn assigns ->
        ~H|<.modal id="m" on_close="closed" on_open={Phoenix.LiveView.JS.push("opened")} target="#lv">
  x
</.modal>|
      end)

    assert html =~ ~s(data-lu-on-close="closed")
    assert html =~ "data-lu-on-open"
    assert html =~ "opened"
    assert html =~ ~s(data-lu-target="#lv")
  end

  test "inline is a static preview" do
    html = html(%{}, fn assigns -> ~H|<.modal id="m" inline size="sm">x</.modal>| end)
    refute html =~ "phx-hook"
    refute html =~ "position:fixed"
    assert html =~ ~s(role="dialog")
    refute html =~ "aria-modal"
    assert html =~ ~s(class="lu-scrim")
  end

  test "empty default slot renders no body" do
    html =
      html(%{}, fn assigns ->
        ~H"""
        <.modal id="m" title="T">
          <:footer>f</:footer>
        </.modal>
        """
      end)

    refute html =~ "lu-modal-b"
  end
end
