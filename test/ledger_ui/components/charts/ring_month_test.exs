defmodule LedgerUI.Components.RingMonthTest do
  use ExUnit.Case, async: true

  import LedgerUI.DiffCase

  alias LedgerUI.Components.RingMonth

  @series [
    %{id: :direct, label: "Venda direta", color: "c1", pending: 3_500},
    %{id: :cd, label: "Reposição do CD", color: "c2", pending: 0},
    %{id: :online, label: "Loja online", color: "c3"}
  ]

  defp days_data(n) do
    for d <- 1..n,
        do: %{direct: 1_000 * d, cd: 500 + d * 10, online: if(rem(d, 3) == 0, do: 300, else: 0)}
  end

  defp base(extra \\ %{}) do
    Map.merge(
      %{
        id: "r",
        days: 30,
        today: 24,
        month: ~D[2026-11-01],
        series: @series,
        days_data: days_data(24),
        last_month: for(d <- 1..30, do: 12_000 + d * 100),
        target: 400_000,
        pace: 400_000,
        format: &Integer.to_string(round(&1)),
        size: 380,
        progress_only: false,
        label: nil,
        labels: %{},
        class: nil,
        rest: %{},
        locale: "pt_BR",
        center: [
          %{__slot__: :center, inner_block: nil, label: "Recebimentos", value: "R$ 1", sub: "76%"}
        ]
      },
      extra
    )
  end

  defp render(assigns), do: html(&RingMonth.ring_month/1, assigns)
  defp doc(assigns), do: assigns |> render() |> LazyHTML.from_fragment()
  defp q(doc, sel), do: LazyHTML.query(doc, sel)
  defp count(doc, sel), do: doc |> q(sel) |> Enum.count()
  defp attr(node, name), do: node |> LazyHTML.attribute(name) |> List.first()

  describe "render and a11y" do
    test "role img with a summary, a hidden table with a row per day" do
      d = doc(base())
      [svg] = q(d, "svg") |> Enum.to_list()
      assert attr(svg, "role") == "img"
      assert attr(svg, "aria-label") =~ "Recebimentos: R$ 1, dia 24 de 30"
      assert attr(svg, "aria-label") =~ "Abaixo do ritmo"
      assert count(d, "table.sr-only tbody tr") == 30
      assert count(d, "table.sr-only thead th") == 6
      assert d |> q("table caption") |> LazyHTML.text() == "Recebimentos"
    end

    test "the labels are 1, 8, 15, 22 and 29 and the day 1 mark is at the top" do
      d = doc(base())

      labels =
        d
        |> q("[data-part=ring-month-day-label]")
        |> Enum.map(&LazyHTML.text/1)
        |> Enum.map(&String.trim/1)

      assert labels == ~w(1 8 15 22 29)
      [mark] = q(d, "[data-part=ring-month-start]") |> Enum.to_list()
      assert attr(mark, "x1") == "160"
    end
  end

  describe "geometry" do
    # a spoke is a vertical path `M160 y1Vy2` in a group rotated by the angle of its day
    defp ys(seg) do
      [_, a, b] = Regex.run(~r/^M160 ([\d.]+)V([\d.]+)$/, attr(seg, "d"))
      {tof(a), tof(b)}
    end

    defp tof(s), do: s |> Float.parse() |> elem(0)

    defp rot(d, day) do
      [g] = d |> q("[data-day='#{day}'] > g") |> Enum.to_list()
      [_, deg] = Regex.run(~r/^rotate\(([\d.]+) 160 160\)$/, attr(g, "transform"))
      tof(deg)
    end

    test "one group per day, the stack of day 1 starts at the top, a segment per series with a value" do
      d = doc(base())
      assert count(d, "[data-tgt=day]") == 30
      segs = d |> q("[data-day='1'] path[data-n]") |> Enum.to_list()
      assert Enum.map(segs, &attr(&1, "data-n")) == ~w(s1 s2)
      assert rot(d, 1) == 0.0
      assert count(d, "[data-day='3'] path[data-n]") == 3
      # going outwards: y gets smaller
      starts = Enum.map(segs, &(ys(&1) |> elem(0)))
      assert starts == Enum.sort(starts, :desc)
    end

    test "day 2 is 12 degrees clockwise of day 1 (30 days) and 360/31 with 31 days" do
      assert rot(doc(base()), 2) == 12.0
      d31 = doc(base(%{days: 31, days_data: days_data(24), last_month: []}))
      assert_in_delta rot(d31, 2), 360 / 31, 0.05
    end

    test "future days are grey (data-n x), from the last month; no data, no spoke" do
      d = doc(base())
      [seg] = q(d, "[data-day='25'] path[data-n]") |> Enum.to_list()
      assert attr(seg, "data-n") == "x"
      assert count(doc(base(%{last_month: []})), "[data-day='25'] path[data-n]") == 0
      assert count(doc(base(%{last_month: []})), "[data-day='25'] [data-h]") == 0
    end

    test "the longest day takes the full spoke length" do
      data = for d <- 1..24, do: %{direct: if(d == 5, do: 100, else: 10)}
      d = doc(base(%{last_month: [], days_data: data, series: [hd(@series)]}))
      [seg] = d |> q("[data-day='5'] path[data-n]") |> Enum.to_list()
      {_, y2} = ys(seg)
      assert_in_delta 160 - y2, 125 - 4.5, 0.1
    end

    test "the outer ring: an arc per series with data, a trail for the rest, the pace circle" do
      d = doc(base())
      assert count(d, "[data-tgt=series]") == 3
      assert count(d, "[data-part=ring-month-trail]") == 1
      assert count(d, "[data-part=ring-month-pace]") == 1

      assert count(
               doc(base(%{today: 30, days_data: days_data(30)})),
               "[data-part=ring-month-trail]"
             ) == 0

      assert count(doc(base(%{pace: nil})), "[data-part=ring-month-pace]") == 0
    end
  end

  describe "the seal" do
    defp summary(assigns),
      do: assigns |> doc() |> q("[data-p=s]") |> LazyHTML.text()

    test "below the pace (warn), on the pace (pos), target met" do
      assert summary(base()) =~ "Abaixo do ritmo"
      assert doc(base()) |> q("[data-p=s] [data-t=warn]") |> Enum.count() == 1
      assert summary(base(%{pace: 1})) =~ "No ritmo"

      assert doc(base(%{pace: 1}))
             |> q("[data-p=s] [data-t=pos]")
             |> Enum.count() == 1

      assert summary(base(%{target: 1})) =~ "Meta batida"
      refute summary(base(%{pace: nil, target: nil})) =~ "ritmo"
    end

    test "english, and overrides by `labels`" do
      assert summary(base(%{locale: "en"})) =~ "Below pace"
      assert summary(base(%{labels: %{below_pace: "Atrasado"}})) =~ "Atrasado"
    end

    test "without the slot, the centre has the formatted total and the % of the target" do
      s = summary(base(%{center: [], target: 100_000}))
      assert s =~ "% de"
    end
  end

  describe "progress_only" do
    test "no spokes, no labels, no hook; the ring and the centre stay" do
      d = doc(base(%{progress_only: true}))
      assert count(d, "[data-tgt=day]") == 0
      assert count(d, "[data-part=ring-month-day-label]") == 0
      assert count(d, "[data-tgt=series]") == 3
      assert count(d, "[phx-hook]") == 0
      assert count(doc(base()), "[phx-hook=\"LedgerUI.RingMonth\"]") == 1
    end
  end

  describe "the centre as tooltip" do
    test "a panel per day with data, per series; today and future days; in transit" do
      d = doc(base())
      assert count(d, "[data-p=d]") == 30
      assert count(d, "[data-p=a]") == 3
      today = d |> q("[data-day='24'] [data-p=d]") |> LazyHTML.text()
      assert today =~ "Ainda contando" and today =~ "ter, 24 nov"

      assert d |> q("[data-day='9'] [data-p=d]") |> LazyHTML.text() =~
               "Venda direta liderou"

      future = d |> q("[data-day='27'] [data-p=d]") |> LazyHTML.text()
      assert future =~ "Previsto" and future =~ "mês passado, mesmo dia"

      assert d |> q("[data-n=s1] [data-p=a]") |> LazyHTML.text() =~
               "3500 em trânsito"

      assert d |> q("[data-n=s2] [data-p=a]") |> LazyHTML.text() =~ "Tudo recebido"
    end

    test "the day change against the same day last month, with the locale decimal" do
      text = doc(base()) |> q("[data-day='9'] [data-p=d]") |> LazyHTML.text()
      assert text =~ ~r/[↑↓] \d+,\d%/

      en =
        doc(base(%{locale: "en"}))
        |> q("[data-day='9'] [data-p=d]")
        |> LazyHTML.text()

      assert (en =~ ~r/[↑↓] \d+\.\d%/ and en =~ "Thu, Nov 9") or en =~ "Mon, Nov 9"
    end

    test "series are marked for the hook (id and tabindex are set by it)" do
      [g | _] = doc(base()) |> q("[data-tgt=series]") |> Enum.to_list()
      assert attr(g, "data-id") == "direct"
      assert attr(g, "tabindex") == nil
    end
  end

  describe "validation" do
    test "clear messages" do
      assert_raise ArgumentError, ~r/`days` must be 28, 29, 30 or 31 \(got 27\)/, fn ->
        render(base(%{days: 27}))
      end

      assert_raise ArgumentError, ~r/`today` must be an integer from 0 to `days` \(30\)/, fn ->
        render(base(%{today: 31}))
      end

      assert_raise ArgumentError, ~r/at most 5 series/, fn ->
        render(base(%{series: for(i <- 1..6, do: %{id: i, label: "s"})}))
      end

      assert_raise ArgumentError, ~r/color "c9"/, fn ->
        render(base(%{series: [%{id: 1, label: "s", color: "c9"}]}))
      end

      assert_raise ArgumentError, ~r/31 entries but `days` is 30/, fn ->
        render(base(%{days_data: days_data(31)}))
      end
    end
  end

  describe "change tracking" do
    test "each source patches without stale output" do
      each_source(&RingMonth.ring_month/1, base(),
        today: 20,
        pace: 100,
        target: 10,
        month: ~D[2026-12-01],
        locale: "en",
        progress_only: true,
        label: "Other",
        size: 240,
        series: [%{id: :direct, label: "X", color: "c4"}, Enum.at(@series, 1), List.last(@series)],
        labels: %{counting: "Hoje"}
      )

      each_source(&RingMonth.ring_month/1, base(),
        days_data: List.update_at(days_data(24), 3, &%{&1 | direct: 9_999}),
        last_month: for(d <- 1..30, do: 5_000 + d)
      )
    end

    test "changing only `today` or one day does not resend the whole SVG" do
      b = base()
      {full, _} = first(&RingMonth.ring_month/1, b)
      today = patch(&RingMonth.ring_month/1, b, today: 23)

      one_day =
        patch(&RingMonth.ring_month/1, b,
          days_data: List.update_at(days_data(24), 3, &%{&1 | direct: 2})
        )

      pace = patch(&RingMonth.ring_month/1, b, pace: 123)

      IO.puts(
        "MEASURE html=#{byte_size(render(b))} first=#{byte_size(full)} today=#{byte_size(today)} one=#{byte_size(one_day)} pace=#{byte_size(pace)}"
      )

      # measured: html 22 KB, first render 23 KB, today 1.1 KB, one day 0.75 KB, pace 205 B
      assert byte_size(render(b)) < 25_000
      assert byte_size(today) < byte_size(full) / 10
      assert byte_size(one_day) < byte_size(full) / 10
      assert byte_size(pace) < byte_size(full) / 5
    end
  end
end
