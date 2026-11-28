defmodule LedgerUI.Components.ColorPickerOnChangeTest do
  # #119 (item 1), color_picker: `on_change` is an event name or a `%JS{}` (it is serialized, never printed as a struct).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI
  alias Phoenix.LiveView.JS
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  test "an event name goes as it is" do
    assigns = %{}
    html = rendered_to_string(~H|<.color_picker id="c" name="c" on_change="pick" />|)
    assert html =~ ~s(data-lu-on-change="pick")
  end

  test "a %JS{} goes as the JSON of its commands" do
    assigns = %{js: JS.push("pick", value: %{a: 1})}
    html = rendered_to_string(~H|<.color_picker id="c" name="c" on_change={@js} />|)
    assert html =~ ~s(data-lu-on-change="[[&quot;push&quot;,)
    assert html =~ "pick"
    refute html =~ "%Phoenix.LiveView.JS"
  end

  test "no on_change, no attribute" do
    assigns = %{}
    refute rendered_to_string(~H|<.color_picker id="c" name="c" />|) =~ "data-lu-on-change"
  end

  test "anything else is an ArgumentError that says what is accepted" do
    assigns = %{}

    assert_raise ArgumentError, ~r/event name or a %Phoenix.LiveView.JS\{\}/, fn ->
      rendered_to_string(~H|<.color_picker id="c" name="c" on_change={42} />|)
    end
  end
end
