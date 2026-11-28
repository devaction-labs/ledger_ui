defmodule LedgerUI.Components.TagsInputTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.TagsInput

  test "value as list or comma string becomes tags with hidden select name[]" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tags_input name="tags" value="clear,items" removable label="Tags" placeholder="Add" />
      """)

    assert html =~ ~s(phx-hook="LedgerUI.TagsInput")
    assert length(Regex.scan(~r/data-part="tags-input-tag"/, html)) == 2
    assert html =~ ~s(<select name="tags[]" multiple hidden)
    assert html =~ ~s(<option value="" selected></option>)
    assert html =~ ~s(<option value="items" selected>items</option>)
    assert html =~ "data-lu-remove"
    assert html =~ ~r/<label class="[^"]*" data-part="field"/
    assert html =~ ~s(placeholder="Add")
  end

  test "field fills name and value" do
    form = to_form(%{"tags" => ["awesome", "neat"]}, as: "f")
    assigns = %{form: form}
    html = rendered_to_string(~H|<.tags_input field={@form[:tags]} />|)
    assert html =~ ~s(name="f[tags][]")
    assert html =~ "awesome"
    refute html =~ "data-lu-remove"
  end

  test "max disables the input, shows the limit placeholder and the counter" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tags_input name="t" value={["a", "b"]} max={2} limit_placeholder="Full" help="Up to two" />
      """)

    assert html =~ ~s(placeholder="Full")
    assert html =~ "disabled"
    assert html =~ ~r/data-lu-counter[^>]*>\s*2 \/ 2/
    assert html =~ ~s(data-lu-max="2")
    assert html =~ "Up to two"

    html =
      rendered_to_string(~H|<.tags_input name="t" value={["a", "b"]} max={2} counter={false} />|)

    refute html =~ "data-lu-counter"
  end

  test "suggestions render a list; options with labels name the chips" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tags_input
        name="t"
        value={["2"]}
        options={[%{label: "Priority", value: "1", hint: "12 uses"}, %{label: "Bug", value: "2"}]}
        create={false}
        on_search="search_tags"
        target="#x"
        create_position="bottom"
        persist={false}
        restore_on_backspace
        clearable
        create_hint="Enter"
      />
      """)

    assert html =~ ~s(data-part="tags-input-panel")
    assert html =~ ~s(data-lu-create="false")
    assert html =~ ~s(data-lu-create-position="bottom")
    assert html =~ ~s(data-lu-on-search="search_tags")
    assert html =~ ~s(data-lu-persist="false")
    assert html =~ "data-lu-restore"
    assert html =~ ~s(<option value="2" selected>Bug</option>)
    assert html =~ "12 uses"
    assert html =~ "data-lu-clear"
  end

  test "selected_options label chosen values missing from options" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tags_input
        name="t"
        value={["9"]}
        options={[]}
        selected_options={[%{label: "Nine", value: "9"}]}
      />
      """)

    assert html =~ "Nine"
    assert html =~ ~s(data-lu-value="9")
  end

  test "disabled draws tags without remove buttons" do
    assigns = %{}
    html = rendered_to_string(~H|<.tags_input name="t" value={["a"]} removable disabled />|)
    refute html =~ "data-lu-remove"
    assert html =~ "data-lu-disabled"
  end

  test "tags are concentric to the field and follow its shape" do
    assigns = %{}
    html = rendered_to_string(~H|<.tags_input name="t" value={["a"]} />|)
    assert html =~ "rounded-sm"
    refute html =~ ~r/data-lu-cls="[^"]*rounded-full/

    pill = rendered_to_string(~H|<.tags_input name="t" value={["a"]} shape="pill" />|)
    assert pill =~ ~r/data-lu-cls="[^"]*rounded-full/
    refute pill =~ "rounded-sm"
  end
end
