defmodule LedgerUI.Components.Chart do
  @moduledoc """
  Charts drawn by the package itself, as SVG with the `lu-*` look (axis labels, grid lines, legend,
  tooltips, light and dark).

  The look-alike canvas charts are rendered **on the server**, with the same markup `ledger.js`
  builds, so they show without JavaScript; a small hook only adds the hover guide and tooltip:

    * `line_chart/1` (hook `LedgerUI.LineChart`): lines and areas, with head, legend and tooltip.
      The server draws the SVG at `width`; the hook then measures the container (`ResizeObserver`)
      and lays the same geometry out at the real width, so axis text and strokes stay at their CSS
      size on any screen. The lines draw in once on mount (no loop; not with
      `prefers-reduced-motion`).
    * `donut_chart/1` (hook `LedgerUI.DonutChart`): the ring and its plan rows.
    * `waterfall_chart/1`: floating steps and totals.
    * `bar_chart/1`: the column strip (`lu-bars`).
    * `cohort_heatmap/1`: the retention grid.
    * `bar_list/1` and `heatmap/1`: a ranking over tracks and a grid of dots.

  `chart/1` is the generic, options-driven chart (an ApexCharts-shaped subset: `line`, `area`,
  `bar`, `donut`/`pie`) drawn by the `LedgerUI.Chart` hook into an element LiveView leaves alone.

  Cards, headers and segmented controls around a chart are separate components; these functions
  render only the chart (and, for `line_chart/1`, its head and legend).
  """
  use LedgerUI.Component

  @chart_colors Enum.map(1..6, &"var(--chart-#{&1})")

  # -- number helpers ---------------------------------------------------------------------------

  # `style={nil}` renders `style=""`, so an optional style goes through a spread.
  defp st(v) when v in [nil, false], do: []
  defp st(v), do: [style: v]

  @doc false
  def num(v) when is_integer(v), do: Integer.to_string(v)

  def num(v) when is_float(v) do
    r = Float.round(v, 2)
    if r == Float.round(r), do: Integer.to_string(round(r)), else: Float.to_string(r)
  end

  @doc false
  def money(v) do
    v
    |> round()
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
    |> String.replace("-,", "-")
    |> then(&("$" <> &1))
  end

  @doc false
  def kilo(v) when v >= 1000, do: "$" <> Integer.to_string(round(v / 1000)) <> "k"
  def kilo(v), do: "$" <> num(v)

  defp rng(min, max) when max == min, do: 1.0
  defp rng(min, max), do: max - min

  # -- line chart -------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :labels, :list, default: [], doc: "X axis labels, one per point."

  attr :series, :list,
    default: [],
    doc:
      "`[%{name: .., values: [..], area: bool, dashed: bool, color: css}]`. Without series only the empty container is rendered."

  attr :min, :any, default: nil, doc: "Lowest value of the axis (default: lowest of the data)."
  attr :max, :any, default: nil
  attr :ticks, :integer, default: 4, doc: "Gaps of the Y axis (`ticks + 1` grid lines)."
  attr :label_every, :integer, default: 1, doc: "Draw one X label every N points."

  attr :width, :integer,
    default: 640,
    doc:
      "Width of the server-rendered SVG (first paint). In the browser the hook re-lays the chart to the measured width of its container, so text and strokes keep their CSS size."

  attr :height, :integer,
    default: 250,
    doc: "Height of the chart in CSS pixels (the same on the server and after the hook measured)."

  attr :label, :string, default: "Gráfico", doc: "`aria-label` of the SVG."
  attr :head, :string, default: nil, doc: "Big figure above the chart (`+$70,320`)."
  attr :sub, :string, default: nil, doc: "Muted text after the figure (`since January`)."

  attr :legend, :boolean,
    default: true,
    doc: "Legend of the named series (when there is more than one)."

  attr :sub_delta, :string,
    default: nil,
    doc: "A change after the muted text (`+12,4%`), in bold and colored by `sub_delta_tone`."

  attr :sub_delta_tone, :string, default: "pos", values: ~w(pos neg)

  attr :pin, :integer, default: nil, doc: "Index whose guide and tooltip stay visible."

  attr :axis_format, :any,
    default: &__MODULE__.kilo/1,
    doc: "Function of a value for the Y labels."

  attr :value_format, :any,
    default: &__MODULE__.money/1,
    doc: "Function of a value for the tooltip."

  attr :tip, :any,
    default: nil,
    doc: "Function of an index returning tooltip rows `[[name, value, kind]]`."

  attr :tip_title, :any, default: nil, doc: "Function of an index returning the tooltip title."
  attr :class, :any, default: nil
  attr :rest, :global

  def line_chart(assigns) do
    assigns = assign(assigns, :geo, line_geo(assigns))

    ~H"""
    <div
      :if={@head || @sub || (@legend && length(@series) > 1)}
      class="lu-row"
      style="align-items:flex-start"
    >
      <div class="lu-chart-head">
        <b data-head="">{@head}</b><span class="lu-muted" data-sub="">{@sub}
        <%= if @sub_delta do %>
          · <span style={"color:var(--#{@sub_delta_tone});font-weight:600"}>{@sub_delta}</span>
        <% end %></span>
      </div>
      <span class="lu-grow"></span>
      <span class="lu-leg" data-legend="">
        <span :for={s <- @geo.legend}><i :if={s.dashed} class="dash"></i><i
          :if={!s.dashed}
          class="sq"
          style={"background:" <> s.color}
        ></i>{s.name}</span>
      </span>
    </div>
    <div
      id={@id}
      data-chart=""
      class={cx([@geo.svg && "lu-chart", @class])}
      phx-hook={@geo.svg && "LedgerUI.LineChart"}
      data-part="line-chart"
      data-lu-chart-data={@geo.json}
      {@rest}
    >
      <svg
        :if={@geo.svg}
        class="lu-chart-svg"
        viewBox={@geo.viewbox}
        role="img"
        aria-label={@label}
      >
        <defs>
          <linearGradient id={@id <> "-fill"} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="var(--accent)" stop-opacity=".18" />
            <stop offset="1" stop-color="var(--accent)" stop-opacity="0" />
          </linearGradient>
        </defs>
        <%= for g <- @geo.grid do %>
          <line class="lu-gridline" x1={g.x1} x2={g.x2} y1={g.y} y2={g.y} />
          <text class="lu-axis" x={g.tx} y={g.ty} text-anchor="end">{g.label}</text>
        <% end %>
        <text
          :for={l <- @geo.xlabels}
          class={cx(["lu-axis lu-xl", l.on && "on"])}
          data-i={l.i}
          x={l.x}
          y={l.y}
          text-anchor="middle"
        >
          {l.text}
        </text>
        <%= for s <- @geo.lines do %>
          <path :if={s.area} d={s.area} fill={"url(##{@id}-fill)"} />
          <path class={cx(["lu-line", s.dashed && "dashed"])} d={s.d} style={"stroke:" <> s.color} />
          <circle :if={!s.dashed} class="lu-endpt" cx={s.ex} cy={s.ey} r="4" />
        <% end %>
        <g class="lu-hover" {st(@geo.hover_style)}>
          <line
            class="lu-guide"
            y1={@geo.pt}
            y2={@geo.pb}
            x1={@geo.pin && @geo.pin.x}
            x2={@geo.pin && @geo.pin.x}
          />
          <circle
            :for={{s, si} <- Enum.with_index(@geo.lines)}
            class={cx(["lu-dot", s.dashed && "ghost"])}
            data-s={si}
            r={if s.dashed, do: "3.5", else: "6"}
            cx={@geo.pin && @geo.pin.x}
            cy={@geo.pin && Enum.at(@geo.pin.ys, si)}
          />
        </g>
        <rect
          class="lu-hit"
          x={@geo.pl}
          y={@geo.pt}
          width={@geo.iw}
          height={@geo.ih}
          fill="transparent"
        />
      </svg>
      <div :if={@geo.svg} class="lu-tip" {st(@geo.tip_style)}>
        <%= if @geo.pin do %>
          <b>{@geo.pin.title}</b>
          <div :for={[name, value, kind] <- @geo.pin.rows} class="r">
            <i class={"d " <> kind}></i><span>{name}</span><em>{value}</em>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp line_geo(%{series: []} = a) do
    %{
      svg: false,
      legend: [],
      json: nil,
      grid: [],
      xlabels: [],
      lines: [],
      pin: nil,
      hover_style: nil,
      tip_style: nil,
      pt: a.height,
      pb: 0,
      pl: 0,
      iw: 0,
      ih: 0,
      viewbox: nil
    }
  end

  defp line_geo(a) do
    {w, h, pl, pr, pt, pb} = {a.width, a.height, 46, 14, 12, 26}
    n = length(a.labels)
    all = Enum.flat_map(a.series, & &1.values)
    min = a.min || Enum.min(all)
    max = a.max || Enum.max(all)
    range = rng(min, max)
    iw = w - pl - pr
    ih = h - pt - pb
    x = fn i -> if n == 1, do: pl + iw / 2, else: pl + i * iw / (n - 1) end
    y = fn v -> pt + ih - (v - min) / range * ih end

    grid =
      for t <- 0..a.ticks do
        v = min + (max - min) * t / a.ticks
        yy = y.(v)

        %{
          x1: pl,
          x2: w - pr,
          y: num(yy * 1.0),
          tx: pl - 8,
          ty: num(yy + 4.0),
          label: a.axis_format.(v)
        }
      end

    xlabels =
      for {l, i} <- Enum.with_index(a.labels), rem(i, a.label_every) == 0 or i == n - 1 do
        %{i: i, x: num(x.(i) * 1.0), y: h - 6, text: l, on: a.pin == i}
      end

    lines =
      Enum.map(a.series, fn s ->
        pts = s.values |> Enum.with_index() |> Enum.map(fn {v, i} -> {x.(i), y.(v)} end)
        d = smooth(pts)
        {ex, ey} = List.last(pts)

        area =
          if s[:area],
            do: "#{d} L#{num(x.(n - 1) * 1.0)} #{pt + ih} L#{num(x.(0) * 1.0)} #{pt + ih}Z"

        %{
          d: d,
          area: area,
          dashed: !!s[:dashed],
          color: s[:color] || "var(--accent)",
          ex: num(ex * 1.0),
          ey: num(ey * 1.0)
        }
      end)

    tip = a.tip || fn i -> default_tip(a.series, i, a.value_format) end
    tip_title = a.tip_title || fn i -> Enum.at(a.labels, i) end
    tips = for i <- 0..(n - 1)//1, do: %{title: tip_title.(i), rows: tip.(i)}

    pin =
      case a.pin do
        nil ->
          nil

        i ->
          gx = x.(i)
          ys = Enum.map(a.series, fn s -> y.(Enum.at(s.values, i)) end)

          %{
            title: tip_title.(i),
            rows: tip.(i),
            x: num(gx * 1.0),
            ys: Enum.map(ys, &num(&1 * 1.0)),
            hover_style: nil,
            tip_style: tip_style(gx, hd(ys), w, h)
          }
      end

    json =
      Jason.encode!(%{
        w: w,
        h: h,
        pl: pl,
        pr: pr,
        pt: pt,
        pb: pb,
        iw: iw,
        ih: ih,
        min: min,
        max: max,
        ticks: a.ticks,
        label_every: a.label_every,
        pin: a.pin,
        values: Enum.map(a.series, & &1.values),
        area: Enum.map(a.series, &(!!&1[:area])),
        grid_labels: Enum.map(grid, & &1.label),
        xs: Enum.map(0..(n - 1)//1, &Float.round(x.(&1) * 1.0, 2)),
        ys: Enum.map(a.series, fn s -> Enum.map(s.values, &Float.round(y.(&1) * 1.0, 2)) end),
        dashed: Enum.map(a.series, &(!!&1[:dashed])),
        tips: tips
      })

    legend =
      a.series
      |> Enum.filter(& &1[:name])
      |> Enum.map(&%{name: &1.name, dashed: !!&1[:dashed], color: &1[:color] || "var(--accent)"})

    %{
      svg: true,
      viewbox: "0 0 #{w} #{h}",
      grid: grid,
      xlabels: xlabels,
      lines: lines,
      pin: pin,
      hover_style: if(pin, do: nil, else: "display:none"),
      tip_style: (pin && pin.tip_style) || "display:none",
      json: json,
      legend: legend,
      pl: pl,
      pt: pt,
      pb: pt + ih,
      iw: iw,
      ih: ih
    }
  end

  defp tip_style(gx, gy, w, h) do
    "left:#{num(gx / w * 100)}%;top:#{num(gy / h * 100)}%;transform:translate(calc(-100% - 14px),calc(-100% - 8px))"
  end

  defp default_tip(series, i, fmt) do
    for s <- series,
        do: [s[:name], fmt.(Enum.at(s.values, i)), if(s[:dashed], do: "ghost", else: "acc")]
  end

  defp smooth([{x0, y0} | rest]) do
    {d, _} =
      Enum.reduce(rest, {"M#{num(x0 * 1.0)} #{num(y0 * 1.0)}", {x0, y0}}, fn {x1, y1},
                                                                             {acc, {px, py}} ->
        cx = (px + x1) / 2

        {"#{acc} C#{num(cx * 1.0)} #{num(py * 1.0)} #{num(cx * 1.0)} #{num(y1 * 1.0)} #{num(x1 * 1.0)} #{num(y1 * 1.0)}",
         {x1, y1}}
      end)

    d
  end

  # -- donut chart ------------------------------------------------------------------------------

  attr :id, :string, required: true

  attr :segments, :list,
    default: [],
    doc:
      "`[%{name: .., value: number, color: css, display: \"$96,900\"}]`. Empty: only the container."

  attr :center_label, :string, default: "TOTAL"
  attr :center_value, :string, default: nil
  attr :label, :string, default: "Distribuição"

  attr :rows, :boolean,
    default: true,
    doc: "Draw the plan rows (name, value and share) under the ring."

  attr :value_format, :any, default: &__MODULE__.money/1
  attr :class, :any, default: nil
  attr :rest, :global

  def donut_chart(assigns) do
    segs = donut_segments(assigns)
    total = Enum.reduce(assigns.segments, 0, &(&1.value + &2))

    assigns =
      assigns
      |> assign(:segs, segs)
      |> assign(:viewbox, "0 0 180 180")
      |> assign(
        :center_value,
        assigns.center_value || (total > 0 && assigns.value_format.(total)) || ""
      )

    ~H"""
    <div
      id={@id}
      class={cx(["lu-donut", @class])}
      data-donut=""
      phx-hook="LedgerUI.DonutChart"
      data-part="donut-chart"
      {@rest}
    >
      <%= if @segs != [] do %>
        <svg viewBox={@viewbox} class="lu-donut-svg" role="img" aria-label={@label}>
          <circle
            :for={s <- @segs}
            class="lu-seg"
            data-i={s.i}
            cx="90"
            cy="90"
            r="70"
            fill="none"
            stroke={s.color}
            stroke-width="14"
            stroke-linecap="round"
            stroke-dasharray={s.dash}
            stroke-dashoffset={s.offset}
            transform="rotate(-90 90 90)"
          />
        </svg>
        <div class="lu-donut-c">
          <span data-k data-lu-default={@center_label}>{@center_label}</span><b
            data-v
            data-lu-default={@center_value}
          >{@center_value}</b>
        </div>
      <% end %>
    </div>
    <%= if @rows do %>
      <div :for={s <- @segs} class="lu-plan-row" data-row={s.i}>
        <i class="sq" style={"width:9px;height:9px;border-radius:2px;background:" <> s.color}></i>{s.name}<span class="v">{s.display}</span><span class="p">{s.percent}%</span>
      </div>
    <% end %>
    """
  end

  defp donut_segments(%{segments: []}), do: []

  defp donut_segments(a) do
    total = Enum.reduce(a.segments, 0, &(&1.value + &2))
    c = 2 * :math.pi() * 70

    {segs, _} =
      a.segments
      |> Enum.with_index()
      |> Enum.map_reduce(0.0, fn {s, i}, off ->
        share = s.value / total
        len = share * c - 7

        seg = %{
          i: i,
          name: s.name,
          color: s[:color] || Enum.at(@chart_colors, rem(i, length(@chart_colors))),
          display: s[:display] || a.value_format.(s.value),
          percent: num(Float.round(share * 100, 1)),
          dash: "#{num(Float.round(len, 3))} #{num(Float.round(c - len, 3))}",
          offset: num(Float.round(-off, 3))
        }

        {seg, off + share * c}
      end)

    segs
  end

  # -- waterfall chart --------------------------------------------------------------------------

  @doc false
  def wf_axis(0), do: "$0"
  def wf_axis(v), do: "$" <> num(v / 1000) <> "k"

  attr :id, :string, default: nil

  attr :steps, :list,
    default: [],
    doc:
      "`[%{name:, value:, label:, color:, total: bool}]`: a step moves the running total, `total` starts from zero."

  attr :max, :integer, default: 30_000, doc: "Top of the Y axis."
  attr :ticks, :integer, default: 3, doc: "Gaps of the Y axis."
  attr :label, :string, default: "Movimento", doc: "`aria-label` of the SVG."
  attr :axis_format, :any, default: &__MODULE__.wf_axis/1
  attr :class, :any, default: nil
  attr :rest, :global

  def waterfall_chart(assigns) do
    assigns = assign(assigns, :wf, waterfall_geo(assigns))

    ~H"""
    <div id={@id} data-wf="" class={@class} {@rest}>
      <svg :if={@wf} viewBox={@wf.viewbox} class="lu-chart-svg" role="img" aria-label={@label}>
        <%= for g <- @wf.grid do %>
          <line class="lu-gridline" x1="40" x2="420" y1={g.y} y2={g.y} />
          <text class="lu-axis" x="34" y={g.ty} text-anchor="end">{g.label}</text>
        <% end %>
        <%= for b <- @wf.bars do %>
          <rect x={b.x} y={b.y} width="38" height={b.h} rx="6" fill={b.color}>
            <title>{b.name} {b.label}</title>
          </rect>
          <text class="lu-wf-l" x={b.cx} y={b.ly} text-anchor="middle">{b.label}</text>
          <text class={cx(["lu-axis", b.total && "strong"])} x={b.cx} y="254" text-anchor="middle">
            {b.name}
          </text>
          <line :if={b.connector} class="lu-wf-c" x1={b.x1} x2={b.x2} y1={b.cy} y2={b.cy} />
        <% end %>
      </svg>
    </div>
    """
  end

  defp waterfall_geo(%{steps: []}), do: nil

  defp waterfall_geo(a) do
    {w, h, pl, pb, pt, bw} = {420, 260, 40, 26, 26, 38}
    iw = w - pl - 8
    ih = h - pt - pb
    y = fn v -> pt + ih - v / a.max * ih end
    count = length(a.steps)
    slot = iw / count

    grid =
      for t <- 0..a.ticks do
        v = a.max * t / a.ticks
        %{y: num(y.(v) * 1.0), ty: num(y.(v) + 4.0), label: a.axis_format.(round(v))}
      end

    {bars, _} =
      a.steps
      |> Enum.with_index()
      |> Enum.map_reduce(0, fn {s, i}, run ->
        x = pl + slot * i + (slot - bw) / 2
        total? = !!s[:total]

        {from, to, run} =
          if total?, do: {0, s.value, run}, else: {run, run + s.value, run + s.value}

        top = y.(max(from, to))
        height = max(abs(y.(from) - y.(to)), 4)
        line_v = if total?, do: s.value, else: run

        bar = %{
          name: s.name,
          label: s.label,
          total: total?,
          color: s[:color] || wf_color(total?, s.value),
          x: num(x * 1.0),
          y: num(top * 1.0),
          h: num(height * 1.0),
          cx: num((x + bw / 2) * 1.0),
          ly: num(top - 8.0),
          connector: i < count - 1,
          x1: num((x + bw) * 1.0),
          x2: num((x + slot) * 1.0),
          cy: num(y.(line_v) * 1.0)
        }

        {bar, run}
      end)

    %{viewbox: "0 0 #{w} #{h}", grid: grid, bars: bars}
  end

  defp wf_color(true, _), do: "var(--chart-1)"
  defp wf_color(_, v) when v < 0, do: "var(--neg)"
  defp wf_color(_, _), do: "var(--pos)"

  # -- bar chart --------------------------------------------------------------------------------

  attr :values, :list, default: [], doc: "One number per bar."

  attr :data, :list,
    default: [],
    doc:
      "The bars as `{label, value}` tuples or `%{label:, value:}` maps, in place of `values` and `labels`."

  attr :max, :any,
    default: nil,
    doc:
      "The value of a full-height bar (the highest value, or 100 when it is lower, by default)."

  attr :labels, :list, default: [], doc: "Labels in a row under the bars."
  attr :titles, :list, default: [], doc: "`title` (hover text) of each bar."

  attr :highlight, :any,
    default: :last,
    doc: "Index of the highlighted bar, or its label (`:last`, `nil` for none)."

  attr :shape, :string, default: "round", values: ~w(round square)
  attr :height, :any, default: nil, doc: "CSS height of the strip (`120px`)."
  attr :width, :any, default: nil, doc: "CSS width of the strip."
  attr :class, :any, default: nil
  attr :rest, :global

  def bar_chart(assigns) do
    {values, labels} = bar_data(assigns)
    assigns = assign(assigns, values: values, labels: labels, max: assigns.max || bar_max(values))
    n = length(assigns.values)

    hi =
      case assigns.highlight do
        :last -> n - 1
        label when is_binary(label) -> Enum.find_index(assigns.labels, &(to_string(&1) == label))
        other -> other
      end

    style =
      [assigns.height && "height:#{assigns.height}", assigns.width && "width:#{assigns.width}"]
      |> Enum.filter(& &1)
      |> Enum.join(";")

    bars =
      assigns.values
      |> Enum.with_index()
      |> Enum.map(fn {v, i} ->
        %{
          on: i == hi,
          style:
            "height:#{num(v / assigns.max * 100)}%" <>
              if(assigns.shape == "square", do: ";border-radius:2px", else: ";"),
          title: Enum.at(assigns.titles, i)
        }
      end)

    assigns =
      assigns
      |> assign(:bars, bars)
      |> assign(:strip_style, if(style != "", do: style))

    ~H"""
    <div
      class={cx(["lu-bars", @class])}
      {st(@strip_style)}
      data-part="bar-chart"
      {@rest}
    >
      <div :for={b <- @bars} class={b.on && "on"} style={b.style} title={b.title}></div>
    </div>
    <div
      :if={@labels != []}
      class="lu-row lu-xs lu-muted"
      style="justify-content:space-between;margin-top:8px"
    >
      <span :for={l <- @labels}>{l}</span>
    </div>
    """
  end

  defp bar_data(%{data: [], values: values, labels: labels}), do: {values, labels}

  defp bar_data(%{data: data}) do
    pairs =
      Enum.map(data, fn
        {label, value} -> {label, value}
        %{label: label, value: value} -> {label, value}
      end)

    {Enum.map(pairs, &elem(&1, 1)), Enum.map(pairs, &elem(&1, 0))}
  end

  defp bar_max(values), do: max(100, Enum.max(values, fn -> 0 end))

  # -- cohort heatmap ---------------------------------------------------------------------------

  attr :columns, :list, required: true, doc: "Header labels (`M0`, `M1`...)."

  attr :rows, :list,
    required: true,
    doc: "`[%{label: \"Jan\", values: [100, 94, nil, ...]}]`; `nil` is an empty cell."

  attr :thresholds, :list, default: [86, 90, 94, 100], doc: "Lower bounds of levels 2 to 5."
  attr :suffix, :string, default: "%"
  attr :class, :any, default: nil
  attr :rest, :global

  def cohort_heatmap(assigns) do
    rows =
      Enum.map(assigns.rows, fn r ->
        %{
          label: r.label,
          cells:
            Enum.map(r.values, fn
              nil ->
                nil

              v ->
                %{
                  text: num(v) <> assigns.suffix,
                  level: "l" <> Integer.to_string(level(v, assigns.thresholds))
                }
            end)
        }
      end)

    assigns = assign(assigns, :data, rows)

    ~H"""
    <table class={cx(["lu-table lu-heat", @class])} data-part="cohort-heatmap" {@rest}>
      <thead>
        <tr>
          <th></th>
          <th :for={c <- @columns}>{c}</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={r <- @data}>
          <td class="lbl">{r.label}</td>
          <td :for={c <- r.cells}>
            <div :if={c} class={"c " <> c.level}>{c.text}</div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp level(v, thresholds) do
    1 + Enum.count(thresholds, &(v >= &1))
  end

  # -- bar list ---------------------------------------------------------------------------------

  attr :label, :string, default: nil, doc: "The list's `aria-label`."

  attr :max, :any,
    default: nil,
    doc: "The amount of a full track (the largest `amount` by default)."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :label, :string
    attr :value, :string
    attr :amount, :any
  end

  def bar_list(assigns) do
    max = assigns.max || assigns.item |> Enum.map(& &1.amount) |> Enum.max(fn -> 1 end)

    items =
      Enum.map(assigns.item, fn i ->
        %{label: i.label, value: i.value, width: num(Float.round(i.amount / max * 100, 1))}
      end)

    assigns = assign(assigns, :items, items)

    ~H"""
    <ul
      role="list"
      aria-label={@label}
      class={@class}
      style="list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:12px"
      data-part="bar-list"
      {@rest}
    >
      <li :for={i <- @items} style="display:flex;flex-direction:column;gap:6px">
        <div class="lu-row" style="justify-content:space-between;font-size:13px">
          <span>{i.label}</span><b class="num">{i.value}</b>
        </div>
        <div class="lu-progress sm" aria-hidden="true"><i style={"width:#{i.width}%"}></i></div>
      </li>
    </ul>
    """
  end

  # -- dot heatmap ------------------------------------------------------------------------------

  attr :levels, :list, required: true, doc: "One level per cell, 0 to 4, row by row."
  attr :columns, :integer, default: 20
  attr :size, :integer, default: 12, doc: "The cell size in pixels."
  attr :shape, :string, default: "round", values: ~w(round square)
  attr :label, :string, required: true, doc: "What the map shows, for assistive technology."
  attr :titles, :list, default: nil, doc: "A `title` per cell."
  attr :less, :string, default: nil, doc: "Text before the scale; no scale without it."
  attr :more, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @heat_fallback %{
    0 => "var(--heat0, var(--bg-sunken))",
    1 => "var(--heat1, color-mix(in oklab, var(--accent) 25%, var(--bg-sunken)))",
    2 => "var(--heat2, color-mix(in oklab, var(--accent) 50%, var(--bg-sunken)))",
    3 => "var(--heat3, color-mix(in oklab, var(--accent) 75%, var(--bg-sunken)))",
    4 => "var(--heat4, var(--accent))"
  }

  def heatmap(assigns) do
    radius = if assigns.shape == "round", do: "50%", else: "3px"
    titles = assigns.titles || []

    cells =
      assigns.levels
      |> Enum.with_index()
      |> Enum.map(fn {l, i} ->
        %{bg: "background:" <> @heat_fallback[min(max(l, 0), 4)], title: Enum.at(titles, i)}
      end)

    assigns =
      assigns
      |> assign(:cells, cells)
      |> assign(
        :grid_style,
        "display:grid;grid-template-columns:repeat(#{assigns.columns},#{assigns.size}px);gap:4px"
      )
      |> assign(
        :cell_style,
        "width:#{assigns.size}px;height:#{assigns.size}px;border-radius:#{radius};"
      )
      |> assign(:scale, Enum.map(0..4, &@heat_fallback[&1]))

    ~H"""
    <div class={@class} data-part="heatmap" {@rest}>
      <div role="img" aria-label={@label} style={@grid_style}>
        <i :for={c <- @cells} title={c.title} style={@cell_style <> c.bg}></i>
      </div>
      <div
        :if={@less}
        class="lu-row lu-xs lu-muted"
        style="margin-top:8px;gap:4px;align-items:center"
        aria-hidden="true"
      >
        <span>{@less}</span>
        <i :for={bg <- @scale} style={@cell_style <> "background:" <> bg}></i>
        <span>{@more}</span>
      </div>
    </div>
    """
  end

  # -- generic chart (hook) ---------------------------------------------------------------------

  attr :id, :string, required: true, doc: "DOM id; also what `push_event` payloads target."

  attr :options, :any,
    required: true,
    doc: "ApexCharts-shaped options, a map (encoded to JSON) or an encoded JSON string."

  attr :formatters, :map,
    default: %{},
    doc:
      ~s(Options path to built-in formatter name, e.g. `%{"yaxis.labels.formatter" => "thousands"}`.)

  attr :table_toggle, :any,
    default: false,
    doc: "Reserved: a Chart / Table switch (not drawn yet)."

  attr :summary, :boolean,
    default: false,
    doc: "Reserved: the cursor summary line (not drawn yet)."

  attr :on_cursor, :string, default: nil, doc: "LiveView event pushed as the cursor moves."
  attr :class, :any, default: nil
  attr :rest, :global

  def chart(assigns) do
    assigns =
      assigns
      |> assign(:options_json, json(assigns.options))
      |> assign(:formatters_json, Jason.encode!(assigns.formatters))
      |> assign(:canvas_id, assigns.id <> "-canvas")

    ~H"""
    <div
      id={@id}
      class={cx(["lu-chart", @class])}
      phx-hook="LedgerUI.Chart"
      data-options={@options_json}
      data-formatters={@formatters_json}
      data-on-cursor={@on_cursor}
      data-part="chart"
      {@rest}
    >
      <div id={@canvas_id} phx-update="ignore" data-canvas></div>
    </div>
    """
  end

  defp json(v) when is_binary(v), do: v
  defp json(v), do: Jason.encode!(v)
end
