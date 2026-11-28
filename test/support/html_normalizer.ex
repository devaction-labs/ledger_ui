defmodule LedgerUI.HTMLNormalizer do
  @moduledoc """
  Normalizes rendered HTML for snapshot and parity comparisons (#109).

  The order of the attributes that come from `{@rest}` and of the keys of the JSON in `data-lu-*`
  depends on the atom table (small maps with atom keys are iterated in the order the atoms were
  created, which follows the order the modules were loaded), so two runs of the same code can print
  the same page with the attributes in another order. `normalize/1`:

    * sorts the attributes of every tag by name;
    * sorts the keys, at every depth, of the JSON in the `data-lu-*` attributes (`data-lu-config`...);
    * replaces the random id of `show_toast/1..3` (`toast-<digits>`) with `toast-N`.

  Never compare raw HTML between two runs or two checkouts: compare `normalize(a) == normalize(b)`.
  """

  @tag ~r/<([a-zA-Z][\w:.-]*)((?:\s+[^\s=>\/]+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>"']+))?)*)\s*(\/?)>/
  @attr ~r/([^\s=>\/]+)(?:\s*=\s*("[^"]*"|'[^']*'|[^\s>"']+))?/

  @spec normalize(String.t() | iodata()) :: String.t()
  def normalize(html) do
    html
    |> IO.iodata_to_binary()
    |> then(&Regex.replace(@tag, &1, fn _, name, attrs, close -> tag(name, attrs, close) end))
    |> String.replace(~r/toast-\d+/, "toast-N")
  end

  defp tag(name, attrs, close) do
    attrs =
      @attr
      |> Regex.scan(attrs)
      |> Enum.map(fn
        [_, key] -> {key, nil}
        [_, key, value] -> {key, value}
      end)
      |> Enum.map(&normalize_attr/1)
      |> Enum.sort()
      |> Enum.map(fn
        {key, nil} -> key
        {key, value} -> key <> "=" <> value
      end)

    "<" <> Enum.join([name | attrs], " ") <> close <> ">"
  end

  defp normalize_attr({"data-lu-" <> _ = key, "\"" <> _ = quoted}) do
    raw = quoted |> String.trim_leading("\"") |> String.trim_trailing("\"")

    case raw |> unescape() |> Jason.decode() do
      {:ok, decoded} when is_map(decoded) or is_list(decoded) ->
        json = decoded |> sort_json() |> Jason.encode!()
        {key, "\"" <> escape(json) <> "\""}

      _ ->
        {key, quoted}
    end
  end

  defp normalize_attr(attr), do: attr

  defp sort_json(map) when is_map(map) and not is_struct(map),
    do:
      map
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {k, v} -> {k, sort_json(v)} end)
      |> Jason.OrderedObject.new()

  defp sort_json(list) when is_list(list), do: Enum.map(list, &sort_json/1)
  defp sort_json(other), do: other

  defp unescape(s) do
    s
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
  end

  defp escape(s) do
    s
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
