# TimePicker

Escolha de horário em lista rolável com passos de 15 ou 30 minutos.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** variant input · list

## Uso (Phoenix / HEEx)

```heex
<.time_picker field={@form[:at]} step={30} />
```

## Regras

- Formato 24h por padrão no Brasil; respeite o locale.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: time_picker)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's time picker (flatpickr with no calendar): an input with a clock icon that opens
a card with the hour and the minute as two columns (an up arrow, a number box and a down
arrow each) and, on a 12-hour clock with AM/PM, the AM/PM button beside them (or a 24-hour
clock), held inside a minimum and a maximum.

    <.time_picker field={@form[:opens_at]} placeholder="Choose time..." />
    <.time_picker name="alarm" time_24hr min_time="15:00" max_time="22:30" />
    <.time_picker name="lunch" value="13:13" />

The form gets `"HH:MM"` (24-hour) through a hidden input named like the field, and every
change fires a bubbling `input` event for `phx-change`. The popup is an overlay:
`LedgerUI.open/close/toggle("id")` work on it.

### A list of fixed slots

`variant="list"` draws no input: the times from `min_time` to `max_time`, every `minute_step` minutes, as a
menu-like list where one is chosen (an appointment slot, a delivery window). Each slot is a native radio, so the
form gets `"HH:MM"` under the field's name, the arrow keys move the choice and `phx-change` runs:

    <.time_picker field={@form[:slot]} variant="list" min_time="14:00" max_time="14:45" minute_step={15} />

### Keyboard and screen readers

The popup is a dialog with a name, and the hour and minute boxes, the arrows over them and the
AM/PM toggle are real controls you reach with `Tab`: `↑`/`↓` in a box step it, and the buttons
have names ("Increase hour"...). An arrow that cannot move because `min_time` or `max_time`
stop it is dimmed and `aria-disabled`. `Esc` closes the popup and gives the focus back to the
input.

### `<.time_picker>`

Renders a time input.

    <.time_picker name="start" label="Start" minute_step={15} />

Events: `on_change` is pushed with `%{"id" => id, "value" => "HH:MM"}` after each change, to
`target` or to the LiveView/LiveComponent the picker is in.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, or a generated one. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:any` |  | A `Time` or `"HH:MM"`. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `placeholder` | `:string` | `nil` |  |
| `time_24hr` | `:boolean` | `false` | Hours 0-23 instead of 1-12 with AM/PM. |
| `min_time` | `:string` | `nil` | The earliest time, `"HH:MM"`. |
| `max_time` | `:string` | `nil` | The latest time, `"HH:MM"`. |
| `minute_step` | `:integer` | `5` | Minutes added by the arrows and the arrow keys. |
| `hour_step` | `:integer` | `1` |  |
| `default_hour` | `:integer` | `12` | The hour shown when the input is empty. |
| `display_format` | `:string` | `nil` | The text of the input in flatpickr tokens; `h:i K` (`9:30 AM`) by default, `H:i` with `time_24hr`. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` — The language of the texts of the popup (`labels`); the clock is set by `time_24hr`. |
| `labels` | `:map` | `%{}` | Single texts of the popup, over the `locale` ones: `:picker_time_dialog` (its name), `:picker_hour`, `:picker_minute`, `:picker_hour_up`, `:picker_hour_down`, `:picker_minute_up`, `:picker_minute_down`, `:picker_toggle_period` (the AM/PM button). |
| `variant` | `:string` | `"input"` | `input`, `list` — `input` opens the clock popup; `list` shows the fixed slots from `min_time` to `max_time` every `minute_step` minutes (see above). |
| `show_icon` | `:boolean` | `true` |  |
| `disabled` | `:boolean` | `false` |  |
| `on_change` | `:string` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` | Classes of the input. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — Replaces the clock icon.
- `<:trailing>` — Buttons joined to the right of the input.
