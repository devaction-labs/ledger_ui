defmodule LedgerShowcase.ExamplesTest do
  @moduledoc """
  One group of tests per `examples/<id>/NN.heex`. Visual fidelity against the canvas is checked
  by `scripts/visual/run.sh` (MIGRATION.md, "Exemplos da vitrine").

  Per example:

    * renders (non-empty HTML)
    * no `lu-*` class token in a `class` attribute (the package has no component stylesheet).
    * a11y/structure (`ExampleChecks.a11y/1`): ids unique, `aria-*` references resolve, `role=tab` has
      `aria-selected`, buttons/links/images are named.
    * calling a `<.component>` renders `data-part` (every component element carries one)

      mix test test/examples_test.exs --only component:button
  """
  use ExUnit.Case, async: true

  alias LedgerShowcase.{ExampleChecks, Examples}

  for id <- Examples.ids(), %{index: index, title: title} <- Examples.sections(id) do
    @tag component: id
    test "#{id} ##{index} (#{title})" do
      id = unquote(id)
      index = unquote(index)
      html = ExampleChecks.render(id, index)
      assert String.trim(html) != "", "renders nothing"

      # no lu-* classes
      found = ExampleChecks.lu_tokens(html)

      assert found == [],
             "lu-* classes in #{id}/#{index}: #{inspect(found)}. Use components/utilities (MIGRATION.md, \"Exemplos da vitrine\")."

      # a11y/structure
      problems = ExampleChecks.a11y(html)

      assert problems == [],
             "a11y/structure problems in #{id}/#{index}:\n" <> Enum.join(problems, "\n")

      source = Enum.find(Examples.sections(id), &(&1.index == index)).source

      refute ExampleChecks.data_part_missing?(source, html),
             "components rendered without data-part"
    end
  end
end
