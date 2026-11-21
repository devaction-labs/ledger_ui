defmodule LedgerUI.Components.Palette do
  @moduledoc """
  Swatches of the kit palette: the accent scale, warm-neutral base, status signals and chart
  series. Colours are read from the tokens (`var(--lu-ink)`, `bg-accent-500`), so the swatches
  follow the theme (light, dark, any palette and any `--color-accent`).

      <.palette variant="ramp" />
      <.palette variant="chips" scale="gray" />
      <.palette
        cols={6}
        colors={[
          %{token: "--bg-page", name: "Página", light: "#ffffff", dark: "#0e100f"},
          %{token: "--ink", name: "Ink", light: "#141514", dark: "#f2f3f2"}
        ]}
      />

  ## Variants

    * `swatches` (default): a grid of cards, one per entry of `colors` with the colour, its name,
      the token and (when given) the `light` and `dark` hex values. `cols` is the number of
      columns. `token` is a kit token (`"--bg-page"` or `"--lu-bg-page"`, both read
      `var(--lu-bg-page)`).
    * `ramp`: the full `scale` (`accent` by default, or `gray`) as a strip of labelled steps
      (`steps`, `50..900` by default), the label turning white from step 400.
    * `chips`: the same scale as a row of small rounded chips, appearing one after the other.

  Styled only with Tailwind utilities.
  """
  use LedgerUI.Component

  @steps ~w(50 100 200 300 400 500 600 700 800 900)

  # Static class strings (Tailwind finds them here): a step of a scale is its background, and the
  # label is the darkest step on the light ones and white from step 400.
  @scales %{
    "accent" => %{
      "50" => {"bg-accent-50", "text-accent-900"},
      "100" => {"bg-accent-100", "text-accent-900"},
      "200" => {"bg-accent-200", "text-accent-900"},
      "300" => {"bg-accent-300", "text-accent-900"},
      "400" => {"bg-accent-400", "text-white"},
      "500" => {"bg-accent-500", "text-white"},
      "600" => {"bg-accent-600", "text-white"},
      "700" => {"bg-accent-700", "text-white"},
      "800" => {"bg-accent-800", "text-white"},
      "900" => {"bg-accent-900", "text-white"}
    },
    "gray" => %{
      "50" => {"bg-gray-50", "text-gray-900"},
      "100" => {"bg-gray-100", "text-gray-900"},
      "200" => {"bg-gray-200", "text-gray-900"},
      "300" => {"bg-gray-300", "text-gray-900"},
      "400" => {"bg-gray-400", "text-white"},
      "500" => {"bg-gray-500", "text-white"},
      "600" => {"bg-gray-600", "text-white"},
      "700" => {"bg-gray-700", "text-white"},
      "800" => {"bg-gray-800", "text-white"},
      "900" => {"bg-gray-900", "text-white"},
      "950" => {"bg-gray-950", "text-white"}
    }
  }

  attr :variant, :string, default: "swatches", values: ~w(swatches ramp chips)

  attr :colors, :list,
    default: [],
    doc: "`swatches`: maps with `:token` (`\"--bg-page\"`), `:name`, `:light`, `:dark`."

  attr :cols, :integer, default: 6, doc: "`swatches`: number of columns."

  attr :scale, :string,
    default: "accent",
    values: Map.keys(@scales),
    doc: "`ramp` and `chips`: the colour scale (the theme's `accent`, or `gray`)."

  attr :steps, :list, default: @steps, doc: "`ramp` and `chips`: the steps of the scale."
  attr :class, :any, default: nil
  attr :rest, :global

  def palette(%{variant: "ramp"} = assigns) do
    assigns = assign(assigns, :items, items(assigns.scale, assigns.steps))

    ~H"""
    <div
      data-part="palette"
      class={[
        "grid grid-cols-[repeat(10,1fr)] overflow-hidden rounded-[12px] border border-line",
        @class
      ]}
      {@rest}
    >
      <div
        :for={i <- @items}
        data-part="palette-step"
        class={[
          "flex h-[72px] flex-col justify-end px-2 py-1.5 font-mono text-[11px]",
          i.bg,
          i.text
        ]}
      >
        {i.step}
      </div>
    </div>
    """
  end

  def palette(%{variant: "chips"} = assigns) do
    assigns =
      assign(assigns, :items, assigns.scale |> items(assigns.steps) |> Enum.with_index())

    ~H"""
    <div data-part="palette" class={["flex flex-wrap items-center gap-1.5", @class]} {@rest}>
      <i
        :for={{i, n} <- @items}
        data-part="palette-chip"
        class={[
          "block size-11 rounded-[10px] [animation-delay:var(--dl)]",
          "animate-[mo-stg_7s_cubic-bezier(.2,.8,.2,1)_infinite]",
          i.bg
        ]}
        style={"--dl:#{delay(n)}s"}
      ></i>
    </div>
    """
  end

  def palette(assigns) do
    assigns =
      assigns
      |> assign(:cols_style, "--cols:#{assigns.cols}")
      |> assign(:items, Enum.map(assigns.colors, &swatch_item/1))

    ~H"""
    <div
      data-part="palette"
      class={["grid grid-cols-[repeat(var(--cols),minmax(0,1fr))] gap-2.5", @class]}
      style={@cols_style}
      {@rest}
    >
      <div
        :for={i <- @items}
        data-part="palette-swatch"
        class="overflow-hidden rounded-[12px] border border-line bg-panel"
      >
        <div data-part="palette-color" class="h-16" style={i.style}></div>
        <div data-part="palette-meta" class="flex flex-col gap-px px-2.5 py-2">
          <b data-part="palette-name" class="text-[12.5px] font-semibold">{i.name}</b><span
            data-part="palette-token"
            class="font-mono text-[11px] text-muted"
          >{i.token}</span><span
            :if={i.values}
            data-part="palette-values"
            class="font-mono text-[11px] text-muted"
          >{i.values}</span>
        </div>
      </div>
    </div>
    """
  end

  defp items(scale, steps) do
    scale_map = Map.fetch!(@scales, scale)

    for step <- steps, step = to_string(step), Map.has_key?(scale_map, step) do
      {bg, text} = scale_map[step]
      %{step: step, bg: bg, text: text}
    end
  end

  defp delay(i), do: :erlang.float_to_binary(i * 0.12, decimals: 2)

  defp swatch_item(color) do
    token = to_string(color[:token])

    values =
      case {color[:light], color[:dark]} do
        {nil, nil} -> nil
        {light, nil} -> light
        {nil, dark} -> dark
        {light, dark} -> "#{light} · #{dark}"
      end

    %{
      style: "background:var(#{kit_var(token)})",
      name: color[:name],
      token: token,
      values: values
    }
  end

  # `--bg-page` (the design's name) and `--lu-bg-page` are the same token.
  defp kit_var("--lu-" <> _ = token), do: token
  defp kit_var("--" <> name), do: "--lu-" <> name
  defp kit_var(token), do: token
end
