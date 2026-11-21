defmodule LedgerShowcase.Sections do
  @moduledoc """
  The vitrine sections (`vitrine/sec/<id>.json` of the design data, see `LedgerShowcase.Design`).

  `NN` of an example = position in `vitrine/1`, then the canvas-only demos
  (`canvas/extras.json`). The vitrine dropped the "Referência visual" sections; the
  canvas demos with that title are ignored. Without the design data every list is empty.
  """

  alias LedgerShowcase.Design

  @doc "Sections `[%{\"t\", \"h\", \"code\", ...}]` of `vitrine/sec/<id>.json` (`[]` without the data)."
  def vitrine(id), do: Design.json("vitrine/sec/#{id}.json", [])
end
