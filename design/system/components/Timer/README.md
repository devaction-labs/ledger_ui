# Timer

Cronômetro ou contagem regressiva, em anel ou compacto.

**Grupo:** 09 · Fluxo de trabalho  
**Resumo visual:** direction up · down × variant ring · mini × size sm/md/lg × color (7) × format auto/hms/hm

## Uso (Phoenix / HEEx)

```heex
<.timer id="sessao" direction="down" seconds={600} variant="ring" />
<.timer id="t" direction="up" variant="mini" format="hms" />
```

## Regras

- Regressivo: o anel esvazia; progressivo: o anel enche.
- `mini` cabe em barras e linhas de tabela.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: timer)

Todos os function components, atributos, valores e slots que este componente cobre.

A timer that ticks in the browser: a ring with the time in the middle for a cash register shift, a countdown or
any stretch of time, and a small pill of it for a top bar.

    <.timer id="shift" elapsed={@shift_seconds} running={@running} kicker="Register open"
      kicker_paused="Paused" label="Register 01 · Ana Souza" on_toggle="shift_toggled">
      <:actions>
        <.button variant="soft" phx-click={LedgerUI.Timer.toggle("shift")}>Pause</.button>
        <.button variant="outline" phx-click={LedgerUI.Timer.add("shift", 900)}>+15 min</.button>
      </:actions>
    </.timer>

    <.timer id="break" direction="down" total={900} elapsed={0} color="warning" on_finish="break_over" />

The `mini` variant is the pill for the top bar of a screen, with a pulsing dot while it runs:

    <header class="flex h-14 items-center justify-between px-5">
      <span>PDV</span>
      <.timer id="shift-mini" variant="mini" elapsed={@shift_seconds} running={@running} label="Shift time" />
    </header>

The server owns the time: `elapsed` is the seconds counted so far, `running` whether it counts, and `total` the
seconds the ring stands for (8 hours by default). The browser counts from there without a round trip, from a
monotonic clock, so a background tab never loses a second. A new `elapsed`, `running`, `total` or `direction` from
the server replaces what the browser counted; a patch that changes none of them leaves the count alone.

`format` is `hms` (`03:12:45`), `hm` (`3h12`) or `hh:mm` (`03:12`), the mini clock of a top bar.

`direction="up"` shows the time elapsed and fills the ring as it passes; `direction="down"` shows the time left
(`total - elapsed`) and empties it. The ring is drawn in `color` while it runs and in warning when paused; the
kicker under it is green while it runs and orange when paused.

The timer has `role="timer"` and the accessible name `label` ("Timer" when there is none); the ticking text is not
a live region, so a screen reader is not interrupted every second.

### Controls

The buttons are the caller's, in the `actions` slot. They run in the browser, with no round trip, through
`LedgerUI.Timer`, which also pushes from the server:

    phx-click={LedgerUI.Timer.pause("shift")}
    phx-click={LedgerUI.Timer.resume("shift")}
    phx-click={LedgerUI.Timer.toggle("shift")}
    phx-click={LedgerUI.Timer.add("shift", 900)}

    LedgerUI.Timer.add(socket, "shift", 900)

`pause`, `resume` and `toggle` push `on_toggle` when the state changes; `add` takes time away with a negative number.
Keep a server `running` assign in step with `on_toggle` so a later patch does not undo the choice:

    def handle_event("shift_toggled", %{"running" => running, "elapsed" => elapsed}, socket),
      do: {:noreply, assign(socket, running: running, shift_seconds: elapsed)}

### Events

Each takes an event name or a `%JS{}` and goes to `target` when there is one.

  * `on_toggle` - a command paused or resumed it: `%{"id" => id, "running" => boolean, "elapsed" => seconds}`.
  * `on_tick` - every second: `%{"id" => id, "elapsed" => seconds, "remaining" => seconds}`. It is a round trip a
    second, leave it out unless the server needs it.
  * `on_finish` - once, when a countdown reaches zero (or a count up reaches `total` with `stop_at_total`); the
    timer stops: `%{"id" => id, "elapsed" => seconds}`.

### `<.timer>`

Renders a timer.

    <.timer id="shift" elapsed={@seconds} running={@running} kicker="Register open" kicker_paused="Paused">
      <:actions>
        <.button phx-click={LedgerUI.Timer.toggle("shift")}>Pause</.button>
      </:actions>
    </.timer>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Needed by the hook and by `LedgerUI.Timer`. |
| `elapsed` | `:integer` | `0` | The seconds counted so far. A new value from the server replaces the browser's count. |
| `total` | `:integer` | `28800` | The seconds the ring stands for, and where a countdown ends (8 hours by default). |
| `running` | `:boolean` | `true` | Whether it counts. A change from the server replaces the browser's state. |
| `direction` | `:string` | `"up"` | `up`, `down` — `up` shows the time elapsed, `down` the time left (`total - elapsed`). |
| `variant` | `:string` | `"ring"` | `ring`, `mini` — `ring` is the card with the ring, `mini` the pill for a top bar. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — The ring's diameter (128, 168 or 208 px), or the pill's height. |
| `color` | `:string` | `"primary"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` — The ring while it runs (`ring` only); paused is always warning. |
| `format` | `:string` | `"auto"` | `auto`, `hms`, `hm`, `hh:mm` — `hms` is `03:12:45`, `hm` is `3h12`, `hh:mm` is `03:12`, `auto` is `hms` for the ring and `hm` for the pill. |
| `kicker` | `:string` | `nil` | The small uppercase text over the time while it runs (`ring` only). |
| `kicker_paused` | `:string` | `nil` | The kicker while it is paused; the kicker itself when not set. |
| `label` | `:string` | `nil` | The line under the time, and the accessible name of the timer. |
| `stop_at_total` | `:boolean` | `false` | Counting up, stop at `total` and fire `on_finish`, instead of going past it. |
| `on_toggle` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_tick` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_finish` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of the events. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — The controls under the ring, the caller's buttons (`ring` only).
- `<:caption>` — Replaces the `label` line under the time (`ring` only); the accessible name stays `label`.
