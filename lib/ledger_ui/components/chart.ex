defmodule LedgerUI.Components.Chart do
  @moduledoc """
  Charts drawn by the package itself, as SVG (axis labels, grid lines, legend, tooltips, light and
  dark). Styled only with Tailwind utilities: series take their colour from the chart tokens
  (`--lu-chart-1` ... `--lu-chart-5`, derived from the accent) or from the `color` you give, so a theme
  recolours them. Old names such as `var(--chart-3)` and `var(--accent)` are read as the `--lu-` tokens.

  The look-alike canvas charts are rendered **on the server**, so they show without JavaScript; a small
  hook only adds the hover guide and tooltip:

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

  @chart_colors Enum.map(1..5, &"var(--lu-chart-#{&1})")
  @accent "var(--lu-accent-500)"

  # Series colours: the old canvas names (`var(--chart-3)`, `var(--accent)`) are the `--lu-` tokens now.
  @doc false
  def tok("var(--" <> rest = v) do
    if String.starts_with?(rest, ["lu-", "color-"]), do: v, else: "var(--lu-" <> rest
  end

  def tok(v), do: v

  # --- utilities shared by the SVG charts
  @svg "block h-auto w-full overflow-visible"
  @grid "stroke-chart-grid [stroke-width:1]"
  @axis_text "font-sans text-[11.5px] tabular-nums"
  @axis @axis_text <> " fill-muted"
  @axis_on "data-[state=on]:fill-ink data-[state=on]:font-semibold"
  @axis_strong @axis_text <> " fill-ink font-semibold"
  @line "fill-none [stroke-width:2.2] [stroke-linecap:round]"
  @line_dashed "fill-none [stroke-width:1.5] [stroke-linecap:round] [stroke-dasharray:4_4]"
  # the entrance plays once: the line is wiped in from the left (a clip, so dashed series keep their dash),
  # the area fades, the end point pops
  @wipe "[clip-path:inset(-6px_-6px_-6px_0)] transition-[clip-path] duration-[1200ms] ease-[cubic-bezier(.4,0,.2,1)] " <>
          "starting:[clip-path:inset(-6px_100%_-6px_0)] motion-reduce:transition-none"
  @fade "transition-opacity delay-[250ms] duration-[900ms] ease-out starting:opacity-0 motion-reduce:transition-none"
  @pop "[transform-box:fill-box] origin-center transition-[scale,opacity] delay-[900ms] duration-[450ms] " <>
         "ease-[cubic-bezier(.34,1.56,.64,1)] starting:scale-0 starting:opacity-0 motion-reduce:transition-none"

  # the tooltip: the server draws the pinned one, the hook builds the others from this config
  @tip "pointer-events-none absolute z-[2] min-w-[170px] rounded-[12px] border border-line bg-panel px-3 py-2.5 text-[13px] shadow-md"
  @tip_cls %{
    "title" => "mb-1 block font-semibold",
    "row" => "flex items-center gap-[7px] leading-[21px]",
    "name" => "text-muted",
    "value" => "ml-auto pl-3.5 font-semibold not-italic tabular-nums",
    "dot" => "inline-block size-[7px] flex-none rounded-full",
    "kinds" => %{
      "acc" => "bg-accent-500",
      "ghost" => "bg-chart-ghost",
      # the "Net new" green of the canvas tooltip: a light lime that is not one of the tokens
      "lime" => "bg-[#a3d65c]",
      "c2" => "bg-chart-2",
      "c3" => "bg-chart-3",
      "c4" => "bg-chart-4",
      "c5" => "bg-chart-5"
    }
  }

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
    assigns =
      assigns
      |> assign(:geo, line_geo(assigns))
      |> assign(:c, %{
        svg: @svg,
        grid: @grid,
        axis: @axis,
        axis_on: @axis_on,
        line: @line,
        line_dashed: @line_dashed,
        wipe: @wipe,
        fade: @fade,
        pop: @pop,
        tip: @tip,
        tip_cls: @tip_cls,
        accent: @accent
      })

    ~H"""
    <div
      :if={@head || @sub || (@legend && length(@series) > 1)}
      data-part="line-chart-head"
      class="flex flex-wrap items-start gap-2.5"
    >
      <div data-part="line-chart-title" class="mb-2 flex items-baseline gap-2.5">
        <b
          data-part="line-chart-figure"
          data-head=""
          class="font-display text-[30px] leading-9 font-semibold tracking-[-.03em] tabular-nums"
        >{@head}</b><span data-part="line-chart-sub" class="text-muted" data-sub="">{@sub}
        <%= if @sub_delta do %>
          ·
          <span data-part="line-chart-delta" class={["font-semibold", delta_color(@sub_delta_tone)]}>{@sub_delta}</span>
        <% end %></span>
      </div>
      <span class="min-w-0 flex-1"></span>
      <span
        data-part="line-chart-legend"
        class="inline-flex items-center gap-4 text-[13px] text-ink-2"
        data-legend=""
      >
        <span
          :for={s <- @geo.legend}
          data-part="line-chart-legend-item"
          class="inline-flex items-center gap-[7px]"
        ><i
          :if={s.dashed}
          data-part="line-chart-legend-dash"
          class="inline-block w-3.5 border-t-[1.5px] border-dashed border-chart-ghost"
        ></i><i
          :if={!s.dashed}
          data-part="line-chart-legend-swatch"
          class="inline-block size-[9px] rounded-[2px]"
          style={"background:" <> s.color}
        ></i>{s.name}</span>
      </span>
    </div>
    <div
      id={@id}
      data-chart=""
      class={cx([@geo.svg && "relative", @class])}
      phx-hook={@geo.svg && "LedgerUI.LineChart"}
      data-part="line-chart"
      data-lu-chart-data={@geo.json}
      data-lu-config={@geo.config}
      {@rest}
    >
      <svg
        :if={@geo.svg}
        data-part="line-chart-svg"
        class={[@c.svg, "max-h-[260px]"]}
        viewBox={@geo.viewbox}
        role="img"
        aria-label={@label}
      >
        <defs>
          <linearGradient id={@id <> "-fill"} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color={@c.accent} stop-opacity=".18" />
            <stop offset="1" stop-color={@c.accent} stop-opacity="0" />
          </linearGradient>
        </defs>
        <%= for g <- @geo.grid do %>
          <line data-part="line-chart-gridline" class={@c.grid} x1={g.x1} x2={g.x2} y1={g.y} y2={g.y} />
          <text data-part="line-chart-axis" class={@c.axis} x={g.tx} y={g.ty} text-anchor="end">
            {g.label}
          </text>
        <% end %>
        <text
          :for={l <- @geo.xlabels}
          data-part="line-chart-x-label"
          class={[@c.axis, @c.axis_on]}
          data-state={l.on && "on"}
          data-i={l.i}
          x={l.x}
          y={l.y}
          text-anchor="middle"
        >
          {l.text}
        </text>
        <%= for s <- @geo.lines do %>
          <path
            :if={s.area}
            data-part="line-chart-area"
            class={@c.fade}
            d={s.area}
            fill={"url(##{@id}-fill)"}
          />
          <path
            data-part="line-chart-line"
            class={[if(s.dashed, do: @c.line_dashed, else: @c.line), @c.wipe]}
            d={s.d}
            style={"stroke:" <> s.color}
          />
          <circle
            :if={!s.dashed}
            data-part="line-chart-endpoint"
            class={["fill-accent-500 stroke-panel [stroke-width:2.5]", @c.pop]}
            cx={s.ex}
            cy={s.ey}
            r="4"
          />
        <% end %>
        <g data-part="line-chart-hover" {st(@geo.hover_style)}>
          <line
            data-part="line-chart-guide"
            class="stroke-chart-ghost [stroke-dasharray:3_3]"
            y1={@geo.pt}
            y2={@geo.pb}
            x1={@geo.pin && @geo.pin.x}
            x2={@geo.pin && @geo.pin.x}
          />
          <circle
            :for={{s, si} <- Enum.with_index(@geo.lines)}
            data-part="line-chart-dot"
            class={
              if s.dashed,
                do: "fill-panel stroke-chart-ghost [stroke-width:1.5]",
                else: "fill-panel stroke-accent-500 [stroke-width:2.5]"
            }
            data-s={si}
            r={if s.dashed, do: "3.5", else: "6"}
            cx={@geo.pin && @geo.pin.x}
            cy={@geo.pin && Enum.at(@geo.pin.ys, si)}
          />
        </g>
        <rect
          data-part="line-chart-hit"
          class="cursor-crosshair"
          x={@geo.pl}
          y={@geo.pt}
          width={@geo.iw}
          height={@geo.ih}
          fill="transparent"
        />
      </svg>
      <div :if={@geo.svg} data-part="line-chart-tip" class={@c.tip} {st(@geo.tip_style)}>
        <%= if @geo.pin do %>
          <b data-part="line-chart-tip-title" class={@c.tip_cls["title"]}>{@geo.pin.title}</b>
          <div
            :for={[name, value, kind] <- @geo.pin.rows}
            data-part="line-chart-tip-row"
            class={@c.tip_cls["row"]}
          >
            <i data-part="line-chart-tip-dot" class={[@c.tip_cls["dot"], @c.tip_cls["kinds"][kind]]}></i><span
              data-part="line-chart-tip-name"
              class={@c.tip_cls["name"]}
            >{name}</span><em data-part="line-chart-tip-value" class={@c.tip_cls["value"]}>{value}</em>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp delta_color("neg"), do: "text-neg"
  defp delta_color(_), do: "text-pos"

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
      config: nil,
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
          color: tok(s[:color]) || @accent,
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
      |> Enum.map(&%{name: &1.name, dashed: !!&1[:dashed], color: tok(&1[:color]) || @accent})

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
      config: Jason.encode!(@tip_cls),
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

  # a segment carries the SVG transform rotate(-90 90 90): its pivot is the viewBox origin; `data-state=dim`
  # (hook) fades the others while one is hovered
  @donut_seg "cursor-pointer [transform-box:view-box] [transform-origin:0_0] transition-[opacity,stroke-width] duration-150 " <>
               "animate-[mo-donut_7s_ease-out] data-[state=dim]:opacity-[.28]! motion-reduce:animate-none"
  @donut_row "flex cursor-default items-center gap-2.5 rounded-md border-t border-line px-1 py-[9px] text-sm " <>
               "transition-colors duration-[120ms] data-[state=on]:bg-hover"

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
      |> assign(:seg_class, @donut_seg)
      |> assign(:row_class, @donut_row)
      |> assign(
        :center_value,
        assigns.center_value || (total > 0 && assigns.value_format.(total)) || ""
      )

    ~H"""
    <div
      id={@id}
      class={cx(["relative mx-auto mt-1 mb-3 size-[180px]", @class])}
      data-donut=""
      phx-hook="LedgerUI.DonutChart"
      data-part="donut-chart"
      {@rest}
    >
      <%= if @segs != [] do %>
        <svg
          data-part="donut-chart-svg"
          viewBox={@viewbox}
          class="size-full animate-[mo-dspin_7s_cubic-bezier(.2,.8,.2,1)] motion-reduce:animate-none"
          role="img"
          aria-label={@label}
        >
          <circle
            :for={s <- @segs}
            data-part="donut-chart-segment"
            class={@seg_class}
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
        <div
          data-part="donut-chart-center"
          class="pointer-events-none absolute inset-0 flex flex-col items-center justify-center"
        >
          <span
            data-part="donut-chart-center-label"
            class="text-[11px] font-medium tracking-[.08em] text-muted"
            data-k
            data-lu-default={@center_label}
          >{@center_label}</span><b
            data-part="donut-chart-center-value"
            class="text-[24px] leading-[30px] font-semibold tracking-[-.02em] tabular-nums"
            data-v
            data-lu-default={@center_value}
          >{@center_value}</b>
        </div>
      <% end %>
    </div>
    <%= if @rows do %>
      <div
        :for={s <- @segs}
        data-part="donut-chart-row"
        class={@row_class}
        data-row={s.i}
      >
        <i
          data-part="donut-chart-swatch"
          class="size-[9px] rounded-[2px]"
          style={"background:" <> s.color}
        ></i>{s.name}<span
          data-part="donut-chart-value"
          class="ml-auto font-semibold tabular-nums"
        >{s.display}</span><span
          data-part="donut-chart-percent"
          class="w-[52px] text-right text-[13px] text-muted tabular-nums"
        >{s.percent}%</span>
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
          color: tok(s[:color]) || Enum.at(@chart_colors, rem(i, length(@chart_colors))),
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

  # each bar grows from its base, once
  @wf_bar "[transform-box:fill-box] origin-bottom transition-transform duration-700 ease-[cubic-bezier(.2,.8,.2,1)] " <>
            "starting:scale-y-0 motion-reduce:transition-none"

  def waterfall_chart(assigns) do
    assigns =
      assigns
      |> assign(:wf, waterfall_geo(assigns))
      |> assign(
        svg: @svg,
        grid: @grid,
        axis: @axis,
        axis_strong: @axis_strong,
        bar: @wf_bar
      )

    ~H"""
    <div id={@id} data-wf="" data-part="waterfall-chart" class={@class} {@rest}>
      <svg
        :if={@wf}
        data-part="waterfall-chart-svg"
        viewBox={@wf.viewbox}
        class={@svg}
        role="img"
        aria-label={@label}
      >
        <%= for g <- @wf.grid do %>
          <line data-part="waterfall-chart-gridline" class={@grid} x1="40" x2="420" y1={g.y} y2={g.y} />
          <text data-part="waterfall-chart-axis" class={@axis} x="34" y={g.ty} text-anchor="end">
            {g.label}
          </text>
        <% end %>
        <%= for b <- @wf.bars do %>
          <rect
            data-part="waterfall-chart-bar"
            class={@bar}
            style={"transition-delay:#{b.delay}s"}
            x={b.x}
            y={b.y}
            width="38"
            height={b.h}
            rx="6"
            fill={b.color}
          >
            <title>{b.name} {b.label}</title>
          </rect>
          <text
            data-part="waterfall-chart-label"
            class="fill-ink text-xs font-medium tabular-nums"
            x={b.cx}
            y={b.ly}
            text-anchor="middle"
          >
            {b.label}
          </text>
          <text
            data-part="waterfall-chart-name"
            class={if b.total, do: @axis_strong, else: @axis}
            x={b.cx}
            y="254"
            text-anchor="middle"
          >
            {b.name}
          </text>
          <line
            :if={b.connector}
            data-part="waterfall-chart-connector"
            class="stroke-chart-ghost [stroke-dasharray:2_3]"
            x1={b.x1}
            x2={b.x2}
            y1={b.cy}
            y2={b.cy}
          />
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
          color: tok(s[:color]) || wf_color(total?, s.value),
          delay: Float.round(i * 0.08, 2),
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

  defp wf_color(true, _), do: "var(--lu-chart-1)"
  defp wf_color(_, v) when v < 0, do: "var(--lu-neg)"
  defp wf_color(_, _), do: "var(--lu-pos)"

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

  # a column grows from its base, once (the delay staggers them)
  @bar "relative min-w-0 flex-1 origin-bottom transition-transform duration-700 ease-[cubic-bezier(.2,.8,.2,1)] " <>
         "starting:scale-y-0 motion-reduce:transition-none"

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
            "height:#{num(v / assigns.max * 100)}%;transition-delay:#{Float.round(min(i, 13) * 0.08, 2)}s",
          title: Enum.at(assigns.titles, i)
        }
      end)

    assigns =
      assigns
      |> assign(:bars, bars)
      |> assign(:strip_style, if(style != "", do: style))
      |> assign(:bar, @bar)
      |> assign(
        :radius,
        if(assigns.shape == "square", do: "rounded-[2px]", else: "rounded-[6px_6px_3px_3px]")
      )

    ~H"""
    <div
      class={cx(["flex h-[140px] items-end gap-2.5", @class])}
      {st(@strip_style)}
      data-part="bar-chart"
      {@rest}
    >
      <div
        :for={b <- @bars}
        data-part="bar-chart-bar"
        class={[@bar, @radius, if(b.on, do: "bg-accent-500", else: "bg-chart-5")]}
        style={b.style}
        title={b.title}
      >
      </div>
    </div>
    <div
      :if={@labels != []}
      data-part="bar-chart-labels"
      class="mt-2 flex flex-wrap items-center justify-between gap-2.5 text-xs leading-4 text-muted"
    >
      <span :for={l <- @labels} data-part="bar-chart-label">{l}</span>
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

  @heat_th "p-1 text-center text-[12.5px] leading-4 font-medium whitespace-nowrap text-muted"
  @heat_cell "grid h-7 min-w-0 animate-[mo-heat_7s_ease-out_both] place-items-center rounded-xs text-xs font-medium tabular-nums motion-reduce:animate-none"
  @heat_levels %{
    5 => "bg-accent-600 text-(--lu-on-accent)",
    4 => "bg-accent-400 text-white",
    3 => "bg-accent-200 text-accent-900",
    2 => "bg-accent-100 text-accent-800",
    1 => "bg-accent-50 text-accent-700"
  }

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
                  level: level(v, assigns.thresholds)
                }
            end)
        }
      end)

    assigns =
      assigns
      |> assign(:data, rows)
      |> assign(:th, @heat_th)
      |> assign(:cell, @heat_cell)
      |> assign(:levels, @heat_levels)

    ~H"""
    <table
      class={cx(["w-full table-fixed border-separate border-spacing-0 text-sm", @class])}
      data-part="cohort-heatmap"
      {@rest}
    >
      <thead data-part="cohort-heatmap-head">
        <tr>
          <th data-part="cohort-heatmap-corner" class={[@th, "w-10"]}></th>
          <th :for={c <- @columns} data-part="cohort-heatmap-column" class={@th}>{c}</th>
        </tr>
      </thead>
      <tbody data-part="cohort-heatmap-body">
        <tr :for={r <- @data} data-part="cohort-heatmap-row" class="hover:[&>td]:bg-hover">
          <td
            data-part="cohort-heatmap-label"
            class="w-10 p-0.5 pr-2.5 text-[13px] whitespace-nowrap text-ink-2"
          >
            {r.label}
          </td>
          <td
            :for={c <- r.cells}
            data-part="cohort-heatmap-cell"
            class="p-0.5 whitespace-nowrap text-ink-2"
          >
            <div
              :if={c}
              data-part="cohort-heatmap-value"
              class={[@cell, @levels[c.level]]}
            >
              {c.text}
            </div>
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
      class={cx(["m-0 flex list-none flex-col gap-3 p-0", @class])}
      data-part="bar-list"
      {@rest}
    >
      <li :for={i <- @items} data-part="bar-list-item" class="flex flex-col gap-1.5">
        <div
          data-part="bar-list-row"
          class="flex flex-wrap items-center justify-between gap-2.5 text-[13px]"
        >
          <span data-part="bar-list-label">{i.label}</span><b
            data-part="bar-list-value"
            class="tabular-nums"
          >{i.value}</b>
        </div>
        <div
          data-part="bar-list-track"
          class="h-1 overflow-hidden rounded-xs bg-sunken"
          aria-hidden="true"
        >
          <i
            data-part="bar-list-bar"
            class="block h-full rounded-xs bg-accent-500"
            style={"width:#{i.width}%"}
          ></i>
        </div>
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
    0 => "var(--heat0, var(--lu-bg-sunken))",
    1 => "var(--heat1, color-mix(in oklab, var(--lu-accent-500) 25%, var(--lu-bg-sunken)))",
    2 => "var(--heat2, color-mix(in oklab, var(--lu-accent-500) 50%, var(--lu-bg-sunken)))",
    3 => "var(--heat3, color-mix(in oklab, var(--lu-accent-500) 75%, var(--lu-bg-sunken)))",
    4 => "var(--heat4, var(--lu-accent-500))"
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
      <div data-part="heatmap-grid" role="img" aria-label={@label} style={@grid_style}>
        <i :for={c <- @cells} data-part="heatmap-cell" title={c.title} style={@cell_style <> c.bg}></i>
      </div>
      <div
        :if={@less}
        data-part="heatmap-scale"
        class="mt-2 flex flex-wrap items-center gap-1 text-xs leading-4 text-muted"
        aria-hidden="true"
      >
        <span data-part="heatmap-less">{@less}</span>
        <i
          :for={bg <- @scale}
          data-part="heatmap-swatch"
          style={@cell_style <> "background:" <> bg}
        ></i>
        <span data-part="heatmap-more">{@more}</span>
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

  # classes of the nodes the `LedgerUI.Chart` hook creates (the Tailwind scan only reads `lib/`)
  @chart_cls %{
    "svg" => @svg,
    "gridline" => @grid,
    "axis" => @axis,
    "line" => @line,
    "seg" =>
      "cursor-pointer transition-[opacity,stroke-width] duration-150 data-[state=dim]:opacity-[.28]!"
  }

  def chart(assigns) do
    assigns =
      assigns
      |> assign(:options_json, json(assigns.options))
      |> assign(:formatters_json, Jason.encode!(assigns.formatters))
      |> assign(:canvas_id, assigns.id <> "-canvas")
      |> assign(:cls_json, Jason.encode!(@chart_cls))

    ~H"""
    <div
      id={@id}
      class={cx(["relative", @class])}
      phx-hook="LedgerUI.Chart"
      data-lu-cls={@cls_json}
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
