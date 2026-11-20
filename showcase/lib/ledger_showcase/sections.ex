defmodule LedgerShowcase.Sections do
  @moduledoc """
  The vitrine sections (`design/vitrine/sec/<id>.json`).

  `NN` of an example = position in `vitrine/1`, then the canvas-only demos
  (`design/canvas/extras.json`). The vitrine dropped the "Referência visual" sections; the
  canvas demos with that title are ignored too (`LedgerShowcase.Canvas`).
  """

  @design Path.expand("../../../design", __DIR__)

  @doc "Sections `[%{\"t\", \"h\", \"code\", ...}]` of `design/vitrine/sec/<id>.json`."
  def vitrine(id) do
    @design
    |> Path.join("vitrine/sec/#{id}.json")
    |> File.read!()
    |> Jason.decode!()
  end
end
