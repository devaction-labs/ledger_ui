defmodule LedgerUI.Components.Sparkline do
  @moduledoc """
  The canvas's sparkline (`lu-spark`): a line with a soft fill under it, drawn on the server from a
  list of numbers (the highest at the top), so it renders without JavaScript.

      <.sparkline id="bb" values={[8, 12, 9, 14, 11, 16]} />
      <.sparkline id="itau" values={@balances} color="primary" />

  `color="primary"` draws it in the accent, `neutral` (default) in the ink. The SVG stretches to
  the width of its box (`preserveAspectRatio="none"`); the box gets its size from `class`/`style`.
  `id` names the gradient of the fill and must be unique on the page.
  """
  use LedgerUI.Component

  @w 200
  @h 70

  @colors %{"neutral" => "var(--ink)", "primary" => "var(--accent)"}

  attr :id, :string, required: true, doc: "Names the gradient of the fill, so it must be unique."
  attr :values, :list, required: true, doc: "Numbers for the line."
  attr :color, :string, default: "neutral", values: ~w(neutral primary)
  attr :class, :any, default: nil
  attr :rest, :global

  def sparkline(assigns) do
    {d, area, {lx, ly}} = path(assigns.values)

    assigns =
      assigns
      |> assign(:classes, cx(["lu-spark", assigns.class]))
      |> assign(:stroke, @colors[assigns.color])
      |> assign(:gid, assigns.id <> "-fill")
      |> assign(:d, d)
      |> assign(:area, area)
      |> assign(:dot, "left:#{pct(lx, @w)}%;top:#{pct(ly, @h)}%")
      |> assign(:viewbox, "0 0 #{@w} #{@h}")

    ~H"""
    <div id={@id} data-part="sparkline" class={@classes} {@rest}>
      <svg :if={@d != ""} viewBox={@viewbox} preserveAspectRatio="none" aria-hidden="true">
        <defs>
          <linearGradient id={@gid} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0" stop-color={@stroke} stop-opacity=".22" />
            <stop offset="1" stop-color={@stroke} stop-opacity="0" />
          </linearGradient>
        </defs>
        <path d={@area} fill={"url(##{@gid})"} />
        <path
          d={@d}
          fill="none"
          stroke={@stroke}
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          vector-effect="non-scaling-stroke"
        />
      </svg>
      <span :if={@d != ""} class="lu-spark-dot" style={@dot}></span>
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
