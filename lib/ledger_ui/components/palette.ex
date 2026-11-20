defmodule LedgerUI.Components.Palette do
  @moduledoc """
  Swatches of the kit palette: a warm-neutral base with a teal brand scale, status signals and
  chart series. Colours are always read from the tokens (`var(--teal-500)`), so the swatches
  follow the theme.

      <.palette variant="ramp" />
      <.palette variant="chips" scale="teal" />
      <.palette
        cols={6}
        colors={[
          %{token: "--bg-page", name: "Página", light: "#ffffff", dark: "#0e100f"},
          %{token: "--ink", name: "Ink", light: "#141514", dark: "#f2f3f2"}
        ]}
      />

  ## Variants

    * `swatches` (default): a grid of `lu-swc` cards, one per entry of `colors` with the colour,
      its name, the token and (when given) the `light` and `dark` hex values. `cols` is the
      number of columns.
    * `ramp`: the full `scale` (`teal` by default) as a strip of labelled steps (`steps`,
      `50..900` by default), the label turning white from step 400.
    * `chips`: the same scale as a row of small rounded chips, appearing one after the other
      (`lu-palrow`).
  """
  use LedgerUI.Component

  @steps ~w(50 100 200 300 400 500 600 700 800 900)
  @dark_text ~w(50 100 200 300)
  @chip "display:block;width:44px;height:44px;border-radius:10px"

  attr :variant, :string, default: "swatches", values: ~w(swatches ramp chips)

  attr :colors, :list,
    default: [],
    doc: "`swatches`: maps with `:token` (`\"--bg-page\"`), `:name`, `:light`, `:dark`."

  attr :cols, :integer, default: 6, doc: "`swatches`: number of columns."

  attr :scale, :string,
    default: "teal",
    doc: "`ramp` and `chips`: the colour scale (`--<scale>-<step>`)."

  attr :steps, :list, default: @steps, doc: "`ramp` and `chips`: the steps of the scale."
  attr :class, :any, default: nil
  attr :rest, :global

  def palette(%{variant: "ramp"} = assigns) do
    assigns = assign(assigns, :items, Enum.map(assigns.steps, &ramp_item(assigns.scale, &1)))

    ~H"""
    <div data-part="palette" class={cx(["lu-ramp", @class])} {@rest}>
      <div :for={i <- @items} style={i.style}>{i.step}</div>
    </div>
    """
  end

  def palette(%{variant: "chips"} = assigns) do
    assigns = assign(assigns, :items, chip_items(assigns.scale, assigns.steps))

    ~H"""
    <div data-part="palette" class={cx(["lu-row lu-palrow", @class])} style="gap:6px" {@rest}>
      <i :for={style <- @items} style={style}></i>
    </div>
    """
  end

  def palette(assigns) do
    assigns =
      assigns
      |> assign(:grid_style, "--cols:#{assigns.cols};gap:10px")
      |> assign(:items, Enum.map(assigns.colors, &swatch_item/1))

    ~H"""
    <div data-part="palette" class={cx(["lu-grid", @class])} style={@grid_style} {@rest}>
      <div :for={i <- @items} class="lu-swc">
        <div class="c" style={i.style}></div>
        <div class="m">
          <b>{i.name}</b><span>{i.token}</span><span :if={i.values}>{i.values}</span>
        </div>
      </div>
    </div>
    """
  end

  defp ramp_item(scale, step) do
    step = to_string(step)
    color = if step in @dark_text, do: "var(--#{scale}-900)", else: "#fff"
    %{step: step, style: "background:var(--#{scale}-#{step});color:#{color}"}
  end

  defp chip_items(scale, steps) do
    steps
    |> Enum.with_index()
    |> Enum.map(fn {step, i} ->
      delay = :erlang.float_to_binary(i * 0.12, decimals: 2)
      "#{@chip};background:var(--#{scale}-#{step});--dl:#{delay}s"
    end)
  end

  defp swatch_item(color) do
    token = to_string(color[:token])

    values =
      case {color[:light], color[:dark]} do
        {nil, nil} -> nil
        {light, nil} -> light
        {nil, dark} -> dark
        {light, dark} -> "#{light} · #{dark}"
      end

    %{style: "background:var(#{token})", name: color[:name], token: token, values: values}
  end
end
