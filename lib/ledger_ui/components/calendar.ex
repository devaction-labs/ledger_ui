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
  that have events); `size` is `sm`, `md` or `lg`, and `view="week"` draws only the week of
  `date` (the weekday letters and one row, a strip). `view="day"` is the week grid with a single day, an addition to the README.

  The roving focus and the arrow keys live in the `LedgerUI.Calendar` hook
  (`priv/static/ledger_ui/hooks/calendar.js`), attached only when `on_select` is set.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Badge, only: [badge: 1]

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

  # the colour of an event chip: the compact canvas badge tones
  @tones %{
    "neutral" => "bg-sunken text-ink-2",
    "primary" => "bg-accent-soft text-accent-content",
    "secondary" => "bg-lime-soft text-lime",
    "info" => "bg-info-soft text-info",
    "success" => "bg-pos-soft text-pos",
    "warning" => "bg-warn-soft text-warn",
    "error" => "bg-neg-soft text-neg"
  }

  # the tint of a marked day of the mini month, and of its legend swatch
  @tints %{
    "primary" => "bg-accent-soft",
    "secondary" => "bg-lime-soft",
    "info" => "bg-info-soft",
    "success" => "bg-pos-soft",
    "warning" => "bg-warn-soft",
    "error" => "bg-neg-soft"
  }

  # {grid columns, cell height, weekday letter look} per size; as in the bundle the `sm` and `lg`
  # letters take the height and digit size of the cells, only `md` has the small 24px letters
  @mini_sizes %{
    "sm" => {"grid-cols-[repeat(7,28px)]", "h-[26px]", "h-[26px] text-xs"},
    "md" => {"grid-cols-[repeat(7,34px)]", "h-8", "h-6 text-[11.5px]"},
    "lg" => {"grid-cols-[repeat(7,42px)]", "h-10", "h-10 text-sm"}
  }
  @mini_fonts %{"sm" => "text-xs", "md" => "text-[13px]", "lg" => "text-sm"}

  # the canvas demo animations: one delay per day, 0.25s apart from the 1st (`pick` / `range`)
  @loops %{
    "pick" => "animate-[mo-day_8s_infinite] [animation-delay:var(--dl)]",
    "range" => "animate-[mo-rng_7s_infinite] [animation-delay:var(--dl)]"
  }

  @chip "inline-flex h-[18px] items-center gap-[5px] rounded-sm px-1.5 text-[11px] leading-none font-medium whitespace-nowrap tabular-nums"

  @cell "flex h-[78px] flex-col gap-[3px] border-r border-b border-line px-2 py-1.5 text-[12.5px]"
  @head "border-b border-line px-2.5 py-2 text-xs text-muted"
  @today "self-start rounded-sm bg-inverse px-[5px] font-semibold text-on-inverse"

  # the compact toolbar button of the canvas (`lu-btn icon sm`), plain or ghost
  @nav "inline-flex size-[30px] cursor-pointer items-center justify-center rounded-[8px] border leading-none transition-[background,border-color,box-shadow] duration-150 " <>
         "focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-45 [&_svg]:size-4"
  @nav_plain "border-line-strong bg-panel text-ink shadow-xs hover:bg-hover disabled:shadow-none"
  @nav_ghost "border-transparent bg-transparent text-ink-2 hover:bg-hover hover:text-ink"

  @tab "inline-flex h-6 cursor-pointer items-center gap-1.5 rounded-[6px] border-0 px-[9px] text-[12.5px] font-medium transition-[color,background] duration-150 focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"
  @tab_on "bg-panel text-ink shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)]"
  @tab_off "bg-transparent text-muted hover:text-ink"

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

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc:
      "`variant=\"mini\"` only: the cell size, 28x26 / 34x32 / 42x40px with 12 / 13 / 14px digits."

  attr :loop, :string,
    default: nil,
    values: [nil, "pick", "range"],
    doc:
      "`variant=\"mini\"` only: the canvas demo animation, each day lighting up in turn as the picked day (`pick`) or the picked range (`range`)."

  attr :marks, :string, default: "dot", values: ~w(dot tint)
  attr :months_shown, :integer, default: 1

  attr :date, :any,
    default: nil,
    doc: "A date of the month (or week, day) shown; today by default."

  attr :month, :any, default: nil, doc: "The same as `date`."
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
    date = to_date(assigns.date) || to_date(assigns.month) || today
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
      |> assign(:nav, @nav)
      |> assign(:nav_plain, @nav_plain)
      |> assign(:tab, @tab)
      |> assign(:tab_on, @tab_on)
      |> assign(:tab_off, @tab_off)
      |> assign(:chip_cls, @chip)
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
      class={["overflow-hidden rounded-lg border border-line bg-panel", @class]}
      {@rest}
    >
      <div
        :if={@header}
        data-part="calendar-header"
        class="flex flex-wrap items-center gap-2.5 border-b border-line px-3.5 py-3"
      >
        <b data-part="calendar-title" class="text-base">{@title}</b>
        <span class="min-w-0 flex-1"></span>
        <div
          data-part="calendar-views"
          class="inline-flex gap-0.5 rounded-md bg-sunken p-[3px]"
          data-lu-single
          role="tablist"
        >
          <button
            :for={{v, text} <- @tabs}
            data-part="calendar-view"
            aria-selected={to_string(v == @view)}
            class={[@tab, if(v == @view, do: @tab_on, else: @tab_off)]}
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
          data-part="calendar-nav"
          aria-label={@l.calendar_previous}
          class={[@nav, @nav_plain]}
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
          data-part="calendar-nav"
          aria-label={@l.calendar_next}
          class={[@nav, @nav_plain]}
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
          data-part="calendar-grid"
          class="grid grid-cols-[repeat(7,1fr)]"
          role={@interactive && "grid"}
          aria-label={@interactive && @title}
        >
          <div :for={w <- @grid.weekdays} data-part="calendar-weekday" class={@grid.head}>{w}</div>
          <div
            :for={c <- @grid.cells}
            data-part="calendar-cell"
            class={c.class}
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
            <span data-part="calendar-day" class={c.num_class}>{c.day}</span>
            <%= for e <- c.events do %>
              <.chip e={e} on_event={@on_event} id={@id} target={@target_attr} slot={@event} />
            <% end %>
            <button
              :if={c.more > 0}
              type="button"
              data-part="calendar-more"
              class={[@chip_cls, "cursor-pointer border-0 bg-sunken text-ink-2"]}
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
    assigns = assign(assigns, :cls, [@chip, @tones[assigns.e[:color] || "neutral"]])

    ~H"""
    <%= if @on_event do %>
      <button
        type="button"
        data-part="calendar-event"
        class={[@cls, "max-w-full cursor-pointer border-0"]}
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
      <span data-part="calendar-event" class={@cls}>
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
          class: [@cell, !in_month? && "bg-tray text-subtle"],
          num_class: if(d == today, do: @today),
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
    <div
      data-part="calendar-grid"
      class="grid"
      style={"grid-template-columns:56px repeat(#{@grid.n},1fr)"}
    >
      <div class="border-b border-line px-2.5 py-2"></div>
      <div
        :for={c <- @grid.cols}
        data-part="calendar-weekday"
        class={[
          "border-b border-l border-line px-2.5 py-2 text-xs",
          if(c.today, do: "font-semibold text-ink", else: "text-muted")
        ]}
      >
        {c.label}
      </div>
      <div class="border-b border-line px-2 py-1.5 text-xs text-muted">
        {@l.calendar_all_day}
      </div>
      <div
        :for={c <- @grid.cols}
        data-part="calendar-cell"
        class="flex min-h-7 flex-col gap-[3px] border-b border-l border-line p-1"
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
        <div class="h-12 border-b border-line px-2 py-1 font-mono text-xs text-muted">
          {pad2(h)}:00
        </div>
        <div
          :for={c <- @grid.cols}
          data-part="calendar-cell"
          class="relative h-12 border-b border-l border-line"
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
      |> assign(:style, "top:#{trunc(top)}px;height:#{trunc(height)}px")
      |> assign(
        :cls,
        "absolute inset-x-0.5 z-[1] overflow-hidden rounded-[6px] border-l-[3px] border-l-accent-500 bg-accent-soft px-1.5 py-0.5 text-left text-[11.5px] text-ink"
      )
      |> assign(:time, "#{hhmm(e.start_m)}#{if e.end_m, do: "–" <> hhmm(e.end_m)}")

    ~H"""
    <%= if @on_event do %>
      <button
        type="button"
        data-part="calendar-event"
        class={[@cls, "cursor-pointer"]}
        style={@style}
        phx-click={@on_event}
        phx-target={@target}
        phx-value-id={@id}
        phx-value-event={@e[:id]}
        phx-value-date={iso(@e.date)}
      >
        <.block_body e={@e} time={@time} slot={@slot} />
      </button>
    <% else %>
      <div data-part="calendar-event" class={@cls} style={@style}>
        <.block_body e={@e} time={@time} slot={@slot} />
      </div>
    <% end %>
    """
  end

  defp block_body(assigns) do
    ~H"""
    <%= if @slot != [] do %>
      {render_slot(@slot, @e)}
    <% else %>
      <b class="font-medium">{@e.title}</b>
      <div :if={@e[:subtitle]} class="text-muted">{@e[:subtitle]}</div>
      <div class="font-mono text-muted">{@time}</div>
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
    strip? = assigns.view == "week"

    months =
      for i <- 0..(max(n, 1) - 1) do
        m = Date.shift(first, month: i)

        %{
          title: "#{Enum.at(assigns.month_names, m.month - 1)} #{m.year}",
          cells: mini_cells(m, n, range, assigns, strip?)
        }
      end

    months = if strip?, do: Enum.take(months, 1), else: months
    {cols, _cell, head} = @mini_sizes[assigns.size]

    letters = assigns.day_names |> Enum.map(&String.first/1) |> rotate(assigns.week_start)

    assigns =
      assigns
      |> assign(:minis, months)
      |> assign(:grid_cls, ["grid gap-0.5 tabular-nums", cols, cell_font(assigns.size)])
      |> assign(:head_cls, ["grid place-items-center text-muted", head])
      |> assign(:letters, letters)
      |> assign(:prev, iso(Date.shift(first, month: -1)))
      |> assign(:next, iso(Date.shift(first, month: 1)))
      |> assign(:interactive, assigns.on_select != nil)
      |> assign(:navs, assigns.header and assigns.on_navigate != nil and n == 1)
      |> assign(:tints, @tints)
      |> assign(:nav, @nav)
      |> assign(:nav_ghost, @nav_ghost)

    ~H"""
    <div
      id={@id}
      data-part="calendar"
      phx-hook={@hook}
      class={["flex flex-wrap gap-3", @class]}
      {@rest}
    >
      <div
        :for={m <- @minis}
        data-part="calendar-month"
        class={@card && "rounded-lg border border-line bg-panel p-3.5"}
      >
        <div
          :if={@card and @header}
          class="mb-2 flex flex-wrap items-center gap-2.5"
        >
          <b data-part="calendar-title" class="text-sm">{m.title}</b>
          <span class="min-w-0 flex-1"></span>
          <button
            :if={@navs}
            data-part="calendar-nav"
            aria-label={@l.calendar_previous}
            class={[@nav, @nav_ghost]}
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
            data-part="calendar-nav"
            aria-label={@l.calendar_next}
            class={[@nav, @nav_ghost]}
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
        <div
          data-part="calendar-grid"
          class={@grid_cls}
          role={@interactive && "grid"}
        >
          <span
            :for={l <- @letters}
            data-part="calendar-weekday"
            class={@head_cls}
          >{l}</span>
          <span
            :for={c <- m.cells}
            id={c.id}
            data-part="calendar-day"
            class={c.class}
            style={c.style}
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
        <div :if={@card and @legend != []} class="mt-2.5 flex flex-wrap items-center gap-3">
          <span
            :for={{label, color} <- @legend}
            class="inline-flex items-center gap-1.5 text-xs text-muted"
          >
            <i class={["size-2.5 rounded-[3px]", Map.get(@tints, color, "bg-selected")]}></i>{label}
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp cell_font(size), do: @mini_fonts[size]

  defp mini_range(nil), do: nil

  defp mini_range(v) do
    case LedgerUI.Components.DatePicker.value_dates(v) do
      [a, b] -> {a, b}
      _ -> nil
    end
  end

  defp mini_cells(month, n, range, a, strip?) do
    %{today_d: today, selected_d: sel, evs: evs, week_start: ws, on_select: on_select} = a

    days =
      if strip? do
        # the week of `date` only (a single-row strip)
        lead = Integer.mod(rem(Date.day_of_week(a.date_d), 7) - ws, 7)
        wk = Date.add(a.date_d, -lead)

        for i <- 0..6 do
          d = Date.add(wk, i)
          {d, d.month == a.date_d.month, true}
        end
      else
        mini_days(month, n, a, ws)
      end

    for {d, in_month?, shown?} <- days do
      all = Map.get(evs, d, [])
      first = List.first(all)
      has? = all != [] and in_month?

      button? = shown? and on_select != nil and (not a.interactive_marked_only or has?)
      rc = range_class(range, d, shown?)
      tint = (has? and a.marks == "tint") && color_key(first)

      sel? = shown? and d == sel

      # one utility per property; as in the original stylesheet a tint wins over a range edge,
      # that over the range body, that over the selected day (colour: edge > body > selected)
      cls = [
        "relative grid place-items-center",
        elem(@mini_sizes[a.size], 1),
        sel? && "font-semibold",
        cond do
          rc in ["rs", "re"] -> "text-white"
          rc == "r" -> "text-accent-content"
          sel? -> "text-on-inverse"
          in_month? -> "text-ink-2"
          true -> "text-subtle"
        end,
        cond do
          tint -> @tints[tint]
          rc in ["rs", "re"] -> "bg-accent-600"
          rc == "r" -> "bg-accent-soft"
          sel? -> "bg-inverse"
          true -> nil
        end,
        case rc do
          "rs" -> "rounded-l-[8px] rounded-r-none"
          "re" -> "rounded-r-[8px] rounded-l-none"
          "r" -> "rounded-none"
          _ -> "rounded-[8px]"
        end,
        (shown? and d == today) && "shadow-[inset_0_0_0_1px_var(--lu-line-strong)]",
        (has? and a.marks == "dot") &&
          "after:absolute after:bottom-1 after:size-1 after:rounded-full after:bg-accent-500 after:content-['']",
        button? && "cursor-pointer",
        a.loop && in_month? && @loops[a.loop]
      ]

      %{
        style: a.loop && in_month? && "--dl:#{loop_delay(d)}s",
        iso: iso(d),
        day: if(shown?, do: d.day, else: nil),
        class: cls,
        tint: tint,
        button: button?,
        selected: d == sel,
        tabindex: if(d == (sel || a.date_d), do: "0", else: "-1"),
        id: day_id(a.day_id, d, in_month?)
      }
    end
  end

  defp mini_days(month, n, a, ws) do
    if n > 1 do
      # side by side months: only the month's own days, padded with empty cells
      for {d, in_month?} <- grid_days(month, ws), do: {d, in_month?, in_month?}
    else
      for {d, in_month?} <- grid_days(month, ws),
          do: {d, in_month?, in_month? or a.outside_days}
    end
  end

  # 0s on the 1st, then +0.25s per day (the bundle's `--dl`)
  defp loop_delay(d), do: Float.round((d.day - 1) * 0.25, 2)

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
          badge_color:
            cond do
              status == "overdue" -> "error"
              status == "today" -> if(assigns.animated, do: "warning", else: "primary")
              true -> "neutral"
            end,
          blink: assigns.animated and status == "overdue",
          status_label: item[:status_label] || status_labels[status] || status,
          today: status == "today"
        }
      end

    assigns = assign(assigns, :rows, rows)

    ~H"""
    <div
      data-part="due-calendar"
      class={["rounded-lg border border-line bg-panel py-1", @class]}
      {@rest}
    >
      <div
        :for={{r, i} <- Enum.with_index(@rows)}
        data-part="due-calendar-row"
        class={[
          "flex flex-nowrap items-center gap-3.5 px-4 py-2.5",
          i > 0 && "border-t border-line",
          @animated &&
            "animate-[mo-stg_6s_cubic-bezier(.2,.8,.2,1)_var(--dl,0s)_infinite]"
        ]}
        style={@animated && "--dl:#{:erlang.float_to_binary(i * 0.4, decimals: 1)}s"}
      >
        <div
          data-part="due-calendar-date"
          class={[
            "w-11 rounded-[10px] py-1 text-center",
            if(r.today, do: "bg-inverse text-on-inverse", else: "bg-sunken")
          ]}
        >
          <div data-part="due-calendar-weekday" class="text-xs opacity-75">{r.weekday}</div>
          <b data-part="due-calendar-day" class="tabular-nums">{r.day}</b>
        </div>
        <div data-part="due-calendar-info" class="flex min-w-0 flex-1 flex-col">
          <b data-part="due-calendar-title" class="font-medium">{r.title}</b>
          <span data-part="due-calendar-subtitle" class="text-xs text-muted">{r.subtitle}</span>
        </div>
        <span
          :if={@animated}
          data-part="due-calendar-status"
          class={r.blink && "animate-[mo-blink_1.4s_ease-in-out_infinite]"}
        >
          <.badge canvas color={r.badge_color}>{r.status_label}</.badge>
        </span>
        <.badge :if={!@animated} canvas color={r.badge_color}>{r.status_label}</.badge>
        <b
          data-part="due-calendar-amount"
          class="text-right tabular-nums"
          style={"width:#{@amount_width}px"}
        >{r.amount}</b>
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
