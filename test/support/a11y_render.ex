defmodule LedgerUI.A11yStructureTest.Render do
  @moduledoc false
  # Renders every public function component of the kit with the smallest assigns: its required
  # attrs and slots (and, in a second pass, every declared slot). Used by the structural
  # accessibility test; adapted from the fuzzer of the quality audit (#121).

  @doc "`%{runs: [{component_name, {:ok, html} | {:error, reason}}], failed: [name]}`."
  def all do
    runs =
      for mod <- LedgerUI.Components.__modules__(),
          {fun, comp} <- mod.__components__(),
          function_exported?(mod, fun, 1),
          mode <- [false, true, :rich, :rich_strings],
          rich?(comp, mode),
          do: {fun, render(mod, fun, comp, mode)}

    runs = runs ++ extra()
    %{runs: runs, failed: for({fun, {:error, _}} <- runs, uniq: true, do: fun)}
  end

  # Renderings the minimal sweep does not reach: a dialog with its own `<:header>` (alone, and next
  # to a `title`).
  defp extra do
    slot = fn name -> [%{__slot__: name, inner_block: fn _, _ -> "s-#{name}" end}] end

    for fun <- [:modal, :drawer, :sheet],
        mod = module_of(fun),
        mod != nil,
        extra <- [%{header: slot.(:header)}, %{header: slot.(:header), title: "T"}] do
      assigns =
        Map.merge(
          %{id: "fz-id", inner_block: slot.(:inner_block), __changed__: nil},
          extra
        )

      html =
        try do
          {:ok, mod |> apply(fun, [assigns]) |> Phoenix.LiveViewTest.rendered_to_string()}
        rescue
          e -> {:error, Exception.message(e) |> String.slice(0, 200)}
        end

      {fun, html}
    end
  end

  defp module_of(fun) do
    Enum.find(LedgerUI.Components.__modules__(), fn m ->
      Code.ensure_loaded?(m) and function_exported?(m, :__components__, 0) and
        Enum.any?(m.__components__(), fn {n, _} -> n == fun end)
    end)
  end

  @doc false
  def __render_debug__(mod, fun, comp, all?), do: apply(mod, fun, [assigns(comp, all?)])

  # `:rich` also gives `id`, `label` and `options` (pairs) to the components that have them, `:rich_strings`
  # `options` as plain strings (pillbox, tags_input).
  defp rich?(_comp, mode) when mode in [false, true], do: true

  defp rich?(comp, _mode),
    do: Enum.any?(comp.attrs, &(&1.name in [:label, :options]))

  defp assigns(comp, mode) do
    comp
    |> base()
    |> Map.merge(slots(comp, mode != false))
    |> Map.merge(rich(comp, mode))
    |> Map.put(:__changed__, nil)
  end

  defp rich(comp, mode) when mode in [:rich, :rich_strings] do
    for a <- comp.attrs, a.name in [:id, :label, :options], into: %{} do
      case {a.name, mode} do
        {:id, _} -> {:id, "fz-id"}
        {:label, _} -> {:label, "Label"}
        {:options, :rich} -> {:options, [{"Option A", "a"}, {"Option B", "b"}]}
        {:options, :rich_strings} -> {:options, ["Option A", "Option B"]}
      end
    end
  end

  defp rich(_comp, _mode), do: %{}

  defp render(mod, fun, comp, all?) do
    html =
      mod
      |> apply(fun, [assigns(comp, all?)])
      |> Phoenix.LiveViewTest.rendered_to_string()

    {:ok, html}
  rescue
    e -> {:error, Exception.message(e) |> String.slice(0, 200)}
  catch
    kind, value -> {:error, inspect({kind, value}) |> String.slice(0, 200)}
  end

  defp form_field do
    form = Phoenix.Component.to_form(%{"f" => "v"}, as: "fz")
    form[:f]
  end

  defp base(comp) do
    for a <- comp.attrs, a.required, a.type != :global, into: %{}, do: {a.name, value(a)}
  end

  defp value(a) do
    case {a.type, a.name} do
      {_, :upload} -> %Phoenix.LiveView.UploadConfig{name: :f, ref: "r", entries: []}
      {:string, :id} -> "fz-id"
      {:string, _} -> first_value(a.opts[:values]) || "x"
      {:integer, _} -> 1
      {:list, _} -> []
      {:map, _} -> %{}
      {:boolean, _} -> true
      {:atom, _} -> :x
      {{:struct, Phoenix.HTML.FormField}, _} -> form_field()
      {:any, :rows} -> []
      {:any, :code} -> 404
      {:any, :counts} -> %{}
      {:any, :options} -> %{}
      {:any, _} -> "x"
      _ -> nil
    end
  end

  defp first_value([v | _]), do: v
  defp first_value(_), do: nil

  defp slots(comp, all?) do
    for s <- comp.slots, s.required or all?, into: %{} do
      attrs =
        for a <- s.attrs, a.required, into: %{} do
          {a.name, slot_attr(a)}
        end

      entry =
        Map.merge(attrs, %{
          __slot__: s.name,
          inner_block: fn _, _ -> "s-#{s.name}" end
        })

      {s.name, [entry]}
    end
  end

  defp slot_attr(a) do
    case a.type do
      :integer -> 1
      :boolean -> true
      :list -> []
      _ -> "x"
    end
  end
end
