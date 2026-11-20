# DatePicker

Seleção de data única ou intervalo, com atalhos de período.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** mode single/multiple/range · size sm/md/lg · skin

## Uso (Phoenix / HEEx)

```heex
<.date_picker field={@form[:period]} range presets={~w(this_month last_month qtd ytd)} />
```

## Regras

- Hoje marcado com ponto teal; escolhido em `inverse`; intervalo em `accent-soft`.
- Botão de período no topo da página (Oct 2026) abre este popover.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: date_picker)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's date pickers (flatpickr's calendar in Ledger UI's skin): one date, several dates or a
range, with limits, disabled days, a custom text format, and a calendar that pops under the
input or stays inline. For a date and a time in one panel see `datetime_picker/1`.

    <.date_picker field={@form[:due_on]} placeholder="Choose date..." />
    <.date_picker name="trip" mode="range" value={{~D[2026-10-10], ~D[2026-10-20]}} />
    <.date_picker name="days" mode="multiple" disabled_weekdays={[0, 6]} week_start={1} />
    <.date_picker name="due" display_format="M j, Y" show_icon={false} placeholder="Due date" />

The input shows the date in `display_format` (flatpickr tokens: `Y-m-d`, `F j, Y`, `H:i`...);
the form gets ISO text through hidden inputs named like the field: `2026-10-23` (one date), and
`name[]` per date for `multiple` and `range` (with an
empty `name[]` first so an empty choice still reaches the server). A pick fires a bubbling
`input` event, so `phx-change` runs; the server re-rendering the same value changes nothing,
a different value replaces the one in the browser.

The calendar is an overlay: `LedgerUI.open/close/toggle("id")` work on it, and
`date_picker_clear/1` empties it.

### A range in two fields

A range can submit its two ends as two fields instead of `name[]`: give `start_field` and
`end_field` (or `start_name` and `end_name`) and the form gets `start=2026-10-01` and
`end=2026-10-31` (empty text for an end not picked yet). `presets` adds quick choices under
the calendar, computed on the server from `today`:

    <.date_picker
      start_field={@form[:from]}
      end_field={@form[:to]}
      locale="pt_BR"
      week_start={1}
      placeholder="Período"
      presets={[
        {"Hoje", "today"},
        {"Últimos 7 dias", "last_7_days"},
        {"Este mês", "this_month"},
        {"Mês passado", "last_month"}
      ]}
    />

`locale="pt_BR"` names the months and weekdays in Portuguese, shows `dd/mm/aaaa` and joins
a range with "até"; `months`, `weekdays`, `display_format` and `range_separator` still
override it one by one.

### Keyboard and screen readers

The popup is a dialog named "Choose date" ("Choose period" for a range); the month buttons are
real buttons with a name, and the days are a `grid` of rows and cells with `aria-selected`,
`aria-disabled`, `aria-current="date"` for today and a long name ("Friday, October 23, 2026",
in the `locale`). The `labels` attribute changes any of these texts.

`↓` or `Enter` on the input opens the calendar with the focus on the chosen day. In the calendar
the arrows move a day or a week, `Home`/`End` the start and end of the week, `Page Up`/`Page Down`
a month (with `Shift` a year) and `Enter` or `Space` picks. `Esc` closes the calendar and gives
the focus back to the input; leaving it with `Tab` closes it.

### `<.date_picker>`

Renders a date input with its calendar.

    <.date_picker id="due" name="due" label="Due" min={Date.utc_today()} />
    <.date_picker id="when" name="when" placeholder="Choose date">
      <:trailing>
        <.button phx-click={LedgerUI.toggle("when")}>…</.button>
        <.button phx-click={date_picker_clear("when")}>×</.button>
      </:trailing>
    </.date_picker>

Events: `on_change` is pushed with `%{"id" => id, "value" => value}` after each pick, where
`value` is the ISO text (or a list of them for `multiple` and `range`), to `target` or to the
LiveView/LiveComponent the picker is in.

