defmodule LedgerUI.Icons.Hugeicons do
  @moduledoc """
  Reads Hugeicons Stroke Rounded SVGs and converts them to the kit's stroke format.

  Upstream files hard-code `stroke="#141B34"`, `stroke-width="1.5"` and the line caps on every
  shape. The kit's dictionary (`priv/icons.json`) keeps only the shapes and lets the `<svg>` that
  `LedgerUI.Components.Icon` renders supply `stroke: currentColor`, the 1.5 width and the round caps,
  so `convert/1` does the same: it keeps the geometry, drops the stroke attributes and the `fill="none"`, and turns a
  solid fill into `fill="currentColor" stroke="none"`. Only shape elements and a fixed list of
  attributes survive, so a vendored file can never inject script or styles.

  `names_in/1` finds the icon names a source file uses, for `mix ledger_ui.icons sync`.
  """

  @shapes ~w(path circle ellipse rect line polyline polygon)
  @geometry ~w(d cx cy r rx ry x y x1 y1 x2 y2 width height points transform fill-rule clip-rule
               opacity fill-opacity)
  @svg_open ~s(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" ) <>
              ~s(stroke-linecap="round" stroke-linejoin="round">)

  @tag_regex ~r/<(#{Enum.join(@shapes, "|")})\b([^>]*?)\/?>/s
  @attr_regex ~r/([a-zA-Z][a-zA-Z0-9:-]*)\s*=\s*"([^"]*)"/
  @icon_tag_regex ~r/<\.icon\b[^>]*?\bname=["']([a-z0-9:_-]+)["']/s
  @huge_regex ~r/(?<![A-Za-z0-9_-])huge-([a-z0-9]+(?:-[a-z0-9]+)*)/
  @extensions ~w(.ex .exs .heex .eex .leex .js .jsx .ts .tsx .html)

  @doc """
  Converts an upstream SVG to the kit's format: the inner shapes only, as a string.

  Returns `{:ok, inner}` or `{:error, :no_shapes}`.

      iex> svg = ~s(<svg viewBox="0 0 24 24" fill="none"><path d="M1 1L2 2" stroke="#141B34" stroke-width="1.5"/></svg>)
      iex> LedgerUI.Icons.Hugeicons.convert(svg)
      {:ok, ~s(<path d="M1 1L2 2"/>)}
  """
  @spec convert(binary()) :: {:ok, String.t()} | {:error, :no_shapes}
  def convert(svg) when is_binary(svg) do
    shapes =
      @tag_regex
      |> Regex.scan(svg, capture: :all_but_first)
      |> Enum.map(fn [tag, attrs] -> shape(tag, attributes(attrs)) end)

    case shapes do
      [] -> {:error, :no_shapes}
      _ -> {:ok, Enum.join(shapes)}
    end
  end

  defp attributes(text) do
    @attr_regex |> Regex.scan(text, capture: :all_but_first) |> Enum.map(fn [k, v] -> {k, v} end)
  end

  defp shape(tag, attrs) do
    kept = for {k, v} <- attrs, k in @geometry, do: {k, v}
    fill = Enum.find_value(attrs, fn {k, v} -> if k == "fill", do: v end)
    stroke = Enum.find_value(attrs, fn {k, v} -> if k == "stroke", do: v end)

    extra =
      if solid?(fill),
        do:
          [{"fill", "currentColor"}] ++
            if(stroke in [nil, "none"], do: [{"stroke", "none"}], else: []),
        else: []

    "<#{tag}" <> render(kept ++ extra) <> "/>"
  end

  defp solid?(nil), do: false
  defp solid?("none"), do: false
  defp solid?(_), do: true

  defp render(attrs),
    do: Enum.map_join(attrs, fn {k, v} -> ~s( #{k}="#{escape(v)}") end)

  defp escape(value), do: value |> String.replace("&", "&amp;") |> String.replace("\"", "&quot;")

  @doc "Wraps converted inner shapes in a standalone `<svg>` (what the task vendors)."
  @spec wrap(String.t()) :: String.t()
  def wrap(inner), do: @svg_open <> "\n  " <> inner <> "\n</svg>\n"

  @doc """
  The inner shapes of a vendored file (what `wrap/1` wrote), or `:error` when it is not an SVG.
  Run through `convert/1` again, so a hand-edited file is sanitized the same way.
  """
  @spec inner(binary()) :: {:ok, String.t()} | :error
  def inner(svg) do
    case convert(svg) do
      {:ok, inner} -> {:ok, inner}
      {:error, _} -> :error
    end
  end

  @doc "Sorted, unique icon names (without `huge-`) used by `<.icon name=\"...\">` or written as `huge-*`."
  @spec names_in(String.t()) :: [String.t()]
  def names_in(text) do
    tagged =
      @icon_tag_regex
      |> Regex.scan(text, capture: :all_but_first)
      |> List.flatten()
      |> Enum.map(&strip_prefix/1)

    huge = @huge_regex |> Regex.scan(text, capture: :all_but_first) |> List.flatten()
    (tagged ++ huge) |> Enum.filter(&valid_name?/1) |> Enum.uniq() |> Enum.sort()
  end

  @doc "Names in every source file under `roots`."
  @spec scan([String.t()]) :: [String.t()]
  def scan(roots) do
    roots
    |> Enum.flat_map(&source_files/1)
    |> Enum.flat_map(&names_in(File.read!(&1)))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_files(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.reject(&String.contains?(&1, ["/node_modules/", "/_build/", "/deps/"]))
    |> Enum.filter(&(Path.extname(&1) in @extensions and File.regular?(&1)))
  end

  @doc "`\"huge-x\"`, `\"hugeicons:x\"` and `\"x\"` all become `\"x\"`."
  @spec strip_prefix(String.t()) :: String.t()
  def strip_prefix("huge-" <> rest), do: rest
  def strip_prefix("hugeicons:" <> rest), do: rest
  def strip_prefix(name), do: name

  @doc "Whether `name` looks like an upstream file name (`search-01`)."
  @spec valid_name?(String.t()) :: boolean()
  def valid_name?(name), do: Regex.match?(~r/\A[a-z0-9]+(-[a-z0-9]+)*\z/, name)
end
