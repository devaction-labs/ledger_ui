defmodule LedgerShowcase.Parity do
  @moduledoc """
  Compares the HTML rendered by an example (`examples/<id>/NN.heex`) with the `h` field of
  section NN in `design/vitrine/sec/<id>.json`.

  Both are parsed with LazyHTML and flattened in document order into `{path, node}` items:

    * text: whitespace-collapsed, empty text dropped
    * element: tag + attributes. Ignored attributes: `id`, `phx-*`, `data-phx-*`, `data-part`,
      `keep-*`. `class` is a sorted set (empties dropped, `lu-i` dropped on icons), `style` is
      split on `;`, trimmed, empties dropped, sorted. Attribute order is irrelevant.
    * icon: `<i data-i="X" class="...">` (vitrine, unhydrated) and `<svg data-icon="X"
      class="lu-i ...">` (server) are the same node `{:icon, "X", size classes}`; their
      children are not compared.
  """

  @sec_dir Path.expand("../../../design/vitrine/sec", __DIR__)
  @max_report 10

  @doc "Path of the vitrine json of a component."
  def sec_path(id), do: Path.join(@sec_dir, id <> ".json")

  @doc "Expected HTML (`h`) of section `index` (1-based)."
  def expected_html(id, index) do
    sec_path(id) |> File.read!() |> Jason.decode!() |> Enum.at(index - 1) |> Map.fetch!("h")
  end

  @doc "Renders the example to a string."
  def actual_html(id, index) do
    id
    |> LedgerShowcase.Examples.render(index, %{})
    |> Phoenix.LiveViewTest.rendered_to_string()
  end

  @doc "Returns `:ok` or `{:error, report_string}`."
  def compare(id, index) do
    expected = expected_html(id, index) |> flatten()
    actual = actual_html(id, index) |> flatten()

    case diff(expected, actual) do
      [] -> :ok
      mismatches -> {:error, report(id, index, mismatches)}
    end
  end

  @doc "Flattens an HTML fragment into normalized `{path, node}` items."
  def flatten(html) do
    html |> LazyHTML.from_fragment() |> LazyHTML.to_tree() |> walk("")
  end

  defp walk(nodes, parent) do
    {items, _} =
      Enum.flat_map_reduce(nodes, 0, fn
        text, n when is_binary(text) ->
          case collapse(text) do
            "" -> {[], n}
            t -> {[{parent <> " > #text", {:text, t}}], n}
          end

        {:comment, _}, n ->
          {[], n}

        {tag, attrs, children}, n ->
          n = n + 1
          attrs = Map.new(attrs)

          icon? =
            (tag == "i" and Map.has_key?(attrs, "data-i")) or
              (tag == "svg" and Map.has_key?(attrs, "data-icon"))

          path = "#{parent} > #{if icon?, do: "icon", else: tag}:#{n}"

          cond do
            tag == "i" and Map.has_key?(attrs, "data-i") ->
              {[{path, {:icon, attrs["data-i"], size_classes(attrs)}}], n}

            tag == "svg" and Map.has_key?(attrs, "data-icon") ->
              {[{path, {:icon, attrs["data-icon"], size_classes(attrs)}}], n}

            true ->
              {[{path, {:el, tag, norm_attrs(attrs)}} | walk(children, path)], n}
          end
      end)

    items
  end

  defp collapse(text), do: text |> String.replace(~r/\s+/u, " ") |> String.trim()

  defp size_classes(attrs), do: attrs |> class_set() |> List.delete("lu-i")

  defp class_set(attrs) do
    attrs
    |> Map.get("class", "")
    |> String.split(~r/\s+/, trim: true)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp norm_attrs(attrs) do
    attrs
    |> Enum.reject(fn {k, _} -> ignored?(k) end)
    |> Enum.map(fn
      {"class", v} -> {"class", class_set(%{"class" => v})}
      {"style", v} -> {"style", norm_style(v)}
      {k, v} -> {k, v}
    end)
    |> Enum.reject(fn {k, v} -> k == "class" and v == [] end)
    |> Enum.sort()
  end

  defp ignored?(k),
    do: k == "id" or k == "data-part" or String.starts_with?(k, ["phx-", "data-phx-", "keep-"])

  defp norm_style(v) do
    v
    |> String.split(";")
    |> Enum.map(fn decl ->
      decl |> String.split(":", parts: 2) |> Enum.map_join(":", &String.trim/1)
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.sort()
  end

  defp diff(expected, actual) do
    pairs = zip_all(expected, actual)

    for {e, a} <- pairs, e != a, do: {e, a}
  end

  defp zip_all([], []), do: []
  defp zip_all([e | er], []), do: [{e, nil} | zip_all(er, [])]
  defp zip_all([], [a | ar]), do: [{nil, a} | zip_all([], ar)]
  defp zip_all([e | er], [a | ar]), do: [{e, a} | zip_all(er, ar)]

  defp report(id, index, mismatches) do
    shown = Enum.take(mismatches, @max_report)

    body =
      Enum.map_join(shown, "\n\n", fn {e, a} ->
        path = elem(e || a, 0)

        "at #{path}\n  expected (vitrine): #{inspect(e && elem(e, 1), limit: 20)}\n  actual   (example): #{inspect(a && elem(a, 1), limit: 20)}"
      end)

    more = length(mismatches) - length(shown)
    more = if more > 0, do: "\n\n... and #{more} more mismatches", else: ""

    "Parity mismatch for #{id} section #{index} (#{length(mismatches)} total):\n\n" <>
      body <> more
  end
end
