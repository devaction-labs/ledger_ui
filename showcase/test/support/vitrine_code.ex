defmodule LedgerShowcase.VitrineCode do
  @moduledoc """
  Compiles the HEEx `code` of every vitrine section (`design/vitrine/sec/<id>.json`) against the
  library: the snippet is the reference usage of the component API, so it must compile without
  diagnostics (unknown component, unknown attr or slot, value outside `values:`, missing required
  attr). `check/2` returns `:ok` or `{:error, [message]}`.

  Snippets are compiled inside a throw-away module that does `use Phoenix.Component` and
  `use LedgerUI`. `~p"..."` verified routes become plain strings (the showcase has no such routes)
  and `@assigns` are left as they are (they are only read when rendering, never at compile time).
  """

  @design Path.expand("../../../design", __DIR__)

  @doc "`[{id, index, code}]` of every section of every component."
  def snippets do
    for path <- Path.wildcard(Path.join(@design, "vitrine/sec/*.json")) |> Enum.sort(),
        id = Path.basename(path, ".json"),
        {s, i} <- path |> File.read!() |> Jason.decode!() |> Enum.with_index(1) do
      {id, i, s["code"]}
    end
  end

  @doc "Compiles one snippet. Returns `:ok` or `{:error, [String.t()]}`."
  def check(code, tag) do
    code = Regex.replace(~r/~p("[^"]*")/, code, "\\1")
    indented = code |> String.split("\n") |> Enum.map_join("\n", &("    " <> &1))
    mod = "LedgerShowcase.VitrineCode.Snippet#{System.unique_integer([:positive])}"

    src = """
    defmodule #{mod} do
      use Phoenix.Component
      use LedgerUI
      def render(assigns) do
        ~H\"\"\"
    #{indented}
        \"\"\"
      end
    end
    """

    out = fn ->
      Code.with_diagnostics([log: false], fn ->
        try do
          Code.compile_string(src, "vitrine/#{tag}")
          :ok
        rescue
          e -> {:raised, Exception.message(e)}
        end
      end)
    end

    # the compiler also logs the warnings it collects: keep the test output clean
    parent = self()

    ExUnit.CaptureIO.capture_io(:stderr, fn -> send(parent, {:vc, out.()}) end)

    {result, diagnostics} =
      receive do
        {:vc, r} -> r
      end

    :code.purge(String.to_atom("Elixir." <> mod))
    :code.delete(String.to_atom("Elixir." <> mod))

    msgs =
      for d <- diagnostics,
          d.severity in [:warning, :error],
          msg = String.trim(d.message),
          not ignorable?(msg),
          do: msg

    msgs = if match?({:raised, _}, result), do: msgs ++ [elem(result, 1)], else: msgs
    if msgs == [], do: :ok, else: {:error, Enum.uniq(msgs)}
  end

  # Shorthand of the snippets, not API gaps: the examples leave out the `id`, the labels or the
  # slot a real page must pass (`missing required ...`), and the pointer-style `checked="True" checked`
  # of the generator repeats a key (`key :checked will be overridden`).
  defp ignorable?("missing required " <> _), do: true
  defp ignorable?("key :" <> rest), do: String.contains?(rest, "will be overridden")
  defp ignorable?(_), do: false

  @doc "Short category of a diagnostic: `:function`, `:attr`, `:slot`, `:value`, `:other`."
  def category(msg) do
    cond do
      String.starts_with?(msg, "undefined function") -> :function
      String.starts_with?(msg, "undefined attribute") -> :attr
      String.starts_with?(msg, "undefined slot") -> :slot
      String.contains?(msg, "must be one of") or String.contains?(msg, "must be a") -> :value
      true -> :other
    end
  end
end
