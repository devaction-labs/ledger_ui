defmodule LedgerUI.Components.SwitchTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Switch

  test "renders the lu-sw label with role and aria-checked" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch color="primary" label="Notifications" />|)
    assert html =~ ~s(role="switch")
    assert html =~ ~s(aria-checked="false")
    assert html =~ ~s(class="lu-sw c-primary")
    assert html =~ "<i></i>"
    assert html =~ ~s(<span class="t">)
    refute html =~ "<input"
  end

  test "classes: size, shape, inset, variant, filled, position, state" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.switch
        size="lg"
        shape="pill"
        thumb_inset={4}
        variant="outline"
        filled
        label_position="left"
        checked
        disabled
      />
      """)

    assert html =~ ~s(class="lu-sw c-neutral s-lg pill in-4 outline filled dis left on")
    assert html =~ ~s(aria-checked="true")
    assert html =~ ~s(class="lu-sw c-neutral in-3") == false
    html = rendered_to_string(~H|<.switch size="sm" thumb_inset={3} />|)
    assert html =~ "s-sm in-3"
  end

  test "named: real hidden checkbox, unchecked input and a JS toggle" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch name="notify" checked label="Notify" />|)
    assert html =~ ~s(<input type="hidden" name="notify" value="false")
    assert html =~ ~r/<input type="checkbox" name="notify" value="true" checked/
    assert html =~ "toggle_class"
    assert html =~ "toggle_attr"
    assert html =~ "closest"
  end

  test "field fills the name, checked and errors" do
    form = to_form(%{"public" => true}, as: "f", errors: [public: {"nope", []}])
    assigns = %{form: form}
    html = rendered_to_string(~H|<.switch field={@form[:public]} label="Public" />|)
    assert html =~ ~s(name="f[public]")
    assert html =~ ~s(aria-checked="true")
    assert html =~ "nope"
  end

  test "description, inner block, wrapper and own phx-click" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.switch name="e" description="Sends mail" wrapper_class="w-full" phx-click="toggle">
        Email
      </.switch>
      """)

    assert html =~ "<small>Sends mail</small>"
    assert html =~ ~s(<div class="w-full">)
    assert html =~ ~s(phx-click="toggle")
    refute html =~ "toggle_class"
  end
end
