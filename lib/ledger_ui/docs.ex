defmodule LedgerUI.Docs do
  @moduledoc """
  The installed components as data: modules, docs, attrs and slots.

  Reads what the compiler recorded (`__components__/0` of `Phoenix.Component` and the docs chunk),
  so it describes the code that is running. `LedgerUI.Skill` builds on it.

      LedgerUI.Docs.components()
      #=> [%{key: "accordion", module: LedgerUI.Components.Accordion, summary: "...",
      #      moduledoc: "...", functions: [%{name: :accordion, doc: "...", attrs: [...],
      #      global: %{...} | nil, slots: [...]}, ...]}, ...]
  """

  @doc "Every component module with at least one function component, sorted by key."
  @spec components() :: [map()]
  def components do
    LedgerUI.Components.__modules__()
    |> Enum.map(&describe/1)
    |> Enum.reject(&(&1.functions == []))
    |> Enum.sort_by(& &1.key)
  end

  @doc "The snake_case key of a component module: `LedgerUI.Components.ContextMenu` is `\"context_menu\"`."
  @spec key(module()) :: String.t()
  def key(module), do: module |> Module.split() |> List.last() |> Macro.underscore()

  defp describe(module) do
    Code.ensure_loaded!(module)
    {moduledoc, docs} = docs(module)

    %{
      key: key(module),
      module: module,
      summary: summary(moduledoc),
      moduledoc: moduledoc,
      functions: functions(module, docs)
    }
  end

  defp functions(module, docs) do
    if function_exported?(module, :__components__, 0) do
      module.__components__()
      |> Enum.filter(fn {name, _} -> function_exported?(module, name, 1) end)
      |> Enum.sort_by(fn {_name, c} -> c.line end)
      |> Enum.map(&function(&1, docs))
    else
      []
    end
  end

  defp function({name, component}, docs) do
    %{
      name: name,
      doc: function_doc(docs, name),
      attrs: component.attrs |> Enum.reject(&(&1.type == :global)) |> Enum.sort_by(& &1.line),
      global: Enum.find(component.attrs, &(&1.type == :global)),
      slots: component.slots
    }
  end

  defp docs(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, moduledoc, _, docs} -> {text(moduledoc), docs}
      _ -> {"", []}
    end
  end

  defp text(%{"en" => doc}), do: String.trim(doc)
  defp text(_), do: ""

  defp summary(moduledoc) do
    moduledoc |> String.split("\n\n", parts: 2) |> hd() |> String.replace("\n", " ")
  end

  defp function_doc(docs, name) do
    Enum.find_value(docs, "", fn
      {{:function, ^name, 1}, _, _, %{"en" => doc}, _} -> strip_generated(doc)
      _ -> nil
    end)
  end

  # Phoenix appends "## Attributes" / "## Slots" to the doc; the skill renders its own tables.
  defp strip_generated(doc),
    do: doc |> String.split(~r/^## (Attributes|Slots)$/m) |> hd() |> String.trim()
end
