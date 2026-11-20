defmodule LedgerShowcase.ExamplesTest do
  @moduledoc """
  One group of tests per `examples/<id>/NN.heex` (this replaces the old markup-parity test, which compared the
  example with the canvas markup INCLUDING `lu-*` classes; that comparison is still available with
  `mix test --only markup_parity`, see `test/parity_test.exs`). Visual fidelity against the canvas is checked
  by `scripts/visual/run.sh` (MIGRATION.md, "Exemplos da vitrine").

  Per example:

    * renders (non-empty HTML)
    * no `lu-*` class token in a `class` attribute. Allowlist: `test/lu_allowlist.exs`
      (`%{{id, index} => ~w(tokens)}`). Entries are PENDING rewrites, never new code: a token missing from the
      list fails, and so does a listed token that is gone ("remove it from the list"), so the list only shrinks.
    * a11y/structure (`ExampleChecks.a11y/1`): ids unique, `aria-*` references resolve, `role=tab` has
      `aria-selected`, buttons/links/images are named. Known problems: `test/a11y_known.exs`
      (same ratchet).
    * calling a `<.component>` renders `data-part` (every component element carries one)

      mix test test/examples_test.exs --only component:button
  """
  use ExUnit.Case, async: true

  alias LedgerShowcase.{ExampleChecks, Examples}

  @allow "lu_allowlist.exs" |> Path.expand(__DIR__) |> Code.eval_file() |> elem(0)
  @a11y_known "a11y_known.exs" |> Path.expand(__DIR__) |> Code.eval_file() |> elem(0)

  for id <- Examples.ids(), %{index: index, title: title} <- Examples.sections(id) do
    @tag component: id
    test "#{id} ##{index} (#{title})" do
      id = unquote(id)
      index = unquote(index)
      html = ExampleChecks.render(id, index)
      assert String.trim(html) != "", "renders nothing"

      # no lu-* classes
      allowed = Map.get(@allow, {id, index}, [])
      found = ExampleChecks.lu_tokens(html)

      assert found -- allowed == [],
             "lu-* classes in #{id}/#{index}: #{inspect(found -- allowed)}. Use components/utilities (MIGRATION.md, \"Exemplos da vitrine\"); do not add them to test/lu_allowlist.exs."

      assert allowed -- found == [],
             "#{id}/#{index}: #{inspect(allowed -- found)} no longer used: remove from test/lu_allowlist.exs"

      # a11y/structure
      problems = ExampleChecks.a11y(html)
      known = Map.get(@a11y_known, {id, index}, [])

      assert problems -- known == [],
             "a11y/structure problems in #{id}/#{index}:\n" <> Enum.join(problems -- known, "\n")

      assert known -- problems == [],
             "#{id}/#{index}: #{inspect(known -- problems)} fixed: remove from test/a11y_known.exs"

      source = Enum.find(Examples.sections(id), &(&1.index == index)).source

      refute ExampleChecks.data_part_missing?(source, html),
             "components rendered without data-part"
    end
  end
end
