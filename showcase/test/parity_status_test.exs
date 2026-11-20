defmodule LedgerShowcase.ParityStatusTest do
  @moduledoc """
  Regenerates `design/PARITY_STATUS.md` (excluded by default):

      cd showcase && mix test --only parity_status

  Runs the whole parity comparison itself (no dependency on the order of the other tests).
  """
  use ExUnit.Case, async: false

  alias LedgerShowcase.{Examples, Parity, ParityReport}

  @moduletag :parity_status

  test "writes design/PARITY_STATUS.md" do
    exc = ParityReport.exceptions()

    for id <- Examples.ids(), %{index: i} <- Examples.sections(id), !exc[{id, i}] do
      Parity.compare(id, i)
    end

    path = Path.expand("../../design/PARITY_STATUS.md", __DIR__)
    File.write!(path, ParityReport.markdown())
  end
end
