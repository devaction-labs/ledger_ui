defmodule LedgerShowcase.Design do
  @moduledoc """
  Where the design data (canvas, reference vitrine, design system) lives.

  The data is not part of this repository: it is in the private `ledger_ui_design` repo, cloned
  next to this one. `path/0` resolves, in order:

    1. the `LEDGER_DESIGN` environment variable;
    2. `<repo root>/../ledger_ui_design`, if it exists;
    3. `<repo root>/design`, if it exists (legacy layout);
    4. `<repo root>/../ledger_ui_design` (it does not exist: `available?/0` is `false`).

  Everything that reads the data returns an empty fallback when it is missing, so the showcase
  compiles and runs without it (with fewer pages); the tests that need it are tagged `:design`.

  Several modules read the data at compile time (`@external_resource` of the files that exist).
  After cloning the data, or changing `LEDGER_DESIGN`, run `mix compile --force` once.
  """

  @root Path.expand("../../..", __DIR__)

  @doc "The repository root (the kit's root, parent of `showcase/`)."
  def root, do: @root

  @doc "The directory with the design data (it may not exist, see `available?/0`)."
  def path do
    sibling = Path.expand("../ledger_ui_design", @root)
    legacy = Path.join(@root, "design")

    cond do
      env = System.get_env("LEDGER_DESIGN") -> Path.expand(env, File.cwd!())
      File.dir?(sibling) -> sibling
      File.dir?(legacy) -> legacy
      true -> sibling
    end
  end

  @doc "Whether the design data is there."
  def available?, do: File.dir?(Path.join(path(), "vitrine"))

  @doc "`path/0` joined with a relative path."
  def path(rel), do: Path.join(path(), rel)

  @doc "Reads a file of the design data, or returns `default` when it is missing."
  def read(rel, default \\ nil) do
    case File.read(path(rel)) do
      {:ok, bin} -> bin
      {:error, _} -> default
    end
  end

  @doc "Decodes a JSON file of the design data, or returns `default` when it is missing."
  def json(rel, default \\ nil) do
    case read(rel) do
      nil -> default
      bin -> Jason.decode!(bin)
    end
  end

  @doc "Files of the design data matching a wildcard relative to `path/0`, sorted."
  def wildcard(pattern), do: path(pattern) |> Path.wildcard() |> Enum.sort()

  @doc "`[path]` for `@external_resource`: only the files that exist."
  def resources(rels), do: rels |> Enum.map(&path/1) |> Enum.filter(&File.exists?/1)

  @doc "The message the tests print when the data is missing."
  def missing_message do
    "design data not found at #{path()}: tests tagged :design are excluded. " <>
      "Clone the private repo devaction-labs/ledger_ui_design next to this one " <>
      "or set LEDGER_DESIGN to its path."
  end
end
