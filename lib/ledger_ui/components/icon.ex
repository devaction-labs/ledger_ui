defmodule LedgerUI.Components.Icon do
  @moduledoc """
  Server-side SVG icons (Hugeicons Stroke Rounded), no JavaScript needed.

      <.icon name="download" />
      <.icon name="huge-download-01" size="sm" class="text-muted" />
      <.icon name="check-circle" boxed tone="success" />

  The SVG is styled only with Tailwind utilities (1.75 stroke; it follows `currentColor`, so it inherits the
  surrounding text colour and `text-*` colours it). `size` picks the box: `sm` 14px, `md` 16px, `base` 18px (default), `lg` 22px,
  `xl` 28px. Use `size`, not a `size-*` class, to change it: two utilities of one property in a
  class list are resolved by the stylesheet, not by their order.

      <svg class="... size-[18px]" viewBox="0 0 24 24" aria-hidden="true" data-icon="download">...</svg>

  Every icon is precomputed at compile time from `priv/icons.json` (regenerate it with
  `elixir scripts/extract_icons.exs`) as an iodata binary and emitted with `Phoenix.HTML.raw/1`,
  so rendering costs one map lookup.

  ## Names

  Dictionary keys (`download`, `chevron-down`, ...) are used as-is. The API's `huge-*` names
  are accepted too: `huge-` (or `hugeicons:`) is stripped, then the exact key is tried, then
  the key without a trailing `-NN` suffix (`huge-download-01` -> `download-01` -> `download`).
  Unknown names render nothing and log a warning (disable with
  `config :ledger_ui, warn_unknown_icons: false`).

  ## Vendored icons

  Icons outside the dictionary come from the app's own folder, filled by `mix ledger_ui.icons`
  (`get`, `sync`; see `LedgerUI.Icons`):

      config :ledger_ui, :icons_path, "priv/hugeicons"

      <.icon name="huge-invoice-01" />

  They are loaded once into `:persistent_term` and render the same markup as the built-in ones.
  Order of lookup: a built-in key (exact, after dropping `huge-`), then a vendored file of that
  name, then the built-in key without its `-NN` suffix. So a built-in name always wins over a
  vendored file of the same name, while `huge-download-01` finds the vendored `download-01.svg`
  before settling for the built-in `download`.

  ## Box

  `boxed` wraps the icon in a rounded square box (40px, radius 8px, panel background, 1px `line` border, 20px
  icon in `ink`; 48px with `box_size="lg"`). Without `tone` the box is neutral; `tone` colours it (`accent`/`acc`, `success`/`pos`,
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
           # {head, mid, tail}: the class string goes between head and mid, the extra attrs
           # between mid and tail.
           {name,
            {~s(<svg class="), ~s(" viewBox="0 0 24 24" aria-hidden="true" data-icon="#{name}"),
             ~s(>#{inner}</svg>)}}
         end)

  @sizes %{
    "sm" => "size-3.5",
    "md" => "size-4",
    "base" => "size-[18px]",
    "lg" => "size-[22px]",
    "xl" => "size-7"
  }

  @base "inline flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round] align-middle"

  # the icon inside a box is always 20px (the descendant selector outranks the svg's own size class)
  @box "inline-grid flex-none place-items-center border [&>svg]:size-5"

  # the tone sets background + icon colour; `lg` is the large box (48px, radius 12px)
  @tones %{
    "neutral" => "bg-panel text-ink border-line",
    "accent" => "bg-accent-soft text-accent-content border-transparent",
    "acc" => "bg-accent-soft text-accent-content border-transparent",
    "success" => "bg-pos-soft text-pos border-transparent",
    "pos" => "bg-pos-soft text-pos border-transparent",
    "error" => "bg-neg-soft text-neg border-transparent",
    "neg" => "bg-neg-soft text-neg border-transparent",
    "warning" => "bg-warn-soft text-warn border-transparent",
    "warn" => "bg-warn-soft text-warn border-transparent",
    "info" => "bg-info-soft text-info border-transparent",
    "lime" => "bg-lime-soft text-lime border-transparent"
  }

  @box_sizes %{"md" => "size-10 rounded-md", "lg" => "size-12 rounded-lg"}

  @doc "Names of all icons in the built-in dictionary."
  def names, do: Map.keys(@icons)

  @doc """
  Whether `name` (with or without `huge-`) is a key of the built-in dictionary.

  `mix ledger_ui.icons sync` skips these: they need no download.
  """
  @spec builtin?(String.t()) :: boolean()
  def builtin?(name) when is_binary(name),
    do: Map.has_key?(@icons, name) or Map.has_key?(@icons, strip_prefix(name))

  @doc false
  # The `{head, mid, tail}` render parts of an icon whose shapes are `inner`.
  def parts(name, inner) do
    {~s(<svg class="), ~s(" viewBox="0 0 24 24" aria-hidden="true" data-icon="#{name}"),
     ~s(>#{inner}</svg>)}
  end

  # Built-in exact, vendored, built-in without the `-NN` suffix.
  defp lookup(nil), do: nil

  defp lookup(name) do
    base = strip_prefix(name)

    cond do
      parts = @icons[name] -> parts
      parts = @icons[base] -> parts
      parts = LedgerUI.Icons.fetch(base) -> parts
      key = strip_suffix(base) -> @icons[key]
      true -> nil
    end
  end

  defp strip_prefix("huge-" <> rest), do: rest
  defp strip_prefix("hugeicons:" <> rest), do: rest
  defp strip_prefix(other), do: other

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
    base = strip_prefix(name)

    cond do
      Map.has_key?(@icons, name) -> name
      Map.has_key?(@icons, base) -> base
      true -> strip_suffix(base)
    end
  end

  defp strip_suffix(base) do
    stripped = strip_digits(base)
    if Map.has_key?(@icons, stripped), do: stripped
  end

  # Same as `~r/-\d+$/` replaced by "": drops a trailing `-<digits>` (at most one; `\d` is ASCII here).
  defp strip_digits(base) do
    case :binary.matches(base, "-") do
      [] ->
        base

      matches ->
        {pos, _} = List.last(matches)
        size = byte_size(base) - pos - 1
        tail = binary_part(base, pos + 1, size)
        if size > 0 and all_digits?(tail), do: binary_part(base, 0, pos), else: base
    end
  end

  defp all_digits?(<<c, rest::binary>>) when c in ?0..?9, do: all_digits?(rest)
  defp all_digits?(<<>>), do: true
  defp all_digits?(_), do: false

  attr :name, :string, default: nil, doc: "Icon name (dictionary key or `huge-*`)."

  attr :size, :string,
    default: "base",
    values: [nil | Map.keys(@sizes)],
    doc: "`sm` 14px, `md` 16px, `base` 18px, `lg` 22px, `xl` 28px (`nil` is `base`)."

  attr :class, :any, default: nil
  attr :boxed, :boolean, default: false, doc: "Wraps the icon in a rounded square box."

  attr :tone, :string,
    default: nil,
    values: [nil | Map.keys(@tones)],
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
    sized? = box_style(a.box_size) != nil

    cx([
      @box,
      # an explicit pixel size comes as inline style: no `size-*` class to compete with
      !sized? && (@box_sizes[a.box_size] || @box_sizes["md"]),
      sized? && "rounded-md",
      @tones[a.tone || "neutral"],
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
    case lookup(name) do
      nil ->
        if name && warn?(), do: Logger.warning("LedgerUI icon not found: #{inspect(name)}")
        {:safe, ""}

      {head, mid, tail} ->
        {:safe, [head, class_part(assigns), mid, attrs_part(rest), tail]}
    end
  end

  defp warn?, do: Application.get_env(:ledger_ui, :warn_unknown_icons, true)

  @doc """
  The class string of an icon's `<svg>` for a `size` (`sm`, `md`, `base`, `lg`, `xl`): for hooks that create SVGs
  in JS (send it in the hook's config).
  """
  def svg_class(size \\ "base"), do: cx([@base, @sizes[size] || @sizes["base"]])

  defp class_part(assigns) do
    elem(Phoenix.HTML.html_escape(cx([@base, @sizes[assigns.size || "base"], assigns.class])), 1)
  end

  defp attrs_part(rest) when rest == %{} or rest == [], do: ""
  defp attrs_part(rest), do: [?\s | elem(Phoenix.HTML.attributes_escape(rest), 1)]
end
