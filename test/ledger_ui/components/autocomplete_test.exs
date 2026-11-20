defmodule LedgerUI.Components.AutocompleteTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Autocomplete
  alias Phoenix.LiveView.JS

  defp ff(params), do: to_form(params, as: "f")

  test "shows the chosen label and submits the value through a hidden input" do
    assigns = %{f: ff(%{"city" => "ssa"})}

    html =
      rendered_to_string(~H"""
      <.autocomplete field={@f[:city]} options={[{"Salvador", "ssa"}, {"Santos", "snt"}]} label="City" />
      """)

    assert html =~ ~s(phx-hook="LedgerUI.Autocomplete")
    assert html =~ ~s(value="Salvador")
    assert html =~ ~s(<input type="hidden" name="f[city]" value="ssa")
    assert html =~ ~r/data-part="listbox-option"[^>]*aria-selected="true"/
    assert html =~ ~s(role="listbox")
    assert html =~ "City"
  end

  test "display_value stands in for a value that is not among the options" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.autocomplete name="c" value="9" display_value="Acme" options={[]} />|
      )

    assert html =~ ~s(value="Acme")
  end

  test "free_text uses the typed text as value" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.autocomplete name="city" value="Lisbon" options={~w(a)} free_text />|
      )

    assert html =~ ~s(data-lu-free)
    assert html =~ ~s(name="city" value="Lisbon")
  end

  test "server search, create row and events" do
    assigns = %{js: JS.push("created")}

    html =
      rendered_to_string(~H"""
      <.autocomplete
        name="c"
        options={[]}
        on_search="find"
        debounce={150}
        search_threshold={2}
        create="Add “%{query}”"
        on_create="new_customer"
        target="#box"
        clearable
        open_on_focus
      />
      """)

    assert html =~ ~s(data-lu-on-search="find")
    assert html =~ ~s(data-lu-debounce="150")
    assert html =~ ~s(data-lu-threshold="2")
    assert html =~ ~s(data-lu-create=)
    assert html =~ ~s(data-lu-on-create="new_customer")
    assert html =~ "data-lu-open-on-focus"
    assert html =~ "data-lu-clear"
    assert html =~ ~s(role="status")

    html =
      rendered_to_string(~H|<.autocomplete name="c" options={[]} create="x" on_create={@js} />|)

    assert html =~ ~s(data-lu-on-create="[[&quot;push&quot;)
  end

  test "hint, icon, initials and disabled options" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.autocomplete
        name="c"
        size="lg"
        options={[
          %{label: "Ana Souza", value: "1", hint: "ana@x", initials: "AS"},
          %{label: "Off", value: "2", disabled: true, icon: "building"}
        ]}
      />
      """)

    assert html =~ ~r/data-part="listbox-option-right"[^>]*>\s*ana@x\s*<\/span>/
    assert html =~ ~s(data-part="person-avatar")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "h-11"
  end

  test "an option's :tone picks the avatar color" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.autocomplete
        id="ac-tone"
        name="c"
        options={[%{label: "Ana Souza", value: "1", initials: "AS", tone: "t3"}]}
      />
      """)

    assert html =~ "bg-[#e3e6fb]"
  end
end
