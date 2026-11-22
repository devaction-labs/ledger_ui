defmodule LedgerUI.Components.AlertTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Alert
  import LedgerUI.Components.Icon

  test "colour, variant, shape and accent become utilities" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.alert color="warning" variant="soft" shape="pill" accent="left">x</.alert>|
      )

    assert html =~ ~s(data-part="alert")
    assert html =~ "[--c:var(--lu-warn)]"
    assert html =~ "bg-(--c-soft)"
    assert html =~ "rounded-full"
    assert html =~ "shadow-[inset_3px_0_0_var(--c)]"
    assert html =~ ~s(role="alert")
    refute html =~ "lu-al"
  end

  test "title and description draw the two lines; the quiet ink is for tinted variants" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.alert color="info" variant="soft" title="Heads up" description="Details" />|
      )

    assert html =~ ~s(data-part="alert-title">Heads up</b>)
    assert html =~ ~s(data-part="alert-description")
    assert html =~ "text-ink-2"

    solid =
      rendered_to_string(~H|<.alert color="info" variant="solid" title="T" description="D" />|)

    refute solid =~ "text-ink-2"
  end

  test "icon, action and dismiss button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.alert id="a1" dismissible on_dismiss="hide" close_label="Fechar">
        <:icon boxed><.icon name="info" /></:icon>
        body
        <:action><button>Go</button></:action>
      </.alert>
      """)

    assert html =~ ~s(data-part="alert-icon")
    assert html =~ ~s(aria-label="Fechar")
    assert html =~ ~s(data-part="alert-close")
    assert html =~ "hide"
    assert html =~ "Go"
  end

  test "the canvas variant tints the icon with the colour" do
    assigns = %{}

    assert rendered_to_string(~H|<.alert color="error">x</.alert>|) =~
             "[&amp;&gt;svg]:text-(--c-ink)"
  end

  test "closed alert is hidden and dismiss_alert/0 hides the closest alert" do
    assigns = %{}
    assert rendered_to_string(~H|<.alert open={false}>x</.alert>|) =~ "hidden"

    assert %Phoenix.LiveView.JS{
             ops: [["hide", %{to: %{closest: "[data-part=alert]"}}]]
           } = dismiss_alert()
  end

  test "a nil colour and variant leave the bare box" do
    assigns = %{}
    html = rendered_to_string(~H|<.alert color={nil} variant={nil}>x</.alert>|)
    assert html =~ "border-transparent"
    refute html =~ "[--c:"
    refute html =~ "bg-(--c"
  end

  test "loop plays the entering loop; without it there is no animation" do
    assigns = %{}

    assert rendered_to_string(~H|<.alert loop>x</.alert>|) =~
             "animate-[mo-alin_6s_cubic-bezier(.2,.8,.2,1)_infinite]"

    refute rendered_to_string(~H|<.alert>x</.alert>|) =~ "mo-alin"
  end
end
