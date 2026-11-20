defmodule LedgerShowcase.Parity do
  @moduledoc """
  Compares the HTML rendered by an example (`examples/<id>/NN.heex`) with the reference of
  section NN: the CANVAS markup (`LedgerShowcase.Canvas`, source of truth) when the canvas has
  the section, else the `h` field of `design/vitrine/sec/<id>.json` (fallback). The failure
  message tells which source was used. Template escapes `{{x}}` / `{ {x} }` are normalized to
  `{{x}}` on both sides.

  Both are parsed with LazyHTML and flattened in document order into `{path, node}` items:

    * text: whitespace-collapsed, empty text dropped
    * element: tag + attributes. Ignored attributes: `id`, `phx-*`, `data-phx-*`, `data-part`,
      `keep-*`. Accessibility/state attributes (`aria-*`, `role`, `tabindex`, `hidden`,
      `popover`, `inert`, `data-lu-*`, `data-state`) are "extras": when present on OUR
      element and absent on the reference element they are ignored (components render ARIA
      server-side, the vitrine only gets it from JS); when the reference element has the
      attribute, the values must still match. `class` is a sorted set (empties dropped, `lu-i` dropped on icons), `style` is
      split on `;`, trimmed, empties dropped, sorted. Attribute order is irrelevant.
    * CONVERTED PARTS (Tailwind): a component converted to utility classes no longer emits the canvas
      `lu-*` classes, so its `class` cannot match. Every element of a converted component carries
      `data-part="<name>"`; names listed in `test/converted_parts.exs` have their `class` ignored on
      BOTH sides (tag, text, other attributes, style, order and children are still compared). This
      holds in every section that renders the component, not only its own. Unconverted components
      keep the full class comparison.
    * icon: `<i data-i="X" class="...">` (vitrine, unhydrated) and `<svg data-icon="X"
      class="lu-i ...">` (server) are the same node `{:icon, "X", size classes}`; their
      children are not compared.
  """

  alias LedgerShowcase.Canvas

  @converted_file Path.expand("converted_parts.exs", __DIR__ |> Path.dirname())
  @external_resource @converted_file
  @converted_parts @converted_file |> Code.eval_file() |> elem(0) |> MapSet.new()

  @doc "`data-part` names whose `class` is not compared (see the moduledoc)."
  def converted_parts, do: @converted_parts

  @sec_dir Path.expand("../../../design/vitrine/sec", __DIR__)
  @max_report 10

  @doc "Path of the vitrine json of a component."
  def sec_path(id), do: Path.join(@sec_dir, id <> ".json")

  @doc "Expected HTML (`h`) of section `index` (1-based)."
  def expected_html(id, index) do
    id |> LedgerShowcase.Sections.vitrine() |> Enum.at(index - 1) |> Map.fetch!("h")
  end

  @doc "Renders the example to a string."
  def actual_html(id, index) do
    id
    |> LedgerShowcase.Examples.render(index, %{})
    |> Phoenix.LiveViewTest.rendered_to_string()
  end

  @doc "Returns `:ok` or `{:error, report_string}`."
  def compare(id, index) do
    source = Canvas.source(id, index)
    expected = reference(id, index) |> flatten()
    actual = actual_html(id, index) |> flatten()

    result =
      case diff(expected, actual) |> Enum.reject(&extras_only?/1) do
        [] -> :ok
        mismatches -> {:error, report(id, index, source, mismatches)}
      end

    record(id, index, source, result)
    result
  end

  @doc "Reference of a section: canvas tree when available, else the vitrine `h` html."
  def reference(id, index), do: Canvas.get(id, index) || expected_html(id, index)

  @table :ledger_parity_results

  @doc "Creates the ETS table that collects results (call from `test_helper.exs`)."
  def init_results do
    if :ets.whereis(@table) == :undefined,
      do: :ets.new(@table, [:named_table, :public, :set])

    :ok
  end

  @doc "Recorded `{{id, index}, source, :ok | :error, first_mismatch}` rows."
  def results, do: if(:ets.whereis(@table) == :undefined, do: [], else: :ets.tab2list(@table))

  defp record(id, index, source, result) do
    if :ets.whereis(@table) != :undefined do
      first =
        case result do
          :ok -> nil
          {:error, report} -> count_prefix(report) <> first_mismatch(report)
        end

      :ets.insert(@table, {{id, index}, source, if(result == :ok, do: :ok, else: :error), first})
    end
  end

  defp count_prefix(report) do
    case Regex.run(~r/\((\d+) total\)/, report) do
      [_, n] -> "[#{n} mismatches] "
      _ -> ""
    end
  end

  @doc "First `at ... expected ... actual` block of a report."
  def first_mismatch(report) do
    case String.split(report, "\n\n", parts: 3) do
      [_, first | _] -> first
      _ -> report
    end
  end

  @doc "Flattens an HTML fragment (string) or a LazyHTML tree into normalized `{path, node}` items."
  def flatten(html) when is_binary(html) do
    html |> LazyHTML.from_fragment() |> LazyHTML.to_tree() |> walk("")
  end

  def flatten(tree) when is_list(tree), do: walk(tree, "")

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

  defp collapse(text) do
    text
    |> String.replace(~r/\s+/u, " ")
    |> String.replace(~r/\{\s*\{\s*([\w.]+)\s*\}\s*\}/u, "{{\\1}}")
    |> String.trim()
  end

  # canvas: `lu-i` + a size name (`sm`, `md`, `lg`, `xl`); ours (Tailwind): utilities. Both reduce to the size
  # name plus the classes the caller added, without the icon's own utilities.
  @icon_base ~w(inline flex-none fill-none stroke-current stroke-[1.5] [stroke-linecap:round] [stroke-linejoin:round] align-middle)
  @icon_sizes %{"size-3.5" => "sm", "size-4" => "md", "size-[22px]" => "lg", "size-7" => "xl"}

  defp size_classes(attrs) do
    attrs
    |> class_set()
    |> Enum.reject(&(&1 in ["lu-i", "size-[18px]" | @icon_base]))
    |> Enum.map(&Map.get(@icon_sizes, &1, &1))
    |> Enum.sort()
  end

  defp class_set(attrs) do
    attrs
    |> Map.get("class", "")
    |> String.split(~r/\s+/, trim: true)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp norm_attrs(attrs) do
    attrs
    |> Enum.reject(fn {k, v} -> ignored?(k) and not converted_part?(k, v) end)
    |> Enum.map(fn
      {"class", v} -> {"class", class_set(%{"class" => v})}
      {"style", v} -> {"style", v |> norm_ref() |> norm_style()}
      {k, v} -> {k, norm_ref(v)}
    end)
    |> Enum.reject(fn {k, v} -> k in ["class", "style"] and v == [] end)
    |> Enum.sort()
  end

  # generated ids (e.g. chart gradients) differ per render: `url(#gw9ppl8)` == `url(#x)`
  # and long floats are rounded to 2 decimals (canvas: 164.66666666666669, ours: 164.67)
  defp norm_ref(v) when is_binary(v) do
    v
    |> String.replace(~r/url\(#[^)]*\)/, "url(#_)")
    |> String.replace(~r/-?\d+\.\d{3,}/, fn n ->
      f = n |> String.to_float() |> Float.round(2)
      if f == Float.round(f), do: f |> trunc() |> Integer.to_string(), else: Float.to_string(f)
    end)
  end

  defp norm_ref(v), do: v

  defp converted_part?("data-part", v), do: MapSet.member?(@converted_parts, v)
  defp converted_part?(_, _), do: false

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

  @extra_prefixes ["aria-", "data-lu-"]
  @extra_names ["role", "tabindex", "hidden", "popover", "inert", "data-state", "data-part"]

  @doc "True for attributes our element may carry extra (a11y/state/hook config)."
  def extra_attr?(k), do: k in @extra_names or String.starts_with?(k, @extra_prefixes)

  # A mismatch is harmless when both are elements with the same tag and OUR attrs only
  # add extra attributes the reference does not have.
  @doc false
  def extras_only?({{path, {:el, tag, e_attrs}}, {path, {:el, tag, a_attrs}}}) do
    # a converted part (data-part kept by norm_attrs): class and style are not compared
    {e_attrs, a_attrs} =
      case List.keytake(a_attrs, "data-part", 0) do
        {{_, _}, rest} ->
          drop = &(&1 |> List.keydelete("class", 0) |> List.keydelete("style", 0))
          {drop.(e_attrs), drop.(rest)}

        nil ->
          {e_attrs, a_attrs}
      end

    e_keys = Enum.map(e_attrs, &elem(&1, 0))

    stripped =
      Enum.reject(a_attrs, fn {k, _} -> extra_attr?(k) and k not in e_keys end)

    stripped == e_attrs
  end

  @doc false
  def extras_only?(_), do: false

  @doc false
  def diff(expected, actual) do
    pairs = zip_all(expected, actual)

    for {e, a} <- pairs, e != a, do: {e, a}
  end

  defp zip_all([], []), do: []
  defp zip_all([e | er], []), do: [{e, nil} | zip_all(er, [])]
  defp zip_all([], [a | ar]), do: [{nil, a} | zip_all([], ar)]
  defp zip_all([e | er], [a | ar]), do: [{e, a} | zip_all(er, ar)]

  defp report(id, index, source, mismatches) do
    shown = Enum.take(mismatches, @max_report)

    body =
      Enum.map_join(shown, "\n\n", fn {e, a} ->
        path = elem(e || a, 0)

        "at #{path}\n  expected (#{source}): #{inspect(e && elem(e, 1), limit: 20)}\n  actual   (example): #{inspect(a && elem(a, 1), limit: 20)}"
      end)

    more = length(mismatches) - length(shown)
    more = if more > 0, do: "\n\n... and #{more} more mismatches", else: ""

    "Parity mismatch for #{id} section #{index} against #{source} (#{length(mismatches)} total):\n\n" <>
      body <> more
  end
end
