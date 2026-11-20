# Extrai o dicionário ICONS de priv/static/ledger.js para priv/icons.json.
#
#     elixir scripts/extract_icons.exs
#
# Requer jason (usa Mix.install).
Mix.install([{:jason, "~> 1.4"}])

root = Path.expand("..", __DIR__)
js = File.read!(Path.join(root, "priv/static/ledger.js"))

[_, json] = Regex.run(~r/var ICONS = (\{.*\});\n/U, js)
icons = Jason.decode!(json)

sorted = icons |> Enum.sort() |> Jason.OrderedObject.new()
File.write!(Path.join(root, "priv/icons.json"), Jason.encode!(sorted, pretty: true) <> "\n")
IO.puts("#{map_size(icons)} icons -> priv/icons.json")
