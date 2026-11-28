defmodule LedgerUI.Components.ListboxAriaTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  import LedgerUI.Components.Autocomplete
  import LedgerUI.Components.Pillbox
  import LedgerUI.Components.Select
  import LedgerUI.Components.TagsInput

  defp ids(html), do: Regex.scan(~r/ id="([^"]+)"/, html) |> Enum.map(&List.last/1)

  defp opt_ids(html),
    do:
      Regex.scan(~r/id="([^"]+)"[^>]*data-part="listbox-option"/, html) |> Enum.map(&List.last/1)

  @options [{"Bahia", "BA"}, {"Ceará", "CE"}, {"Goiás", "GO"}]

  test "select: the rows are options with a stable id, the list is a listbox" do
    assigns = %{o: @options}
    html = rendered_to_string(~H|<.select id="sel" name="s" label="Estado" options={@o} />|)

    refute html =~ ~s(role="menuitem")
    assert length(Regex.scan(~r/role="option"/, html)) == 3
    assert [_, _, _] = opt_ids(html)
    assert opt_ids(html) == Enum.uniq(opt_ids(html))
    assert Enum.all?(opt_ids(html), &String.starts_with?(&1, "sel-pop-o"))
    assert html =~ ~s(id="sel-pop-list")
    assert html =~ ~r/id="sel-pop-list"\s+role="listbox"/

    # The same ids on another render, and for the same options in another order.
    again = rendered_to_string(~H|<.select id="sel" name="s" label="Estado" options={@o} />|)
    assert opt_ids(again) == opt_ids(html)

    assigns = %{o: Enum.reverse(@options)}
    rev = rendered_to_string(~H|<.select id="sel" name="s" label="Estado" options={@o} />|)
    assert Enum.sort(opt_ids(rev)) == Enum.sort(opt_ids(html))
  end

  test "select: the search box is a combobox that controls the listbox" do
    assigns = %{o: @options}
    html = rendered_to_string(~H|<.select id="sel" options={@o} />|)
    [input] = Regex.run(~r/<input[^>]*data-part="select-search"[^>]*>/s, html)

    assert input =~ ~s(role="combobox")
    assert input =~ ~s(aria-controls="sel-pop-list")
    assert input =~ ~s(aria-expanded="false")
    assert input =~ ~s(aria-autocomplete="list")
    refute input =~ "aria-activedescendant"
    assert html =~ ~s(id="sel-pop-list")

    panel = rendered_to_string(~H|<.select id="sel" options={@o} multiple />|)
    [pinput] = Regex.run(~r/<input[^>]*data-part="select-search"[^>]*>/s, panel)
    assert pinput =~ ~s(role="combobox")
    assert pinput =~ ~s(aria-controls="sel-pop-list")
    assert panel =~ ~s(aria-multiselectable="true")

    open = rendered_to_string(~H|<.select id="sel" options={@o} open />|)
    assert open =~ ~r/<input[^>]*data-part="select-search"[^>]*aria-expanded="true"/s
  end

  test "select: the row of an option that is chosen keeps aria-selected" do
    assigns = %{o: @options}
    html = rendered_to_string(~H|<.select id="sel" options={@o} value="CE" />|)
    assert html =~ ~r/role="option"[^>]*data-lu-value="CE"[^>]*aria-selected="true"/s
  end

  test "select: a create row is an option owned by the listbox" do
    assigns = %{o: @options}
    html = rendered_to_string(~H|<.select id="sel" options={@o} create />|)

    assert html =~ ~s(aria-owns="sel-pop-create")
    assert html =~ ~r/role="option"\s+id="sel-pop-create"/
  end

  test "select: options with a group and a slot have role option and an id" do
    assigns = %{o: [{"Sul", [{"Paraná", "PR"}]}, %{label: "Ana", value: "1", hint: "x"}]}
    html = rendered_to_string(~H|<.select id="sel" options={@o} />|)

    refute html =~ ~s(role="menuitem")
    assert length(opt_ids(html)) == 2
  end

  test "pillbox: the same options and combobox" do
    assigns = %{o: @options}
    html = rendered_to_string(~H|<.pillbox id="pb" options={@o} value={["BA"]} />|)

    refute html =~ ~s(role="menuitem")
    assert length(opt_ids(html)) == 3
    assert Enum.all?(opt_ids(html), &String.starts_with?(&1, "pb-pop-o"))
    assert html =~ ~s(aria-controls="pb-pop-list")
    assert html =~ ~s(aria-multiselectable="true")
  end

  test "tags_input: the field is a combobox over a listbox of options" do
    assigns = %{o: @options}
    html = rendered_to_string(~H|<.tags_input id="ti" name="t" options={@o} />|)

    refute html =~ ~s(role="menuitem")
    assert length(Regex.scan(~r/role="option"/, html)) == 4
    assert [_, _, _] = opt_ids(html) |> Enum.reject(&String.ends_with?(&1, "-create"))
    assert html =~ ~r/<input[^>]*data-part="tags-input-control"[^>]*role="combobox"/s
    assert html =~ ~s(aria-controls="ti-pop")
    assert html =~ ~r/id="ti-pop"[^>]*role="listbox"/s
    assert html =~ ~s(id="ti-pop-create")
  end

  test "tags_input without suggestions stays a plain input" do
    assigns = %{}
    html = rendered_to_string(~H|<.tags_input id="ti" name="t" />|)
    refute html =~ ~s(role="combobox")
    refute html =~ "aria-controls"
  end

  test "the ids of the rows are valid ids (no spaces) whatever the value" do
    assigns = %{o: ["a b", "ç/ã", "x\"y"]}
    html = rendered_to_string(~H|<.select id="sel" options={@o} />|)
    assert Enum.all?(opt_ids(html), &(&1 =~ ~r/^[A-Za-z0-9-]+$/))
    assert length(ids(html)) == length(Enum.uniq(ids(html)))
  end

  test "autocomplete: the field is named by the label and every row has an id" do
    assigns = %{o: @options}

    html =
      rendered_to_string(
        ~H|<.autocomplete id="ac" label="Cliente" options={@o} create="Criar %{query}" />|
      )

    assert html =~ ~r/<input[^>]*role="combobox"[^>]*aria-labelledby="ac-label"/s
    assert html =~ ~s(id="ac-label")

    assert opt_ids(html) == Enum.uniq(opt_ids(html))

    assert length(opt_ids(html)) == 4

    assert Enum.all?(
             opt_ids(html),
             &(String.starts_with?(&1, "ac-list-o") or &1 == "ac-list-create")
           )

    assert html =~ ~r/role="option"\s+id="ac-list-create"/
  end

  test "autocomplete without a label has no aria-labelledby; rich rows have ids too" do
    assigns = %{o: [%{label: "Ana", value: "1", hint: "x", icon: "search"}, {"Bia", "2"}]}
    html = rendered_to_string(~H|<.autocomplete id="ac" options={@o} />|)

    refute html =~ "aria-labelledby"
    assert length(opt_ids(html)) == 2
  end
end
