defmodule LedgerUI.Components.PillSelectTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.PillSelect

  test "single choice: pressed chip is on and the value travels in a hidden input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pill_select name="canal" value="online" options={["Todos", "Balcão", "online"]} label="Canal" />
      """)

    assert html =~ ~s(phx-hook="LedgerUI.PillSelect")
    assert html =~ ~s(role="group")
    assert html =~ ~r/class="lu-chip on"[^>]*aria-pressed="true"/s
    assert html =~ ~s(<input type="hidden" name="canal" value="online" data-lu-v)
    refute html =~ ~s(name="canal[]")
  end

  test "multiple: acc chips, check icon, count, name[] with an empty first entry" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pill_select
        name="c"
        multiple
        value={["a", "b"]}
        options={[
          %{label: "A", value: "a", count: 4},
          %{label: "B", value: "b"},
          %{label: "C", value: "c", disabled: true}
        ]}
      />
      """)

    assert html =~ "data-lu-multiple"
    assert html =~ ~s(class="lu-chip acc on")
    assert html =~ ~s(<span class="n">4</span>)
    assert html =~ ~s(data-icon="check")
    assert html =~ ~s(<input type="hidden" name="c[]" value="")
    assert html =~ ~s(name="c[]" value="a")
    assert html =~ ~s(name="c[]" value="b")
    assert html =~ ~r/<button[^>]*disabled/
  end

  test "nameless renders only the buttons; field fills name and value" do
    assigns = %{}
    html = rendered_to_string(~H|<.pill_select options={~w(a b)} value="a" />|)
    refute html =~ ~s(type="hidden")

    form = to_form(%{"r" => "30d"}, as: "f")
    assigns = %{form: form}
    html = rendered_to_string(~H|<.pill_select field={@form[:r]} options={~w(7d 30d)} />|)
    assert html =~ ~s(name="f[r]" value="30d")
  end

  test "on_change and target are handed to the hook" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.pill_select id="p" options={~w(a)} on_change="pick" target="#x" />|)

    assert html =~ ~s(data-lu-on-change="pick")
    assert html =~ ~s(data-lu-target="#x")
  end
end
