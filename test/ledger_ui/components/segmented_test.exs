defmodule LedgerUI.Components.SegmentedTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Segmented
  alias Phoenix.LiveView.JS

  test "renders a group of buttons with the chosen one on" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.segmented id="range" value="month" options={~w(day month year)} label="Range" size="sm" full />
      """)

    assert html =~ ~s(role="group")
    assert html =~ ~s(phx-hook="LedgerUI.Segmented")
    assert html =~ ~s(class="lu-seg sm block")
    assert html =~ ~r/<button[^>]*class="on"[^>]*aria-pressed="true"[^>]*data-lu-value="month"/s
    assert html =~ ~s(aria-pressed="false")
    # one segment in the tab order
    assert length(Regex.scan(~r/tabindex="0"/, html)) == 1
    refute html =~ ~s(type="hidden")
  end

  test "options with icon, count and disabled; pill shape" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.segmented
        id="v"
        shape="pill"
        value="a"
        options={[
          %{label: "A", value: "a", icon: "building", count: 3},
          %{label: "B", value: "b", disabled: true}
        ]}
      />
      """)

    assert html =~ ~s(<span class="n">3</span>)
    assert html =~ "data-icon="
    assert html =~ "border-radius:999px"
    assert html =~ ~r/<button[^>]*disabled/
  end

  test "submits through a hidden input named like the field" do
    form = to_form(%{"view" => "list"}, as: "f")
    assigns = %{form: form}

    html =
      rendered_to_string(
        ~H|<.segmented field={@form[:view]} options={[{"List", "list"}, {"Kanban", "kanban"}]} />|
      )

    assert html =~ ~s(<input type="hidden" name="f[view]" value="list")
    assert html =~ ~s(id="f_view")
  end

  test "on_change as event or JS command" do
    assigns = %{js: JS.push("x")}

    html =
      rendered_to_string(~H|<.segmented id="a" options={~w(a b)} on_change="set" target="#t" />|)

    assert html =~ ~s(data-lu-on-change="set")
    assert html =~ ~s(data-lu-target="#t")
    html = rendered_to_string(~H|<.segmented id="a" options={~w(a b)} on_change={@js} />|)
    assert html =~ ~s(data-lu-on-change="[[&quot;push&quot;)
  end
end
