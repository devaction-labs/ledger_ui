# DateTimePicker

Data e hora no mesmo popover para agendamentos.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** mode single/range · time list/input · formato 12/24 · layout · variant · size

## Uso (Phoenix / HEEx)

```heex
<.datetime_picker field={@form[:send_at]} />
```

## Regras

- Mostre o fuso ao lado do horário.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: datetime_picker)

Todos os function components, atributos, valores e slots que este componente cobre.

A date and a time chosen in one panel: a calendar with a list of times beside it, or, for a
range, two months side by side with a start and an end time.

    <.datetime_picker field={@form[:starts_at]} label="Starts at" />
    <.datetime_picker name="meeting" interval={15} min="now" min_time="08:00" max_time="18:00" />
    <.datetime_picker name="slot" time="input" unavailable="12:00-13:00, 2026-10-14, 2026-10-15T10:00" />
    <.datetime_picker name="shift" mode="range" default_time="09:00/17:00" locale="pt_BR" />

The value is wall-clock text, like a native `datetime-local` input: `2026-10-14T10:30`, with no
time zone and no conversion. The form gets it through a hidden input named like the field (a
range gets `name[]` twice, start then end, with an empty `name[]` first so an empty choice
still reaches the server; `start_field`/`end_field` or `start_name`/`end_name` submit the two
ends as two fields instead). `value` takes a `NaiveDateTime`, a `DateTime` (its clock, not
converted), `"2026-10-14T10:30"` or `"2026-10-14 10:30"`; a range takes `{from, to}` or a list
of two. A bubbling `input` event fires on every change, so `phx-change` runs; the server
re-rendering the same value changes nothing, a different value replaces the one in the browser.

### One date and time

The default `mode="single"` opens a calendar with the times of the day beside it, the chosen
time highlighted. Changing only the day updates the value at once, keeping the time (or taking
the default one when that time is closed on the new day); choosing a time updates it and closes
the panel. On a narrow screen the time list becomes a dropdown under the calendar and a
"Select" button confirms (with a "Cancel" beside it): a tap alone does not change the value.
A time that is closed is struck through and dimmed; today is marked with a dot under its number.

### A range

`mode="range"` shows two months and, under them, the day and a time control for the start and
for the end. The first click on a day starts the range, the next one closes it (a click before
the start restarts it); nothing is applied until "Select range" is pressed, and "Cancel" (the
`datetime_cancel` label) closes the panel without applying. `default_time`
takes `"start/end"` (`"09:00/17:00"`); the end of a range cannot be before its start.

### Times

`interval` is the step of the suggested times in minutes. With `time="input"` the person types an
exact time (`9:30`, `930`, `9:30 pm`, `21:15`) and the suggested times drop down as they type.
`time_format` is the 12 or 24-hour clock, by default the one of the `locale`.

### Restrictions

`min` and `max` bound the days (`"now"`, `"today"`, a `Date`, a `NaiveDateTime` or ISO text;
`"now"` also closes the earlier times of today). `min_time` and `max_time` bound the times of
every day. `unavailable` closes whole days (`"2026-10-14"`), a time range every day
(`"12:00-13:00"`, from the first time up to but not including the second; `"22:00-02:00"`
crosses midnight) or one date-time (`"2026-10-14T10:00"`), as a comma separated text or a list.
A day with no time left cannot be picked.

### Your own trigger

The `trigger` slot replaces the input: any button opens the panel, and the picker shows no text
of its own. The panel is an overlay, so `LedgerUI.open/close/toggle("id")` work on it.

    <.datetime_picker id="when" name="when">
      <:trigger>
        <.button variant="outline">Pick a date and time</.button>
      </:trigger>
    </.datetime_picker>

### Month and year

The header of a month has two buttons beside the arrows, the month ("October") and the year
("2026"). The month opens a grid of the twelve months and the year a page of twelve years; picking
one goes back to the days of that month. While a grid is open the arrows turn the year (or the
page of years), months and years that `min` and `max` close are dimmed, and `Esc` goes back to
the days with the focus on the button. The buttons are named by `:datetime_choose_month` and
`:datetime_choose_year` in `labels`.

### Keyboard

`↓` or `Enter` on the input opens the panel with the focus on the chosen day. In the calendar the
arrows move a day or a week, `Home`/`End` the start and end of the week, `Page Up`/`Page Down` a
month (with `Shift` a year) and `Enter` or `Space` picks. In the time list `↑`/`↓`/`Home`/`End`
move and `Enter` picks; in the time field `↓`/`↑` walk the suggestions. `Esc` closes the panel and
gives the focus back; leaving the panel with `Tab` closes it. In the month and year grids the
arrows move over the three columns, `Home`/`End` to the first and the last, `Enter` or `Space` picks.

### `<.datetime_picker>`

Renders the date and time input with its panel.

    <.datetime_picker id="due" name="due" label="Due" help="Local time" />
    <.datetime_picker field={@form[:window]} mode="range" label="Window" min="today" />

