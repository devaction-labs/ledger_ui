# Regenerates the imports and the Hooks map of priv/static/ledger_ui.esm.js from the files in
# priv/static/ledger_ui/hooks/ (dropdown.js -> "LedgerUI.Dropdown"; my_hook.js -> "LedgerUI.MyHook").
#
#     elixir scripts/gen_hooks_index.exs

root = Path.expand("..", __DIR__)
entry = Path.join(root, "priv/static/ledger_ui.esm.js")

files =
  root
  |> Path.join("priv/static/ledger_ui/hooks/*.js")
  |> Path.wildcard()
  |> Enum.sort()

entries =
  for file <- files do
    base = Path.basename(file, ".js")
    camel = base |> String.split(["_", "-"], trim: true) |> Enum.map_join(&String.capitalize/1)
    {base, camel}
  end

imports =
  Enum.map_join(entries, "\n", fn {base, camel} ->
    ~s(import Hook#{camel} from "./ledger_ui/hooks/#{base}.js")
  end)

map =
  Enum.map_join(entries, "\n", fn {_base, camel} ->
    ~s(  "LedgerUI.#{camel}": Hook#{camel},)
  end)

replace = fn src, tag, body ->
  re = ~r/(\/\/ GENERATED:#{tag}:START\n).*?(\/\/ GENERATED:#{tag}:END)/s
  Regex.replace(re, src, fn _, s, e -> s <> if(body == "", do: "", else: body <> "\n") <> e end)
end

entry
|> File.read!()
|> replace.("IMPORTS", imports)
|> replace.("HOOKS", map)
|> then(&File.write!(entry, &1))

IO.puts("#{length(entries)} hooks registered")
