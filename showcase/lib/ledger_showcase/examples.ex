defmodule LedgerShowcase.Examples do
  @moduledoc """
  Compiles every `examples/<id>/NN.heex` at compile time.

    * `ids/0` - component ids that have examples
    * `sections(id)` - `[%{index, title, source}]`, title from `design/vitrine/sec/<id>.json`
      followed by the canvas-only sections (`design/canvas/extras.json`, see `CONVENTIONS.md`)
    * `render(id, index, assigns)` - the rendered section (`index` is the 1-based integer of `NN`)

  Each file is plain HEEx using the `<.component>` calls of `use LedgerUI` (and raw HTML).
  Adding or removing a file triggers a recompile.
  """
  use Phoenix.Component
  use LedgerUI

  @root Path.expand("../../examples", __DIR__)
  @sec_root Path.expand("../../../design/vitrine/sec", __DIR__)
  @extras_path Path.expand("../../../design/canvas/extras.json", __DIR__)
  @external_resource @extras_path
  @extras @extras_path |> File.read!() |> Jason.decode!()

  @files @root |> Path.join("*/*.heex") |> Path.wildcard() |> Enum.sort()
  @hash :erlang.md5(:erlang.term_to_binary(@files))

  @entries (for path <- @files do
              id = path |> Path.dirname() |> Path.basename()
              {index, ""} = path |> Path.basename(".heex") |> Integer.parse()
              {id, index, path}
            end)

  @titles (for id <- @entries |> Enum.map(&elem(&1, 0)) |> Enum.uniq(), into: %{} do
             sec = Path.join(@sec_root, id <> ".json")
             Module.put_attribute(__MODULE__, :external_resource, sec)
             vitrine = sec |> File.read!() |> Jason.decode!() |> Enum.map(& &1["t"])
             canvas_only = @extras |> Map.get(id, []) |> Enum.map(& &1["t"])
             {id, vitrine ++ canvas_only}
           end)

  @sections Enum.group_by(@entries, &elem(&1, 0), fn {id, index, path} ->
              %{
                index: index,
                title: @titles |> Map.fetch!(id) |> Enum.at(index - 1),
                source: File.read!(path)
              }
            end)

  for {_id, _index, path} <- @entries, do: @external_resource(path)

  @doc false
  def __mix_recompile__? do
    hash =
      @root
      |> Path.join("*/*.heex")
      |> Path.wildcard()
      |> Enum.sort()
      |> :erlang.term_to_binary()
      |> :erlang.md5()

    hash != @hash
  end

  @doc "Component ids with examples."
  def ids, do: @sections |> Map.keys() |> Enum.sort()

  @doc "Sections of a component, ordered by index."
  def sections(id), do: @sections |> Map.get(id, []) |> Enum.sort_by(& &1.index)

  for {id, index, path} <- @entries do
    @doc false
    def render(unquote(id), unquote(index), assigns) do
      require Phoenix.LiveView.HTMLEngine
      Phoenix.LiveView.HTMLEngine.compile(unquote(path))
    end
  end
end
