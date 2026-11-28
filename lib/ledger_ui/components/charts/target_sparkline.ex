defmodule LedgerUI.Components.TargetSparkline do
  @moduledoc """
  A sparkline with a goal: the line and its soft fill, a dashed line at the `target` with its
  label, and the points that miss the target drawn as `warn` dots. Drawn on the server (the paths
  stretch to the width of the box; the dots and the label are HTML, so they stay round and sharp).

      <.target_sparkline id="taxa" values={@taxa} target={95.0} target_label="Meta 95,0%" />

  `better="higher"` (default) means a point under the target misses it; `better="lower"` (a
  response time, a defect rate) means a point over it does. `color` is the line (`c1`..`c5`, `pos`,
  `info`...). The height is 46px; `class` can change it.

  The box is `role="img"` with an `aria-label` that sums it up (points, last value, target, how many
  miss it; translated), and each dot has its value as native tooltip. `format` writes the values of
  the label and the tooltips (default: the number in the locale). `id` names the gradient and must be
  unique on the page.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.OpsFormat, as: F

  @w 300
  @h 46
  @top 6
  @bottom 14

  @box "relative h-[46px] w-full"
  @dot "absolute size-[7px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-panel bg-chart-3"

  attr :id, :string, required: true, doc: "Names the gradient of the fill, so it must be unique."
  attr :values, :list, required: true, doc: "Numbers for the line."
  attr :target, :any, required: true, doc: "The goal: a number."
  attr :target_label, :string, default: nil, doc: "Text under the target line (`Meta 95,0%`)."

  attr :better, :string,
    default: "higher",
    values: ~w(higher lower),
    doc: "`higher`: points under the target miss it. `lower`: points over it do."

  attr :color, :string,
    default: "c1",
    values: tone_values(F.tones()),
    doc: "The line and the fill."

  attr :format, :any,
    default: nil,
    doc: "`fn number -> text` for the values of the label and the tooltips."

  attr :label, :string, default: nil, doc: "The `aria-label`; default: a summary, translated."
  attr :class, :any, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :rest, :global

  def target_sparkline(assigns) do
    changed0 = assigns.__changed__
    geo = geometry(assigns.values, assigns.target, assigns.better)

    assigns =
      assigns
      |> assign(:box_class, cx([@box, F.text(assigns.color), assigns.class]))
      |> assign(:dot_class, @dot)
      |> assign(:gid, assigns.id <> "-fill")
      |> assign(:viewbox, "0 0 #{@w} #{@h}")
      |> assign(:geo, geo)
      |> assign(:dots, dots(geo, assigns.values, assigns.format, assigns.locale))
      |> assign(:aria, assigns.label || summary(geo, assigns))

    assigns =
      settle(assigns, changed0,
        box_class: [:color, :class],
        dot_class: [],
        gid: [:id],
        viewbox: [],
        geo: [:values, :target, :better],
        dots: [:values, :target, :better, :format, :locale],
        aria: [:values, :target, :better, :format, :locale, :label]
      )

    ~H"""
    <div
      id={@id}
      data-part="target-sparkline"
      role="img"
      aria-label={@aria}
      class={@box_class}
      {@rest}
    >
      <svg
        :if={@geo.line != ""}
        data-part="target-sparkline-svg"
        class="block size-full overflow-visible"
        viewBox={@viewbox}
        preserveAspectRatio="none"
        aria-hidden="true"
      >
        <defs>
          <linearGradient id={@gid} x1="0" x2="0" y1="0" y2="1">
            <stop offset="0" stop-color="currentColor" stop-opacity=".18" />
            <stop offset="1" stop-color="currentColor" stop-opacity="0" />
          </linearGradient>
        </defs>
        <path data-part="target-sparkline-area" d={@geo.area} fill={"url(##{@gid})"} />
        <line
          data-part="target-sparkline-target"
          class="stroke-muted"
          x1="0"
          x2={@geo.w}
          y1={@geo.ty}
          y2={@geo.ty}
          stroke-width="1"
          stroke-dasharray="3 3"
          vector-effect="non-scaling-stroke"
        />
        <path
          data-part="target-sparkline-line"
          class="stroke-current"
          d={@geo.line}
          fill="none"
          stroke-width="1.8"
          stroke-linejoin="round"
          vector-effect="non-scaling-stroke"
        />
      </svg>
      <span
        :if={@target_label && @geo.line != ""}
        data-part="target-sparkline-label"
        class="absolute bottom-0 left-1 text-[10.5px] leading-none text-muted"
      >{@target_label}</span>
      <span
        :for={d <- @dots}
        :key={d.i}
        data-part="target-sparkline-dot"
        class={@dot_class}
        style={d.style}
        title={d.title}
        aria-hidden="true"
      ></span>
    </div>
    """
  end

  defp geometry([], _target, _better),
    do: %{line: "", area: "", ty: "0", w: @w, pts: [], miss: []}

  defp geometry(values, target, better) do
    vals = Enum.map(values, &(&1 * 1.0))
    t = target * 1.0
    {lo, hi} = Enum.min_max([t | vals])
    range = if hi == lo, do: 1.0, else: hi - lo
    n = length(vals)
    inner = @h - @top - @bottom
    y = fn v -> @top + (hi - v) / range * inner end

    pts =
      vals
      |> Enum.with_index()
      |> Enum.map(fn {v, i} ->
        x = if n == 1, do: @w / 2, else: 2 + i * (@w - 4) / (n - 1)
        {x, y.(v), v}
      end)

    line = "M" <> Enum.map_join(pts, " L", fn {x, y, _} -> "#{F.num(x)} #{F.num(y)}" end)
    {lx, _, _} = List.last(pts)
    {fx, _, _} = hd(pts)

    miss =
      for {{_, _, v}, i} <- Enum.with_index(pts),
          misses?(v, t, better),
          do: i

    %{
      line: line,
      area: "#{line} L#{F.num(lx)} #{@h} L#{F.num(fx)} #{@h}Z",
      ty: F.num(y.(t)),
      w: @w,
      pts: pts,
      miss: miss
    }
  end

  defp misses?(v, t, "lower"), do: v > t
  defp misses?(v, t, _), do: v < t

  defp dots(%{pts: pts, miss: miss}, values, format, locale) do
    for i <- miss do
      {x, y, _} = Enum.at(pts, i)

      %{
        i: i,
        style: "left:#{F.num(x / @w * 100)}%;top:#{F.num(y / @h * 100)}%",
        title: F.fmt(format, Enum.at(values, i), locale)
      }
    end
  end

  defp summary(%{pts: []}, a), do: summary_text(a, 0, 0)
  defp summary(%{miss: miss}, a), do: summary_text(a, length(a.values), length(miss))

  defp summary_text(a, count, below) do
    I18n.t("target_sparkline.summary", a.locale,
      count: count,
      last: if(a.values == [], do: "-", else: F.fmt(a.format, List.last(a.values), a.locale)),
      target: F.fmt(a.format, a.target, a.locale),
      below: below
    )
  end
end
