defmodule LedgerShowcase.Canvas do
  @moduledoc """
  Canvas reference for the parity test.

  The design canvas (`design/canvas/G*Claro*.dc.html`) is the source of truth; the vitrine
  (`design/vitrine/sec/<id>.json`) is only a fallback. Mapping (see `design/CANVAS_VS_VITRINE.md`):

    * every board `<section>` has an `<h2>` with the component name (`docs.json` `name` -> `id`)
    * every LEAF `.lu-demo` (no `.lu-demo` inside) has a `.lu-spec` title (trailing " · em loop"
      removed) that equals the `t` of a vitrine section
    * the demo body (children except `.lu-spec`) is the canvas markup of that section (already
      hydrated: `<svg class="lu-i" data-icon>`)

  `reference/0` returns `%{{id, index} => tree}` (LazyHTML tree). When an id appears in several
  boards, or a section in several demos, the LAST board in file-name order wins (`Claro` <
  `Claro2` < `Claro3`: the numbered boards are later revisions). A board section without
  `.lu-demo` whose vitrine json has a single section uses its first `.lu-stage` content. Titles repeated inside one
  vitrine json are matched in order of appearance.

  The map is built once and cached in `:persistent_term` (call `load!/0` from `test_helper.exs`).
  """

  @design Path.expand("../../../design", __DIR__)
  @key {__MODULE__, :reference}

  @doc "Files of the canvas boards used (Claro, Claro2, Claro3), sorted."
  def files, do: Path.wildcard(Path.join(@design, "canvas/G*Claro*.dc.html")) |> Enum.sort()

  @doc "Builds (once) and returns the reference map."
  def load! do
    case :persistent_term.get(@key, nil) do
      nil ->
        :global.trans({__MODULE__, self()}, fn ->
          case :persistent_term.get(@key, nil) do
            nil ->
              ref = build()
              :persistent_term.put(@key, ref)
              ref

            ref ->
              ref
          end
        end)

      ref ->
        ref
    end
  end

  @doc "`%{{id, index} => tree}`."
  def reference, do: load!()

  @doc "Canvas tree of `{id, index}` or `nil` (use the vitrine)."
  def get(id, index) do
    case Map.get(reference(), {id, index}) do
      {:extra, _title, body} -> body
      other -> other
    end
  end

  @doc "`:canvas` when the section has a canvas reference, else `:vitrine`."
  def source(id, index), do: if(get(id, index), do: :canvas, else: :vitrine)

  @doc "Builds the reference map from the board files."
  def build(files \\ files()) do
    names = names()
    secs = Map.new(Map.values(names), fn id -> {id, titles(id)} end)

    Enum.reduce(files, %{}, fn file, acc ->
      refs = file |> File.read!() |> board_refs(names, secs)
      # a later board that has the component replaces the canvas-only demos of earlier ones
      ids = refs |> Map.keys() |> Enum.map(&elem(&1, 0)) |> Enum.uniq()

      acc =
        Map.reject(acc, fn {{id, i}, _} -> id in ids and i > length(secs[id]) end)

      Map.merge(acc, refs)
    end)
  end

  @doc """
  Canvas-only demos (leaf demos whose `.lu-spec` title matches no vitrine section, or repeats a
  title more often than the vitrine does): `%{id => [%{t, h}]}` in canvas order. Their section
  number is the vitrine section count + position (`{id, count + k}` in `reference/0`).
  """
  def extras(ref \\ reference()) do
    secs = Map.new(names() |> Map.values(), fn id -> {id, titles(id)} end)

    ref
    |> Enum.flat_map(fn {{id, i}, tree} ->
      n = length(secs[id] || [])
      if i > n, do: [{id, i - n, tree}], else: []
    end)
    |> Enum.sort()
    |> Enum.group_by(&elem(&1, 0), fn {_, _, {:extra, t, tree}} ->
      %{"t" => t, "h" => tree |> LazyHTML.Tree.to_html() |> String.trim()}
    end)
  end

  @doc "`%{{id, index} => tree}` of one board html."
  def board_refs(html, names, secs) do
    tree = html |> LazyHTML.from_document() |> LazyHTML.to_tree()

    tree
    |> find_all(&(tag(&1) == "section"))
    |> Enum.flat_map(fn sec ->
      with [h2 | _] <- find_all(children(sec), &(tag(&1) == "h2")),
           id when is_binary(id) <- names[text(h2)],
           titles when is_list(titles) <- secs[id] do
        sec_refs(id, titles, sec)
      else
        _ -> []
      end
    end)
    |> Map.new()
  end

  defp sec_refs(id, titles, sec) do
    demos =
      sec
      |> find_all(&has_class?(&1, "lu-demo"))
      |> Enum.reject(fn d -> find_all(children(d), &has_class?(&1, "lu-demo")) != [] end)

    if demos == [], do: stage_ref(id, titles, sec), else: demo_refs(id, titles, demos)
  end

  # Boards of single-example components (charts, shell-floating, status-toast...) have no
  # `.lu-demo`/`.lu-spec`: the content of the first `.lu-stage` is the reference of the only
  # vitrine section.
  defp stage_ref(id, [_only], sec) do
    case find_all(sec, &has_class?(&1, "lu-stage")) do
      [stage | _] -> [{{id, 1}, children(stage)}]
      [] -> []
    end
  end

  defp stage_ref(_, _, _), do: []

  defp demo_refs(id, titles, demos) do
    {refs, {_, extra_n}} =
      Enum.flat_map_reduce(demos, {%{}, 0}, fn demo, {seen, extra_n} ->
        {spec, body} =
          Enum.split_with(children(demo), &(is_tuple(&1) and has_class?(&1, "lu-spec")))

        title =
          case spec do
            [s | _] -> s |> text() |> String.replace(~r/\s*·\s*em loop$/u, "") |> String.trim()
            [] -> nil
          end

        n = Map.get(seen, title, 0)

        idxs =
          for {t, i} <- Enum.with_index(titles, 1), String.trim(t) == title, do: i

        seen = Map.put(seen, title, n + 1)

        case Enum.at(idxs, n) do
          nil when title in [nil, ""] ->
            {[], {seen, extra_n}}

          nil ->
            k = length(titles) + extra_n + 1
            {[{{id, k}, {:extra, title, body}}], {seen, extra_n + 1}}

          idx ->
            {[{{id, idx}, body}], {seen, extra_n}}
        end
      end)

    _ = extra_n
    refs
  end

  defp names do
    @design
    |> Path.join("vitrine/docs.json")
    |> File.read!()
    |> Jason.decode!()
    |> Map.new(&{&1["name"], &1["id"]})
  end

  defp titles(id) do
    path = Path.join(@design, "vitrine/sec/#{id}.json")

    if File.exists?(path),
      do: id |> LedgerShowcase.Sections.vitrine() |> Enum.map(& &1["t"]),
      else: nil
  end

  ## tree helpers

  defp tag({t, _, _}) when is_binary(t), do: t
  defp tag(_), do: nil

  defp children({_, _, kids}), do: kids
  defp children(list) when is_list(list), do: list

  defp has_class?({_, attrs, _}, class) do
    case List.keyfind(attrs, "class", 0) do
      {_, v} -> class in String.split(v)
      nil -> false
    end
  end

  # all descendant elements (document order), accepting a node or a list of nodes
  defp find_all(nodes, pred) when is_list(nodes) do
    Enum.flat_map(nodes, fn
      {_, _, kids} = n -> if(pred.(n), do: [n], else: []) ++ find_all(kids, pred)
      _ -> []
    end)
  end

  defp find_all({_, _, kids}, pred), do: find_all(kids, pred)

  @doc "Whitespace-joined text content of a node."
  def text({_, _, kids}), do: text(kids)

  def text(kids) when is_list(kids) do
    kids
    |> Enum.map(fn
      b when is_binary(b) -> b
      {:comment, _} -> ""
      n -> text(n)
    end)
    |> Enum.join(" ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end
end
