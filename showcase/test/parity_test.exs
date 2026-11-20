defmodule LedgerShowcase.ParityTest do
  @moduledoc """
  LEGACY markup comparison of every `examples/<id>/NN.heex` with the canvas markup (including `lu-*`
  classes). Excluded by default (`:markup_parity`): the examples are being rewritten as real components,
  so this no longer applies; the default checks are `test/examples_test.exs` (no `lu-*`, ARIA/structure) and
  `scripts/visual/` (pixels). Kept because `LedgerShowcase.Parity` is also used by the templates and
  hero/stat canvas tests, and to inspect what an old example looked like:

      mix test test/parity_test.exs --only markup_parity --only component:button
  """
  use ExUnit.Case, async: true

  @moduletag :markup_parity

  alias LedgerShowcase.{Examples, Parity}

  @exceptions "parity_exceptions.exs" |> Path.expand(__DIR__) |> Code.eval_file() |> elem(0)

  for id <- Examples.ids(), %{index: index, title: title} <- Examples.sections(id) do
    @tag component: id
    if reason = @exceptions[{id, index}] do
      @tag skip: reason
    end

    test "#{id} ##{index} (#{title})" do
      case Parity.compare(unquote(id), unquote(index)) do
        :ok -> :ok
        {:error, report} -> flunk(report)
      end
    end
  end
end
