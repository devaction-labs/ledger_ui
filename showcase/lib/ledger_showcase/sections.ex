defmodule LedgerShowcase.Sections do
  @moduledoc """
  The vitrine sections (`design/vitrine/sec/<id>.json`) that still exist.

  A vitrine section is *retired* when the design canvas redesigned its component and no longer
  has a demo with that title (`design/canvas/retired.json`, `%{id => [title]}`). Retired sections
  are dropped from the showcase (page, examples, parity) and the remaining sections are numbered
  from 1: `NN` = position in `vitrine/1`, then the canvas-only demos (`design/canvas/extras.json`).

  Rule: when a component's board section exists in the canvas and a vitrine section title has no
  matching canvas demo, the section is retired, unless it is still needed.
  """

  @design Path.expand("../../../design", __DIR__)
  @retired_path Path.join(@design, "canvas/retired.json")
  @external_resource @retired_path
  @retired @retired_path |> File.read!() |> Jason.decode!()

  @doc "Retired section titles by component id."
  def retired, do: @retired

  @doc "Sections `[%{\"t\", \"h\", ...}]` of `design/vitrine/sec/<id>.json` without the retired ones."
  def vitrine(id) do
    drop = Map.get(@retired, id, [])

    @design
    |> Path.join("vitrine/sec/#{id}.json")
    |> File.read!()
    |> Jason.decode!()
    |> Enum.reject(&(&1["t"] in drop))
  end
end
