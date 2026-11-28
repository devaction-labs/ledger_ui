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

      assert html =~ "h-9"
      assert html =~ "bg-sunken"
      assert html =~ "rounded-full"
      assert html =~ ~s(name="f[plan]")
      assert html =~ ~s(id="f_plan")
      assert html =~ ~s(<option value="">)
      assert html =~ ~s(<optgroup label="Teams">)
      assert html =~ ~r/<option value="Pro" selected/
      assert html =~ "inline-flex"
      assert html =~ ~s(data-part="label")
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
      assert html =~ ~r/data-part="listbox-option" data-lu-value="Pro" aria-selected="true"/
      assert html =~ ~s(<option value="Pro" selected>Pro</option>)
      assert html =~ ~s(name="f[plan]")
      assert html =~ ~s(data-part="select-panel")
      assert html =~ ~r/<div[^>]*data-part="select-panel"[^>]*hidden/
    end

    test "the row class is on the panel once, not on every option; the label is the row's text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select id="s" options={["Pro", "Scale", {"Group", ["Deep"]}]} create />
        """)

      [panel] = Regex.run(~r/<div[^>]*data-part="select-panel"[^>]*>/, html)
      assert panel =~ "[&amp;_[data-part=listbox-option]]:h-[34px]"
      assert panel =~ "[&amp;_[data-part=listbox-option]]:aria-selected:font-medium"
      rows = Regex.scan(~r/<button[^>]*data-part="listbox-option"[^>]*>/, html)
      assert length(rows) == 4

      assert Enum.all?(rows, fn [r] ->
               r =~ ~r/^<button type="button"[^>]* data-part="listbox-option"/ and
                 not (r =~ "class=")
             end)

      refute html =~ "data-lu-label"
      assert html =~ ~r/data-lu-value="Pro"[^>]*>\s*Pro\s*</
      # the classes the hook gives the rows it makes are the panel's too: no `item` in the JSON
      refute html =~ "&quot;item&quot;"
    end

    test "a row with an :option slot keeps data-lu-label (its text is more than the label)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select id="s" options={[%{label: "Ana", value: "ana", description: "Dev"}]}>
          <:option :let={o}>{o.label} - {o.description}</:option>
        </.select>
        """)

      assert html =~ ~s(data-lu-label="Ana")
    end

    test "the root carries the chosen options (value and label) for the hook to compare between patches" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select id="s" name="s" multiple value={["a", "z"]} options={[{"Alpha", "a"}]} />
        <.select id="t" value={nil} options={~w(a)} />
        """)

      assert html =~
               ~s(data-lu-value="[{&quot;label&quot;:&quot;Alpha&quot;,&quot;value&quot;:&quot;a&quot;},{&quot;label&quot;:&quot;z&quot;,&quot;value&quot;:&quot;z&quot;}]")

      assert html =~ ~s(data-lu-value="[]")
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
      assert length(Regex.scan(~r/data-part="select-chip"/, html)) == 2
      assert html =~ ~s(data-lu-remove="a")
      assert html =~ "data-lu-clear"
      assert html =~ ~s(data-lu-overflow="wrap")
      assert html =~ ~s(data-lu-max="3")
      assert html =~ "min-h-10"
      assert html =~ "flex-wrap"
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

    test "cache={false} writes the opt-out only with on_search" do
      assigns = %{}

      on = rendered_to_string(~H|<.select name="s" options={~w(a)} on_search="q" />|)
      refute on =~ "data-lu-cache"

      off =
        rendered_to_string(~H|<.select name="s" options={~w(a)} on_search="q" cache={false} />|)

      assert off =~ ~s(data-lu-cache="false")

      pill =
        rendered_to_string(
          ~H|<LedgerUI.Components.Pillbox.pillbox name="s" options={~w(a)} on_search="q" cache={false} />|
        )

      assert pill =~ ~s(data-lu-cache="false")
    end

    test "search auto is the control for a single select and the panel when multiple" do
      assigns = %{}

      single = rendered_to_string(~H|<.select name="s" options={~w(a b)} />|)
      multi = rendered_to_string(~H|<.select name="s" options={~w(a b)} multiple />|)

      refute single =~ "data-lu-search"
      refute single =~ "select-panel-search"
      assert single =~ ~s(data-part="select-search")

      assert multi =~ ~s(data-lu-search="panel")
      assert multi =~ ~s(data-part="select-panel-search")
    end

    test "explicit search values are kept" do
      assigns = %{}

      ctl = rendered_to_string(~H|<.select name="s" options={~w(a)} multiple search="control" />|)
      pan = rendered_to_string(~H|<.select name="s" options={~w(a)} search="panel" />|)
      none = rendered_to_string(~H|<.select name="s" options={~w(a)} multiple search="none" />|)

      refute ctl =~ "data-lu-search"
      refute ctl =~ "select-panel-search"
      assert ctl =~ ~s(data-part="select-search")
      assert pan =~ ~s(data-lu-search="panel")
      assert none =~ ~s(data-lu-search="none")
      refute none =~ ~s(data-part="select-search")
    end

    test "count has the height of an input and wrap grows" do
      for {size, h} <- [{"sm", "h-9"}, {"md", "h-10"}, {"lg", "h-11"}] do
        assigns = %{size: size}

        count =
          rendered_to_string(
            ~H|<.select name="s" options={~w(a)} multiple size={@size} value={["a"]} />|
          )

        assert count =~ h <> " py-0"
        refute count =~ "min-h-"
      end

      assigns = %{}

      wrap =
        rendered_to_string(
          ~H|<.select name="s" options={~w(a)} multiple overflow="wrap" value={["a"]} />|
        )

      assert wrap =~ "min-h-10 py-[5px]"
    end

    test "the root keeps the default width and accepts w-full" do
      assigns = %{}

      assert rendered_to_string(~H|<.select name="s" options={~w(a)} multiple />|) =~ "w-[260px]"

      assert rendered_to_string(~H|<.select name="s" options={~w(a)} multiple class="w-full" />|) =~
               "w-[260px] w-full"
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
      assert html =~ ~r/data-part="listbox-group"[^>]*role="presentation">\s*Grp/
    end

    test "a stable id is derived when none is given" do
      assigns = %{}
      a = rendered_to_string(~H|<.select options={~w(a)} label="One" />|)
      b = rendered_to_string(~H|<.select options={~w(a)} label="One" />|)
      assert a == b
    end
  end

  test "person avatar photo is taken out of grid flow (#1)" do
    assigns = %{}
    html = rendered_to_string(~H|<Options.avatar src="/p.jpg" />|)
    assert html =~ ~r/class="[^"]*\brelative\b/
    assert html =~ ~r/<img[^>]*class="[^"]*\babsolute inset-0\b/
  end

  test "multiple chips are concentric to the field and follow its shape and size" do
    assigns = %{}
    html = rendered_to_string(~H|<.select name="m" options={~w(a b)} multiple value={["a"]} />|)
    assert html =~ "rounded-sm"

    lg =
      rendered_to_string(
        ~H|<.select name="m" options={~w(a b)} multiple size="lg" value={["a"]} />|
      )

    assert lg =~ "rounded-[9px]"

    pill =
      rendered_to_string(
        ~H|<.select name="m" options={~w(a b)} multiple shape="pill" value={["a"]} />|
      )

    assert pill =~ "rounded-full"
    refute pill =~ "rounded-sm"
  end
end