Events: `on_change` is pushed with `%{"id" => id, "value" => value}` after each change, where
`value` is the wall-clock text (`"2026-10-14T10:30"`, `""` for no choice) or, for a range, the
list of the two ends (`[]` for no choice), to `target` or to the LiveView/LiveComponent the
picker is in.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, or a generated one. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:any` |  | A `NaiveDateTime`, a `DateTime` (its clock, not converted) or `"2026-10-14T10:30"`; a range takes `{from, to}` or a list of two. A day without a time takes `default_time`. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `timezone` | `:string` | `nil` | A time zone label shown on the help line (`"Horário de Brasília (UTC−3)"`, `"BRT · UTC−3"`), after `help` when both are given. Display only: the picker never converts dates. |
| `errors` | `:list` | `[]` |  |
| `placeholder` | `:string` | `nil` | Defaults to "Select date and time" ("Select date range" for a range) in the `locale`. |
| `mode` | `:string` | `"single"` | `single`, `range` — `range` picks a start and an end, each with its own time; set by `start_field`/`end_field` and `start_name`/`end_name`. |
| `start_field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | The field the start of a range goes to; with `end_field`. |
| `end_field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | The field the end of a range goes to; with `start_field`. |
| `start_name` | `:string` | `nil` | The input name of the start of a range (without fields); with `end_name`. |
| `end_name` | `:string` | `nil` | The input name of the end of a range. |
| `interval` | `:integer` | `30` | Minutes between the suggested times, from midnight: `15` gives 9:00, 9:15, 9:30... |
| `time` | `:string` | `"list"` | `list`, `input` — `list` chooses the time from the list beside the calendar (a dropdown on a narrow screen); `input` types an exact time, with the suggested times in a dropdown. |
| `default_time` | `:string` | `nil` | The time a picked day starts with, `"09:00"`; for a range `"start/end"`, `"09:00/17:00"`. The first open time when not given or closed. |
| `time_format` | `:string` | `"auto"` | `auto`, `12`, `24` — `12` is 9:30 AM, `24` is 09:30; `auto` follows the `locale` (12 for `en`, 24 for `pt_BR`). |
| `time_24hr` | `:boolean` | `nil` | The attribute of the former flatpickr picker, kept as `time_format="24"`; use `time_format`. |
| `minute_step` | `:integer` | `nil` | The attribute of the former flatpickr picker, kept as `interval`; use `interval`. |
| `default_hour` | `:integer` | `nil` | The attribute of the former flatpickr picker, kept as `default_time="HH:00"`; use `default_time`. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` — Month and weekday names, the words of the panel, the default text format and `time_format`. |
| `display_format` | `:string` | `nil` | The text of the input in flatpickr tokens (`Y y m n d j F M l D H G h i K`); `M j, Y, h:i K` (`d/m/Y H:i` in `pt_BR`) by default. Only the shown text changes: the form still gets the wall-clock text. |
| `range_separator` | `:string` | `" – "` | The text between the two ends of a range in the input. |
| `min` | `:any` | `nil` | The first day or moment that can be picked: `"now"` (closes the earlier times of today too), `"today"`, a `Date`, a `NaiveDateTime` or ISO text. |
| `max` | `:any` | `nil` | The last day or moment that can be picked; same values as `min`. |
| `min_time` | `:string` | `nil` | The earliest time of every day, `"HH:MM"`. |
| `max_time` | `:string` | `nil` | The latest time of every day, `"HH:MM"`. |
| `unavailable` | `:any` | `[]` | What cannot be picked, a comma separated text or a list of: a day (`"2026-10-14"` or a `Date`), a daily time range (`"12:00-13:00"`, up to but not including the end; `"22:00-02:00"` crosses midnight) or a date-time (`"2026-10-14T10:00"` or a `NaiveDateTime`). |
| `week_start` | `:integer` | `0` | The first column of the calendar, 0 = Sunday. |
| `months` | `:list` | `nil` | The twelve month names, for another language. |
| `weekdays` | `:list` | `nil` | The seven weekday names from Sunday; the calendar shows their first three letters. |
| `today` | `:any` | `nil` | The day marked as today and meant by `"now"` and `"today"` (a `Date` or ISO text); the browser's day by default. |
| `labels` | `:map` | `%{}` | Single texts of the panel: `:datetime_select`, `:datetime_select_range`, `:datetime_cancel`, `:datetime_start`, `:datetime_end`, `:datetime_time`, `:datetime_times`, `:datetime_no_times`, `:datetime_time_placeholder`, `:datetime_previous`, `:datetime_next`, `:datetime_choose_month` and `:datetime_choose_year` (the names of the month and year buttons of the header), `:datetime_day` (with `%{weekday}`, `%{month}`, `%{day}`, `%{year}`), `:datetime_title` (with `%{month}`, `%{year}`), `:datetime_dialog`, `:datetime_dialog_range`, `:datetime_placeholder`, `:datetime_placeholder_range`. |
| `layout` | `:string` | `"auto"` | `auto`, `compact` — `auto` picks the panel by the width of the screen (one month and a Select button under 640px, two months side by side above). `compact` always uses the narrow panel, for a picker in a narrow space such as a sidebar or a modal. |
| `variant` | `:string` | `"outlined"` | `outlined`, `filled` — `outlined` is the canvas input (40px, 11px corners, a hairline and the focus ring). |
| `split` | `:boolean` | `false` | Single mode: the date and the time in two fields side by side (each with its icon and its caption, `date_label` and `time_label`); either opens the panel. |
| `date_label` | `:string` | `nil` | With `split`: the caption of the date field. |
| `time_label` | `:string` | `nil` | With `split`: the caption of the time field. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `placement` | `:string` | `"bottom-start"` | Where the panel opens, `top`, `bottom`, `left` or `right` with `-start` or `-end`; it flips when there is no room. |
| `show_icon` | `:boolean` | `true` | The calendar icon inside the input; `false` leaves a bare input. |
| `disabled` | `:boolean` | `false` |  |
| `on_change` | `:string` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` | Classes of the input. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — Replaces the calendar icon.
- `<:trigger>` — Replaces the input: any button inside opens the panel. The picker then shows no text of its own.
