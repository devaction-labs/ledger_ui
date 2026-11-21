# Regenera a seção "Componentes" do README.md (entre <!-- components:start --> e <!-- components:end -->).
#
#   mix run scripts/gen_readme_components.exs
#
# Um exemplo HEEx por function component público (`LedgerUI.Components.__modules__/0` + `__components__/0`),
# agrupado pelos grupos da vitrine. O exemplo é o menor trecho de `vitrine/sec/*.json` dos dados de design (repo privado `ledger_ui_design`, ver `LEDGER_DESIGN`) que chama o
# componente; sem trecho na vitrine, um esqueleto montado dos `attr`/`slot` obrigatórios.
# `test/readme_examples_test.exs` compila cada bloco ```heex do README.

Code.require_file("../test/support/readme_check.ex", __DIR__)

defmodule GenReadme do
  @root Path.expand("..", __DIR__)
  @readme Path.expand("../README.md", __DIR__)

  # Dados de design: `LEDGER_DESIGN`, senão `<raiz>/../ledger_ui_design`, senão `<raiz>/design` (legado).
  def design do
    sibling = Path.expand("../ledger_ui_design", @root)
    legacy = Path.join(@root, "design")

    dir =
      cond do
        env = System.get_env("LEDGER_DESIGN") -> Path.expand(env)
        File.dir?(sibling) -> sibling
        File.dir?(legacy) -> legacy
        true -> sibling
      end

    vitrine = Path.join(dir, "vitrine")

    File.dir?(vitrine) ||
      Mix.raise(
        "dados de design não encontrados em #{dir}: clone devaction-labs/ledger_ui_design ao lado deste repo ou defina LEDGER_DESIGN"
      )

    vitrine
  end

  def run do
    design = design()
    docs = design |> Path.join("docs.json") |> File.read!() |> Jason.decode!()

    snippets =
      for d <- docs,
          path = Path.join(design, "sec/#{d["id"]}.json"),
          File.exists?(path),
          s <- path |> File.read!() |> Jason.decode!(),
          code = s["code"],
          is_binary(code),
          do: {d["group"], code}

    mods =
      for m <- LedgerUI.Components.__modules__() do
        comps =
          m.__components__()
          |> Enum.filter(fn {n, _} -> function_exported?(m, n, 1) end)
          |> Enum.sort_by(&elem(&1, 0))

        {m, comps}
      end

    entries =
      for {m, comps} <- mods do
        {group_of(comps, snippets), m, comps}
      end

    groups =
      entries
      |> Enum.group_by(&elem(&1, 0), &{elem(&1, 1), elem(&1, 2)})
      |> Enum.sort_by(fn {g, _} -> g end)

    body =
      for {g, mods} <- groups do
        title = g |> String.replace(~r/^\d+ · /, "")

        [
          "### #{title}\n\n",
          for {m, comps} <- Enum.sort_by(mods, fn {m, _} -> inspect(m) end) do
            module_section(m, comps, snippets)
          end
        ]
      end

    section =
      IO.iodata_to_binary(["<!-- components:start -->\n\n", body, "<!-- components:end -->"])

    readme = File.read!(@readme)
    [pre, rest] = String.split(readme, "<!-- components:start -->", parts: 2)
    [_, post] = String.split(rest, "<!-- components:end -->", parts: 2)
    File.write!(@readme, pre <> section <> post)

    IO.puts(
      "README: #{length(entries)} módulos, #{Enum.sum(for {_, _, c} <- entries, do: length(c))} componentes"
    )
  end

  # grupo da vitrine em que mais se usa o módulo
  defp group_of(comps, snippets) do
    names = Enum.map(comps, fn {n, _} -> Atom.to_string(n) end)

    counts =
      for {g, code} <- snippets, n <- names, String.contains?(code, "<." <> n), reduce: %{} do
        acc -> Map.update(acc, g, 1, &(&1 + 1))
      end

    case Enum.max_by(counts, &elem(&1, 1), fn -> nil end) do
      {g, _} -> g
      nil -> "99 · Outros"
    end
  end

  defp module_section(m, comps, snippets) do
    name = m |> Module.split() |> List.last()
    {mdoc, fdocs} = docs(m)

    [
      "#### #{name}\n\n",
      if(mdoc != "", do: mdoc <> "\n\n", else: ""),
      for {fname, c} <- comps do
        example = example(m, fname, c, snippets)
        doc = Map.get(fdocs, fname, "")

        [
          "`<.#{fname}>`",
          if(doc != "", do: " — " <> doc, else: ""),
          "\n\n```heex\n",
          example,
          "\n```\n\n"
        ]
      end
    ]
  end

  defp docs(m) do
    case Code.fetch_docs(m) do
      {:docs_v1, _, _, _, mod, _, fdocs} ->
        fm =
          for {{:function, n, 1}, _, _, %{"en" => d}, _} <- fdocs,
              into: %{},
              do: {n, first_sentence(d)}

        {first_sentence(doc_text(mod)), fm}

      _ ->
        {"", %{}}
    end
  end

  defp doc_text(%{"en" => d}), do: d
  defp doc_text(_), do: ""

  defp first_sentence("#" <> _), do: ""

  defp first_sentence(text) do
    text
    |> String.split(~r/\n\s*\n/, parts: 2)
    |> hd()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> then(fn s ->
      case Regex.run(~r/^(.{0,160}?[.!?])(\s|$)/u, s) do
        [_, first | _] -> first
        _ -> shorten(s)
      end
    end)
    |> String.replace(~r/[\r\n]+/, " ")
  end

  defp shorten(s) do
    if String.length(s) <= 160 do
      s
    else
      (s |> String.slice(0, 157) |> String.replace(~r/\s+\S*$/, "")) <> "…"
    end
  end

  # ------------------------------------------------------------ exemplo
  defp example(_m, fname, c, snippets) do
    name = Atom.to_string(fname)

    found =
      for {_, code} <- snippets,
          el <- extract(code, name),
          do: el

    best =
      found
      |> Enum.map(&dedent/1)
      |> Enum.filter(&(length(String.split(&1, "\n")) <= 14 and String.length(&1) <= 700))
      |> Enum.reject(&String.contains?(&1, "lu-"))
      |> Enum.reject(&String.contains?(&1, "hugeicons:"))
      |> Enum.reject(&String.contains?(&1, "style=\""))
      |> Enum.uniq()
      |> Enum.sort_by(&{score(&1), String.length(&1)})
      |> Enum.find(&(LedgerUI.ReadmeCheck.check(&1, name) == :ok))

    case best do
      nil ->
        sk = skeleton(name, c)

        if LedgerUI.ReadmeCheck.check(sk, name) != :ok do
          IO.puts(:stderr, "ATENÇÃO: sem exemplo que compile para #{name}: #{sk}")
        end

        sk

      el ->
        el
    end
  end

  # elementos mais ricos (atributo ou conteúdo) primeiro
  defp score(el) do
    cond do
      String.length(el) < 25 -> 2
      not Regex.match?(~r/^<\.\w+\s+[\w:-]+[=\s>\/]/, el) -> 1
      true -> 0
    end
  end

  defp dedent(el) do
    lines = String.split(el, "\n")
    [first | rest] = lines

    indent =
      rest
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.map(fn l -> String.length(l) - String.length(String.trim_leading(l)) end)
      |> Enum.min(fn -> 0 end)

    Enum.join(
      [String.trim_leading(first) | Enum.map(rest, &String.slice(&1, indent..-1//1))],
      "\n"
    )
  end

  # todas as ocorrências `<.name ...>...</.name>` (ou autofechadas) no código
  defp extract(code, name) do
    open = "<." <> name
    scan(code, open, name, 0, [])
  end

  defp scan(code, open, name, from, acc) do
    case :binary.match(code, open, scope: {from, byte_size(code) - from}) do
      :nomatch ->
        Enum.reverse(acc)

      {pos, len} ->
        next = binary_part(code, pos + len, 1)

        if next in [" ", "\n", ">", "/", "\t"] do
          case el_end(code, pos, name) do
            nil -> scan(code, open, name, pos + len, acc)
            stop -> scan(code, open, name, pos + len, [binary_part(code, pos, stop - pos) | acc])
          end
        else
          scan(code, open, name, pos + len, acc)
        end
    end
  end

  # índice logo após o fim do elemento que abre em `pos`
  defp el_end(code, pos, name) do
    case tag_end(code, pos + 1, 0, nil) do
      {close, true} -> close
      {close, false} -> find_close(code, close, name, 1)
      nil -> nil
    end
  end

  # fim da tag de abertura: `>` fora de aspas e de chaves. Devolve {índice após o `>`, autofechada?}
  defp tag_end(code, i, _depth, _q) when i >= byte_size(code), do: nil

  defp tag_end(code, i, depth, q) do
    c = :binary.at(code, i)

    cond do
      q != nil and c == q -> tag_end(code, i + 1, depth, nil)
      q != nil -> tag_end(code, i + 1, depth, q)
      c in [?", ?'] and depth == 0 -> tag_end(code, i + 1, depth, c)
      c == ?{ -> tag_end(code, i + 1, depth + 1, nil)
      c == ?} -> tag_end(code, i + 1, max(depth - 1, 0), nil)
      c == ?> and depth == 0 -> {i + 1, i > 0 and :binary.at(code, i - 1) == ?/}
      true -> tag_end(code, i + 1, depth, nil)
    end
  end

  defp find_close(code, from, name, depth) do
    open = "<." <> name
    close = "</." <> name <> ">"

    o = :binary.match(code, open, scope: {from, byte_size(code) - from})
    c = :binary.match(code, close, scope: {from, byte_size(code) - from})

    case {o, c} do
      {_, :nomatch} ->
        nil

      {{op, ol}, {cp, _}} when op < cp ->
        n = binary_part(code, op + ol, 1)

        if n in [" ", "\n", ">", "/", "\t"] do
          case tag_end(code, op + 1, 0, nil) do
            {after_open, true} -> find_close(code, after_open, name, depth)
            {after_open, false} -> find_close(code, after_open, name, depth + 1)
            nil -> nil
          end
        else
          find_close(code, op + ol, name, depth)
        end

      {_, {cp, cl}} ->
        if depth == 1, do: cp + cl, else: find_close(code, cp + cl, name, depth - 1)
    end
  end

  # ------------------------------------------------------------ esqueleto
  defp skeleton(name, c) do
    attrs =
      for a <- c.attrs, a.required, a.name != :inner_block, do: attr_src(a)

    slots =
      for s <- c.slots, s.required, s.name != :inner_block, do: s

    inner? = Enum.any?(c.slots, &(&1.name == :inner_block and &1.required))
    body = Enum.map(slots, &slot_src/1) ++ if(inner?, do: ["Texto"], else: [])

    open = "<." <> name <> Enum.map_join(attrs, "", &(" " <> &1))

    if body == [] do
      open <> " />"
    else
      open <> ">\n" <> Enum.map_join(body, "\n", &("  " <> &1)) <> "\n</." <> name <> ">"
    end
  end

  defp attr_src(%{name: n, type: t, opts: opts}) do
    values = Keyword.get(opts, :values)

    cond do
      is_list(values) and values != [] -> ~s(#{n}="#{hd(values)}")
      t == :string -> ~s(#{n}="#{n}")
      t == :integer -> "#{n}={1}"
      t == :boolean -> "#{n}"
      t == :atom -> "#{n}={:#{n}}"
      true -> "#{n}={@#{n}}"
    end
  end

  defp slot_src(%{name: n, attrs: attrs}) do
    a = for at <- attrs, at.required, do: " " <> attr_src(at)
    "<:#{n}#{a}>Texto</:#{n}>"
  end
end

GenReadme.run()
