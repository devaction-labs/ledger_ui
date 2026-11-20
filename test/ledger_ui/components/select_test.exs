defmodule LedgerUI.Components.SelectTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Select

  alias LedgerUI.Components.Select.Options

  defp ff(params \\ %{"plan" => "Pro"}, opts \\ []),
    do: to_form(params, [as: "f"] ++ opts)

  describe "Options" do
    test "normalizes strings, tuples, maps and groups" do
      assert [
               %{label: "Pro", value: "Pro"},
               %{label: "Alabama", value: "AL"},
               %{label: "Ana", value: "1", hint: "ana@x", data: %{job: "dev"}},
               %{group: "G", options: [%{label: "x", value: "y", count: 3}]}
             ] =
               Options.normalize([
                 "Pro",
                 {"Alabama", "AL"},
                 %{label: "Ana", value: 1, hint: "ana@x", job: "dev"},
                 {"G", [{"x", "y", 3}]}
               ])
    end

    test "values/1 and translate_error/1" do
      assert Options.values(nil) == []
      assert Options.values(["a", 1]) == ["a", "1"]
      assert Options.values("a") == ["a"]

      assert Options.translate_error({"must be at least %{count}", count: 3}) ==
               "must be at least 3"
    end
  end

  describe "native" do
    test "renders the styled select with prompt, groups and selection" do
      assigns = %{f: ff()}

      html =
        rendered_to_string(~H"""
        <.select
          native
          field={@f[:plan]}
          label="Plan"
          prompt="Any"
          options={["Pro", {"Teams", ["Scale", "Starter"]}]}
          size="sm"
          variant="filled"
          shape="pill"
          inline
        />
        """)

      assert html =~ ~s(class="lu-input filled sm pill")
      assert html =~ ~s(name="f[plan]")
      assert html =~ ~s(id="f_plan")
      assert html =~ ~s(<option value="">)
      assert html =~ ~s(<optgroup label="Teams">)
      assert html =~ ~r/<option value="Pro" selected/
      assert html =~ "width:auto"
      assert html =~ ~s(class="lu-label")
    end

    test "multiple native appends [] to the name" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.select native multiple name="x" options={~w(a b)} value={["a"]} />|
        )

      assert html =~ ~s(name="x[]")
      assert html =~ "multiple"
    end

    test "shows field errors only after the input was used" do
      assigns = %{f: ff(%{"plan" => "x"}, errors: [plan: {"is invalid", []}])}
      html = rendered_to_string(~H|<.select native field={@f[:plan]} options={~w(a)} />|)
      assert html =~ "is invalid"
    end
  end

  describe "listbox" do
    test "renders control, list, selected row and hidden select" do
      assigns = %{f: ff()}

      html =
        rendered_to_string(~H"""
        <.select field={@f[:plan]} options={["Pro", "Scale"]} placeholder="Choose" />
        """)

      assert html =~ ~s(phx-hook="LedgerUI.Select")
      assert html =~ ~s(role="combobox")
      assert html =~ ~s(class="lu-menu-item sel")
      assert html =~ ~s(<option value="Pro" selected>Pro</option>)
      assert html =~ ~s(name="f[plan]")
      assert html =~ ~s(data-part="panel")
      assert html =~ ~r/<div[^>]*class="lu-pop menu"[^>]*hidden/
    end

    test "multiple renders chips, name[] and a leading empty option" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select
          name="m"
          options={~w(a b c)}
          value={["a", "b"]}
          multiple
          removable
          clearable
          overflow="wrap"
          max={3}
        />
        """)

      assert html =~ ~s(name="m[]")
      assert html =~ ~s(<option value="" selected></option>)
      assert length(Regex.scan(~r/class="lu-chip"/, html)) == 2
      assert html =~ ~s(data-lu-remove="a")
      assert html =~ "data-lu-clear"
      assert html =~ ~s(data-lu-overflow="wrap")
      assert html =~ ~s(data-lu-max="3")
      assert html =~ ~s(class="lu-pbox")
    end

    test "search modes and server events reach the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select
          name="s"
          options={~w(a)}
          search="panel"
          search_placeholder="Find"
          on_search="q"
          debounce={100}
          on_load_more="more"
          has_more
        />
        """)

      assert html =~ ~s(data-lu-search="panel")
      assert html =~ ~s(placeholder="Find")
      assert html =~ ~s(data-lu-on-search="q")
      assert html =~ ~s(data-lu-debounce="100")
      assert html =~ ~s(data-lu-on-load-more="more")
      assert html =~ "Loading…"
    end

    test "the option slot draws rows and groups are labelled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select
          name="s"
          options={[
            %{label: "Ana", value: 1, job: "dev"},
            {"Grp", [%{label: "Bob", value: 2, job: "ops"}]}
          ]}
        >
          <:option :let={o}>{o.label} · {o.data.job}</:option>
        </.select>
        """)

      assert html =~ "Ana · dev"
      assert html =~ ~s(class="lu-menu-label" role="presentation">Grp)
    end

    test "a stable id is derived when none is given" do
      assigns = %{}
      a = rendered_to_string(~H|<.select options={~w(a)} label="One" />|)
      b = rendered_to_string(~H|<.select options={~w(a)} label="One" />|)
      assert a == b
    end
  end
end
