defmodule LedgerUI.Components.FieldIdTest do
  # #118: one rule for the DOM id of a control: `id`, then `field.id`, then the sanitized `name`,
  # then an error (component with a hook) or a deterministic hash (component without one).
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias LedgerUI.Components, as: C
  alias LedgerUI.Helpers

  describe "Helpers.field_id/3" do
    test "id wins over field and name" do
      field = %Phoenix.HTML.FormField{
        id: "f_x",
        name: "f[x]",
        field: :x,
        form: nil,
        errors: [],
        value: nil
      }

      assert Helpers.field_id(%{id: "mine", field: field, name: "n"}, "c") == "mine"
    end

    test "field id wins over name" do
      field = %Phoenix.HTML.FormField{
        id: "f_x",
        name: "f[x]",
        field: :x,
        form: nil,
        errors: [],
        value: nil
      }

      assert Helpers.field_id(%{id: nil, field: field, name: "n"}, "c") == "f_x"
    end

    test "name is sanitized: runs become one dash, no trailing dash" do
      assert Helpers.field_id(%{name: "user[role]"}, "c") == "user-role"
      assert Helpers.field_id(%{name: "user[roles][]"}, "c") == "user-roles"
      assert Helpers.field_id(%{name: "a b.c"}, "c") == "a-b-c"
      assert Helpers.field_id(%{name: "plain_name-1"}, "c") == "plain_name-1"
    end

    test "empty id counts as missing; names list is searched in order" do
      assert Helpers.field_id(%{id: "", name: nil}, "c", names: [nil, "b[c]"]) == "b-c"
    end

    test "nothing to derive from: raises, hashes or nothing" do
      assert_raise ArgumentError, ~r/date-picker needs an id/, fn ->
        Helpers.field_id(%{id: nil, name: nil}, "date-picker")
      end

      a = Helpers.field_id(%{label: "A"}, "box", fallback: :hash)
      b = Helpers.field_id(%{label: "B"}, "box", fallback: :hash)
      assert a =~ ~r/^box-\d+$/
      assert a == Helpers.field_id(%{label: "A"}, "box", fallback: :hash)
      assert a != b
      assert Helpers.field_id(%{label: "A"}, "box", fallback: :none) == nil
    end
  end

  @with_hook [
    date_picker: {C.DatePicker, :date_picker},
    datetime_picker: {C.DatetimePicker, :datetime_picker},
    time_picker: {C.TimePicker, :time_picker},
    number_input: {C.NumberInput, :number_input},
    range: {C.Range, :range},
    rating: {C.Rating, :rating},
    color_picker: {C.ColorPicker, :color_picker},
    signature_pad: {C.SignaturePad, :signature_pad},
    otp_input: {C.OtpInput, :otp_input},
    phone_input: {C.PhoneInput, :phone_input},
    text_editor: {C.TextEditor, :text_editor}
  ]

  for {key, {mod, fun}} <- @with_hook do
    test "#{key}: no id, name or field raises" do
      assert_raise ArgumentError, ~r/needs an id/, fn ->
        render_component(&(unquote(mod).unquote(fun) / 1), %{label: "X", on_change: "go"})
      end
    end

    test "#{key}: name user[role] gives the id user-role" do
      html = render_component(&(unquote(mod).unquote(fun) / 1), %{name: "user[role]"})
      assert html =~ ~s(id="user-role)
      refute html =~ ~s(id="user[role])
    end
  end

  test "image_input and static rating: nothing to derive from means no id at all" do
    refute render_component(&C.ImageInput.image_input/1, %{}) =~ ~s( id=")
    refute render_component(&C.Rating.rating/1, %{value: 3}) =~ ~s( id=")

    html = render_component(&C.ImageInput.image_input/1, %{name: "user[avatar]"})
    assert html =~ ~s(id="user-avatar")
  end

  test "textarea: raises only with a hook; derives from name" do
    assert render_component(&C.Textarea.textarea/1, %{label: "X"}) =~ "<textarea"

    assert_raise ArgumentError, fn ->
      render_component(&C.Textarea.textarea/1, %{autogrow: true})
    end

    assert render_component(&C.Textarea.textarea/1, %{name: "post[body]"}) =~ ~s(id="post-body")
  end

  test "password_input and checkbox_group: two instances with different labels do not collide" do
    a = render_component(&C.PasswordInput.password_input/1, %{label: "Atual"})
    b = render_component(&C.PasswordInput.password_input/1, %{label: "Nova"})
    [ida] = Regex.run(~r/<input id="([^"]+)"/, a, capture: :all_but_first)
    [idb] = Regex.run(~r/<input id="([^"]+)"/, b, capture: :all_but_first)
    assert ida != idb

    html =
      render_component(&C.Checkbox.checkbox_group/1, %{
        name: "user[roles]",
        options: [{"A", "a"}]
      })

    assert html =~ ~s(id="user-roles")
  end

  test "date_picker_clear/1 selector follows the derived id" do
    html = render_component(&C.DatePicker.date_picker/1, %{name: "filter[from]"})
    assert html =~ ~s(id="filter-from")
    refute html =~ "#filter[from]"
  end
end
