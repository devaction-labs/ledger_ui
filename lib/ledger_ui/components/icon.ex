defmodule LedgerUI.Components.Icon do
  @moduledoc """
  Server-side SVG icons (Hugeicons Stroke Rounded), no JavaScript needed.

      <.icon name="download" />
      <.icon name="huge-download-01" size="sm" class="muted" />
      <.icon name="check-circle" boxed tone="success" />

  The output is identical to what `LedgerUI.hydrate()` produces from `<i data-i="name">`:

      <svg class="lu-i sm" viewBox="0 0 24 24" aria-hidden="true" data-icon="download">...</svg>

  Every icon is precomputed at compile time from `priv/icons.json` (regenerate it with
  `elixir scripts/extract_icons.exs`) as an iodata binary and emitted with `Phoenix.HTML.raw/1`,
  so rendering costs one map lookup.

  ## Names

  Dictionary keys (`download`, `chevron-down`, ...) are used as-is. The API's `huge-*` names
  are accepted too: `huge-` (or `hugeicons:`) is stripped, then the exact key is tried, then
  the key without a trailing `-NN` suffix (`huge-download-01` -> `download-01` -> `download`).
  Unknown names render nothing and log a warning (disable with
  `config :ledger_ui, warn_unknown_icons: false`).

  ## Box

  `boxed` wraps the icon in the `lu-ic` box; `tone` colours it (`accent`/`acc`, `success`/`pos`,
  `error`/`neg`, `warning`/`warn`, `info`, `lime`, `neutral`). `box_size="lg"` gives the large
  box; any number of pixels sets width/height inline. The inner block replaces `name`.
  """
  use LedgerUI.Component
  require Logger

  @external_resource Path.expand("../../../priv/icons.json", __DIR__)

  @icons @external_resource
         |> File.read!()
         |> Jason.decode!()
         |> Map.new(fn {name, inner} ->
           # {head, tail}: the class string goes between them.
           {name,
            {~s(<svg class="lu-i),
             ~s(" viewBox="0 0 24 24" aria-hidden="true" data-icon="#{name}"),
             ~s(>#{inner}</svg>)}}
         end)

  @styles %{
    "box" => "lu-ic",
    "tone" => %{
      "neutral" => nil,
      "accent" => "acc",
      "acc" => "acc",
      "success" => "pos",
      "pos" => "pos",
      "error" => "neg",
      "neg" => "neg",
      "warning" => "warn",
      "warn" => "warn",
      "info" => "info",
      "lime" => "lime"
    },
    "box_size" => %{"lg" => "lg"}
  }

  @doc "Names of all icons in the dictionary."
  def names, do: Map.keys(@icons)

  @doc """
  Resolves an API name to a dictionary key (see module docs), or `nil`.

      iex> LedgerUI.Components.Icon.resolve("huge-download-01")
      "download"
      iex> LedgerUI.Components.Icon.resolve("nope")
      nil
  """
  @spec resolve(String.t() | nil) :: String.t() | nil
  def resolve(nil), do: nil

  def resolve(name) when is_binary(name) do
    base =
      case name do
        "huge-" <> rest -> rest
        "hugeicons:" <> rest -> rest
        other -> other
      end

    cond do
      Map.has_key?(@icons, name) -> name
      Map.has_key?(@icons, base) -> base
      true -> strip_suffix(base)
    end
  end

  defp strip_suffix(base) do
    stripped = Regex.replace(~r/-\d+$/, base, "")
    if Map.has_key?(@icons, stripped), do: stripped, else: nil
  end

  attr :name, :string, default: nil, doc: "Icon name (dictionary key or `huge-*`)."
  attr :size, :string, default: nil, values: [nil, "sm", "md", "lg", "xl"]
  attr :class, :any, default: nil
  attr :boxed, :boolean, default: false, doc: "Wraps the icon in the `lu-ic` box."

  attr :tone, :string,
    default: nil,
    values: [nil | Map.keys(@styles["tone"])],
    doc: "Box colour (needs `boxed`)."

  attr :box_size, :any, default: nil, doc: ~s(`"lg"` or a size in pixels.)
  attr :box_class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "Own SVG inside the box, instead of `name`."

  def icon(%{boxed: true} = assigns) do
    assigns =
      assigns
      |> assign(:svg, svg(assigns.name, assigns, []))
      |> assign(:box_class_s, box_class(assigns))
      |> assign(:box_attrs, box_attrs(assigns))

    ~H"""
    <span data-part="icon-box" class={@box_class_s} {@box_attrs}>
      {if @inner_block == [], do: @svg, else: render_slot(@inner_block)}
    </span>
    """
  end

  def icon(assigns) do
    assigns = assign(assigns, :svg, svg(assigns.name, assigns, assigns.rest))
    ~H"{@svg}"
  end

  defp box_class(a) do
    cx([
      @styles["box"],
      @styles["tone"][a.tone],
      is_binary(a.box_size) && @styles["box_size"][a.box_size],
      a.box_class
    ])
  end

  # `style` goes in a map: `style={nil}` would render `style=""`.
  defp box_attrs(a) do
    case box_style(a.box_size) do
      nil -> a.rest
      style -> Map.put(a.rest, :style, style)
    end
  end

  defp box_style(size) when is_integer(size), do: "width:#{size}px;height:#{size}px"

  defp box_style(size) when is_binary(size) do
    if Regex.match?(~r/^\d+$/, size), do: box_style(String.to_integer(size)), else: nil
  end

  defp box_style(_), do: nil

  # In a box the rest attrs go to the box, so `rest` is `[]` there.
  defp svg(name, assigns, rest) do
    case @icons[resolve(name)] do
      nil ->
        if name && warn?(), do: Logger.warning("LedgerUI icon not found: #{inspect(name)}")
        {:safe, ""}

      {head, mid, tail} ->
        {:safe, [head, class_part(assigns), mid, attrs_part(rest), tail]}
    end
  end

  defp warn?, do: Application.get_env(:ledger_ui, :warn_unknown_icons, true)

  defp class_part(assigns) do
    case cx([assigns.size, assigns.class]) do
      "" -> ""
      cls -> [?\s | elem(Phoenix.HTML.html_escape(cls), 1)]
    end
  end

  defp attrs_part(rest) when rest == %{} or rest == [], do: ""
  defp attrs_part(rest), do: [?\s | elem(Phoenix.HTML.attributes_escape(rest), 1)]
end
