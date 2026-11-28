defmodule LedgerUI.Components.OptionClassTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Autocomplete
  import LedgerUI.Components.TagsInput

  alias LedgerUI.Components.Select.Options

  # #98: the class of an option moved from each `<button>` to the panel, as descendant selectors. The set
  # of utilities each option ends up with has to be the one it had.
  @sel "[&_[data-part=listbox-option]]:"

  test "the utilities of the panel rule are exactly the ones the option had (same variants, same order)" do
    own = String.split(Options.item_class())
    ruled = Options.option_class() |> String.split()

    assert length(own) == 21
    assert Enum.map(own, &(@sel <> &1)) == ruled
    assert Enum.all?(ruled, &String.starts_with?(&1, @sel))
  end

  defp count(html, re), do: length(Regex.scan(re, html))
  defp opts(n), do: for(i <- 1..n, do: {"Option #{i}", "v#{i}"})

  test "autocomplete: no class on an option, the rule once on the panel" do
    assigns = %{o: opts(100)}
    html = rendered_to_string(~H|<.autocomplete id="ac" options={@o} create="Criar %{query}" />|)

    assert count(html, ~r/data-part="listbox-option"/) == 101
    assert count(html, ~r/<button[^>]*data-part="listbox-option"[^>]*class=/s) == 0
    assert count(html, ~r/<button[^>]*class=[^>]*data-part="listbox-option"/s) == 0
    assert count(html, ~r/\[&amp;_\[data-part=listbox-option\]\]:flex/) == 1
    assert html =~ ~r/data-part="autocomplete-panel"/

    assert html =~
             ~r/class="[^"]*\[&amp;_\[data-part=listbox-option\]\]:flex[^"]*"[^>]*role="listbox"/s
  end

  test "autocomplete with icons, avatars and hints: the same, in the other template" do
    assigns = %{
      o: [
        %{label: "Ana", value: "1", hint: "x", icon: "search"},
        %{label: "B", value: "2", initials: "B"}
      ]
    }

    html = rendered_to_string(~H|<.autocomplete id="ac" options={@o} />|)
    assert count(html, ~r/<button[^>]*data-part="listbox-option"[^>]*class=/s) == 0
    assert count(html, ~r/<button[^>]*class=[^>]*data-part="listbox-option"/s) == 0
    assert count(html, ~r/\[&amp;_\[data-part=listbox-option\]\]:flex/) == 1
  end

  test "tags_input: no class on an option, the rule once on the panel" do
    assigns = %{o: opts(100)}
    html = rendered_to_string(~H|<.tags_input id="ti" name="t" options={@o} />|)

    assert count(html, ~r/data-part="listbox-option"/) == 101
    assert count(html, ~r/<button[^>]*data-part="listbox-option"[^>]*class=/s) == 0
    assert count(html, ~r/<button[^>]*class=[^>]*data-part="listbox-option"/s) == 0
    assert count(html, ~r/\[&amp;_\[data-part=listbox-option\]\]:flex/) == 1
  end

  test "the size of 100 options: autocomplete <= 32 KB and tags_input <= 25 KB (#98)" do
    assigns = %{o: opts(100)}
    ac = rendered_to_string(~H|<.autocomplete id="ac" options={@o} />|)
    ti = rendered_to_string(~H|<.tags_input id="ti" name="t" options={@o} />|)

    assert byte_size(ac) <= 32_000
    assert byte_size(ti) <= 25_000
  end
end
