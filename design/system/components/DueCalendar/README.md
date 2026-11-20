# DueCalendar

Lista de vencimentos agrupada por dia com total previsto.

**Grupo:** 09 · Fluxo de trabalho  
**Resumo visual:** Agenda de vencimentos por dia com totais

## Uso (Phoenix / HEEx)

```heex
<.due_calendar items={@invoices} />
```

## Regras

- Vencido em `neg`; hoje em destaque; total do dia à direita.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: calendar)

Todos os function components, atributos, valores e slots que este componente cobre.

A calendar for dates that matter (due dates, appointments, deadlines): a month grid or a week grid
of hours, with colored event chips, month and week switching and keyboard navigation.

    <.calendar
      id="due"
      view={@view}
      date={@date}
      events={@events}
      locale="pt_BR"
      on_navigate="calendar_navigate"
      on_view="calendar_view"
      on_select="calendar_select"
      on_event="calendar_event"
    />

The server owns what the calendar shows, because the events of another period have to be loaded:
`view` and `date` come from your assigns, and the toolbar (previous, next, today, month and week)
and the keyboard push the events below with the date and view to show next. Update the assigns and
load that period's events with `calendar_range/3`:

    def handle_event("calendar_navigate", %{"date" => date, "view" => view}, socket) do
      {:noreply, assign(socket, date: Date.from_iso8601!(date), view: view)}
    end

An event is a map with `:date` (a `Date` or ISO text) and `:title`, and optionally `:id`, `:subtitle`,
`:color` (`neutral primary secondary info success warning error`), and `:start` and `:end` (`"09:00"`
or a `Time`). In the week view an event with a `:start` is a block in its hour; the others sit in an
all-day row.

    %{id: 1, title: "Coelba", date: ~D[2026-10-15], color: "error"}
    %{id: 2, title: "Visit", subtitle: "Santa Mônica", date: ~D[2026-10-19], start: "10:00", end: "11:00"}

### Mini month

`variant="mini"` is the canvas's compact month in a card: one-letter weekdays, the days in round
cells, a dot under the days that have events, the `selected` day in solid ink, a `range` painted
in the accent tint and today ringed. `months_shown={2}` puts two months side by side (for long
periods), each in its own card titled with the month's name. `on_select` makes the days buttons;
`on_navigate` (single month with `header`) gives the title its arrows. `marks="tint"` paints
the days with events in their color instead of a dot (a due calendar: to receive and to pay),
and `legend` is then drawn over the grid with square keys.

    <.calendar id="due" variant="mini" header={false} date={~D[2026-11-01]} locale="pt_BR"
               events={for d <- [5, 10], do: %{title: "Vencimento", date: Date.new!(2026, 11, d)}} />
    <.calendar id="range" variant="mini" months_shown={2} header={false} locale="pt_BR"
               date={~D[2026-11-01]} range={{~D[2026-11-20], ~D[2026-12-06]}} />

The grid is `role="grid"`: Tab lands on one day, the arrows move between days (past the first or the
last day they go to the previous or the next period), Home and End go to the ends of the week, Page Up
and Page Down change period, and Enter or Space selects the day. `locale="pt_BR"` names months and
weekdays in Portuguese, like `date_picker`, and writes the labels of the toolbar in Portuguese.

### `<.calendar>`

Renders the calendar.

Events pushed to the LiveView, or to the LiveComponent in `target`:

  * `on_navigate`: `%{"id" => id, "date" => "2026-11-01", "view" => "month"}`, the period to show next
    (the toolbar's arrows and Today, Page Up and Page Down, and the arrows at the edge of the grid).
  * `on_view`: `%{"id" => id, "date" => "2026-10-24", "view" => "week"}`, from the month and week buttons.
  * `on_select`: `%{"id" => id, "date" => "2026-10-24"}`, when a day is clicked or chosen with Enter,
    and from the "more" chip of a crowded day.
  * `on_event`: `%{"id" => id, "event" => event_id, "date" => "2026-10-24"}`, when an event is clicked.

A button whose event is not set does not render as a button (the chips) or is disabled (the toolbar).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `view` | `:string` | `"month"` | `month`, `week` |
| `variant` | `:string` | `"full"` | `full`, `mini` — `mini` is the canvas's compact month in a card (see "Mini month" above); `view` and the week attrs do not apply to it. |
| `range` | `:any` | `nil` | Mini only: a `{from, to}` pair of days (`Date` or ISO text) painted as a period; `selected` still wins on its day. |
| `marks` | `:string` | `"dot"` | `dot`, `tint` — Mini only: how a day with events shows, a dot under the number or (`tint`, the due calendar) the whole day in the soft tone of its first event's `:color` (`primary` accent, `warning` amber, `error`, `success`, `info`). |
| `months_shown` | `:integer` | `1` | Mini only: how many months, from `date`'s, side by side. |
| `date` | `:any` | `nil` | A day of the period to show (a `Date` or ISO text); today by default. It is also where the keyboard lands. |
| `today` | `:any` | `nil` | The day marked as today; the server's UTC day by default. |
| `selected` | `:any` | `nil` | A day drawn as selected (`aria-selected`). |
| `events` | `:list` | `[]` | Maps with `:date`, `:title` and the optional keys above. |
| `legend` | `:list` | `[]` | Pairs `{label, color}` drawn under the grid, with the colors of the events. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` |
| `months` | `:list` | `nil` | The twelve month names, for another language. |
| `weekdays` | `:list` | `nil` | The seven weekday names from Sunday; the grid shows their first three letters. |
| `labels` | `:map` | `%{}` | Single texts: `:calendar_today`, `:calendar_previous`, `:calendar_next`, `:calendar_view`, `:calendar_month`, `:calendar_week`, `:calendar_all_day`, `:calendar_more` (with `%{count}`, the text of the button of a crowded day), `:calendar_more_label` (with `%{count}`, its name for screen readers). |
| `week_start` | `:integer` | `0` | The first column of the grid, 0 = Sunday. |
| `show_weekends` | `:boolean` | `true` | Saturday and Sunday columns in the week view. |
| `day_start` | `:integer` | `8` | The first hour row of the week view. |
| `day_end` | `:integer` | `18` | The end of the last hour row of the week view. |
| `max_events` | `:integer` | `3` | Chips per day in the month view before "more". |
| `header` | `:boolean` | `true` | The toolbar with the title, arrows and view switch. |
| `outside_days` | `:boolean` | `false` | `mini` only: fills the first and the last week with the days of the neighbour months (class `o`, faint). |
| `day_id` | `:any` | `nil` | `mini` only: an id for each day, a `fn date -> id end` or a prefix string (`"day"` gives `day-2026-11-14`). With `months_shown` above 1 only the days of the month itself get one. |
| `interactive_marked_only` | `:boolean` | `false` | `mini` only: with `on_select`, only the days that have events are buttons. |
| `card` | `:boolean` | `true` | `mini` only: `false` renders just the `lu-cal` grid, with no card, title, arrows or legend, for an app card that has its own. |
| `on_navigate` | `:string` | `nil` |  |
| `on_view` | `:string` | `nil` |  |
| `on_select` | `:string` | `nil` |  |
| `on_event` | `:string` | `nil` |  |
| `target` | `:any` | `nil` | The `phx-target` of the events. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:event>` — Replaces the content of an event chip or block; receives the event map (`:let={event}`).
