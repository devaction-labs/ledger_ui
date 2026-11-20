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
    assert html =~ "lu-px px-red"
    assert html =~ ~s(class="ico")
    assert html =~ "<b>Loja</b>"
    assert html =~ ~s(class="d">PDV)
    assert html =~ ~s(class="arr")
    assert html =~ ~s(phx-hook="LedgerUI.PixelCard")
    assert html =~ ~s(id="px-loja")
  end

  test "a link with href, no arrow, custom id" do
    assigns = %{}
    html = rendered_to_string(~H|<.pixel_card href="/x" title="API" arrow={false} id="api" />|)
    assert html =~ "<a"
    assert html =~ ~s(href="/x")
    assert html =~ ~s(id="api")
    refute html =~ "arr"
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
end
