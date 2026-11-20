defmodule LedgerUI.Components.AlertTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Alert
  import LedgerUI.Components.Icon

  test "classes from color, variant, shape and accent" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.alert color="warning" variant="soft" shape="pill" accent="left">x</.alert>|
      )

    for c <- ~w(lu-al c-warning v-soft sh-pill acc-left), do: assert(html =~ c)
    assert html =~ ~s(role="alert")
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

    assert html =~ ~s(class="lu-ic")
    assert html =~ ~s(aria-label="Fechar")
    assert html =~ "hide"
    assert html =~ "Go"
  end

  test "closed alert is hidden and dismiss_alert/0 hides the closest alert" do
    assigns = %{}
    assert rendered_to_string(~H|<.alert open={false}>x</.alert>|) =~ "hidden"
    assert %Phoenix.LiveView.JS{ops: [["hide", %{to: %{closest: ".lu-al"}}]]} = dismiss_alert()
  end
end
