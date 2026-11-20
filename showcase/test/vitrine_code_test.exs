defmodule LedgerShowcase.VitrineCodeTest do
  @moduledoc """
  The HEEx `code` of every vitrine section is the reference usage of the API: each snippet must
  compile against the library (`LedgerShowcase.VitrineCode`). The ones that do not yet are listed
  in `LedgerShowcase.VitrineCodeKnown` with the reason; they are reported, not hidden, and the test fails
  if a listed snippet starts to compile.

      mix test test/vitrine_code_test.exs
  """
  use ExUnit.Case, async: true

  alias LedgerShowcase.VitrineCode

  @known LedgerShowcase.VitrineCodeKnown.known()

  for {id, n, code} <- VitrineCode.snippets() do
    @tag vitrine_code: id
    test "#{id}/#{n} compiles" do
      result = VitrineCode.check(unquote(code), "#{unquote(id)}/#{unquote(n)}")
      known = Map.get(@known, {unquote(id), unquote(n)})

      case {result, known} do
        {:ok, nil} ->
          :ok

        {:ok, reason} ->
          flunk(
            "compiles now: remove {#{inspect(unquote(id))}, #{unquote(n)}} (#{reason}) from test/support/vitrine_code_known.ex"
          )

        {{:error, msgs}, nil} ->
          flunk("does not compile against the library:\n" <> Enum.join(msgs, "\n"))

        {{:error, _}, _reason} ->
          :ok
      end
    end
  end
end
