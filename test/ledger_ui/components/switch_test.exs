defmodule LedgerUI.Components.SwitchTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Switch

  test "renders the switch label with role and aria-checked" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch color="primary" label="Notifications" />|)
    assert html =~ ~s(role="switch")
    assert html =~ ~s(aria-checked="false")
    assert html =~ ~s(data-part="switch")
    assert html =~ "[--c:var(--color-accent)]"
    assert html =~ ~s(data-part="switch-track")
    assert html =~ ~s(data-part="switch-text")
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

    assert html =~ "[--tw:46px] [--th:28px]"
    assert html =~ "[--r:999px]"
    assert html =~ "[--in:4px]"
    assert html =~ "group-aria-checked:bg-(--c-soft)"
    assert html =~ "flex-row-reverse"
    assert html =~ "cursor-not-allowed opacity-45"
    assert html =~ ~s(aria-checked="true")
    refute html =~ "lu-sw"
    html = rendered_to_string(~H|<.switch size="sm" thumb_inset={3} />|)
    assert html =~ "[--tw:30px] [--th:18px]"
    assert html =~ "[--r:6px]"
    assert html =~ "[--in:3px]"
  end

  test "named: real hidden checkbox, unchecked input and a JS toggle" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch name="notify" checked label="Notify" />|)
    assert html =~ ~s(<input type="hidden" name="notify" value="false")
    assert html =~ ~r/<input[^>]*type="checkbox"[^>]*name="notify" value="true" checked/
    refute html =~ "toggle_class"
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

    assert html =~ "Sends mail</small>"
    assert html =~ ~r/<div class="[^"]*w-full"/
    assert html =~ ~s(phx-click="toggle")
    refute html =~ "toggle_class"
  end
end
