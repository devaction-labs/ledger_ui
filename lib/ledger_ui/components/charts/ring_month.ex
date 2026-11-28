defmodule LedgerUI.Components.RingMonth do
  @moduledoc """
  The month as a ring: one spoke per day (day 1 at the top, clockwise), the outer ring with the
  share of each series and a hollow circle where the pace says the total should be. Drawn on the
  server as SVG (no JavaScript needed to read it).

      <.ring_month id="receb" days={30} today={24} month={~D[2026-11-01]}
        series={[%{id: :direct, label: "Venda direta", color: "c1", pending: 3_500}, ...]}
        days_data={@per_day} last_month={@last_month}
        target={400_000} pace={313_300} format={&brl/1}>
        <:center label="Recebimentos" value="R$ 303,6 mil" sub="76% de R$ 400 mil" />
      </.ring_month>

    * `series`: up to 5 `%{id, label, color: "c1".."c5", pending: number | nil}` (colours are the
      `--lu-series-1..5` tokens, utilities `bg-series-N`, `stroke-series-N`...).
    * `days_data`: one entry per day (day 1 first), a map `%{series_id => number}` (or a list in the
      order of `series`). Days after `today` are drawn in grey from `last_month`, a list with the
      total of the same day last month.
    * the outer ring spans the elapsed fraction of the month (`today / days`) split by each series'
      share of the total so far; the circle marks `elapsed * pace / total`, and the seal in the centre
      says "Below pace" (warn) when the total is under `pace`, "On pace" (pos) when it is over, and
      "Target met" when it reached `target`.
    * `progress_only` draws only the ring (no spokes, no labels), for a compact card.

  ## Interaction

  The centre is the tooltip. Hovering (or focusing) a spoke dims the other days and the centre shows
  that day (date, total, leading series, change against the same day last month; today shows
  "Still counting", future days the last month's value as "Expected"). Hovering an arc of the outer
  ring lights only that series on the spokes and the ring, and the centre shows its total, share and
  what is in transit. This is plain CSS (`:has()`, `:hover` and `data-active`); the `LedgerUI.RingMonth`
  hook adds the keyboard (arrows walk the days with a roving tabindex, `Esc` goes back to the summary) and
  links the rows of a `breakdown_list` (`ring={id}`): their `data-lu-series` rows light the series here.

  Accessibility: the SVG is `role="img"` with a summary in `aria-label`, and a visually hidden table has
  the values of every day.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Chart
  alias LedgerUI.I18n

  # geometry, in the units of a 320 box (the SVG scales with `size`)
  @c 160.0
  @ring_r 140.0
  @r0 80.0
  @lmax 45.0
  @inset 4.5
  @arc_inset 3.0 / 140 * 180 / :math.pi()
  @trail_gap 5.0 / 140 * 180 / :math.pi()
  @trail_end 2.5 / 140 * 180 / :math.pi()

  @ns ~w(c1 c2 c3 c4 c5)

  # All the utilities of the spokes, arcs and centre panels live here, once, as descendant variants
  # (the day/series groups and panels carry only `data-*`). `data-n` is the series of a segment or group
  # (`x` is a grey future spoke), `data-p` a centre panel (`s` summary, `d` day, `a` series) and `data-k` its parts.
  # An element is active when hovered OR has `data-active` (set by the hook for the keyboard and the linked list).
  @root_cls [
    "relative inline-block max-w-full",
    # paths: round caps, no fill, 150ms opacity
    "[&_path]:fill-none [&_path]:[stroke-linecap:round] [&_path]:[transition:opacity_.15s] motion-reduce:[&_path]:transition-none [&_[data-tgt]]:[transition:opacity_.15s] motion-reduce:[&_[data-tgt]]:transition-none",
    "[&_foreignObject]:pointer-events-none",
    # series colours and widths
    "[&_[data-n=s1]]:stroke-series-1 [&_[data-n=s2]]:stroke-series-2 [&_[data-n=s3]]:stroke-series-3 [&_[data-n=s4]]:stroke-series-4 [&_[data-n=s5]]:stroke-series-5 [&_[data-n=x]]:stroke-line-strong",
    "[&_[data-tgt=day]_[data-n^=s]]:[stroke-width:8] [&_[data-n=x]]:[stroke-width:9] [&_[data-tgt=series]]:[stroke-width:5]",
    # hit areas
    "[&_[data-h]]:cursor-pointer [&_[data-h]]:stroke-transparent [&_[data-tgt=series]_[data-h]]:[stroke-width:18] [&_[data-tgt]]:focus-visible:outline-none",
    # centre panels: hidden unless active, the summary shown unless something is active
    "[&_[data-p]]:absolute [&_[data-p]]:inset-0 [&_[data-p]]:size-full [&_[data-p]]:flex-col [&_[data-p]]:items-center [&_[data-p]]:justify-center [&_[data-p]]:gap-[3.4px] [&_[data-p]]:text-center [&_[data-p=s]]:flex [&_[data-p=d]]:hidden [&_[data-p=a]]:hidden",
    "[&_[data-tgt]:is(:hover,[data-active])_[data-p]]:flex",
    "[&:has([data-tgt]:is(:hover,[data-active]))_[data-p=s]]:hidden",
    "[&_[data-p]>:first-child]:text-[12px] [&_[data-p]>:first-child]:leading-[1.25] [&_[data-p]>:first-child]:whitespace-nowrap [&_[data-p]>:first-child]:text-muted",
    "[&_[data-p]>b]:text-[20px] [&_[data-p]>b]:leading-[1.2] [&_[data-p]>b]:font-semibold [&_[data-p]>b]:tracking-[-.03em] [&_[data-p]>b]:whitespace-nowrap [&_[data-p]>b]:text-ink [&_[data-p]>b]:tabular-nums",
    "[&_[data-p]>:nth-child(3)]:text-[11.5px] [&_[data-p]>:nth-child(3)]:leading-[1.25] [&_[data-p]>:nth-child(3)]:whitespace-nowrap [&_[data-p]>:nth-child(3)]:text-muted [&_[data-p]>:empty]:hidden",
    "[&_[data-t]]:mt-[4px] [&_[data-t]]:inline-flex [&_[data-t]]:h-[20px] [&_[data-t]]:items-center [&_[data-t]]:rounded-[6px] [&_[data-t]]:px-[7px] [&_[data-t]]:text-[11px] [&_[data-t]]:font-medium [&_[data-t]]:whitespace-nowrap",
    "[&_[data-t=pos]]:bg-pos-soft [&_[data-t=pos]]:text-pos [&_[data-t=warn]]:bg-warn-soft [&_[data-t=warn]]:text-warn [&_[data-t=neg]]:bg-neg-soft [&_[data-t=neg]]:text-neg [&_[data-t=neutral]]:bg-sunken [&_[data-t=neutral]]:text-ink-2",
    # a day is active: the other days fade
    "[&:has([data-tgt=day]:is(:hover,[data-active]))_[data-tgt=day]:not(:is(:hover,[data-active]))]:opacity-[.18]",
    # a series is active: only its segments and arc stay lit
    "[&:has([data-tgt=series][data-n=s1]:is(:hover,[data-active]))_[data-tgt=day]_path:not([data-n=s1])]:opacity-[.16] [&:has([data-tgt=series][data-n=s1]:is(:hover,[data-active]))_[data-tgt=series]:not([data-n=s1])]:opacity-25",
    "[&:has([data-tgt=series][data-n=s2]:is(:hover,[data-active]))_[data-tgt=day]_path:not([data-n=s2])]:opacity-[.16] [&:has([data-tgt=series][data-n=s2]:is(:hover,[data-active]))_[data-tgt=series]:not([data-n=s2])]:opacity-25",
    "[&:has([data-tgt=series][data-n=s3]:is(:hover,[data-active]))_[data-tgt=day]_path:not([data-n=s3])]:opacity-[.16] [&:has([data-tgt=series][data-n=s3]:is(:hover,[data-active]))_[data-tgt=series]:not([data-n=s3])]:opacity-25",
    "[&:has([data-tgt=series][data-n=s4]:is(:hover,[data-active]))_[data-tgt=day]_path:not([data-n=s4])]:opacity-[.16] [&:has([data-tgt=series][data-n=s4]:is(:hover,[data-active]))_[data-tgt=series]:not([data-n=s4])]:opacity-25",
    "[&:has([data-tgt=series][data-n=s5]:is(:hover,[data-active]))_[data-tgt=day]_path:not([data-n=s5])]:opacity-[.16] [&:has([data-tgt=series][data-n=s5]:is(:hover,[data-active]))_[data-tgt=series]:not([data-n=s5])]:opacity-25"
  ]

  attr :id, :string,
    required: true,
    doc: "DOM id of the chart; a `breakdown_list` links to it with `ring={id}`."

  attr :days, :integer,
    default: 30,
    values: [28, 29, 30, 31],
    doc: "Days of the month (one spoke each)."

  attr :today, :integer,
    default: nil,
    doc:
      "Days elapsed (0..days); the day `today` is the last one drawn in colour. Default: `days` (a closed month)."

  attr :series, :list,
    default: [],
    doc:
      "Up to 5 series: `[%{id: term, label: \"Direct\", color: \"c1\"..\"c5\", pending: number | nil}]`. `color` defaults to the position; `pending` is what is still in transit."

  attr :days_data, :list,
    default: [],
    doc:
      "One entry per day, day 1 first: a map `%{series_id => number}` or a list of numbers in the order of `series`."

  attr :last_month, :list,
    default: [],
    doc: "Total of each day of the last month (day 1 first): the grey spokes of the days to come."

  attr :month, :any,
    default: nil,
    doc:
      "A `Date` of the month shown: the centre then writes the weekday and month (`seg, 9 nov`). Without it: `Day 9`."

  attr :target, :any, default: nil, doc: "Target of the month (number): the % in the centre."

  attr :pace, :any,
    default: nil,
    doc: "Where the total should be today to hit the target: places the hollow circle."

  attr :format, :any,
    default: nil,
    doc:
      "Function of one number returning the text of a value. Default: the kit's compact number for the locale."

  attr :size, :integer, default: 320, doc: "Side of the chart in px."

  attr :progress_only, :boolean,
    default: false,
    doc: "Only the progress ring (no spokes, no labels, no hover): the compact variant."

  attr :label, :string,
    default: nil,
    doc: "Name of the chart in the `aria-label` and the table caption. Default: the centre label."

  attr :labels, :map,
    default: %{},
    doc:
      "Overrides of the texts by key (`:day`, `:total`, `:last_month`, `:below_pace`, `:on_pace`, `:goal_met`, `:counting`, `:forecast`, `:last_same_day`, `:all_received`, `:led`, `:of_received`, `:in_transit`, `:day_n`)."

  attr :class, :any, default: nil
  attr :rest, :global

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  slot :center,
    doc: "The summary in the centre (the slot is read once; its attrs are the texts)." do
    attr :label, :string, doc: "Small text above the value."
    attr :value, :string, doc: "The big figure. Default: the total, formatted."
    attr :sub, :string, doc: "Text under the value. Default: the % of the target."
    attr :seal, :string, doc: "Text of the seal. Default: from the pace and the target."
    attr :seal_tone, :string, doc: "`pos`, `warn`, `neg` or `neutral`."
  end

  def ring_month(assigns) do
    changed0 = assigns.__changed__
    g = build(assigns)

    assigns =
      assigns
      |> assign(:days_geo, g.days)
      |> assign(:arcs, g.arcs)
      |> assign(:trail, g.trail)
      |> assign(:pace_pt, g.pace_pt)
      |> assign(:day_labels, g.day_labels)
      |> assign(:summary, g.summary)
      |> assign(:aria, g.aria)
      |> assign(:caption, g.caption)
      |> assign(:head, g.head)
      |> assign(:rows, g.rows)
      |> assign(:hit_w, g.hit_w)

    assigns =
      settle(assigns, changed0,
        days_geo: [
          :days,
          :today,
          :series,
          :days_data,
          :last_month,
          :month,
          :format,
          :labels,
          :locale,
          :progress_only
        ],
        arcs: [:days, :today, :series, :days_data, :format, :labels, :locale, :progress_only],
        trail: [:days, :today],
        pace_pt: [:days, :today, :series, :days_data, :pace],
        day_labels: [:days, :progress_only],
        summary: [
          :days,
          :today,
          :series,
          :days_data,
          :target,
          :pace,
          :format,
          :center,
          :labels,
          :locale
        ],
        aria: [
          :days,
          :today,
          :series,
          :days_data,
          :target,
          :pace,
          :format,
          :center,
          :label,
          :labels,
          :locale
        ],
        caption: [:center, :label, :locale],
        head: [:series, :labels, :locale, :last_month],
        rows: [:days, :today, :series, :days_data, :last_month, :month, :format, :labels, :locale],
        hit_w: [:days]
      )

    ~H"""
    <div
      id={@id}
      data-part="ring-month"
      class={[root_cls(), @class]}
      style={box_style(@size)}
      phx-hook={hook(@progress_only)}
      {@rest}
    >
      <svg
        data-part="ring-month-svg"
        viewBox="0 0 320 320"
        class="block h-auto w-full overflow-visible"
        role="img"
        aria-label={@aria}
      >
        <defs :if={@days_geo != []}>
          <path id={@id <> "-h"} d="M160 90V28" stroke-width={@hit_w} />
        </defs>
        <.ring_day :for={d <- @days_geo} :key={d.day} id={@id} d={d} />
        <.ring_series :for={a <- @arcs} :key={a.s} a={a} />
        <path
          :if={@trail}
          data-part="ring-month-trail"
          class="stroke-line"
          d={@trail}
          fill="none"
          stroke-width="2.5"
          stroke-linecap="round"
        />
        <line
          data-part="ring-month-start"
          class="stroke-ink"
          x1="160"
          y1="29"
          x2="160"
          y2="11"
          stroke-width="2"
          stroke-linecap="round"
        />
        <circle
          :if={@pace_pt}
          data-part="ring-month-pace"
          class="fill-panel stroke-ink"
          cx={@pace_pt.x}
          cy={@pace_pt.y}
          r="6"
          stroke-width="2"
        />
        <text
          :for={l <- @day_labels}
          :key={l.day}
          data-part="ring-month-day-label"
          class="fill-muted font-sans text-[11.5px]"
          x={l.x}
          y={l.y}
          text-anchor="middle"
        >
          {l.day}
        </text>
        <foreignObject
          x="84"
          y="108"
          width="152"
          height="104"
        >
          <.ring_panel p={@summary} part="s" />
        </foreignObject>
      </svg>
      <table data-part="ring-month-table" class="sr-only" phx-no-format>
        <caption>{@caption}</caption><thead><tr><th :for={h <- @head} scope="col">{h}</th></tr></thead><tbody><tr :for={r <- @rows} :key={r.day} data-day={r.day}><th scope="row">{r.title}</th><td :for={c <- r.cells}>{c}</td></tr></tbody>
      </table>
    </div>
    """
  end

  defp root_cls, do: @root_cls

  attr :id, :string, required: true
  attr :d, :map, required: true

  # `phx-no-format`: the markup is written on one line per group, so the HTML has no indentation (a ring is 30+ groups)
  defp ring_day(assigns) do
    ~H"""
    <g data-tgt="day" data-day={@d.day} phx-no-format><g transform={"rotate(#{@d.rot} 160 160)"}><path :for={s <- @d.segs} data-n={s.n} d={s.d} /><use :if={@d.panel} data-h href={"##{@id}-h"} /></g><foreignObject :if={@d.panel} x="84" y="108" width="152" height="104"><.ring_panel p={@d.panel} part="d" /></foreignObject></g>
    """
  end

  attr :a, :map, required: true

  defp ring_series(assigns) do
    ~H"""
    <g data-tgt="series" data-n={@a.s} data-id={@a.id} phx-no-format><path d={@a.d} /><path data-h d={@a.d} /><foreignObject x="84" y="108" width="152" height="104"><.ring_panel p={@a.panel} part="a" /></foreignObject></g>
    """
  end

  attr :p, :map, required: true
  attr :part, :string, required: true

  # label, value, sub (may be empty), seal (`data-t` = tone)
  defp ring_panel(assigns) do
    ~H"""
    <div data-p={@part} phx-no-format><span>{@p.label}</span><b>{@p.value}</b><span>{@p.sub}</span><span :if={@p.seal} data-t={@p.seal.tone}>{@p.seal.text}</span></div>
    """
  end

  defp hook(true), do: nil
  defp hook(false), do: "LedgerUI.RingMonth"
  defp box_style(size), do: "width:#{size}px"

  # -- the geometry ------------------------------------------------------------------------------

  defp build(a) do
    days = a.days
    today = a.today || days

    unless is_integer(days) and days in 28..31,
      do:
        raise(ArgumentError, "ring_month: `days` must be 28, 29, 30 or 31 (got #{inspect(days)})")

    unless is_integer(today) and today in 0..days//1,
      do:
        raise(
          ArgumentError,
          "ring_month: `today` must be an integer from 0 to `days` (#{days}), got #{inspect(today)}"
        )

    if length(a.days_data) > days,
      do:
        raise(
          ArgumentError,
          "ring_month: `days_data` has #{length(a.days_data)} entries but `days` is #{days}"
        )

    series = series!(a.series)
    loc = I18n.locale(a.locale)
    fmt = a.format || default_format(loc)
    overrides = Map.new(a.labels, fn {k, v} -> {to_string(k), v} end)
    t = fn key, b -> text(overrides, key, loc, b) end

    rows = for d <- 1..days, do: day_values(Enum.at(a.days_data, d - 1), series)
    last = for d <- 1..days, do: num_or_nil(Enum.at(a.last_month, d - 1))

    totals = Enum.map(rows, &Enum.sum/1)
    scale_max = Enum.max([0.0 | totals] ++ Enum.reject(last, &is_nil/1))
    k = if scale_max > 0, do: @lmax / scale_max, else: 0.0

    past = Enum.take(rows, today)
    by_series = if past == [], do: Enum.map(series, fn _ -> 0.0 end), else: sum_columns(past)
    total = Enum.sum(by_series)

    elapsed = 360.0 * today / days
    center = List.first(a.center) || %{}

    {summary, status} = summary(a, center, total, today, fmt, t)
    label = a.label || center[:label] || t.("label", [])

    %{
      days:
        if(a.progress_only,
          do: [],
          else: day_geo(days, today, rows, totals, last, series, a, k, fmt, t, loc)
        ),
      arcs: arcs(series, by_series, total, elapsed, fmt, t),
      trail: trail(elapsed, today),
      pace_pt: pace_pt(a.pace, total, elapsed),
      day_labels: if(a.progress_only, do: [], else: day_labels(days)),
      summary: summary,
      aria:
        aria(
          t.("aria", label: label, total: summary.value, today: today, days: days),
          summary.sub,
          status
        ),
      caption: label,
      head:
        [t.("day", [])] ++
          Enum.map(series, & &1.label) ++
          [t.("total", [])] ++ if(Enum.any?(last, & &1), do: [t.("last_month", [])], else: []),
      rows: table_rows(days, today, rows, totals, last, fmt, t),
      hit_w: Float.round(2 * :math.pi() * 100 / days, 1)
    }
  end

  defp series!(list) do
    n = length(list)

    if n > 5,
      do: raise(ArgumentError, "ring_month: at most 5 series are allowed (got #{n})")

    for {s, i} <- Enum.with_index(list, 1) do
      color = to_string(s[:color] || "c#{i}")

      color in @ns or
        raise ArgumentError,
              "ring_month: series #{inspect(s[:id])} has color #{inspect(color)}; use one of #{Enum.join(@ns, ", ")}"

      s[:id] != nil or
        raise ArgumentError, "ring_month: every series needs an `id` (series ##{i})"

      n = String.to_integer(String.trim_leading(color, "c"))

      %{
        id: s[:id],
        sid: to_string(s[:id]),
        label: to_string(s[:label] || s[:id]),
        n: n,
        s: "s#{n}",
        pending: num_or_nil(s[:pending])
      }
    end
  end

  defp day_values(nil, series), do: Enum.map(series, fn _ -> 0.0 end)

  defp day_values(entry, series) when is_list(entry) do
    Enum.map(Enum.with_index(series), fn {_, i} -> num(Enum.at(entry, i)) end)
  end

  defp day_values(entry, series) when is_map(entry) do
    Enum.map(series, fn s ->
      num(Map.get(entry, s.id, Map.get(entry, s.sid)))
    end)
  end

  defp num(nil), do: 0.0
  defp num(v) when is_number(v), do: max(v * 1.0, 0.0)

  defp num(v),
    do: raise(ArgumentError, "ring_month: values must be numbers, got #{inspect(v)}")

  defp num_or_nil(nil), do: nil
  defp num_or_nil(v), do: num(v)

  defp sum_columns(rows) do
    rows |> Enum.zip_with(& &1) |> Enum.map(&Enum.sum/1)
  end

  defp polar(r, deg) do
    rad = deg * :math.pi() / 180
    {@c + r * :math.sin(rad), @c - r * :math.cos(rad)}
  end

  defp f(v) do
    r = Float.round(v * 1.0, 1)
    if r == Float.round(r), do: trunc(r), else: r
  end

  # a spoke is drawn vertical (day 1 at the top) and its group is rotated: the path is `M160 y1 V y2`
  defp seg_line(from, to, n) do
    start = from + @inset
    stop = max(to - @inset, start + 0.1)
    %{n: n, d: "M160 #{f(@c - start)}V#{f(@c - stop)}"}
  end

  defp day_geo(days, today, rows, totals, last, series, a, k, fmt, t, loc) do
    leader_fun = fn vals ->
      {v, i} = vals |> Enum.with_index() |> Enum.max_by(&elem(&1, 0), fn -> {0.0, 0} end)
      if v > 0, do: Enum.at(series, i)
    end

    for d <- 1..days do
      deg = (d - 1) * 360.0 / days
      vals = Enum.at(rows, d - 1)
      lastv = Enum.at(last, d - 1)
      total = Enum.at(totals, d - 1)

      {segs, panel} =
        cond do
          d <= today ->
            {segs, _} =
              series
              |> Enum.zip(vals)
              |> Enum.reject(fn {_, v} -> v <= 0 end)
              |> Enum.map_reduce(@r0, fn {s, v}, cur ->
                vk = v * k
                {seg_line(cur, cur + vk, s.s), cur + vk}
              end)

            {segs, past_panel(d, today, total, lastv, leader_fun.(vals), a, fmt, t, loc)}

          lastv && lastv > 0 ->
            vk = lastv * k
            {[seg_line(@r0, @r0 + vk, "x")], future_panel(d, lastv, a, fmt, t, loc)}

          true ->
            {[], nil}
        end

      %{day: d, rot: f(deg), segs: segs, panel: panel}
    end
  end

  defp past_panel(d, today, total, lastv, leader, a, fmt, t, loc) do
    seal =
      cond do
        d == today -> %{text: t.("counting", []), tone: "neutral"}
        lastv && lastv > 0 -> delta_seal(total, lastv, loc)
        true -> nil
      end

    %{
      label: date_label(a.month, d, t, loc),
      value: fmt.(total),
      sub: if(leader, do: t.("led", series: leader.label), else: ""),
      seal: seal
    }
  end

  defp future_panel(d, lastv, a, fmt, t, loc) do
    %{
      label: date_label(a.month, d, t, loc),
      value: fmt.(lastv),
      sub: t.("last_same_day", []),
      seal: %{text: t.("forecast", []), tone: "neutral"}
    }
  end

  defp delta_seal(total, lastv, loc) do
    pct = (total - lastv) / lastv * 100
    text = decimal(abs(pct), loc)

    if pct >= 0,
      do: %{text: "↑ " <> text <> "%", tone: "pos"},
      else: %{text: "↓ " <> text <> "%", tone: "neg"}
  end

  defp decimal(v, loc) do
    s = :erlang.float_to_binary(Float.round(v * 1.0, 1), decimals: 1)
    if loc == "pt_BR", do: String.replace(s, ".", ","), else: s
  end

  defp date_label(nil, d, t, _loc), do: t.("day_n", day: d)

  defp date_label(%{year: y, month: m}, d, t, loc) do
    case Date.new(y, m, d) do
      {:ok, date} ->
        wd = I18n.list("date.weekdays", loc) |> Enum.at(Date.day_of_week(date) |> rem(7))
        mo = I18n.list("date.months", loc) |> Enum.at(m - 1)
        wd = abbr(wd, loc)
        mo = abbr(mo, loc)

        if loc == "pt_BR", do: "#{wd}, #{d} #{mo}", else: "#{wd}, #{mo} #{d}"

      _ ->
        t.("day_n", day: d)
    end
  end

  defp date_label(_other, d, t, _loc), do: t.("day_n", day: d)

  defp abbr(name, "pt_BR"), do: name |> String.slice(0, 3) |> String.downcase()
  defp abbr(name, _), do: String.slice(name, 0, 3)

  defp day_labels(days) do
    for d <- [1, 8, 15, 22, 29], d <= days do
      {x, y} = polar(160, (d - 1) * 360.0 / days)
      %{day: d, x: f(x), y: f(y + 3.4)}
    end
  end

  defp arcs(series, by_series, total, elapsed, fmt, t) do
    {out, _} =
      series
      |> Enum.zip(by_series)
      |> Enum.reduce({[], 0.0}, fn {s, v}, {acc, start} ->
        if v > 0 and total > 0 do
          stop = start + elapsed * v / total

          arc = %{
            s: s.s,
            id: s.sid,
            d: arc_path(start, stop),
            panel: series_panel(s, v, total, fmt, t)
          }

          {[arc | acc], stop}
        else
          {acc, start}
        end
      end)

    Enum.reverse(out)
  end

  defp series_panel(s, v, total, fmt, t) do
    pct = round(v / total * 100)

    seal =
      if s.pending && s.pending > 0,
        do: %{text: t.("in_transit", value: fmt.(s.pending)), tone: "neutral"},
        else: %{text: t.("all_received", []), tone: "pos"}

    %{
      label: s.label,
      value: fmt.(v),
      sub: t.("of_received", pct: pct),
      seal: seal
    }
  end

  defp arc_path(start, stop) do
    {s, e} = {start + @arc_inset, stop - @arc_inset}
    {s, e} = if e <= s, do: {(start + stop) / 2 - 0.05, (start + stop) / 2 + 0.05}, else: {s, e}
    sweep(s, e)
  end

  defp sweep(s, e) do
    {x0, y0} = polar(@ring_r, s)
    {x1, y1} = polar(@ring_r, e)
    large = if e - s > 180, do: 1, else: 0
    "M#{f(x0)} #{f(y0)} A#{@ring_r} #{@ring_r} 0 #{large} 1 #{f(x1)} #{f(y1)}"
  end

  defp trail(elapsed, today) do
    s = if today == 0, do: @trail_gap, else: elapsed + @trail_gap
    e = 360.0 - @trail_end
    if e - s > 0.5 and elapsed < 360.0, do: sweep(s, e)
  end

  defp pace_pt(pace, total, elapsed) when is_number(pace) and total > 0 do
    deg = :math.fmod(elapsed * pace / total, 360.0)
    {x, y} = polar(@ring_r, deg)
    %{x: f(x), y: f(y)}
  end

  defp pace_pt(_, _, _), do: nil

  defp summary(a, center, total, today, fmt, t) do
    status = status(a, total, today)

    sub =
      center[:sub] ||
        if(is_number(a.target) and a.target > 0,
          do: t.("of_target", pct: round(total / a.target * 100), target: fmt.(a.target)),
          else: ""
        )

    {text, tone} =
      cond do
        center[:seal] -> {center[:seal], center[:seal_tone] || "neutral"}
        status == :goal -> {t.("goal_met", []), "pos"}
        status == :on -> {t.("on_pace", []), "pos"}
        status == :below -> {t.("below_pace", []), "warn"}
        true -> {nil, nil}
      end

    panel = %{
      label: center[:label] || "",
      value: center[:value] || fmt.(total),
      sub: sub,
      seal: text && %{text: text, tone: tone}
    }

    {panel, text}
  end

  defp status(a, total, today) do
    cond do
      today == 0 -> nil
      is_number(a.target) and a.target > 0 and total >= a.target -> :goal
      is_number(a.pace) and total >= a.pace -> :on
      is_number(a.pace) -> :below
      true -> nil
    end
  end

  defp aria(base, sub, seal) do
    [base, sub, seal]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(". ")
  end

  defp table_rows(days, today, rows, totals, last, fmt, t) do
    has_last? = Enum.any?(last, & &1)

    for d <- 1..days do
      vals = Enum.at(rows, d - 1)
      lastv = Enum.at(last, d - 1)
      past? = d <= today

      cells =
        if(past?, do: Enum.map(vals, &cell(&1, fmt)), else: Enum.map(vals, fn _ -> "" end)) ++
          [if(past?, do: fmt.(Enum.at(totals, d - 1)), else: "")] ++
          if(has_last?, do: [if(lastv, do: fmt.(lastv), else: "")], else: [])

      %{day: d, title: t.("day_n", day: d), cells: cells}
    end
  end

  defp cell(v, _fmt) when v <= 0, do: ""
  defp cell(v, fmt), do: fmt.(v)

  # -- text ---------------------------------------------------------------------------------------

  defp text(overrides, key, loc, bindings) do
    case Map.get(overrides, key) do
      nil -> I18n.t("ring_month." <> key, loc, bindings)
      custom -> interpolate(custom, bindings)
    end
  end

  defp interpolate(text, bindings) do
    Enum.reduce(bindings, text, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  defp default_format("pt_BR"), do: &Chart.format_thousands_br/1

  defp default_format(_) do
    fn v ->
      if abs(v) >= 1000,
        do: Chart.num(Float.round(v / 1000, 1)) <> "k",
        else: Chart.num(Float.round(v * 1.0, 1))
    end
  end
end
