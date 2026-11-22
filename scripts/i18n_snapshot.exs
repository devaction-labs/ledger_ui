# HTML snapshot of every component with default attrs (plus hand-picked text-heavy renders).
#
#     MIX_ENV=test mix run scripts/i18n_snapshot.exs /tmp/after.html [scripts/i18n_snapshot_cases.exs]
#
# Run it in two checkouts (before/after a change) and `diff` the outputs. Rendering is
# deterministic; required attrs/slots are filled with dummy values by type, and optional
# slots are rendered too, so every default text of the component shows up.
defmodule I18nSnapshot do
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  def dummy(%{name: n, type: t, opts: opts}) do
    values = Keyword.get(opts, :values)

    cond do
      Keyword.has_key?(opts, :default) and not is_nil(opts[:default]) -> opts[:default]
      is_list(values) and values != [] -> hd(values)
      true -> by_type(n, t)
    end
  end

  defp by_type(_n, :string), do: "x"
  defp by_type(_n, :integer), do: 1
  defp by_type(_n, :float), do: 1.0
  defp by_type(_n, :boolean), do: true
  defp by_type(_n, :atom), do: :x
  defp by_type(_n, :list), do: []
  defp by_type(_n, :map), do: %{}
  defp by_type(_n, :global), do: %{}
  defp by_type(_n, {:struct, Phoenix.HTML.Form}), do: nil
  defp by_type(_n, _), do: "x"

  def slot_entry(name, attrs) do
    base =
      for a <- attrs, a.required, into: %{}, do: {a.name, dummy(a)}

    Map.merge(base, %{
      __slot__: name,
      inner_block: fn _, _ -> "SLOT-#{name}" end
    })
  end

  def assigns_for(info, all_slots?) do
    attrs =
      for a <- info.attrs, a.type != :global, a.required, into: %{}, do: {a.name, dummy(a)}

    slots =
      for s <- info.slots, s.required or all_slots?, into: %{} do
        {s.name, [slot_entry(s.name, s.attrs)]}
      end

    attrs |> Map.merge(slots) |> Map.put(:__changed__, nil)
  end

  def render(mod, name, assigns) do
    try do
      rendered_to_string(apply(mod, name, [assigns]))
    rescue
      e ->
        "ERROR: " <>
          (e.__struct__ |> inspect()) <>
          " " <> (Exception.message(e) |> String.split("\n") |> hd() |> String.slice(0, 60))
    catch
      k, v -> "ERROR: #{inspect({k, v})}" |> String.slice(0, 200)
    end
  end

  # `Jason` writes the keys of a small map in atom-table order (the order the atoms were created
  # in the VM), which changes when unrelated code adds atoms: so the JSON of `data-*="{...}"`
  # attributes is re-encoded with sorted keys before diffing.
  def canonical(html) do
    Regex.replace(~r/="((?:\{|\[)[^"]*&quot;[^"]*)"/, html, fn whole, json ->
      raw =
        json
        |> String.replace("&quot;", "\"")
        |> String.replace("&#39;", "'")
        |> String.replace("&lt;", "<")
        |> String.replace("&gt;", ">")
        |> String.replace("&amp;", "&")

      case Jason.decode(raw) do
        {:ok, data} -> "=\"" <> (data |> sort() |> Jason.encode!() |> escape()) <> "\""
        _ -> whole
      end
    end)
  end

  defp sort(m) when is_map(m),
    do:
      m
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {k, v} -> {k, sort(v)} end)
      |> Jason.OrderedObject.new()

  defp sort(l) when is_list(l), do: Enum.map(l, &sort/1)
  defp sort(v), do: v

  defp escape(s),
    do:
      s
      |> String.replace("&", "&amp;")
      |> String.replace("\"", "&quot;")
      |> String.replace("'", "&#39;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")

  # The attributes that come from a `:global` map are written in atom-table order too: sort them.
  def sort_attrs(html) do
    Regex.replace(~r/<([A-Za-z][\w:.-]*)((?:\s+[^\s=>"\/]+(?:="[^"]*")?)+)\s*(\/?)>/s, html, fn _,
                                                                                                tag,
                                                                                                attrs,
                                                                                                close ->
      list =
        ~r/[^\s=>"\/]+(?:="[^"]*")?/
        |> Regex.scan(attrs)
        |> List.flatten()
        |> Enum.sort()

      "<" <> tag <> " " <> Enum.join(list, " ") <> close <> ">"
    end)
  end

  # A hand-written case: `assigns` are merged over the attrs' defaults (the declarative wrapper
  # fills the missing ones) and rendered like the generic ones.
  def render_case(mod, name, assigns) do
    mod |> render(name, Map.put(assigns, :__changed__, nil)) |> canonical() |> sort_attrs()
  end

  def run do
    for mod <- Enum.sort_by(LedgerUI.Components.__modules__(), &inspect/1),
        {name, info} <- Enum.sort(mod.__components__()),
        function_exported?(mod, name, 1),
        variant <- [:required, :all_slots] do
      html =
        mod
        |> render(name, assigns_for(info, variant == :all_slots))
        |> canonical()
        |> sort_attrs()

      "<!-- #{inspect(mod)}.#{name} #{variant} -->\n#{html}\n"
    end
  end
end

[out | extra] = System.argv()

# `I18N_LOCALE=pt_BR` renders everything with the process locale (a smoke test: no crash, Portuguese)
if locale = System.get_env("I18N_LOCALE"), do: LedgerUI.put_locale(locale)

generic = I18nSnapshot.run()

manual =
  for f <- extra, f != "", reduce: [] do
    acc ->
      {res, _} = Code.eval_file(f)
      acc ++ res
  end

File.write!(out, Enum.join(generic ++ manual, "\n"))
IO.puts("wrote #{out}: #{length(generic)} generic + #{length(manual)} manual renders")
