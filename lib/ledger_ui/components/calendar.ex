defmodule LedgerUI.Components.Calendar do
  @moduledoc """
  A calendar for dates that matter (due dates, appointments, deadlines): a month grid or a week
  grid of hours with colored event chips, month/week switching and keyboard navigation; plus
  `due_calendar/1`, the agenda of due items by day.

      <.calendar id="due" view={@view} date={@date} events={@events} locale="pt_BR"
        on_navigate="calendar_navigate" on_view="calendar_view"
        on_select="calendar_select" on_event="calendar_event" />

  The server owns what the calendar shows: `view` and `date` come from your assigns, and the
  toolbar and the keyboard push `on_navigate` (`%{"id", "date", "view"}`), `on_view`,
  `on_select` (`%{"id", "date"}`) and `on_event` (`%{"id", "event", "date"}`). Load the events of
  a period with `calendar_range/3`.

  An event is a map with `:date` and `:title`, and optionally `:id`, `:subtitle`, `:color`
  (`neutral primary secondary info success warning error`), `:start` and `:end` (`"09:00"` or a
  `Time`).

  `variant="mini"` is the compact month in a card (round cells, a dot or a tint on the days
  that have events). `view="day"` is the week grid with a single day, an addition to the README.

  The roving focus and the arrow keys live in the `LedgerUI.Calendar` hook
  (`priv/static/ledger_ui/hooks/calendar.js`), attached only when `on_select` is set.
  """
  use LedgerUI.Component

  import LedgerUI.Components.DatePicker,
    only: [locale_data: 1, to_date: 1, iso: 1, grid_days: 2, pad2: 1]

  import LedgerUI.Components.TimePicker, only: [minutes: 1, hhmm: 1]

  @labels %{
    "en" => %{
      calendar_today: "Today",
      calendar_previous: "Previous",
      calendar_next: "Next",
      calendar_view: "View",
      calendar_month: "Month",
      calendar_week: "Week",
      calendar_day: "Day",
      calendar_all_day: "All day",
      calendar_more: "+%{count} more",
      calendar_more_label: "%{count} more events"
    },
    "pt_BR" => %{
      calendar_today: "Hoje",
      calendar_previous: "Anterior",
      calendar_next: "Próximo",
      calendar_view: "Visualização",
      calendar_month: "Mês",
      calendar_week: "Semana",
      calendar_day: "Dia",
      calendar_all_day: "Dia todo",
      calendar_more: "+%{count} mais",
      calendar_more_label: "%{count} eventos a mais"
    }
  }

  @tones %{
    "neutral" => nil,
    "primary" => "acc",
    "secondary" => "lime",
    "info" => "info",
    "success" => "pos",
    "warning" => "warn",
    "error" => "neg"
  }

  @tints %{
    "primary" => "var(--accent-soft)",
    "secondary" => "var(--lime-soft)",
    "info" => "var(--info-soft)",
    "success" => "var(--pos-soft)",
    "warning" => "var(--warn-soft)",
    "error" => "var(--neg-soft)"
  }

  @cell "height:78px;padding:6px 8px;border-right:1px solid var(--line);border-bottom:1px solid var(--line);font-size:12.5px;display:flex;flex-direction:column;gap:3px;"
  @head "padding:8px 10px;border-bottom:1px solid var(--line)"
  @today "background:var(--inverse);color:var(--on-inverse);border-radius:6px;padding:0 5px;align-self:flex-start;font-weight:600"

  @doc """
  The first and last day shown for `view` around `date`, to load the events of the period.

      calendar_range("month", ~D[2026-10-15])  #=> {~D[2026-09-27], ~D[2026-10-31]}
      calendar_range("week", ~D[2026-10-15], week_start: 1)
  """
  def calendar_range(view, date, opts \\ []) do
    date = to_date(date) || Date.utc_today()
    ws = Keyword.get(opts, :week_start, 0)

    case view do
      "week" ->
        start = week_start_of(date, ws)
        {start, Date.add(start, 6)}

      "day" ->
        {date, date}

      _ ->
        days = grid_days(date, ws)
        {days |> List.first() |> elem(0), days |> List.last() |> elem(0)}
    end
  end

  defp week_start_of(date, ws),
    do: Date.add(date, -Integer.mod(rem(Date.day_of_week(date), 7) - ws, 7))

  defp norm_events(events) do
    for e <- events || [], d = to_date(e[:date]), d != nil do
      e
      |> Map.put(:date, d)
      |> Map.put(:start_m, minutes(e[:start]))
      |> Map.put(:end_m, minutes(e[:end]))
    end
  end

  defp by_date(events), do: Enum.group_by(events, & &1.date)

  attr :id, :string, required: true
  attr :view, :string, default: "month", values: ~w(month week day)
  attr :variant, :string, default: "full", values: ~w(full mini)
  attr :range, :any, default: nil
  attr :marks, :string, default: "dot", values: ~w(dot tint)
  attr :months_shown, :integer, default: 1
  attr :date, :any, default: nil
  attr :today, :any, default: nil
  attr :selected, :any, default: nil
  attr :events, :list, default: []
  attr :legend, :list, default: []
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :months, :list, default: nil
  attr :weekdays, :list, default: nil
  attr :labels, :map, default: %{}
  attr :week_start, :integer, default: 0
  attr :show_weekends, :boolean, default: true
  attr :day_start, :integer, default: 8
  attr :day_end, :integer, default: 18
  attr :max_events, :integer, default: 3
  attr :header, :boolean, default: true
  attr :outside_days, :boolean, default: false
  attr :day_id, :any, default: nil
  attr :interactive_marked_only, :boolean, default: false
  attr :card, :boolean, default: true
  attr :on_navigate, :string, default: nil
  attr :on_view, :string, default: nil
  attr :on_select, :string, default: nil
  attr :on_event, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :event, doc: "Replaces the content of an event chip or block; receives the event map."

  @doc "Renders the calendar."
  def calendar(assigns) do
    lang = if assigns.locale == "pt_BR", do: "pt_BR", else: "en"
    data = locale_data(lang)
    today = to_date(assigns.today) || Date.utc_today()
    date = to_date(assigns.date) || today
    months = assigns.months || data.months
    weekdays = assigns.weekdays || data.weekdays
    labels = Map.merge(@labels[lang], assigns.labels)
    events = norm_events(assigns.events)

    assigns =
      assigns
      |> assign(:today_d, today)
      |> assign(:date_d, date)
      |> assign(:month_names, months)
      |> assign(:day_names, weekdays)
      |> assign(:l, labels)
      |> assign(:evs, by_date(events))
      |> assign(:selected_d, to_date(assigns.selected))
      |> assign(:target_attr, target(assigns.target))
      |> assign(:hook, if(assigns.on_select, do: "LedgerUI.Calendar"))

    if assigns.variant == "mini", do: mini(assigns), else: full(assigns)
  end

  defp target(nil), do: nil
  defp target(t) when is_binary(t), do: t
  defp target(t), do: to_string(t)

  # ---------------------------------------------------------------------------------------
  # Full: month / week / day
  # ---------------------------------------------------------------------------------------

  defp full(assigns) do
    %{date_d: date, view: view, month_names: months, week_start: ws} = assigns

    {prev, next} =
      case view do
        "month" ->
          {Date.shift(Date.beginning_of_month(date), month: -1),
           Date.shift(Date.beginning_of_month(date), month: 1)}

        "week" ->
          {Date.add(date, -7), Date.add(date, 7)}

        "day" ->
          {Date.add(date, -1), Date.add(date, 1)}
      end

    title =
      case view do
        "month" ->
          "#{Enum.at(months, date.month - 1)} #{date.year}"

        "week" ->
          {a, b} = calendar_range("week", date, week_start: ws)
          "#{a.day} #{short(months, a)} – #{b.day} #{short(months, b)} #{b.year}"

        "day" ->
          "#{date.day} #{Enum.at(months, date.month - 1)} #{date.year}"
      end

    assigns =
      assigns
      |> assign(:title, title)
      |> assign(:prev, iso(prev))
      |> assign(:next, iso(next))
      |> assign(:interactive, assigns.on_select != nil)
      |> assign(:grid, full_grid(assigns))
      |> assign(:tabs, [
        {"month", assigns.l.calendar_month},
        {"week", assigns.l.calendar_week},
        {"day", assigns.l.calendar_day}
      ])

    ~H"""
    <div
      id={@id}
      data-part="calendar"
      phx-hook={@hook}
      class={cx(["lu-panel", @class])}
      style="overflow:hidden"
      {@rest}
    >
      <div :if={@header} class="lu-row" style="padding:12px 14px;border-bottom:1px solid var(--line)">
        <b style="font-size:16px">{@title}</b>
        <span class="lu-grow"></span>
        <div class="lu-seg sm" data-lu-single role="tablist">
          <button
            :for={{v, text} <- @tabs}
            aria-selected={to_string(v == @view)}
            class={if v == @view, do: "on", else: ""}
            data-v={String.downcase(text)}
            role="tab"
            type="button"
            disabled={@on_view == nil}
            phx-click={@on_view}
            phx-target={@target_attr}
            phx-value-id={@on_view && @id}
            phx-value-view={@on_view && v}
            phx-value-date={@on_view && iso(@date_d)}
          >
            {text}
          </button>
        </div>
        <button
          aria-label={@l.calendar_previous}
          class="lu-btn icon sm"
          type="button"
          disabled={@on_navigate == nil}
          phx-click={@on_navigate}
          phx-target={@target_attr}
          phx-value-id={@on_navigate && @id}
          phx-value-date={@on_navigate && @prev}
          phx-value-view={@on_navigate && @view}
        >
          <.icon name="chevron-left" />
        </button>
        <button
          aria-label={@l.calendar_next}
          class="lu-btn icon sm"
          type="button"
          disabled={@on_navigate == nil}
          phx-click={@on_navigate}
          phx-target={@target_attr}
          phx-value-id={@on_navigate && @id}
          phx-value-date={@on_navigate && @next}
          phx-value-view={@on_navigate && @view}
        >
          <.icon name="chevron-right" />
        </button>
      </div>
      <%= if @view == "month" do %>
        <div
          style="display:grid;grid-template-columns:repeat(7,1fr)"
          role={@interactive && "grid"}
          aria-label={@interactive && @title}
        >
          <div :for={w <- @grid.weekdays} class="lu-xs lu-muted" style={@grid.head}>{w}</div>
          <div
            :for={c <- @grid.cells}
            style={c.style}
            role={@interactive && "gridcell"}
            tabindex={@interactive && c.tabindex}
            aria-selected={@interactive && to_string(c.selected)}
            aria-current={c.today && @interactive && "date"}
            data-date={@interactive && c.iso}
            phx-click={@on_select}
            phx-target={@target_attr}
            phx-value-id={@on_select && @id}
            phx-value-date={@on_select && c.iso}
          >
            <span style={c.num_style}>{c.day}</span>
            <%= for e <- c.events do %>
              <.chip e={e} on_event={@on_event} id={@id} target={@target_attr} slot={@event} />
            <% end %>
            <button
              :if={c.more > 0}
              type="button"
              class="lu-badge sm"
              style="border:0;cursor:pointer"
              aria-label={String.replace(@l.calendar_more_label, "%{count}", to_string(c.more))}
              phx-click={@on_select}
              phx-target={@target_attr}
              phx-value-id={@on_select && @id}
              phx-value-date={@on_select && c.iso}
            >
              {String.replace(@l.calendar_more, "%{count}", to_string(c.more))}
            </button>
          </div>
        </div>
      <% else %>
        <.time_grid
          grid={@grid}
          on_event={@on_event}
          on_select={@on_select}
          id={@id}
          target={@target_attr}
          slot={@event}
          l={@l}
        />
      <% end %>
    </div>
    """
  end

  defp short(months, date), do: months |> Enum.at(date.month - 1) |> String.slice(0, 3)

  attr :e, :map, required: true
  attr :on_event, :string, default: nil
  attr :id, :string, required: true
  attr :target, :any, default: nil
  attr :slot, :list, default: []

  defp chip(assigns) do
    assigns =
      assign(assigns, :cls, cx(["lu-badge", @tones[assigns.e[:color] || "neutral"], "sm"]))

    ~H"""
    <%= if @on_event do %>
      <button
        type="button"
        class={@cls}
        style="border:0;cursor:pointer;max-width:100%"
        phx-click={@on_event}
        phx-target={@target}
        phx-value-id={@id}
        phx-value-event={@e[:id]}
        phx-value-date={iso(@e.date)}
      >
        <%= if @slot != [] do %>
          {render_slot(@slot, @e)}
        <% else %>
          {@e.title}
        <% end %>
      </button>
    <% else %>
      <span class={@cls}>
        <%= if @slot != [] do %>
          {render_slot(@slot, @e)}
        <% else %>
          {@e.title}
        <% end %>
      </span>
    <% end %>
    """
  end

  defp full_grid(%{view: "month"} = a) do
    %{date_d: date, today_d: today, week_start: ws, evs: evs, day_names: names, selected_d: sel} =
      a

    focus = if Date.compare(date, Date.beginning_of_month(date)) == :lt, do: date, else: date

    cells =
      for {d, in_month?} <- grid_days(date, ws) do
        all = Map.get(evs, d, [])
        {shown, rest} = Enum.split(all, a.max_events)

        %{
          iso: iso(d),
          day: d.day,
          style:
            @cell <> if(in_month?, do: "", else: "background:var(--bg-tray);color:var(--subtle)"),
          num_style: if(d == today, do: @today, else: ""),
          events: shown,
          more: length(rest),
          today: d == today,
          selected: d == sel,
          tabindex: if(d == focus, do: "0", else: "-1")
        }
      end

    %{
      weekdays: names |> Enum.map(&String.slice(&1, 0, 3)) |> rotate(ws),
      head: @head,
      cells: cells
    }
  end

  defp full_grid(%{view: view} = a) do
    %{date_d: date, today_d: today, week_start: ws, evs: evs, day_names: names} = a

    days =
      if view == "day" do
        [date]
      else
        {from, to} = calendar_range("week", date, week_start: ws)

        for d <- Date.range(from, to),
            a.show_weekends or rem(Date.day_of_week(d), 7) in 1..5,
            do: d
      end

    hours = for h <- a.day_start..(a.day_end - 1)//1, do: h

    cols =
      for d <- days do
        all = Map.get(evs, d, [])
        {timed, allday} = Enum.split_with(all, & &1.start_m)

        %{
          iso: iso(d),
          date: d,
          label:
            "#{names |> Enum.at(rem(Date.day_of_week(d), 7)) |> String.slice(0, 3)} #{d.day}",
          today: d == today,
          allday: allday,
          timed: timed
        }
      end

    %{cols: cols, hours: hours, n: length(days), day_start: a.day_start, day_end: a.day_end}
  end

  attr :grid, :map, required: true
  attr :on_event, :string, default: nil
  attr :on_select, :string, default: nil
  attr :id, :string, required: true
  attr :target, :any, default: nil
  attr :slot, :list, default: []
  attr :l, :map, required: true

  defp time_grid(assigns) do
    ~H"""
    <div style={"display:grid;grid-template-columns:56px repeat(#{@grid.n},1fr)"}>
      <div style="padding:8px 10px;border-bottom:1px solid var(--line)"></div>
      <div
        :for={c <- @grid.cols}
        class="lu-xs lu-muted"
        style={"padding:8px 10px;border-bottom:1px solid var(--line);border-left:1px solid var(--line)" <> if(c.today, do: ";color:var(--ink);font-weight:600", else: "")}
      >
        {c.label}
      </div>
      <div class="lu-xs lu-muted" style="padding:6px 8px;border-bottom:1px solid var(--line)">
        {@l.calendar_all_day}
      </div>
      <div
        :for={c <- @grid.cols}
        style="padding:4px;border-bottom:1px solid var(--line);border-left:1px solid var(--line);display:flex;flex-direction:column;gap:3px;min-height:28px"
        data-date={c.iso}
        phx-click={@on_select}
        phx-target={@target}
        phx-value-id={@on_select && @id}
        phx-value-date={@on_select && c.iso}
      >
        <%= for e <- c.allday do %>
          <.chip e={e} on_event={@on_event} id={@id} target={@target} slot={@slot} />
        <% end %>
      </div>
      <%= for h <- @grid.hours do %>
        <div
          class="lu-xs lu-muted mono"
          style="height:48px;padding:4px 8px;border-bottom:1px solid var(--line)"
        >
          {pad2(h)}:00
        </div>
        <div
          :for={c <- @grid.cols}
          style="height:48px;position:relative;border-bottom:1px solid var(--line);border-left:1px solid var(--line)"
          data-date={c.iso}
          data-hour={h}
          phx-click={@on_select}
          phx-target={@target}
          phx-value-id={@on_select && @id}
          phx-value-date={@on_select && c.iso}
        >
          <%= for e <- c.timed, div(e.start_m, 60) == h do %>
            <.block e={e} on_event={@on_event} id={@id} target={@target} slot={@slot} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :e, :map, required: true
  attr :on_event, :string, default: nil
  attr :id, :string, required: true
  attr :target, :any, default: nil
  attr :slot, :list, default: []

  defp block(assigns) do
    e = assigns.e
    top = rem(e.start_m, 60) / 60 * 48
    height = max(((e.end_m || e.start_m + 60) - e.start_m) / 60 * 48, 18)

    assigns =
      assigns
      |> assign(
        :style,
        "position:absolute;left:2px;right:2px;top:#{trunc(top)}px;height:#{trunc(height)}px;z-index:1;overflow:hidden;font-size:11.5px;text-align:left;padding:2px 6px;border:0;border-left:3px solid var(--accent);border-radius:6px;background:var(--accent-soft);color:var(--ink)"
      )
      |> assign(:time, "#{hhmm(e.start_m)}#{if e.end_m, do: "–" <> hhmm(e.end_m)}")

    ~H"""
    <%= if @on_event do %>
      <button
        type="button"
        style={@style <> ";cursor:pointer"}
        phx-click={@on_event}
        phx-target={@target}
        phx-value-id={@id}
        phx-value-event={@e[:id]}
        phx-value-date={iso(@e.date)}
      >
        <.block_body e={@e} time={@time} slot={@slot} />
      </button>
    <% else %>
      <div style={@style}><.block_body e={@e} time={@time} slot={@slot} /></div>
    <% end %>
    """
  end

  defp block_body(assigns) do
    ~H"""
    <%= if @slot != [] do %>
      {render_slot(@slot, @e)}
    <% else %>
      <b style="font-weight:500">{@e.title}</b>
      <div :if={@e[:subtitle]} class="lu-muted">{@e[:subtitle]}</div>
      <div class="lu-muted mono">{@time}</div>
    <% end %>
    """
  end

  # ---------------------------------------------------------------------------------------
  # Mini month
  # ---------------------------------------------------------------------------------------

  defp mini(assigns) do
    %{date_d: date, months_shown: n} = assigns
    first = Date.beginning_of_month(date)
    range = mini_range(assigns.range)

    months =
      for i <- 0..(max(n, 1) - 1) do
        m = Date.shift(first, month: i)

        %{
          title: "#{Enum.at(assigns.month_names, m.month - 1)} #{m.year}",
          cells: mini_cells(m, n, range, assigns)
        }
      end

    letters = assigns.day_names |> Enum.map(&String.first/1) |> rotate(assigns.week_start)

    assigns =
      assigns
      |> assign(:minis, months)
      |> assign(:letters, letters)
      |> assign(:prev, iso(Date.shift(first, month: -1)))
      |> assign(:next, iso(Date.shift(first, month: 1)))
      |> assign(:interactive, assigns.on_select != nil)
      |> assign(:navs, assigns.header and assigns.on_navigate != nil and n == 1)
      |> assign(:tints, @tints)

    ~H"""
    <div
      id={@id}
      data-part="calendar"
      phx-hook={@hook}
      class={cx(["lu-mini-cals", @class])}
      style="display:flex;gap:12px;flex-wrap:wrap"
      {@rest}
    >
      <div
        :for={m <- @minis}
        class={if @card, do: "lu-panel", else: ""}
        style={if @card, do: "padding:14px", else: ""}
      >
        <div :if={@card and @header} class="lu-row" style="margin-bottom:8px">
          <b style="font-size:14px">{m.title}</b>
          <span class="lu-grow"></span>
          <button
            :if={@navs}
            aria-label={@l.calendar_previous}
            class="lu-btn icon ghost sm"
            type="button"
            phx-click={@on_navigate}
            phx-target={@target_attr}
            phx-value-id={@id}
            phx-value-date={@prev}
            phx-value-view="month"
          >
            <.icon name="chevron-left" />
          </button>
          <button
            :if={@navs}
            aria-label={@l.calendar_next}
            class="lu-btn icon ghost sm"
            type="button"
            phx-click={@on_navigate}
            phx-target={@target_attr}
            phx-value-id={@id}
            phx-value-date={@next}
            phx-value-view="month"
          >
            <.icon name="chevron-right" />
          </button>
        </div>
        <div class="lu-cal" role={@interactive && "grid"}>
          <span :for={l <- @letters} class="h">{l}</span>
          <span
            :for={c <- m.cells}
            id={c.id}
            class={c.class}
            style={c.tint && "background:" <> @tints[c.tint]}
            role={@interactive && c.button && "button"}
            tabindex={@interactive && c.button && c.tabindex}
            aria-pressed={@interactive && c.button && to_string(c.selected)}
            data-date={c.iso}
            phx-click={c.button && @on_select}
            phx-target={@target_attr}
            phx-value-id={c.button && @on_select && @id}
            phx-value-date={c.button && @on_select && c.iso}
          >
            {c.day}
          </span>
        </div>
        <div :if={@card and @legend != []} class="lu-row" style="margin-top:10px;gap:12px">
          <span
            :for={{label, color} <- @legend}
            class="lu-xs lu-muted"
            style="display:inline-flex;align-items:center;gap:6px"
          >
            <i style={"width:10px;height:10px;border-radius:3px;background:" <> Map.get(@tints, color, "var(--bg-selected)")}></i>{label}
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp mini_range(nil), do: nil

  defp mini_range(v) do
    case LedgerUI.Components.DatePicker.value_dates(v) do
      [a, b] -> {a, b}
      _ -> nil
    end
  end

  defp mini_cells(month, n, range, a) do
    %{today_d: today, selected_d: sel, evs: evs, week_start: ws, on_select: on_select} = a

    days =
      if n > 1 do
        # side by side months: only the month's own days, padded with empty cells
        for {d, in_month?} <- grid_days(month, ws), do: {d, in_month?, in_month?}
      else
        for {d, in_month?} <- grid_days(month, ws),
            do: {d, in_month?, in_month? or a.outside_days}
      end

    for {d, in_month?, shown?} <- days do
      all = Map.get(evs, d, [])
      first = List.first(all)
      has? = all != [] and in_month?

      cls =
        cx([
          if(in_month?, do: "d", else: "o"),
          (shown? and d == today) && "t",
          (shown? and d == sel) && "s",
          range_class(range, d, shown?),
          (has? and a.marks == "dot") && "dot",
          (has? and a.marks == "tint") && "tint"
        ])

      %{
        iso: iso(d),
        day: if(shown?, do: d.day, else: nil),
        class: if(shown?, do: cls, else: "o"),
        tint: (has? and a.marks == "tint") && color_key(first),
        button: shown? and on_select != nil and (not a.interactive_marked_only or has?),
        selected: d == sel,
        tabindex: if(d == (sel || a.date_d), do: "0", else: "-1"),
        id: day_id(a.day_id, d, in_month?)
      }
    end
  end

  defp color_key(%{color: c}) when c in ["neutral", nil], do: "warning"
  defp color_key(%{color: c}), do: c
  defp color_key(_), do: "warning"

  defp day_id(nil, _, _), do: nil
  defp day_id(_, _, false), do: nil
  defp day_id(f, d, _) when is_function(f, 1), do: f.(d)
  defp day_id(prefix, d, _) when is_binary(prefix), do: "#{prefix}-#{iso(d)}"

  defp range_class({a, b}, d, true) do
    cond do
      a == b -> nil
      d == a -> "rs"
      d == b -> "re"
      Date.compare(d, a) == :gt and Date.compare(d, b) == :lt -> "r"
      true -> nil
    end
  end

  defp range_class(_, _, _), do: nil

  defp rotate(list, n), do: Enum.drop(list, n) ++ Enum.take(list, n)

  # ---------------------------------------------------------------------------------------
  # <.due_calendar>
  # ---------------------------------------------------------------------------------------

  attr :items, :list,
    default: [],
    doc:
      "Maps with `:date`, `:title`, `:subtitle`, `:amount` (text or number) and optionally `:status` (`overdue`, `today`, `scheduled`) and `:status_label`."

  attr :today, :any, default: nil
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :currency, :string, default: "", doc: "Prefix of numeric amounts (`\"R$ \"`)."
  attr :amount_width, :integer, default: 80

  attr :animated, :boolean,
    default: false,
    doc:
      "Staged demo (`mo-stg`): rows enter with a `--dl` delay, the overdue badge blinks, weekdays are lowercase and today's badge is `warn`."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The agenda of due items, one row per item: the weekday and day, the title, a status badge
  (overdue in `neg`, today highlighted) and the amount on the right.

      <.due_calendar items={@invoices} today={~D[2026-11-19]} locale="pt_BR" currency="R$ " />
  """
  def due_calendar(assigns) do
    lang = if assigns.locale == "pt_BR", do: "pt_BR", else: "en"
    data = locale_data(lang)
    today = to_date(assigns.today) || Date.utc_today()

    status_labels =
      if lang == "pt_BR",
        do: %{"overdue" => "Vencida", "today" => "Hoje", "scheduled" => "Agendada"},
        else: %{"overdue" => "Overdue", "today" => "Today", "scheduled" => "Scheduled"}

    rows =
      for item <- assigns.items, d = to_date(item[:date]), d != nil do
        status =
          to_string(
            item[:status] ||
              case Date.compare(d, today) do
                :lt -> "overdue"
                :eq -> "today"
                :gt -> "scheduled"
              end
          )

        %{
          weekday:
            data.weekdays
            |> Enum.at(rem(Date.day_of_week(d), 7))
            |> String.slice(0, 3)
            |> then(&if(assigns.animated, do: String.downcase(&1), else: String.upcase(&1))),
          day: d.day,
          title: item[:title],
          subtitle: item[:subtitle],
          amount: amount(item[:amount], assigns.currency, lang),
          status: status,
          badge:
            cx([
              "lu-badge",
              status == "overdue" && "neg",
              status == "today" && if(assigns.animated, do: "warn", else: "acc")
            ]),
          blink: assigns.animated and status == "overdue",
          status_label: item[:status_label] || status_labels[status] || status,
          today: status == "today"
        }
      end

    {extra_style, rest} = Map.pop(assigns.rest, :style)

    assigns =
      assigns
      |> assign(:rows, rows)
      |> assign(:rest, rest)
      |> assign(:panel_style, Enum.join(Enum.filter(["padding:4px 0", extra_style], & &1), ";"))

    ~H"""
    <div
      data-part="due-calendar"
      class={cx(["lu-panel", @animated && "mo-stg", @class])}
      style={@panel_style}
      {@rest}
    >
      <div
        :for={{r, i} <- Enum.with_index(@rows)}
        class="lu-row"
        style={"#{if @animated, do: "--dl:#{:erlang.float_to_binary(i * 0.4, decimals: 1)}s;"}padding:10px 16px;border-top:#{if i == 0, do: "0", else: "1px solid var(--line)"};gap:14px;flex-wrap:nowrap"}
      >
        <div style={"width:44px;text-align:center;border-radius:10px;padding:4px 0;" <> if(r.today, do: "background:var(--inverse);color:var(--on-inverse)", else: "background:var(--bg-sunken)")}>
          <div class="lu-xs" style="opacity:.75">{r.weekday}</div>
          <b class="num">{r.day}</b>
        </div>
        <div class="lu-col lu-grow" style="gap:0">
          <b style="font-weight:500">{r.title}</b>
          <span class="lu-xs lu-muted">{r.subtitle}</span>
        </div>
        <span :if={@animated} class={r.blink && "mo-blink"}>
          <span class={r.badge}>{r.status_label}</span>
        </span>
        <span :if={!@animated} class={r.badge}>{r.status_label}</span>
        <b class="num" style={"width:#{@amount_width}px;text-align:right"}>{r.amount}</b>
      </div>
    </div>
    """
  end

  defp amount(nil, _, _), do: ""
  defp amount(v, _, _) when is_binary(v), do: v

  defp amount(v, currency, lang) when is_number(v) do
    {thousands, decimal} = if lang == "pt_BR", do: {".", ","}, else: {",", "."}
    cents = round(abs(v) * 100)
    int = div(cents, 100)
    frac = rem(cents, 100)

    grouped =
      int
      |> Integer.to_string()
      |> String.reverse()
      |> String.graphemes()
      |> Enum.chunk_every(3)
      |> Enum.map_join(thousands, &Enum.join/1)
      |> String.reverse()

    sign = if v < 0, do: "-", else: ""
    tail = if frac == 0 and is_integer(v), do: "", else: decimal <> pad2(frac)
    "#{sign}#{currency}#{grouped}#{tail}"
  end

  defp amount(v, currency, _), do: currency <> to_string(v)
end
