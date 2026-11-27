defmodule LedgerUI.Components.Sparkline do
  @moduledoc """
  The canvas's sparkline: a line with a soft fill under it, drawn on the server from a list of
  numbers (the highest at the top), so it renders without JavaScript. Styled only with Tailwind
  utilities; the line draws in once on mount (the area fades in, the end dot pops).

      <.sparkline id="bb" values={[8, 12, 9, 14, 11, 16]} />
      <.sparkline id="itau" values={@balances} color="primary" />

  `color="primary"` draws it in the accent, `neutral` (default) in the ink. The SVG stretches to
  the width of its box (`preserveAspectRatio="none"`); the box gets its size from `class`/`style`.
  `variant="backdrop"` is the faded panel at the right of a `kpi_card` (it positions itself
  absolutely inside the card body); `variant="corner"` is the small 96x30 one at the bottom right of the
  card body (no panel behind it). `dot={false}` leaves out the dot at the end of the line.
  `id` names the gradient of the fill and must be unique on the page.
  """
  use LedgerUI.Component

  @w 200
  @h 70

  @colors %{"neutral" => "var(--lu-ink)", "primary" => "var(--lu-accent-500)"}

  # `relative` (the dot is positioned against the box) or the KPI backdrop: 40% of the card body at the
  # right, faded in from the left, with the accent soft as the background
  @variants %{
    "inline" => "relative",
    "backdrop" =>
      "absolute inset-y-0 right-0 w-[40%] border-l border-line bg-[linear-gradient(90deg,transparent,var(--lu-accent-soft))] [mask-image:linear-gradient(90deg,transparent,#000_30%)]",
    "corner" => "absolute right-4 bottom-4 h-[30px] w-24"
  }

  @dot "absolute -mt-1.5 -ml-1.5 size-3 rounded-full border-[3px] border-accent-500 bg-panel " <>
         "shadow-[0_0_0_5px_color-mix(in_oklab,var(--lu-accent-500)_22%,transparent)] " <>
         "animate-[mo-pop_7s_ease-out]"
  @line "[stroke-dasharray:2000] animate-[mo-line_7s_cubic-bezier(.4,0,.2,1)] motion-reduce:animate-none"
  @area "animate-[mo-area_7s_ease-in-out] motion-reduce:animate-none"

  attr :id, :string, required: true, doc: "Names the gradient of the fill, so it must be unique."
  attr :values, :list, required: true, doc: "Numbers for the line."
  attr :color, :string, default: "neutral", values: ~w(neutral primary)
  attr :variant, :string, default: "inline", values: ~w(inline backdrop corner)

  attr :dot, :boolean,
    default: true,
    doc: "The dot at the end of the line; `false` leaves it out."

  attr :class, :any, default: nil
  attr :rest, :global

  def sparkline(assigns) do
    {d, area, {lx, ly}} = path(assigns.values)

    assigns =
      assigns
      |> assign(:classes, cx([@variants[assigns.variant], assigns.class]))
      |> assign(:dot_class, @dot)
      |> assign(:line_class, @line)
      |> assign(:area_class, @area)
      |> assign(:stroke, @colors[assigns.color])
      |> assign(:gid, assigns.id <> "-fill")
      |> assign(:d, d)
      |> assign(:area, area)
      |> assign(:dot_style, "left:#{pct(lx, @w)}%;top:#{pct(ly, @h)}%")
      |> assign(:viewbox, "0 0 #{@w} #{@h}")

    ~H"""
    <div id={@id} data-part="sparkline" class={@classes} {@rest}>
      <svg
        :if={@d != ""}
        data-part="sparkline-svg"
        class="block size-full opacity-55"
        viewBox={@viewbox}
        preserveAspectRatio="none"
        aria-hidden="true"
      >
        <defs>
          <linearGradient id={@gid} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0" stop-color={@stroke} stop-opacity=".22" />
            <stop offset="1" stop-color={@stroke} stop-opacity="0" />
          </linearGradient>
        </defs>
        <path data-part="sparkline-area" class={@area_class} d={@area} fill={"url(##{@gid})"} />
        <path
          data-part="sparkline-line"
          class={@line_class}
          d={@d}
          fill="none"
          stroke={@stroke}
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          vector-effect="non-scaling-stroke"
        />
      </svg>
      <span
        :if={@d != "" and @dot}
        data-part="sparkline-dot"
        class={@dot_class}
        style={@dot_style}
      ></span>
    </div>
    """
  end

  @doc false
  # Returns `{line_path, area_path, last_point}`; empty path for no values.
  def path([]), do: {"", "", {0, 0}}

  def path(values) do
    values = Enum.map(values, &(&1 * 1.0))
    {mn, mx} = Enum.min_max(values)
    range = if mx == mn, do: 1.0, else: mx - mn
    n = length(values)

    pts =
      values
      |> Enum.with_index()
      |> Enum.map(fn {v, i} ->
        x = if n == 1, do: @w / 2, else: i * (@w - 10) / (n - 1) + 2
        y = @h - 8 - (v - mn) / range * (@h - 20)
        {x, y}
      end)

    d = "M" <> Enum.map_join(pts, " L", fn {x, y} -> "#{num(x)} #{num(y)}" end)
    {lx, _} = last = List.last(pts)
    {d, "#{d} L#{num(lx)} #{@h} L2 #{@h}Z", last}
  end

  defp pct(v, total), do: num(v / total * 100)

  defp num(v) when is_integer(v), do: Integer.to_string(v)

  defp num(v) do
    r = Float.round(v * 1.0, 2)
    if r == Float.round(r), do: Integer.to_string(round(r)), else: Float.to_string(r)
  end
end
