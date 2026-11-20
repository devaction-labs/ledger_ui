defmodule LedgerUI.Icons do
  @moduledoc """
  The icons an app vendored with `mix ledger_ui.icons`, loaded for `<.icon>`.

      # config/config.exs
      config :ledger_ui, :icons_path, "priv/hugeicons"
      # or, to resolve it inside a release:
      config :ledger_ui, :icons_path, {:my_app, "priv/hugeicons"}

  The folder is read once, on first use, and kept in `:persistent_term` as a map of
  `name => iodata parts`, so a lookup costs one `Application.get_env/3`, one `:persistent_term`
  read and one map access, with no file access. When a name is missing the folder's signature (modification
  time and file count) is compared with the loaded one and the folder is read again if it changed, so icons added by
  `mix ledger_ui.icons get`/`sync` show up in a running dev server without a restart (a missing name
  in a stable folder costs one `File.stat/1`, and `<.icon>` logs it anyway).

  Each file is converted again on load (`LedgerUI.Icons.Hugeicons.convert/1`), so only shapes
  survive. Without `:icons_path` nothing is loaded and every lookup misses.
  """

  alias LedgerUI.Components.Icon
  alias LedgerUI.Icons.Hugeicons

  @doc "The configured folder as an absolute path, or `nil`."
  @spec path() :: Path.t() | nil
  def path do
    case Application.get_env(:ledger_ui, :icons_path) do
      nil -> nil
      {app, rel} when is_atom(app) and is_binary(rel) -> Path.join(Application.app_dir(app), rel)
      path when is_binary(path) -> Path.expand(path)
    end
  end

  @doc "The render parts of a vendored icon (see `LedgerUI.Components.Icon`), or `nil`."
  @spec fetch(String.t()) :: tuple() | nil
  def fetch(name) do
    case path() do
      nil -> nil
      path -> fetch(path, name)
    end
  end

  defp fetch(path, name) do
    {_mtime, icons} = table(path)

    case icons do
      %{^name => parts} -> parts
      _ -> reload_if_changed(path, name)
    end
  end

  defp reload_if_changed(path, name) do
    {signature, _} = table(path)

    if signature(path) != signature do
      {_, icons} = load!(path)
      Map.get(icons, name)
    end
  end

  @doc "The names of the vendored icons currently loaded."
  @spec names() :: [String.t()]
  def names do
    case path() do
      nil -> []
      path -> path |> table() |> elem(1) |> Map.keys() |> Enum.sort()
    end
  end

  @doc "Forgets the loaded icons; the next lookup reads the folder again."
  @spec reload() :: :ok
  def reload do
    if path = path(), do: :persistent_term.erase({__MODULE__, path})
    :ok
  end

  defp table(path) do
    case :persistent_term.get({__MODULE__, path}, nil) do
      nil -> load!(path)
      loaded -> loaded
    end
  end

  # Returns `{signature, icons}` and stores it. `:persistent_term.put/2` of an equal term is free,
  # of a different one triggers a global GC, which is acceptable for a folder that changes by hand.
  defp load!(path) do
    icons =
      path
      |> Path.join("*.svg")
      |> Path.wildcard()
      |> Enum.flat_map(fn file ->
        name = Path.basename(file, ".svg")

        with true <- Hugeicons.valid_name?(name),
             {:ok, svg} <- File.read(file),
             {:ok, inner} <- Hugeicons.inner(svg) do
          [{name, Icon.parts(name, inner)}]
        else
          _ -> []
        end
      end)
      |> Map.new()

    loaded = {signature(path), icons}
    :persistent_term.put({__MODULE__, path}, loaded)
    loaded
  end

  # Modification time (one-second resolution) plus the file count, so two files added in the
  # same second are still noticed.
  defp signature(path) do
    case File.stat(path, time: :posix) do
      {:ok, %{mtime: mtime}} -> {mtime, path |> File.ls!() |> length()}
      _ -> nil
    end
  end
end
