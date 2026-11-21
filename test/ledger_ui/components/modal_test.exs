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
    assert html =~ "fixed inset-0"
    assert html =~ "hidden"
    assert html =~ "data-[state=open]:flex"
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

    assert html =~ "w-[560px]"
    assert html =~ "items-start"
    assert html =~ "backdrop-blur-[4px]"
    assert html =~ ~s(role="alertdialog")
    assert html =~ ~s(data-lu-prevent-close="true")
    assert html =~ ~s(data-lu-animation="scale")
    assert html =~ ~s(data-lu-origin="top")
  end

  test "size sets the card width, with sm between xs and md" do
    widths = %{"xs" => 320, "sm" => 440, "md" => 560, "lg" => 720, "xl" => 960}

    for {size, px} <- widths do
      html =
        html(%{size: size}, fn assigns ->
          ~H"""
          <.modal id="m" title="T" size={@size}>x</.modal>
          """
        end)

      assert html =~ "w-[#{px}px]"
    end
  end

  test "placement top/bottom anchors the card to the edge; centre keeps the centred pixels" do
    card = fn placement, extra ->
      html(%{}, fn assigns ->
        assigns = Map.merge(assigns, %{p: placement, x: extra})

        ~H"""
        <.modal id="m" title="T" placement={@p} {@x}>x</.modal>
        """
      end)
    end

    center = card.("center", %{})
    assert center =~ "top-1/2"
    assert center =~ "[transform:translate(-50%,-50%)]"

    top = card.("top", %{})
    assert top =~ "top-3"
    assert top =~ "[transform:translate(-50%,0)]"
    refute top =~ "top-1/2"
    refute top =~ "translate(-50%,-50%)"

    bottom = card.("bottom", %{})
    assert bottom =~ "bottom-3"
    assert bottom =~ "[transform:translate(-50%,0)]"
    refute bottom =~ "top-1/2"

    # the page layout follows the same rule and keeps its animation variable
    page = card.("bottom", %{layout: "page", open: true})
    assert page =~ "bottom-3"
    assert page =~ "[transform:translate(-50%,0)_var(--lu-m,)]"
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

    assert html =~ "modal-header"
    assert html =~ "<h3"
    assert html =~ "Delete?"
    assert html =~ "Sure?"
    assert html =~ "bg-neg-soft text-neg"
    assert html =~ "modal-body"
    assert html =~ "modal-footer"
    assert html =~ "buttons"
  end

  test "without a header the close button sits in the corner; chip variant has a backdrop" do
    plain = html(%{}, fn assigns -> ~H|<.modal id="m">x</.modal>| end)
    chip = html(%{}, fn assigns -> ~H|<.modal id="m" close_variant="chip">x</.modal>| end)
    none = html(%{}, fn assigns -> ~H|<.modal id="m" close_button={false}>x</.modal>| end)

    assert plain =~ "absolute top-2.5 right-2.5"
    refute plain =~ "rgba(0,0,0,.35)"
    assert chip =~ "rgba(0,0,0,.35)"
    refute none =~ "modal-close"
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
    refute html =~ "fixed inset-0"
    assert html =~ ~s(role="dialog")
    refute html =~ "aria-modal"
    assert html =~ "relative flex justify-center overflow-hidden rounded-lg bg-overlay"
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

    refute html =~ "modal-body"
  end

  test "layout page: overlay + dialog only while open; a form with phx-submit" do
    assigns = %{}

    refute rendered_to_string(~H|<.modal id="m" layout="page" on_close="close">x</.modal>|) =~
             ~s(data-part="modal")

    html =
      rendered_to_string(~H|<.modal id="m" layout="page" open on_close="close" title="Novo">
  body
  <:footer>f</:footer>
</.modal>|)

    assert html =~ ~s(data-part="modal-overlay")
    assert html =~ ~r/<div[^>]*data-part="modal"/
    assert html =~ ~r/<header data-part="modal-header"/
    assert html =~ ~s(data-part="modal-body")
    refute html =~ "phx-hook"

    form =
      rendered_to_string(
        ~H|<.modal id="m" layout="page" open on_close="close" phx-submit="save" phx-change="chg">x</.modal>|
      )

    assert form =~ ~r/<form[^>]*data-part="modal"/
    assert form =~ ~s(phx-submit="save")
  end
end
