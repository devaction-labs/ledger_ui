defmodule LedgerUI.Components.PixelCardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.PixelCard

  test "a button without a link, with the colour class, icon, title and arrow" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.pixel_card color="red" icon="cart" title="Loja" description="PDV" phx-click="pick" />|
      )

    assert html =~ "<button"
    assert html =~ ~s(type="button")
    assert html =~ "[--px:#e5484d]"
    assert html =~ "group relative"
    assert html =~ ~s(data-part="pixel-card-icon")
    assert html =~ ">Loja</b>"
    assert html =~ ~s(data-part="pixel-card-description")
    assert html =~ ~s(data-part="pixel-card-arrow")
    assert html =~ "data-lu-grid-class="
    assert html =~ "group-hover:opacity-100"
    assert html =~ ~s(phx-hook="LedgerUI.PixelCard")
    assert html =~ ~s(id="px-loja")
  end

  test "a link with href, no arrow, custom id" do
    assigns = %{}
    html = rendered_to_string(~H|<.pixel_card href="/x" title="API" arrow={false} id="api" />|)
    assert html =~ "<a"
    assert html =~ ~s(href="/x")
    assert html =~ ~s(id="api")
    refute html =~ "pixel-card-arrow"
  end

  test "inner block goes under the description; style carries --px" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.pixel_card title="Marca" style="--px: #f97316"><i id="x"></i></.pixel_card>|
      )

    assert html =~ ~s(id="x")
    assert html =~ "--px: #f97316"
  end

  test "loop plays the hover on the card, the pixels and the arrow" do
    assigns = %{}
    html = rendered_to_string(~H|<.pixel_card title="Loja" loop />|)
    assert html =~ "animate-[lu-pxbd_4s_ease_infinite]"
    assert html =~ "animate-[lu-pxon_4s_ease_infinite]"
    assert html =~ "animate-[lu-pxarr_4s_ease_infinite]"
    refute rendered_to_string(~H|<.pixel_card title="Loja" />|) =~ "lu-pxbd"
  end
end
