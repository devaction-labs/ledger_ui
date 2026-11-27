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
  @line_report "fill-none [stroke-width:2] [stroke-linecap:round] [stroke-dasharray:5_5]"
  # the entrance plays once: the line is wiped in from the left (a clip, so dashed series keep their dash),
  # the area fades, the end point pops
  @wipe "[clip-path:inset(-6px_-6px_-6px_0)] transition-[clip-path] duration-[1200ms] ease-[cubic-bezier(.4,0,.2,1)] " <>
          "starting:[clip-path:inset(-6px_100%_-6px_0)] motion-reduce:transition-none"
  @fade "transition-opacity delay-[250ms] duration-[900ms] ease-out starting:opacity-0 motion-reduce:transition-none"
  @pop "[transform-box:fill-box] origin-center transition-[scale,opacity] delay-[900ms] duration-[450ms] " <>
         "ease-[cubic-bezier(.34,1.56,.64,1)] starting:scale-0 starting:opacity-0 motion-reduce:transition-none"

  # the tooltip: the server draws the pinned one, the hook builds the others from this config
  @tip "pointer-events-none absolute z-[2] min-w-[170px] rounded-lg border border-line bg-panel px-3 py-2.5 text-[13px] shadow-md"
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

  @tip_cls_json Jason.encode!(@tip_cls)

  @head_class %{
    "lg" => "font-display text-[30px] leading-9 font-semibold tracking-[-.03em] tabular-nums",
    "md" => "font-display text-[24px] leading-[30px] font-semibold tracking-[-.03em] tabular-nums"
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

  # -- pt-BR formatters ---------------------------------------------------------------------------
  # The same outputs as the formatters of the same name in the `LedgerUI.Chart` hook, for the
  # server-rendered charts (`value_format={&Chart.format_k/1}`, `axis_format=...`).

  @doc """
  `12_000` -> `"12 mil"`, `1_500` -> `"1,5 mil"`; below 1000 the number as is (`"500"`).
  Hook name: `thousands_br`.
  """
  def format_thousands_br(v), do: if(abs(v) >= 1000, do: dec(v / 1000) <> " mil", else: dec(v))

  @doc """
  `12_000` -> `"12k"`, `1_500` -> `"1,5k"` (decimal comma); below 1000 the number as is. Hook name: `k`.
  """
  def format_k(v), do: if(abs(v) >= 1000, do: dec(v / 1000) <> "k", else: dec(v))

  @doc """
  `12_000` -> `"R$ 12 mil"`, `1_500` -> `"R$ 1,5 mil"`, `500` -> `"R$ 500"`. Hook name: `brl_thousands`.
  """
  def format_brl_thousands(v) do
    "R$ " <> if(abs(v) >= 1000, do: dec(v / 1000) <> " mil", else: dec(v))
  end

  @doc """
  The compact pt-BR amount, one decimal only when needed: `850` -> `"R$ 850"`, `850_000` -> `"R$ 850 mil"`,
  `2_600_000` -> `"R$ 2,6 mi"`, `10_414_000` -> `"R$ 10,4 mi"`, `1_200_000_000` -> `"R$ 1,2 bi"`.
  Hook name: `brl_compact`.
  """
  def format_brl_compact(v) do
    a = abs(v)

    cond do
      a >= 1_000_000_000 -> "R$ " <> dec(v / 1_000_000_000) <> " bi"
      a >= 1_000_000 -> "R$ " <> dec(v / 1_000_000) <> " mi"
      a >= 1000 -> "R$ " <> dec(v / 1000) <> " mil"
      true -> "R$ " <> dec(v)
    end
  end

  @doc """
  The full amount with two decimals: `1234.56` -> `"R$ 1.234,56"`, `-5` -> `"-R$ 5,00"`.
  Hook name: `brl_full` (the hook's `brl` keeps its simpler output).
  """
  def format_brl_full(v) do
    cents = round(abs(v) * 100)
    int = cents |> div(100) |> Integer.to_string() |> group_br()
    frac = cents |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    sign = if v < 0 and cents > 0, do: "-", else: ""
    "#{sign}R$ #{int},#{frac}"
  end

  # one decimal at most, comma separator: 1.5 -> "1,5", 12.0 -> "12"
  defp dec(v) do
    r = Float.round(v * 1.0, 1)

    if r == Float.round(r),
      do: Integer.to_string(round(r)),
      else: String.replace("#{r}", ".", ",")
  end

  defp group_br(digits) do
    digits |> String.reverse() |> String.replace(~r/(\d{3})(?=\d)/, "\\1.") |> String.reverse()
  end

  defp rng(min, max) when max == min, do: 1.0
  defp rng(min, max), do: max - min

  # -- line chart -------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :labels, :list, default: [], doc: "X axis labels, one per point."

  attr :series, :list,
    default: [],
    doc:
      "`[%{name: .., values: [..], area: bool | %{opacity: n}, dashed: bool, dash_style: \"default\" | \"report\", color: css, band: %{lower: [..], upper: [..]}, band_opacity: n, band_label: text}]`. A `nil` in `values` is a point without data: the line breaks there (no 0 is drawn), the area does not fill it and the default tooltip shows an em dash. `area: true` is the accent gradient; `area: %{opacity: .16}` is a flat fill in the series colour. `dash_style: \"report\"` draws a dashed series at 2px with a `5 5` dash and its legend dash and hover dot in the series colour. `band` is an uncertainty band (same length as `values`, `nil` outside it) drawn behind the lines, with a legend item `band_label` (default: the translated \"Uncertainty band\"). Without series only the empty container is rendered."

  attr :min, :any, default: nil, doc: "Lowest value of the axis (default: lowest of the data)."
  attr :max, :any, default: nil
  attr :ticks, :integer, default: 4, doc: "Gaps of the Y axis (`ticks + 1` grid lines)."
  attr :label_every, :integer, default: 1, doc: "Draw one X label every N points."

  attr :axis_width, :integer,
    default: nil,
    doc:
      "Left margin of the plot (room for the Y labels), in px. Default: the width of the longest Y label (at least 46)."

  attr :split, :any,
    default: nil,
    doc:
      "`%{at: index, before: \"realizado\", after: \"projeção\"}`: a dashed vertical line between the points `at` and `at + 1`, with a text on each side (default: the translated \"actual\" / \"projection\")."

  attr :width, :integer,
    default: 640,
    doc:
      "Width of the server-rendered SVG (first paint). In the browser the hook re-lays the chart to the measured width of its container, so text and strokes keep their CSS size."

  attr :height, :integer,
    default: 250,
    doc: "Height of the chart in CSS pixels (the same on the server and after the hook measured)."

  attr :label, :string, default: nil, doc: "`aria-label` of the SVG."
  attr :head, :string, default: nil, doc: "Big figure above the chart (`+$70,320`)."

  attr :head_size, :string,
    default: "lg",
    values: ~w(lg md),
    doc: "`lg`: 30px figure; `md`: 24px (the report card)."

  attr :sub, :string, default: nil, doc: "Muted text after the figure (`since January`)."

  slot :sub_content,
    doc:
      "Rich content after `sub` (before the delta), e.g. a coloured change in the middle of the text."

  attr :legend, :any,
    default: :auto,
    doc:
      "`:auto` (default; also `true`): legend only with more than one series, with a band legend item or with `legend_note`. `:always`: legend even with a single series. `:never` (or `false`): no legend. The strings `\"auto\"`, `\"always\"` and `\"never\"` are accepted."

  attr :legend_note, :string,
    default: nil,
    doc:
      "Free text in muted after the legend items (same size as the legend), e.g. `\"No projection · 7 months of history\"`. With `legend: :auto` it makes the legend show; `:never` hides it."

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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def line_chart(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: {:pt, "chart.line"})

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
        line_report: @line_report,
        wipe: @wipe,
        fade: @fade,
        pop: @pop,
        tip: @tip,
        tip_cls: @tip_cls,
        accent: @accent
      })
      |> assign(:head_class, @head_class[assigns.head_size])
      |> assign(:show_head, !!(assigns.head || assigns.sub || assigns.sub_content != []))
      |> then(&assign(&1, :show_legend, show_legend?(&1)))

    # The geometry (`geo`) and the legend are data: they are sent every time. The classes are not.
    assigns =
      settle(assigns, changed0,
        c: [],
        head_class: [:head_size],
        show_head: [:head, :sub, :sub_content]
      )

    ~H"""
    <div
      :if={@show_head || @head || @sub || @show_legend}
      data-part="line-chart-head"
      class="flex flex-wrap items-start gap-2.5"
    >
      <div data-part="line-chart-title" class="mb-2 flex items-baseline gap-2.5">
        <b
          data-part="line-chart-figure"
          data-head=""
          class={@head_class}
        >{@head}</b><span data-part="line-chart-sub" class="text-muted" data-sub="">{@sub}{render_slot(
          @sub_content
        )}
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
          :if={s.dashed && !s.band}
          data-part="line-chart-legend-dash"
          class={s.dash_class}
          {st(s.dash_style)}
        ></i><i
          :if={!s.dashed && !s.band}
          data-part="line-chart-legend-swatch"
          class="inline-block size-[9px] rounded-[2px]"
          style={"background:" <> s.color}
        ></i><i
          :if={s.band}
          data-part="line-chart-legend-band"
          class="inline-block h-[9px] w-3.5 rounded-[2px]"
          style={"background:" <> s.color <> ";opacity:.22"}
        ></i>{s.name}</span><span
          :if={@legend_note}
          data-part="line-chart-legend-note"
          class="text-muted"
        >{@legend_note}</span>
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
        <path
          :for={b <- @geo.bands}
          data-part="line-chart-band"
          class="stroke-none"
          data-s={b.s}
          d={b.d}
          fill={b.color}
          fill-opacity={b.opacity}
        />
        <%= if @geo.split do %>
          <line
            data-part="line-chart-split"
            class="stroke-chart-ghost [stroke-dasharray:3_3]"
            x1={@geo.split.x}
            x2={@geo.split.x}
            y1={@geo.pt}
            y2={@geo.pb}
          />
          <text
            data-part="line-chart-split-label"
            data-side="before"
            class="fill-muted font-sans text-[11px]"
            x={@geo.split.xb}
            y={@geo.split.y}
            text-anchor="end"
          >
            {@geo.split.before}
          </text>
          <text
            data-part="line-chart-split-label"
            data-side="after"
            class="fill-ink-2 font-sans text-[11px] font-medium"
            x={@geo.split.xa}
            y={@geo.split.y}
          >
            {@geo.split.after}
          </text>
        <% end %>
        <%= for s <- @geo.lines do %>
          <path
            :if={s.area}
            data-part="line-chart-area"
            class={@c.fade}
            d={s.area}
            fill={s.area_fill || "url(##{@id}-fill)"}
            fill-opacity={s.area_opacity}
          />
          <path
            data-part="line-chart-line"
            class={[
              cond do
                s.report -> @c.line_report
                s.dashed -> @c.line_dashed
                true -> @c.line
              end,
              @c.wipe
            ]}
            d={s.d}
            style={"stroke:" <> s.color}
          />
          <circle
            :if={!s.dashed}
            data-part="line-chart-endpoint"
            style={is_nil(s.ex) && "display:none"}
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
              cond do
                s.report -> "fill-panel [stroke-width:1.5]"
                s.dashed -> "fill-panel stroke-chart-ghost [stroke-width:1.5]"
                true -> "fill-panel stroke-accent-500 [stroke-width:2.5]"
              end
            }
            data-s={si}
            r={if s.dashed, do: "3.5", else: "6"}
            cx={@geo.pin && @geo.pin.x}
            cy={@geo.pin && Enum.at(@geo.pin.ys, si)}
            style={dot_style(@geo.pin, si, s)}
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
            <i
              data-part="line-chart-tip-dot"
              class={[@c.tip_cls["dot"], tip_kind_class(@c.tip_cls["kinds"], kind)]}
              {st(tip_kind_style(kind))}
            ></i><span
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

  defp legend_mode(v) when v in [false, :never, "never"], do: :never
  defp legend_mode(v) when v in [:always, "always"], do: :always
  defp legend_mode(_), do: :auto

  defp show_legend?(a) do
    case legend_mode(a.legend) do
      :never -> false
      :always -> true
      :auto -> length(a.series) > 1 || a.geo.band_legend || a.legend_note not in [nil, ""]
    end
  end

  defp line_geo(%{series: []} = a) do
    %{
      svg: false,
      legend: [],
      json: nil,
      grid: [],
      xlabels: [],
      lines: [],
      bands: [],
      split: nil,
      band_legend: false,
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
    {w, h, pr, pt, pb} = {a.width, a.height, 14, 12, 26}
    n = length(a.labels)

    # a `nil` value is a point without data: it breaks the line and takes no part in the axis range
    # the uncertainty bands (`band.lower` / `band.upper`) are part of the domain, so they stay inside the plot
    all =
      a.series
      |> Enum.flat_map(fn s -> s.values ++ band_limits(s[:band]) end)
      |> Enum.reject(&is_nil/1)

    {lo, hi} = if all == [], do: {0, 1}, else: {Enum.min(all), Enum.max(all)}
    min = a.min || lo
    max = a.max || hi
    range = rng(min, max)

    # the Y labels first: the left margin is the width of the longest one (46px at least)
    tick_labels = for t <- 0..a.ticks, do: a.axis_format.(min + (max - min) * t / a.ticks)
    pl = a.axis_width || axis_margin(tick_labels)
    iw = w - pl - pr
    ih = h - pt - pb
    x = fn i -> if n == 1, do: pl + iw / 2, else: pl + i * iw / (n - 1) end
    y = fn v -> pt + ih - (v - min) / range * ih end

    grid =
      for {t, label} <- Enum.zip(0..a.ticks, tick_labels) do
        v = min + (max - min) * t / a.ticks
        yy = y.(v)

        %{
          x1: pl,
          x2: w - pr,
          y: num(yy * 1.0),
          tx: pl - 8,
          ty: num(yy + 4.0),
          label: label
        }
      end

    xlabels =
      for {l, i} <- Enum.with_index(a.labels), rem(i, a.label_every) == 0 or i == n - 1 do
        %{i: i, x: num(x.(i) * 1.0), y: h - 6, text: l, on: a.pin == i}
      end

    lines =
      Enum.map(a.series, fn s ->
        pts =
          s.values
          |> Enum.with_index()
          |> Enum.map(fn
            {nil, _} -> nil
            {v, i} -> {x.(i), y.(v)}
          end)

        runs = pts |> Enum.chunk_by(&is_nil/1) |> Enum.reject(&(hd(&1) == nil))
        holes? = Enum.any?(pts, &is_nil/1)
        ds = Enum.map(runs, &run_path(&1, holes?))
        last = pts |> Enum.reject(&is_nil/1) |> List.last()

        {area_fill, area_opacity} = area_paint(s[:area], tok(s[:color]) || @accent)

        area =
          if s[:area] && runs != [] do
            runs
            |> Enum.zip(ds)
            |> Enum.map_join(" ", fn {run, d} ->
              {lx, _} = List.last(run)
              {fx, _} = hd(run)
              "#{d} L#{num(lx * 1.0)} #{pt + ih} L#{num(fx * 1.0)} #{pt + ih}Z"
            end)
          end

        %{
          d: Enum.join(ds, " "),
          area: area,
          dashed: !!s[:dashed],
          report: !!s[:dashed] && s[:dash_style] == "report",
          area_fill: area_fill,
          area_opacity: area_opacity,
          color: tok(s[:color]) || @accent,
          ex: last && num(elem(last, 0) * 1.0),
          ey: last && num(elem(last, 1) * 1.0)
        }
      end)

    bands = line_bands(a.series, x, y, a.locale)
    split = line_split(a.split, x, pt, a.locale)

    tip = a.tip || fn i -> default_tip(a.series, i, a.value_format, a.locale) end
    tip_title = a.tip_title || fn i -> Enum.at(a.labels, i) end
    tips = for i <- 0..(n - 1)//1, do: %{title: tip_title.(i), rows: tip.(i)}

    pin =
      case a.pin do
        nil ->
          nil

        i ->
          gx = x.(i)

          ys =
            Enum.map(a.series, fn s ->
              case Enum.at(s.values, i) do
                nil -> nil
                v -> y.(v)
              end
            end)

          %{
            title: tip_title.(i),
            rows: tip.(i),
            x: num(gx * 1.0),
            ys: Enum.map(ys, &(&1 && num(&1 * 1.0))),
            hover_style: nil,
            tip_style: tip_style(gx, Enum.find(ys, h / 2, & &1), w, h)
          }
      end

    json =
      %{
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
        ys:
          Enum.map(a.series, fn s ->
            Enum.map(s.values, &(&1 && Float.round(y.(&1) * 1.0, 2)))
          end),
        dashed: Enum.map(a.series, &(!!&1[:dashed])),
        tips: tips
      }
      |> put_band_json(a.series, bands)
      |> put_split_json(a.split)
      |> Jason.encode!()

    legend =
      a.series
      |> Enum.filter(& &1[:name])
      |> Enum.map(fn s ->
        color = tok(s[:color]) || @accent
        report = !!s[:dashed] && s[:dash_style] == "report"

        %{
          name: s.name,
          dashed: !!s[:dashed],
          band: false,
          color: color,
          dash_class:
            if(report,
              do: "inline-block w-4 border-t-2 border-dashed",
              else: "inline-block w-3.5 border-t-[1.5px] border-dashed border-chart-ghost"
            ),
          dash_style: report && "border-color:" <> color
        }
      end)

    band_items =
      for b <- bands,
          do: %{
            name: b.label,
            dashed: false,
            band: true,
            color: b.color,
            dash_class: nil,
            dash_style: nil
          }

    %{
      svg: true,
      viewbox: "0 0 #{w} #{h}",
      grid: grid,
      xlabels: xlabels,
      lines: lines,
      bands: bands,
      split: split,
      band_legend: band_items != [],
      pin: pin,
      hover_style: if(pin, do: nil, else: "display:none"),
      tip_style: (pin && pin.tip_style) || "display:none",
      json: json,
      config: @tip_cls_json,
      legend: legend ++ band_items,
      pl: pl,
      pt: pt,
      pb: pt + ih,
      iw: iw,
      ih: ih
    }
  end

  defp band_limits(%{} = band), do: List.wrap(band[:lower]) ++ List.wrap(band[:upper])
  defp band_limits(_), do: []

  # room for the widest Y label (tabular 11.5px text ~6.6px per char, 8px gap to the grid, 2px spare)
  defp axis_margin(labels) do
    chars = labels |> Enum.map(&String.length(to_string(&1))) |> Enum.max(fn -> 0 end)
    max(46, ceil(chars * 6.6) + 10)
  end

  # `area: true` is the accent gradient (as always); `area: %{opacity: n}` a flat fill in the series colour
  defp area_paint(%{} = area, color), do: {color, area[:opacity] || 0.16}
  defp area_paint(_, _color), do: {nil, nil}

  defp put_band_json(json, series, bands) do
    if bands == [] do
      json
    else
      by_s = Map.new(bands, &{&1.s, &1})

      Map.put(
        json,
        :band,
        series
        |> Enum.with_index()
        |> Enum.map(fn {_, si} -> by_s[si] && %{lower: by_s[si].lower, upper: by_s[si].upper} end)
      )
    end
  end

  defp put_split_json(json, nil), do: json
  defp put_split_json(json, split), do: Map.put(json, :split, %{at: split[:at]})

  # Uncertainty band of a series: a closed path forward along `upper` and back along `lower`, for each run of
  # points that have both limits (a `nil` limit is outside the band).
  defp line_bands(series, x, y, locale) do
    series
    |> Enum.with_index()
    |> Enum.flat_map(fn {s, si} ->
      case s[:band] do
        %{lower: lo, upper: up} when is_list(lo) and is_list(up) ->
          pts =
            lo
            |> Enum.zip(up)
            |> Enum.with_index()
            |> Enum.map(fn
              {{l, u}, i} when not is_nil(l) and not is_nil(u) -> {{x.(i), y.(u)}, {x.(i), y.(l)}}
              _ -> nil
            end)

          runs = pts |> Enum.chunk_by(&is_nil/1) |> Enum.reject(&(hd(&1) == nil))

          d =
            Enum.map_join(runs, " ", fn run ->
              upper = Enum.map(run, &elem(&1, 0))
              lower = run |> Enum.map(&elem(&1, 1)) |> Enum.reverse()
              smooth(upper) <> " " <> String.replace_prefix(smooth(lower), "M", "L") <> " Z"
            end)

          [
            %{
              s: si,
              d: d,
              color: tok(s[:color]) || @accent,
              opacity: s[:band_opacity] || s.band[:opacity] || 0.13,
              label: s[:band_label] || s.band[:label] || I18n.t("chart.band", locale),
              lower: lo,
              upper: up
            }
          ]

        _ ->
          []
      end
    end)
  end

  defp line_split(nil, _x, _pt, _locale), do: nil

  defp line_split(%{at: at} = sp, x, pt, locale) do
    gx = (x.(at) + x.(at + 1)) / 2

    %{
      x: num(gx * 1.0),
      xb: num((gx - 6) * 1.0),
      xa: num((gx + 6) * 1.0),
      y: pt + 8,
      before: sp[:before] || I18n.t("chart.split_before", locale),
      after: sp[:after] || I18n.t("chart.split_after", locale)
    }
  end

  defp dot_style(pin, si, s) do
    hidden = pin && is_nil(Enum.at(pin.ys, si))

    case Enum.filter([s.report && "stroke:" <> s.color, hidden && "display:none"], & &1) do
      [] -> nil
      parts -> Enum.join(parts, ";")
    end
  end

  # `band` is the translucent dot of an uncertainty row (accent, or `band:<css colour>`), inline style
  defp tip_kind_class(_kinds, "band" <> _), do: nil
  defp tip_kind_class(kinds, kind), do: kinds[kind]

  defp tip_kind_style("band:" <> color),
    do: "background:color-mix(in srgb," <> color <> " 30%,transparent)"

  defp tip_kind_style("band"), do: tip_kind_style("band:" <> @accent)
  defp tip_kind_style(_), do: nil

  defp tip_style(gx, gy, w, h) do
    "left:#{num(gx / w * 100)}%;top:#{num(gy / h * 100)}%;transform:translate(calc(-100% - 14px),calc(-100% - 8px))"
  end

  # a point without data (`nil`) shows an em dash
  defp default_tip(series, i, fmt, locale) do
    Enum.flat_map(series, fn s ->
      row = [
        s[:name],
        tip_value(Enum.at(s.values, i), fmt),
        if(s[:dashed], do: "ghost", else: "acc")
      ]

      with %{lower: lo, upper: up} <- s[:band],
           l when not is_nil(l) <- Enum.at(lo, i),
           u when not is_nil(u) <- Enum.at(up, i) do
        label = s[:band_label] || s.band[:label] || I18n.t("chart.band", locale)
        [row, [label, fmt.(l) <> " \u2013 " <> fmt.(u), "band:" <> (tok(s[:color]) || @accent)]]
      else
        _ -> [row]
      end
    end)
  end

  defp tip_value(nil, _fmt), do: "\u2014"
  defp tip_value(v, fmt), do: fmt.(v)

  # one run of consecutive points; with holes in the series a lone point is a zero-length line,
  # so its round cap still shows it
  defp run_path([{x, y}], true), do: "#{smooth([{x, y}])} L#{num(x * 1.0)} #{num(y * 1.0)}"
  defp run_path(run, _holes?), do: smooth(run)

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
               "data-[state=dim]:opacity-[.28]! motion-reduce:animate-none"
  @donut_row "flex cursor-default items-center gap-2.5 rounded-md border-t border-line px-1 py-[9px] text-sm " <>
               "transition-colors duration-[120ms] data-[state=on]:bg-hover"
  # the report canvas rows: no divider on the first one, 13px, 7px of padding
  @donut_row_canvas "flex cursor-default items-center gap-2 border-t border-line py-[7px] text-[13px] text-ink-2 first:border-t-0 " <>
                      "transition-colors duration-[120ms] data-[state=on]:bg-hover"

  attr :id, :string, required: true

  attr :segments, :list,
    default: [],
    doc:
      "`[%{name: .., value: number, color: css, display: \"$96,900\"}]`. Empty: only the container."

  attr :center_label, :string, default: nil
  attr :center_value, :string, default: nil

  attr :center_upcase, :boolean,
    default: false,
    doc: "Write the centre label in capitals (`JAN-OUT/2026`)."

  attr :center_size, :string,
    default: "md",
    values: ~w(md sm),
    doc: "`md`: 24px centre value; `sm`: 19px (the report card)."

  attr :label, :string, default: nil

  attr :layout, :string,
    default: "stack",
    values: ~w(stack side),
    doc:
      "`stack`: the ring centred, the rows below. `side`: the ring on the left and the rows on the right (they wrap below when there is no room); the rows take the report canvas style."

  attr :size, :integer, default: 180, doc: "Side of the ring, in px."
  attr :thickness, :integer, default: 14, doc: "Stroke width of the ring, in px."

  attr :percent_precision, :integer,
    default: 1,
    doc:
      "Decimals of the share (`0`: `52%`). The separator follows the locale (`52,1%` in `pt_BR`)."

  attr :rows_style, :string,
    default: nil,
    values: [nil, "default", "canvas"],
    doc:
      "Look of the plan rows: `canvas` is the report one (no divider on the first row, 13px, 7px padding); default: `canvas` with `layout=\"side\"`, `default` otherwise."

  attr :rows, :boolean,
    default: true,
    doc: "Draw the plan rows (name, value and share) under the ring."

  attr :loop, :boolean,
    default: false,
    doc:
      "The canvas loop: the ring fades in and spins in again every 7s (`mo-donut`, `mo-dspin`)."

  attr :value_format, :any, default: &__MODULE__.money/1
  attr :class, :any, default: nil
  attr :rest, :global

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def donut_chart(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: {:pt, "chart.distribution"}, center_label: "chart.total")

    segs = donut_segments(assigns)
    total = Enum.reduce(assigns.segments, 0, &(&1.value + &2))
    side? = assigns.layout == "side"
    canvas_rows? = (assigns.rows_style || if(side?, do: "canvas", else: "default")) == "canvas"
    c = assigns.size / 2

    assigns =
      assigns
      |> assign(:segs, segs)
      |> assign(:viewbox, "0 0 #{assigns.size} #{assigns.size}")
      |> assign(:cx, num(c))
      |> assign(:r, num(c - assigns.thickness / 2 - 13))
      |> assign(:rotate, "rotate(-90 #{num(c)} #{num(c)})")
      |> assign(:side?, side?)
      |> assign(
        :ring_class,
        if(side?,
          do: ["relative flex-none", assigns.class],
          else: ["relative mx-auto mt-1 mb-3 size-[180px]", assigns.class]
        )
      )
      |> assign(
        :ring_style,
        if(assigns.size != 180 or side?, do: "width:#{assigns.size}px;height:#{assigns.size}px")
      )
      |> assign(:seg_class, [
        @donut_seg,
        if(assigns.loop,
          do: "animate-[mo-donut_7s_ease-out_infinite]",
          else: "animate-[mo-donut_7s_ease-out]"
        )
      ])
      |> assign(:row_class, if(canvas_rows?, do: @donut_row_canvas, else: @donut_row))
      |> assign(
        :value_class,
        if(canvas_rows?,
          do: "ml-auto font-medium text-ink tabular-nums",
          else: "ml-auto font-semibold tabular-nums"
        )
      )
      |> assign(
        :percent_class,
        if(canvas_rows?,
          do: "w-11 text-right text-muted tabular-nums",
          else: "w-[52px] text-right text-[13px] text-muted tabular-nums"
        )
      )
      |> assign(
        :center_label_class,
        [
          "text-[11px] font-medium tracking-[.08em] text-muted",
          assigns.center_upcase && "uppercase"
        ]
      )
      |> assign(
        :center_value_class,
        if(assigns.center_size == "sm",
          do: "text-[19px] leading-6 font-semibold tracking-[-.02em] tabular-nums",
          else: "text-[24px] leading-[30px] font-semibold tracking-[-.02em] tabular-nums"
        )
      )
      |> assign(
        :center_value,
        assigns.center_value || (total > 0 && assigns.value_format.(total)) || ""
      )

    # `segs` and `center_value` are data: they are sent every time. The geometry and the classes
    # hang from the attrs.
    assigns =
      settle(assigns, changed0,
        viewbox: [:size],
        cx: [:size],
        r: [:size, :thickness],
        rotate: [:size],
        side?: [:layout],
        ring_class: [:layout, :class],
        ring_style: [:size, :layout],
        seg_class: [:loop],
        row_class: [:rows_style, :layout],
        value_class: [:rows_style, :layout],
        percent_class: [:rows_style, :layout],
        center_label_class: [:center_upcase],
        center_value_class: [:center_size]
      )

    ~H"""
    <%= if @side? do %>
      <div
        data-part="donut-chart-side"
        class="flex flex-wrap items-center justify-center gap-[22px]"
      >
        <.donut_ring
          center_label={@center_label}
          center_label_class={@center_label_class}
          center_value={@center_value}
          center_value_class={@center_value_class}
          cx={@cx}
          id={@id}
          label={@label}
          loop={@loop}
          r={@r}
          rest={@rest}
          ring_class={@ring_class}
          ring_style={@ring_style}
          rotate={@rotate}
          seg_class={@seg_class}
          segs={@segs}
          thickness={@thickness}
          viewbox={@viewbox}
        />
        <div :if={@rows} data-part="donut-chart-rows" class="flex min-w-[250px] flex-1 flex-col">
          <.donut_rows
            percent_class={@percent_class}
            row_class={@row_class}
            segs={@segs}
            value_class={@value_class}
          />
        </div>
      </div>
    <% else %>
      <.donut_ring
        center_label={@center_label}
        center_label_class={@center_label_class}
        center_value={@center_value}
        center_value_class={@center_value_class}
        cx={@cx}
        id={@id}
        label={@label}
        loop={@loop}
        r={@r}
        rest={@rest}
        ring_class={@ring_class}
        ring_style={@ring_style}
        rotate={@rotate}
        seg_class={@seg_class}
        segs={@segs}
        thickness={@thickness}
        viewbox={@viewbox}
      />
      <.donut_rows
        :if={@rows}
        percent_class={@percent_class}
        row_class={@row_class}
        segs={@segs}
        value_class={@value_class}
      />
    <% end %>
    """
  end

  defp donut_ring(assigns) do
    ~H"""
    <div
      id={@id}
      class={cx(@ring_class)}
      data-donut=""
      phx-hook="LedgerUI.DonutChart"
      data-part="donut-chart"
      {st(@ring_style)}
      {@rest}
    >
      <%= if @segs != [] do %>
        <svg
          data-part="donut-chart-svg"
          viewBox={@viewbox}
          class={[
            "size-full motion-reduce:animate-none",
            if(@loop,
              do: "animate-[mo-dspin_7s_cubic-bezier(.2,.8,.2,1)_infinite]",
              else: "animate-[mo-dspin_7s_cubic-bezier(.2,.8,.2,1)]"
            )
          ]}
          role="img"
          aria-label={@label}
        >
          <circle
            :for={s <- @segs}
            data-part="donut-chart-segment"
            class={@seg_class}
            data-i={s.i}
            cx={@cx}
            cy={@cx}
            r={@r}
            fill="none"
            stroke={s.color}
            stroke-width={@thickness}
            stroke-linecap="round"
            stroke-dasharray={s.dash}
            stroke-dashoffset={s.offset}
            transform={@rotate}
          />
        </svg>
        <div
          data-part="donut-chart-center"
          class="pointer-events-none absolute inset-0 flex flex-col items-center justify-center"
        >
          <span
            data-part="donut-chart-center-label"
            class={@center_label_class}
            data-k
            data-lu-default={@center_label}
          >{@center_label}</span><b
            data-part="donut-chart-center-value"
            class={@center_value_class}
            data-v
            data-lu-default={@center_value}
          >{@center_value}</b>
        </div>
      <% end %>
    </div>
    """
  end

  defp donut_rows(assigns) do
    ~H"""
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
        class={@value_class}
      >{s.display}</span><span
        data-part="donut-chart-percent"
        class={@percent_class}
      >{s.percent}%</span>
    </div>
    """
  end

  defp donut_segments(%{segments: []}), do: []

  defp donut_segments(a) do
    total = Enum.reduce(a.segments, 0, &(&1.value + &2))
    r = a.size / 2 - a.thickness / 2 - 13
    c = 2 * :math.pi() * r
    gap = a.thickness / 2
    comma? = I18n.locale(a.locale) == "pt_BR"

    {segs, _} =
      a.segments
      |> Enum.with_index()
      |> Enum.map_reduce(0.0, fn {s, i}, off ->
        share = s.value / total
        len = share * c - gap

        seg = %{
          i: i,
          name: s.name,
          color: tok(s[:color]) || Enum.at(@chart_colors, rem(i, length(@chart_colors))),
          display: s[:display] || a.value_format.(s.value),
          percent: percent(share * 100, a.percent_precision, comma?),
          dash: "#{num(Float.round(len, 3))} #{num(Float.round(c - len, 3))}",
          offset: num(Float.round(-off, 3))
        }

        {seg, off + share * c}
      end)

    segs
  end

  defp percent(v, precision, comma?) do
    text = num(Float.round(v * 1.0, precision))
    if comma?, do: String.replace(text, ".", ","), else: text
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
  attr :label, :string, default: nil, doc: "`aria-label` of the SVG."
  attr :axis_format, :any, default: &__MODULE__.wf_axis/1

  attr :loop, :boolean,
    default: false,
    doc: "The canvas demo: the bars grow again and again (`mo-bar`) instead of once."

  attr :class, :any, default: nil
  attr :rest, :global

  # each bar grows from its base, once
  @wf_bar "[transform-box:fill-box] origin-bottom transition-transform duration-700 ease-[cubic-bezier(.2,.8,.2,1)] " <>
            "starting:scale-y-0 motion-reduce:transition-none"
  @wf_bar_loop "[transform-box:fill-box] origin-bottom animate-[mo-bar_6s_cubic-bezier(.2,.8,.2,1)_infinite] [animation-fill-mode:both] motion-reduce:animate-none"

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def waterfall_chart(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: {:pt, "chart.waterfall"})

    assigns =
      assigns
      |> assign(:wf, waterfall_geo(assigns))
      |> assign(
        svg: @svg,
        grid: @grid,
        axis: @axis,
        axis_strong: @axis_strong,
        bar: if(assigns.loop, do: @wf_bar_loop, else: @wf_bar)
      )

    assigns =
      settle(assigns, changed0,
        svg: [],
        grid: [],
        axis: [],
        axis_strong: [],
        bar: [:loop]
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
            style={"#{if @loop, do: "animation", else: "transition"}-delay:#{b.delay}s"}
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

  attr :loop, :boolean,
    default: false,
    doc: "The canvas loop: the bars grow from the baseline in turn (`mo-bar`, 6s, 80ms apart)."

  attr :y_axis, :boolean,
    default: false,
    doc:
      "Draws value labels to the left, at the bar heights, on \"nice\" ticks computed from the highest value " <>
        "(or `max`). The top tick is then the full height of the strip."

  attr :y_ticks, :list,
    default: nil,
    doc:
      "Explicit tick values (`[0, 1, 2]`); implies `y_axis`. The highest tick is the full height of the strip."

  attr :y_format, :any,
    default: nil,
    doc:
      "Label format of the ticks: a 1-arity function (`&Chart.format_k/1`) or the name of a kit formatter " <>
        "(`\"thousands_br\"`, `\"k\"`, `\"brl_thousands\"`, `\"brl_full\"`), computed on the server. " <>
        "Default: the number, with a decimal comma."

  attr :y_grid, :boolean,
    default: false,
    doc: "Horizontal grid lines at the ticks (needs `y_axis` or `y_ticks`)."

  attr :height, :any, default: nil, doc: "CSS height of the strip (`120px`)."
  attr :width, :any, default: nil, doc: "CSS width of the strip."
  attr :class, :any, default: nil
  attr :rest, :global

  # a column grows from its base, once (the delay staggers them)
  @bar "relative min-w-0 flex-1 origin-bottom transition-transform duration-700 ease-[cubic-bezier(.2,.8,.2,1)] " <>
         "starting:scale-y-0 motion-reduce:transition-none"

  def bar_chart(assigns) do
    changed0 = assigns.__changed__
    {values, labels} = bar_data(assigns)

    ticks =
      cond do
        is_list(assigns.y_ticks) and assigns.y_ticks != [] -> assigns.y_ticks
        assigns.y_axis -> nice_ticks(assigns.max || Enum.max(values, fn -> 0 end))
        true -> []
      end

    top = if ticks == [], do: assigns.max || bar_max(values), else: Enum.max([1.0e-9 | ticks])
    assigns = assign(assigns, values: values, labels: labels, max: top)
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
            "height:#{num(min(v / assigns.max * 100, if(ticks == [], do: 1.0e9, else: 100)))}%;#{if assigns.loop, do: "animation", else: "transition"}-delay:#{Float.round(min(i, 13) * 0.08, 2)}s",
          title: Enum.at(assigns.titles, i)
        }
      end)

    assigns =
      assigns
      |> assign(:bars, bars)
      |> assign(
        :ticks,
        Enum.map(ticks, &%{at: num(&1 / top * 100), label: tick_label(&1, assigns.y_format)})
      )
      |> assign(:grid, if(assigns.y_grid, do: ticks != [], else: false))
      |> assign(:strip_style, if(style != "", do: style))
      |> assign(:bar, @bar)
      |> assign(
        :radius,
        if(assigns.shape == "square", do: "rounded-[2px]", else: "rounded-[6px_6px_3px_3px]")
      )

    # `bars` and `ticks` are data: they are sent every time.
    assigns =
      settle(assigns, changed0,
        grid: [:y_grid, :y_ticks, :y_axis],
        strip_style: [:height, :width],
        bar: [],
        radius: [:shape]
      )

    ~H"""
    <div :if={@ticks != []} class={cx(["flex flex-col", @class])} data-part="bar-chart-frame" {@rest}>
      <div class="flex h-[140px] gap-2" {st(@strip_style)}>
        <div
          data-part="bar-chart-y-axis"
          class="relative w-10 shrink-0 font-mono text-xs leading-4 text-muted tabular-nums"
        >
          <span
            :for={t <- @ticks}
            data-part="bar-chart-y-tick"
            class="absolute right-0 translate-y-1/2 whitespace-nowrap"
            style={"bottom:#{t.at}%"}
          >
            {t.label}
          </span>
        </div>
        <div class="relative min-w-0 flex-1">
          <div
            :for={t <- if(@grid, do: @ticks, else: [])}
            data-part="bar-chart-grid-line"
            class="pointer-events-none absolute inset-x-0 h-px bg-line"
            style={"bottom:#{t.at}%"}
          >
          </div>
          <div class="relative flex h-full items-end gap-2.5" data-part="bar-chart">
            <.bar_chart_bar :for={b <- @bars} b={b} bar={@bar} radius={@radius} loop={@loop} />
          </div>
        </div>
      </div>
      <div
        :if={@labels != []}
        data-part="bar-chart-labels"
        class="mt-2 ml-12 flex flex-wrap items-center justify-between gap-2.5 text-xs leading-4 text-muted"
      >
        <span :for={l <- @labels} data-part="bar-chart-label">{l}</span>
      </div>
    </div>
    <div
      :if={@ticks == []}
      class={cx(["flex h-[140px] items-end gap-2.5", @class])}
      {st(@strip_style)}
      data-part="bar-chart"
      {@rest}
    >
      <.bar_chart_bar :for={b <- @bars} b={b} bar={@bar} radius={@radius} loop={@loop} />
    </div>
    <div
      :if={@labels != [] and @ticks == []}
      data-part="bar-chart-labels"
      class="mt-2 flex flex-wrap items-center justify-between gap-2.5 text-xs leading-4 text-muted"
    >
      <span :for={l <- @labels} data-part="bar-chart-label">{l}</span>
    </div>
    """
  end

  attr :b, :map, required: true
  attr :bar, :string, required: true
  attr :radius, :string, required: true
  attr :loop, :boolean, required: true

  defp bar_chart_bar(assigns) do
    ~H"""
    <div
      data-part="bar-chart-bar"
      class={[
        @bar,
        @radius,
        if(@b.on, do: "bg-accent-500", else: "bg-chart-5"),
        @loop && "origin-bottom animate-[mo-bar_6s_cubic-bezier(.2,.8,.2,1)_infinite]"
      ]}
      style={@b.style}
      title={@b.title}
    >
    </div>
    """
  end

  @doc """
  "Nice" ticks from 0 to just above `max` (about 4 intervals, steps of 1, 2, 2.5 or 5 times a power
  of ten): `nice_ticks(1.7)` -> `[0, 0.5, 1, 1.5, 2]`, `nice_ticks(95)` -> `[0, 25, 50, 75, 100]`.
  """
  def nice_ticks(max) when not is_number(max) or max <= 0, do: [0, 1]

  def nice_ticks(max) do
    raw = max / 4
    pow = :math.pow(10, Float.floor(:math.log10(raw)))
    f = raw / pow
    step = Enum.find([1, 2, 2.5, 5, 10], &(&1 >= f - 1.0e-9)) * pow
    count = ceil(max / step - 1.0e-9)
    for i <- 0..count, do: tick_round(i * step)
  end

  defp tick_round(v) do
    r = Float.round(v * 1.0, 6)
    if r == Float.round(r), do: round(r), else: r
  end

  defp tick_label(v, nil), do: v |> num() |> String.replace(".", ",")
  defp tick_label(v, f) when is_function(f, 1), do: f.(v)
  defp tick_label(v, "thousands_br"), do: format_thousands_br(v)
  defp tick_label(v, "k"), do: format_k(v)
  defp tick_label(v, "brl_thousands"), do: format_brl_thousands(v)
  defp tick_label(v, "brl_compact"), do: format_brl_compact(v)
  defp tick_label(v, "brl_full"), do: format_brl_full(v)

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
    changed0 = assigns.__changed__

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

    assigns = settle(assigns, changed0, th: [], cell: [], levels: [])

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
    changed0 = assigns.__changed__
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

    assigns =
      settle(assigns, changed0,
        grid_style: [:columns, :size],
        cell_style: [:size, :shape],
        scale: []
      )

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

  @doc """
  The generic, options-driven chart: ApexCharts-shaped options drawn as SVG by the `LedgerUI.Chart`
  hook (supported subset only; everything else is ignored).

  ## Stacked bars

  `chart: %{type: "bar", stacked: true}` with several series piles the series up, in order, from the
  baseline (bottom to top for columns, left to right with `plotOptions: %{bar: %{horizontal: true}}`).
  Each segment is its own `rect` with `data-part="chart-stack-segment"` (`data-series`, `data-index`).
  Positive values pile up from 0, negative ones down from 0; the axis spans the stack totals (its top is raised to a round step) unless
  `yaxis.min`/`max` are given. `plotOptions.bar.borderRadius` rounds only the outermost segment
  (default: square).

      <.chart id="seg" options={%{
        chart: %{type: "bar", stacked: true, height: 280},
        series: [%{name: "Loja", data: [12, 18]}, %{name: "Online", data: [7, 9]}],
        xaxis: %{categories: ["Jan", "Fev"]}
      }} />

  ## Range band on the X axis

  `annotations: %{xaxis: [%{x: "Mar", x2: "Mai", tone: "neg", label: %{text: "Ruptura"}}]}` draws a
  translucent rectangle (`data-part="chart-band"`, opacity `.15`, `opacity` overrides it) behind the
  series. `x`/`x2` are a category (text) or an index (number, fractions allowed); without `x2` the
  band covers that one category. On bar charts the band covers whole slots; on line charts it runs
  from point to point. `tone` is `neg`, `warn`, `pos` or `info` (default) and uses the theme
  tokens; `fillColor` is accepted only as a theme variable (`"var(--lu-chart-3)"`), a loose hex is
  ignored. `label.text` is written at the top of the band.

  ## Projection bars, whiskers and the "today" line (bar)

    * `plotOptions: %{bar: %{projectedFrom: 7}}` (an index or a category name): from that category on
      the bars (simple and stacked) are translucent (`projectedFillOpacity`, default `.28`) with a dashed
      outline in their own colour (`projectedStrokeDashArray`, default `"3 2"`; `projectedStrokeWidth`,
      default `1.2`), marked `data-projected`.
    * `series[].error: %{lower: [..], upper: [..]}` draws an interval whisker (a stem with two 6px caps,
      `data-part="chart-whisker"`) on the bars that have both limits, only from `projectedFrom` on, and
      the axis grows to fit the upper limits (simple bars).
    * `annotations: %{xaxis: [%{x: 6, split: %{before: "realizado", after: "projeção"}}]}` draws a dashed
      vertical line between the category `x` and the next, with a text on each side (`split: true` uses
      the translated "actual" / "projection"); `line: true` is a line through the category `x`
      (`label.text` writes a text on top). Vertical (column) bars and line charts.
    * `legend: %{projection: true, error: "Faixa"}` adds legend items to the bar chart: the translucent
      swatch and the whisker glyph (`true`: the translated "Projection" / "Uncertainty band").
      With `projection`/`error` (or `legend: %{show: "always"}`) the real series' item, with its name, is
      drawn first, even with a single series; the legend height is reserved above the plot.
    * `yaxis: %{width: 80}` sets the left margin in px; by default it follows the widest Y label
      (46px at least, 70px for horizontal bars).

  ## Markers, curve and dashes (line and area)

    * `markers: %{size: 4}` draws a circle on every point (`data-part="chart-marker"`); a list
      (`size: [0, 4]`) sets it per series, `0` meaning none.
    * `stroke: %{curve: "straight"}`: `"straight"` or `"smooth"` (the default, as before), one value
      for all series or a list per series (`["straight", "smooth"]`).
    * `stroke: %{dashArray: [0, 6]}` becomes `stroke-dasharray`: a number for all series or a list
      per series; `0` is solid.

  ## Shared tooltip

  With a `tooltip` map in the options (and not `enabled: false`), hovering or focusing a category
  shows a vertical guide (a horizontal one for horizontal bars) and a box with the value of each
  series at that category, formatted by `tooltip.y.formatter` (a name from the built-in formatters,
  given through `formatters: %{"tooltip.y.formatter" => "brl_thousands"}`). A `nil` value shows
  "—". `tooltip: %{total: true}` adds a total row (`totalLabel` renames it; handy when stacked).
  Without a `tooltip` option nothing is drawn, so existing charts are unchanged.

  Accessibility: the SVG becomes focusable (`tabindex="0"`); once focused, the arrow keys move
  between categories, `Home`/`End` jump to the first/last one and `Escape` hides the tooltip. The
  box is a polite live region (`role="status"`), and the SVG carries a `<desc>` with every value, so
  the data is available to assistive technology without hovering. (`line_chart/1`, which is
  server-rendered, has hover only.)

  ## Few X labels and missing points

  `xaxis: %{tickAmount: 5}` writes about 5 category labels (first and last always, the others spread
  evenly) instead of all of them; the grid and the data are unchanged. A `nil` in a series' `data`
  is a point without data: the line breaks there (nothing is drawn at 0), an area does not fill it,
  markers skip it, bars skip it, and the tooltip shows "\u2014" for that series.

  ## Formatters

  Formatters are named, since the options travel as JSON; give them with `formatters`
  (`%{"yaxis.labels.formatter" => "k", "tooltip.y.formatter" => "brl_full"}`). Available:

  | name | 12000 | 1500 | 1234.56 |
  |---|---|---|---|
  | `thousands_br` | `12 mil` | `1,5 mil` | `1,2 mil` |
  | `k` | `12k` | `1,5k` | `1,2k` |
  | `brl_thousands` | `R$ 12 mil` | `R$ 1,5 mil` | `R$ 1,2 mil` |
  | `brl_compact` | `R$ 12 mil` | `R$ 1,5 mil` | `R$ 1,2 mil` |
  | `brl_full` | `R$ 12.000,00` | `R$ 1.500,00` | `R$ 1.234,56` |

  `brl_compact` also writes `R$ 2,6 mi` (millions) and `R$ 1,2 bi` (billions).

  plus the older `thousands` (`12k`, no rounding), `thousands_round`, `dollars`, `number_br`
  (`12.000`), `brl` (`R$ 1234,5`: only swaps the decimal point; use `brl_full` for money),
  `percent`, `percent_round`, `round`, `hours`, `minutes` and `none`. For the server-rendered
  `line_chart/1` the same exist as functions (`format_thousands_br/1`, `format_k/1`,
  `format_brl_thousands/1`, `format_brl_compact/1`, `format_brl_full/1`) to pass as `axis_format` / `value_format`.

  ## Options reference
  """
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
    "band" => "pointer-events-none",
    "marker" => "stroke-panel [stroke-width:2]",
    "guide" => "stroke-chart-ghost [stroke-dasharray:3_3]",
    "hit" => "cursor-crosshair",
    "tip" => @tip,
    "tip_title" => @tip_cls["title"],
    "tip_row" => @tip_cls["row"],
    "tip_name" => @tip_cls["name"],
    "tip_value" => @tip_cls["value"],
    "tip_dot" => @tip_cls["dot"],
    "tip_total" => "mt-1 border-t border-line pt-1 font-semibold",
    "seg" =>
      "cursor-pointer transition-[opacity,stroke-width] duration-150 data-[state=dim]:opacity-[.28]!"
  }

  @chart_cls_json Jason.encode!(@chart_cls)

  # `options` and `formatters` are encoded inside the template, not into an assign made here: an
  # assign made in the function body is always marked as changed, so any other attribute changing
  # (`class`) would send the whole JSON again.
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def chart(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:canvas_id, assigns.id <> "-canvas")
      |> then(&settle(&1, changed0, canvas_id: [:id]))

    ~H"""
    <div
      id={@id}
      class={cx(["relative", @class])}
      phx-hook="LedgerUI.Chart"
      data-lu-cls={cls_json()}
      data-options={json(@options)}
      data-formatters={Jason.encode!(@formatters)}
      data-on-cursor={@on_cursor}
      data-lu-chart-label={hook_text("chart.aria", @locale)}
      data-lu-total-label={hook_text("chart.sum", @locale)}
      data-lu-split-before={hook_text("chart.split_before", @locale)}
      data-lu-split-after={hook_text("chart.split_after", @locale)}
      data-lu-projection-label={hook_text("chart.projection", @locale)}
      data-lu-error-label={hook_text("chart.band", @locale)}
      data-part="chart"
      {@rest}
    >
      <div id={@canvas_id} phx-update="ignore" data-canvas></div>
    </div>
    """
  end

  defp cls_json, do: @chart_cls_json

  # A text of the hook: sent only when the locale is not English (the hook's own texts).
  defp hook_text(key, locale) do
    if I18n.locale(locale) == "en", do: nil, else: I18n.t(key, locale)
  end

  defp json(v) when is_binary(v), do: v
  defp json(v), do: Jason.encode!(v)
end