A preset is `{label, key}` with a key of `date_range_preset/3` (`"today"`, `"yesterday"`,
`"last_7_days"`, `"last_30_days"`, `"this_week"`, `"last_week"`, `"this_month"`,
`"last_month"`, `"this_year"`, `"last_year"`), `{label, {from, to}}` or
`%{label: label, from: from, to: to}` with `Date`s or ISO text. Picking one sets the range
(or, in `single` mode, its first day), fires `phx-change` and `on_change`, and closes the
calendar; the preset matching the current choice is highlighted.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, or a generated one. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:any` |  | A `Date`, ISO text, a list of them, `{from, to}` or a `Date.Range`. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `placeholder` | `:string` | `nil` |  |
| `mode` | `:string` | `"single"` | `single`, `multiple`, `range` — Set to `range` by `start_field`/`end_field` and `start_name`/`end_name`. |
| `start_field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | The field the first day of a range goes to; with `end_field`. |
| `end_field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | The field the last day of a range goes to; with `start_field`. |
| `start_name` | `:string` | `nil` | The input name of the first day of a range (without fields); with `end_name`. |
| `end_name` | `:string` | `nil` | The input name of the last day of a range. |
| `presets` | `:list` | `[]` | Quick choices under the calendar: `{label, key}`, `{label, {from, to}}` or `%{label:, from:, to:}`. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` — Month and weekday names, the default `display_format` and the range separator. |
| `range_separator` | `:string` | `nil` | The text between the two days of a range; " to " (en) or " até " (pt_BR). |
| `labels` | `:map` | `%{}` | Single texts of the calendar, over the `locale` ones: `:picker_date_dialog`, `:picker_period_dialog` (the name of the popup), `:picker_previous`, `:picker_next`, `:picker_day` (the name of a day, with `%{weekday}`, `%{month}`, `%{day}`, `%{year}`), `:picker_month`, `:picker_year`, `:picker_year_up`, `:picker_year_down`. |
| `min` | `:any` | `nil` | The first day that can be picked (`Date` or ISO text). |
| `max` | `:any` | `nil` | The last day that can be picked. |
| `disabled_dates` | `:list` | `[]` | Days that cannot be picked. |
| `disabled_weekdays` | `:list` | `[]` | Weekdays that cannot be picked, 0 = Sunday. |
| `week_start` | `:integer` | `0` | The first column of the calendar, 0 = Sunday. |
| `display_format` | `:string` | `nil` | The text of the input in flatpickr tokens; `Y-m-d` by default. `M j, Y` reads `Oct 23, 2026`, `D, M j` reads `Fri, Oct 23`, `F j, Y` reads `October 23, 2026`. Only the shown text changes: the form still gets ISO. |
| `months` | `:list` | `nil` | The twelve month names, for another language. |
| `weekdays` | `:list` | `nil` | The seven weekday names from Sunday; the calendar shows their first three letters. |
| `today` | `:any` | `nil` | The day marked as today; the server's UTC day by default. |
| `inline` | `:boolean` | `false` | The calendar always shows, under the input. |
| `show_icon` | `:boolean` | `true` | The calendar icon inside the input; `false` leaves a bare input (and drops the left padding). |
| `skin` | `:string` | `nil` | ``, `linea` — `"linea"` draws the calendar as Ledger UI's own: a compact 300px panel with the month and year as buttons, 36px rounded days, a dot under today, a continuous band for a range and pill presets. Without it the calendar is Ledger UI's flatpickr. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — The height of the input, as an input of that size: `sm` 32px, `md` 36px, `lg` 48px. |
| `disabled` | `:boolean` | `false` |  |
| `on_change` | `:string` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` | Classes of the input. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — Replaces the calendar icon.
- `<:trailing>` — Buttons joined to the right of the input (Ledger UI's External Elements); the icon is then left out.
