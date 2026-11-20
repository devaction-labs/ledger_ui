defmodule LedgerUI.Components.PasswordInputTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.PasswordInput

  test "renders a password input with lock icon and an eye button" do
    assigns = %{}
    html = rendered_to_string(~H|<.password_input name="password" placeholder="Senha" />|)
    assert html =~ ~s(type="password")
    assert html =~ ~s(id="password")
    assert html =~ ~s(data-icon="lock")
    assert html =~ ~s(class="eye")
    assert html =~ ~s(aria-label="Show the password")
    assert html =~ ~s(aria-controls="password")
    assert html =~ ~s(data-icon="eye")
    assert html =~ ~s(data-icon="eye-off")
    refute html =~ "phx-hook"
  end

  test "the eye toggles type and label with JS commands" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.password_input name="pw" show_label="Mostrar a senha" hide_label="Ocultar a senha" />
      """)

    assert html =~ ~s(aria-label="Mostrar a senha")
    assert html =~ "toggle_attr"
    assert html =~ "Ocultar a senha"
    assert html =~ "password"
  end

  test "takes the input attrs: label, help, size, variant, state, field" do
    form =
      to_form(%{"password" => ""},
        as: :user,
        errors: [password: {"too short", []}],
        action: :validate
      )

    assigns = %{f: form[:password]}

    html =
      rendered_to_string(~H"""
      <.password_input
        field={@f}
        label="Senha"
        help="12+"
        size="lg"
        variant="filled"
        autocomplete="new-password"
      />
      """)

    assert html =~ ~s(name="user[password]")
    assert html =~ ~s(id="user_password")
    assert html =~ ~s(autocomplete="new-password")
    assert html =~ "lu-input filled lg err"
    assert html =~ "too short"
    assert html =~ "Senha"
  end

  test "disabled disables the eye too; below slot is forwarded" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.password_input name="pw" disabled>
        <:below><i class="bars"></i></:below>
      </.password_input>
      """)

    assert html =~ ~r/<button[^>]*disabled/
    assert html =~ "bars"
  end
end
