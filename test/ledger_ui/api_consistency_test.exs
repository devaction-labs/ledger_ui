defmodule LedgerUI.ApiConsistencyTest do
  # #119 items 2, 3 and 4: required slot attrs, the long tone names, `values:` on enumerations.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import ExUnit.CaptureIO
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp r(rendered), do: rendered |> rendered_to_string() |> String.replace(~r/\s+/, " ")

  describe "slot attrs read with `.` are required" do
    test "bar_list, progress_stack and flow warn at compile time" do
      for {code, attr} <- [
            {~s(<.bar_list><:item label="x" value="1" /></.bar_list>), "amount"},
            {~s(<.progress_stack><:segment /></.progress_stack>), "value"},
            {~s(<.flow id="f"><:node /></.flow>), "id"}
          ] do
        warnings =
          capture_io(:stderr, fn ->
            Code.compile_string("""
            defmodule LedgerUI.ApiConsistencyTest.Slot#{System.unique_integer([:positive])} do
              use Phoenix.Component
              use LedgerUI
              def t(assigns), do: ~H\"\"\"
              #{code}
              \"\"\"
            end
            """)
          end)

        assert warnings =~ ~s(missing required attribute "#{attr}"),
               "#{code}: #{warnings}"
      end
    end
  end

  describe "long tone names are aliases of the short ones" do
    test "aura" do
      assigns = %{}

      for {long, short} <- [{"success", "pos"}, {"error", "neg"}, {"warning", "warn"}] do
        assigns = %{long: long, short: short}
        assert r(~H|<.aura tone={@long}>x</.aura>|) == r(~H|<.aura tone={@short}>x</.aura>|)
      end

      assert r(~H|<.aura tone="accent">x</.aura>|) == r(~H|<.aura>x</.aura>|)
    end

    test "tag (canvas) and chip" do
      assigns = %{}

      assert r(~H|<.tag canvas tone="accent">x</.tag>|) == r(~H|<.tag canvas tone="acc">x</.tag>|)
      assert r(~H|<.chip tone="accent">x</.chip>|) == r(~H|<.chip tone="acc">x</.chip>|)
      assert r(~H|<.chip tone="accent">x</.chip>|) != r(~H|<.chip>x</.chip>|)
    end

    test "timeline_event and step_group_line" do
      for {long, short} <- [
            {"success", "pos"},
            {"error", "neg"},
            {"warning", "warn"},
            {"accent", "acc"}
          ] do
        assigns = %{long: long, short: short}

        assert r(~H|<.timeline_event tone={@long} title="t" />|) ==
                 r(~H|<.timeline_event tone={@short} title="t" />|)
      end

      for {long, short} <- [{"success", "ok"}, {"error", "err"}] do
        assigns = %{long: long, short: short}

        assert r(~H|<.step_group_line n={1} tone={@long}>x</.step_group_line>|) ==
                 r(~H|<.step_group_line n={1} tone={@short}>x</.step_group_line>|)
      end
    end

    test "the helpers" do
      assert LedgerUI.Helpers.tone_short("success") == "pos"
      assert LedgerUI.Helpers.tone_short("dim") == "dim"
      assert LedgerUI.Helpers.tone_map(%{"pos" => 1}) == %{"pos" => 1, "success" => 1}
      assert LedgerUI.Helpers.tone_map(%{"ok" => 1})["success"] == 1
      # a long name that already has its own entry keeps it
      assert LedgerUI.Helpers.tone_map(%{"accent" => 1, "acc" => 2})["accent"] == 1
      assert LedgerUI.Helpers.tone_values(["a", "neg"]) == ["a", "neg", "error"]
    end
  end

  describe "enumerations declare values:" do
    @closed [
      {LedgerUI.Components.Button, :button, :type, ~w(button submit reset)},
      {LedgerUI.Components.Button, :insight_button, :type, ~w(button submit reset)},
      {LedgerUI.Components.Fab, :fab, :type, ~w(button submit reset)},
      {LedgerUI.Components.Tag, :tag, :type, ~w(button submit reset)},
      {LedgerUI.Components.Dropdown, :dropdown_item, :type, ~w(button submit reset)},
      {LedgerUI.Components.AuthSplit, :auth_submit, :type, ~w(button submit reset)}
    ]

    for {mod, fun, attr, values} <- @closed do
      test "#{inspect(mod)}.#{fun} #{attr}" do
        attrs = unquote(mod).__components__()[unquote(fun)].attrs
        assert Enum.find(attrs, &(&1.name == unquote(attr))).opts[:values] == unquote(values)
      end
    end

    test "view_switcher placement follows the dropdown placements" do
      attrs = LedgerUI.Components.ViewSwitcher.__components__()[:view_switcher].attrs

      assert Enum.find(attrs, &(&1.name == :placement)).opts[:values] ==
               LedgerUI.Components.Dropdown.placements()
    end

    test "a wrong type is a compile-time warning" do
      warnings =
        capture_io(:stderr, fn ->
          Code.compile_string("""
          defmodule LedgerUI.ApiConsistencyTest.BadType do
            use Phoenix.Component
            use LedgerUI
            def t(assigns), do: ~H\"\"\"
            <.button type="sumbit">x</.button>
            \"\"\"
          end
          """)
        end)

      assert warnings =~ "attribute \"type\" in component"
    end
  end
end
