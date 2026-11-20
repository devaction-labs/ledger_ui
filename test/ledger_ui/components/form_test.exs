defmodule LedgerUI.Components.FormTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Form

  # A form built without params counts as unused: its errors stay hidden.
  defp form_field(errors) do
    form = to_form(%{}, as: :user, errors: errors)
    form[:country]
  end

  test "label, error and help_text" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.label for="email">Email</.label>
      <.error>can't be blank</.error>
      <.help_text>We never share it</.help_text>
      <.help_text state="success">Valid</.help_text>
      <.help_text state="error">Bad</.help_text>
      """)

    assert html =~ ~s(<label data-part="label" for="email" class="lu-label">)
    assert html =~ ~s(role="alert")
    assert html =~ "lu-help err"
    assert html =~ ~s(class="lu-help")
    assert html =~ "lu-help ok"
    assert html =~ ~s(data-icon="check-circle")
    assert html =~ ~s(data-icon="warn-circle")
  end

  test "field wraps the control in a label with caption and help" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field label="Pais" label_hint="opcional" help="Onde mora" required><select></select></.field>
      """)

    assert html =~ ~s(<label class="lu-field" data-part="field">)
    assert html =~ ~s(<span class="lu-label">)
    assert html =~ ~s(<span class="req">*</span>)
    assert html =~ ~s(<span class="hint">opcional</span>)
    assert html =~ ~r/<span data-part="help" class="lu-help">\s*Onde mora\s*<\/span>/
  end

  test "field as div, inline layout and states" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field as="div" layout="inline" label="Cidade"><input /></.field>
      """)

    assert html =~ ~s(<div class="lu-field inline" data-part="field">)

    html =
      rendered_to_string(~H"""
      <.field label="Cidade" layout="inline" help="Dica" state="success"><input /></.field>
      """)

    # help and control share a column in the inline layout
    assert html =~ ~s(class="lu-col")
    assert html =~ "lu-help ok"
  end

  test "errors replace the help line and field errors only show once used" do
    assigns = %{errors: ["can't be blank", "too short"]}

    html =
      rendered_to_string(~H"""
      <.field label="X" help="Dica" errors={@errors}><input /></.field>
      """)

    assert html =~ "can&#39;t be blank"
    assert html =~ "too short"
    refute html =~ "Dica"

    # not used: no errors
    assigns = %{f: form_field(country: {"is invalid", []})}
    html = rendered_to_string(~H|<.field field={@f} label="X"><input /></.field>|)
    refute html =~ "is invalid"

    # used (an `_unused_` marker absent => used)
    form =
      to_form(%{"country" => "x"},
        as: :user,
        errors: [country: {"is invalid", []}],
        action: :validate
      )

    assigns = %{f: form[:country]}
    html = rendered_to_string(~H|<.field field={@f} label="X"><input /></.field>|)
    assert html =~ "is invalid"
  end

  test "aside goes in a help row and below sits between control and help" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.field label="X" help="Dica">
        <input />
        <:below><i class="bars"></i></:below>
        <:aside><span class="lu-cnt">3 / 10</span></:aside>
        <:label_aside><a>Esqueci</a></:label_aside>
      </.field>
      """)

    assert html =~ ~s(class="lu-helprow")
    assert html =~ "3 / 10"
    assert html =~ "Esqueci"
    assert html =~ ~s(margin-left:auto)
    {below, _} = :binary.match(html, "bars")
    {help, _} = :binary.match(html, "Dica")
    assert below < help
  end

  test "error messages interpolate their options" do
    assert LedgerUI.Components.Form.lu_translate_error({"at least %{count}", count: 3}) ==
             "at least 3"
  end
end
