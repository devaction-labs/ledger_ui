defmodule LedgerShowcase.ParityTest do
  @moduledoc """
  One test per `examples/<id>/NN.heex`, tagged `component: id`:

      mix test test/parity_test.exs --only component:button
  """
  use ExUnit.Case, async: true

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
