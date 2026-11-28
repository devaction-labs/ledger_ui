defmodule LedgerUI.Components.SwitchTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Switch

  test "renders the unnamed switch label with role and aria-checked" do
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

  test "named: the checkbox is the switch, the label has no role and the track follows :checked" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch name="notify" checked label="Notify" />|)
    assert html =~ ~s(<input type="hidden" name="notify" value="false")

    assert html =~
             ~r/<input[^>]*type="checkbox"[^>]*role="switch"[^>]*name="notify" value="true" checked/

    [label] = Regex.run(~r/<label[^>]*>/, html)
    refute label =~ "role="
    refute label =~ "aria-checked"
    refute html =~ "aria-checked"
    refute html =~ "toggle_attr"
    refute html =~ "group-aria-checked"
    assert html =~ "peer-checked:bg-(--c)"
    assert html =~ "peer-checked:after:translate-x-"
    # one switch per component: only the input has the role
    assert length(Regex.scan(~r/role="switch"/, html)) == 1
    # the track follows the input directly, so `peer` reaches it
    assert html =~
             ~r/class="peer [^"]*"[^>]*data-part="switch-input"[^>]*>\s*<i data-part="switch-track"/
  end

  test "named, outline and filled use peer-checked too" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch name="n" variant="outline" filled />|)
    assert html =~ "peer-checked:bg-(--c-soft)"
    assert html =~ "peer-checked:shadow-[inset_0_0_0_1.5px_var(--c)]"
    refute html =~ "group-aria-checked"
  end

  test "without a name a button is the switch (focusable, one switch node) with a JS toggle" do
    assigns = %{}
    html = rendered_to_string(~H|<.switch label="x" />|)
    assert html =~ ~r/<button type="button"[^>]*role="switch"[^>]*aria-checked="false"/
    refute html =~ "<label"
    assert html =~ "group-aria-checked:bg-(--c)"
    refute html =~ "peer-checked"
    assert html =~ "toggle_attr"
  end

  test "field fills the name, checked and errors" do
    form = to_form(%{"public" => true}, as: "f", errors: [public: {"nope", []}])
    assigns = %{form: form}
    html = rendered_to_string(~H|<.switch field={@form[:public]} label="Public" />|)
    assert html =~ ~s(name="f[public]")
    assert html =~ ~r/<input[^>]*type="checkbox"[^>]*checked/
    assert html =~ "nope"
  end

  test "field fills the name, checked and errors (the checkbox is checked)" do
    form = to_form(%{"public" => true}, as: "f")
    assigns = %{form: form}
    html = rendered_to_string(~H|<.switch field={@form[:public]} />|)
    assert html =~ ~r/<input[^>]*type="checkbox"[^>]*checked/
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
