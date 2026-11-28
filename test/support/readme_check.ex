defmodule LedgerUI.ReadmeCheck do
  @moduledoc """
  Compiles a HEEx snippet against the library (inside a throw-away module that does `use Phoenix.Component`
  and `use LedgerUI`). Returns `:ok` or `{:error, [message]}`: unknown component, attr or slot and values
  outside `values:` and `missing required ...` (an example without its `id`, a required attr or a required slot) are errors.

  Used by `test/readme_examples_test.exs` and by `scripts/gen_readme_components.exs`.
  """

  def check(code, tag) do
    case messages(code, tag) do
      [] -> :ok
      msgs -> {:error, msgs}
    end
  end

  @doc "The compiler warnings and errors of `code`, without repeats (`[]` when it compiles clean)."
  def messages(code, tag) do
    indented = code |> String.split("\n") |> Enum.map_join("\n", &("    " <> &1))
    mod = "LedgerUI.ReadmeSnippet#{System.unique_integer([:positive])}"

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

    {result, diagnostics} =
      Code.with_diagnostics([log: false], fn ->
        try do
          Code.compile_string(src, "README/#{tag}")
          :ok
        rescue
          e -> {:raised, Exception.message(e)}
        end
      end)

    :code.purge(Module.concat([mod]))
    :code.delete(Module.concat([mod]))

    msgs =
      for d <- diagnostics,
          d.severity in [:warning, :error],
          msg = String.trim(d.message),
          do: msg

    msgs = if match?({:raised, _}, result), do: msgs ++ [elem(result, 1)], else: msgs
    Enum.uniq(msgs)
  end
end
