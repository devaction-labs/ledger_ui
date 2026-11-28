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
    assert html =~ ~r/class="flex [^"]*bg-tray/
    assert html =~ "h-6 px-[9px]"
    assert html =~ "flex-1 justify-center"
    assert html =~ ~r/<button[^>]*aria-pressed="true"[^>]*data-lu-value="month"/s
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

    assert html =~ ~s(data-part="segmented-count")
    assert html =~ "data-icon="
    assert html =~ "rounded-full"
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

  describe "icons and tabs (#61)" do
    test "icons: square buttons, no text, title and aria-label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.segmented
          id="c"
          icons
          size="sm"
          value="line"
          options={[
            %{value: "bar", icon: "download", title: "Bars", label: "Bars"},
            %{value: "line", icon: "file", title: "Line"}
          ]}
        />
        """)

      assert html =~ "size-6"
      refute html =~ "h-6 px-[9px]"
      assert html =~ ~s(title="Bars")
      assert html =~ ~s(aria-label="Bars")
      assert html =~ ~s(aria-label="Line")
      refute html =~ ~r/>\s*Bars\s*<\/button>/
      assert html =~ ~s(aria-pressed="true")
    end

    test "an empty label with an icon is icon-only; icon_only hides the text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.segmented
          id="c"
          options={[
            %{value: "a", icon: "download", label: "", title: "A"},
            %{value: "b", icon: "file", label: "Beta", icon_only: true},
            %{value: "c", icon: "file", label: "Gamma"}
          ]}
        />
        """)

      refute html =~ "size-7"
      assert html =~ ~s(aria-label="A")
      assert html =~ ~s(aria-label="Beta")
      refute html =~ ~r/>\s*Beta\s*<\/button>/
      assert html =~ ~r/>\s*Gamma\s*<\/button>/
    end

    test "tablist makes the buttons tabs with aria-selected" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.segmented id="c" role="tablist" value="b" options={~w(a b)} />|)

      assert html =~ ~s(role="tab")
      assert html =~ ~s(aria-selected="true")
      assert html =~ ~s(aria-selected="false")
      refute html =~ ~s(aria-pressed=")
    end
  end
end
