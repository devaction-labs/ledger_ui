defmodule LedgerUI.Components.OnJsTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Pillbox
  import LedgerUI.Components.PillSelect
  import LedgerUI.Components.Select

  alias Phoenix.LiveView.JS

  # #119 item 1: `on_*` given a `%JS{}` where the hook takes an event name.

  describe "pill_select on_change" do
    test "an event name goes as it is" do
      assigns = %{}
      html = rendered_to_string(~H|<.pill_select id="p" options={~w(a b)} on_change="chosen" />|)
      assert html =~ ~s(data-lu-on-change="chosen")
    end

    test "a %JS{} goes as its JSON, which the hook runs (it starts with `[`)" do
      assigns = %{js: JS.push("x", value: %{a: 1})}
      html = rendered_to_string(~H|<.pill_select id="p" options={~w(a b)} on_change={@js} />|)

      assert [_, json] = Regex.run(~r/data-lu-on-change="([^"]*)"/, html)
      json = String.replace(json, "&quot;", "\"")
      assert String.starts_with?(json, "[")
      assert json == LedgerUI.Helpers.js_json(assigns.js)
    end

    test "no on_change, no attribute" do
      assigns = %{}
      html = rendered_to_string(~H|<.pill_select id="p" options={~w(a b)} />|)
      refute html =~ "data-lu-on-change"
    end

    test "a new on_change reaches the client (settle)" do
      fun = fn assigns ->
        ~H|<.pill_select id="p" options={~w(a b)} on_change={@on_change} />|
      end

      LedgerUI.DiffCase.each_source(fun, %{on_change: nil}, on_change: "chosen")
      LedgerUI.DiffCase.each_source(fun, %{on_change: "chosen"}, on_change: JS.push("x"))
    end

    test "anything else is an ArgumentError, not a broken attribute" do
      assigns = %{}

      assert_raise ArgumentError, ~r/pill_select: `on_change`/, fn ->
        rendered_to_string(~H|<.pill_select id="p" options={~w(a b)} on_change={%{a: 1}} />|)
      end
    end
  end

  describe "select on_search" do
    test "an event name goes as it is" do
      assigns = %{}
      html = rendered_to_string(~H|<.select id="s" options={~w(a b)} on_search="find" />|)
      assert html =~ ~s(data-lu-on-search="find")
    end

    test "a %JS{} is an ArgumentError that says why" do
      assigns = %{js: JS.push("x")}

      error =
        assert_raise ArgumentError, fn ->
          rendered_to_string(~H|<.select id="s" options={~w(a b)} on_search={@js} />|)
        end

      assert error.message =~ "on_search"
      assert error.message =~ "event name"
    end

    test "the pillbox (same list) raises too" do
      assigns = %{js: JS.push("x")}

      assert_raise ArgumentError, ~r/on_search/, fn ->
        rendered_to_string(~H|<.pillbox id="p" options={~w(a b)} on_search={@js} />|)
      end
    end
  end
end
