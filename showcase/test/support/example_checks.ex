defmodule LedgerShowcase.ExampleChecks do
  @moduledoc """
  Structural checks of a rendered example (`examples/<id>/NN.heex`), independent of the canvas markup
  (the canvas is compared PIXEL by pixel, see `scripts/visual/` and MIGRATION.md, "Exemplos da vitrine").

    * `render/2` - the example as an HTML string
    * `lu_tokens/1` - the `lu-*` class tokens in `class` attributes (the legacy CSS goes away)
    * `a11y/1` - ARIA / structure problems: duplicate ids, `aria-controls|labelledby|describedby|owns`
      pointing nowhere, `role=tab` without `aria-selected`, unnamed buttons/links/images
    * `data_part_missing?/2` - the source calls a `<.component>` (other than `<.icon>`) but nothing
      rendered carries `data-part`
  """

  @id_refs ~w(aria-controls aria-labelledby aria-describedby aria-owns aria-activedescendant)

  def render(id, index) do
    id
    |> LedgerShowcase.Examples.render(index, %{})
    |> Phoenix.LiveViewTest.rendered_to_string()
  end

  defp elements(html) do
    html |> LazyHTML.from_fragment() |> LazyHTML.to_tree() |> collect([])
  end

  defp collect(nodes, acc) when is_list(nodes), do: Enum.reduce(nodes, acc, &collect/2)

  defp collect({tag, attrs, children}, acc) when is_binary(tag),
    do: collect(children, [{tag, Map.new(attrs), children} | acc])

  defp collect(_text_or_comment, acc), do: acc

  @doc "Sorted unique `lu-*` tokens of the `class` attributes (accepts the HTML string)."
  def lu_tokens(html) do
    html
    |> elements()
    |> Enum.flat_map(fn {_, attrs, _} -> attrs |> Map.get("class", "") |> String.split() end)
    |> Enum.filter(&String.starts_with?(&1, "lu-"))
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc "List of problem strings (empty = ok)."
  def a11y(html) do
    els = elements(html)
    ids = for {_, %{"id" => id}, _} <- els, do: id
    id_set = MapSet.new(ids)

    dup = for {id, n} <- Enum.frequencies(ids), n > 1, do: "duplicate id #{inspect(id)} (#{n}x)"

    dangling =
      for {tag, attrs, _} <- els,
          attr <- @id_refs,
          value = attrs[attr],
          value not in [nil, ""],
          ref <- String.split(value),
          not MapSet.member?(id_set, ref),
          do: "<#{tag} #{attr}=#{inspect(ref)}> points to a missing id"

    tabs =
      for {tag, %{"role" => "tab"} = attrs, _} <- els,
          not Map.has_key?(attrs, "aria-selected"),
          do: "<#{tag} role=tab> without aria-selected"

    unnamed =
      for {tag, attrs, children} <- els,
          unnamed?(tag, attrs, children),
          do: "<#{tag}> without accessible name"

    dup ++ dangling ++ tabs ++ unnamed
  end

  defp unnamed?("button", attrs, children), do: not named?(attrs, children)
  defp unnamed?("a", %{"href" => _} = attrs, children), do: not named?(attrs, children)
  defp unnamed?("img", attrs, _), do: not Map.has_key?(attrs, "alt")
  defp unnamed?(_, _, _), do: false

  defp named?(attrs, children) do
    Enum.any?(["aria-label", "aria-labelledby", "title"], &(attrs[&1] not in [nil, ""])) or
      text?(children)
  end

  # visible text, or an inner element that names itself (img alt, svg <title>, aria-label)
  defp text?(nodes) when is_list(nodes), do: Enum.any?(nodes, &text?/1)
  defp text?(t) when is_binary(t), do: String.trim(t) != ""

  defp text?({_, attrs, children}) do
    Enum.any?(attrs, fn {k, v} -> k in ["aria-label", "alt", "title"] and v != "" end) or
      text?(children)
  end

  defp text?(_), do: false

  @doc "True when the source uses `<.component>` calls (not just `<.icon>`) and the output has no `data-part`."
  def data_part_missing?(source, html) do
    source = Regex.replace(~r/<%!--.*?--%>/s, source, "")
    calls = Regex.scan(~r/<\.([a-z_]+)/, source) |> Enum.map(&List.last/1) |> Enum.uniq()
    calls -- ["icon"] != [] and not String.contains?(html, "data-part=")
  end
end
