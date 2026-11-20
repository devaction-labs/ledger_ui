# StatusToast

Toast compacto e escuro para processos longos (deploy, lote de notas, importação, backup). É o visual padrão de toasts simples.

**Grupo:** 10 · Feedback  
**Resumo visual:** state run · queue · ok · err · com % · ação ghost · centralizado como barra de processo

## Uso (Phoenix / HEEx)

```heex
<.status_toast state="run" value={42}>Importando **stripe-oct.csv**</.status_toast>
<.status_toast state="ok">Deploy concluído<:action>Ver</:action></.status_toast>
```

## Regras

- `run`: círculo enche (ou mostra o % real com `value`); `queue`: círculo tracejado; `ok`: ponto verde; `err`: ponto vermelho.
- `**nome**` na mensagem destaca o nome. Fica até mudar ou fechar; centralizado vira barra de processo (até 440px).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: toast)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's notifications: a small colored note at a corner or an edge of the screen that leaves by
itself after a few seconds.

Mount the toaster once, in the layout every LiveView renders (it reads the flash):

    <.toaster flash={@flash} />

Then, from the server:

    conn |> put_toast("Saved", color: "success") |> redirect(to: ~p"/orders")
    socket |> put_toast("Saved", color: "success") |> push_navigate(to: ~p"/orders")
    socket |> send_toast("Copied", color: "info", position: "center-top")

`put_toast/3` goes through the flash, so it survives a redirect; `send_toast/3` pushes the toast to
the page at once. From the browser, without a round trip:

    <.button phx-click={show_toast("This is a simple notification", color: "primary")}>Primary</.button>

Options: `color` (`neutral primary secondary info success warning error light dark`), `position`
(`left-top left-bottom center-top center-bottom right-top right-bottom`), `duration` in
milliseconds (`0` or `:infinity` keeps it until closed), `close` (a close button) and `template`,
the id of a `<template>` on the page whose first element is shown instead of the message (an
element with `data-toast-dismiss` inside it closes the toast; this is the way to put buttons of
your own in a toast).

### Kinds, descriptions and actions

`kind` (`neutral info success warning error loading`) draws the toast as a card (white, `navy-700`
in dark) with the icon in a tile tinted by the kind (or by `color`, `dark` makes the whole card dark)
and a title; `description` adds a second line and `actions` put buttons on the right. A toast with
none of `kind`, `description`, `actions`, `aura` or `value` stays Ledger UI's plain colored note (a `color: :dark`
card with no `kind` leads with a dot with a halo where the icon would be):

    send_toast(socket, "Invoice sent",
      kind: :success,
      description: "NF-e 1234 was authorized.",
      actions: [
        [label: "Open", event: "open-invoice", value: %{id: 1234}],
        [label: "Undo", js: JS.push("undo")],
        [label: "See all", href: "/invoices"]
      ]
    )

An action takes `label` and one of `event` (pushed to the LiveView with `value` merged with
`%{"toast_id" => id}`, to `target` when given), `js` (a `%JS{}` run in the browser) or `href`
(a link). It closes the toast unless `dismiss: false`; `[label: "Close", dismiss: true]` alone
only closes it. `variant` (`outline` by default, `solid`, `soft`) and `color` (`primary`, `error`)
set the look of the button: `[label: "Review", variant: :solid]`, `[label: "Retry", variant: :soft,
color: :error]`.

### The timer and the toasts that wait

Every toast leaves by itself after `duration` (5000 ms on the toaster by default), and a thin line at its
bottom counts the time down; the pointer over the stack holds both. `timer: false` hides the line of one toast
and `timer={false}` on the toaster of all.

A toast that depends on the person stays until it is closed, with a close button and no line: one with
`actions`, one with a `template` of its own, one with `aura: :glow`, a `loading` one, and a progress one until
it reaches 100. An explicit `duration` wins over all of this, so `duration: 8000` makes a toast with buttons
leave after 8 s and `duration: :infinity` keeps any toast until closed.

    send_toast(socket, "Invoice sent")
    send_toast(socket, "Invoice sent", actions: [[label: "Undo", event: "undo"]])
    send_toast(socket, "Invoice sent", actions: [[label: "Undo", event: "undo"]], duration: 8000)

### Inverted toasts

`invert` reverses the colors of the cards: a dark card on a light page and a light one on a dark page, so
the message stands out. The kind still tells the message (the green check of a success keeps its tint).
Put it on the toaster for all of them, or on one toast; plain notes invert too, keeping their tint:

    <.toaster flash={@flash} invert />

    send_toast(socket, "Changes saved", kind: :success, invert: true)

### Loading, then the answer

A toast with a fixed `id` is updated in place when another one comes with the same `id`:

    socket = send_toast(socket, "Sending the invoice…", id: "nfe-42", kind: :loading)
    # later, in handle_info/2
    send_toast(socket, "Invoice authorized", id: "nfe-42", kind: :success)

A `loading` toast never leaves by itself and has no close button; once it becomes another kind it
takes its duration again. `update_toast/3` changes only the options it is given, keeping the rest
(`update_toast(socket, "nfe-42", description: "Waiting for SEFAZ…")`); `dismiss_toast/2` and
`clear_toasts/1` remove toasts. `send_toast/2` also takes the message as `title:`
(`send_toast(socket, id: "x", kind: :loading, title: "Working…")`). Errors stay until closed when
the toaster has `persist_errors`.

### Aura

`aura` runs a ring of light around the toast while the assistant (or the SEFAZ) works. `true` or
`:default` rotates it, `:dual` rotates two lights (the assistant's and green, for a result that is
ready) and `:glow` pulses red instead of rotating (for something that needs the user). `aura_size`
(`xs sm default lg`, `default` when not given) sets the thickness of the ring and `aura_color` (`assistant primary secondary
info success warning error`, `assistant` by default) the light:

    send_toast(socket, "The assistant is reading NF 88.530",
      id: "ai-1", kind: :info, aura: true, description: "Suggesting product, CFOP and markup.")

    send_toast(socket, "Manifestation is due today", kind: :warning, aura: :glow, aura_size: :lg)

The sizes are the canvas's: `xs` 0.75px, `sm` 1px, `default` 1.25px (what a toast without `aura_size`
gets) and `lg` 2px. `xs sm lg` keep their names and now map to those thicknesses (before, the toast
ring was 1, 1.5 and 2.5px, with `sm` as the default). `Aura.aura/1`'s `width` takes the same four.

The same ring goes around any element with `LedgerUI.Components.Aura.aura/1` (the canvas look, used by
`toast_card/1` below).

### Progress

A toast with a `value` (0 to 100) is a progress toast: a fill grows behind it, a spinner turns and the
percentage shows (`bar: true` draws a 3px bar at the bottom instead, without the percentage). At 100 it
becomes a success and leaves by itself after 1.6 s (or its `duration`); below 100 it stays and has no
close button unless `close: true`. Turning it into `kind: :error` makes it a failure: a red card that
stays, with the reason in the `description` and, say, a retry action. Move it with `update_toast/3`:

    socket = send_toast(socket, "Issuing the NF-e", id: "nfe-42", value: 0, description: "Validating…")
    # later, in handle_info/2
    update_toast(socket, "nfe-42", value: 64, description: "Sending to SEFAZ…")
    update_toast(socket, "nfe-42", value: 100, title: "NF-e authorized", description: "Protocol 1292…")

### Status

A long process (a deploy, a batch of invoices, an import, a backup) gets the compact, inverse toast: dark in both
themes, with a circle at the left, the message and the buttons at the right. `status` is `:run` (the circle fills
while it works, or shows the real percentage when there is a `value`), `:queue` (dashed circle), `:ok` (green dot)
or `:err` (red dot). `**name**` in the message highlights the name. A status toast stays until it changes or is
closed (a finished one without buttons leaves like any other), has no close button unless `close: true`, and
`variant: :ghost` makes an action a plain text button. `position: "center-bottom"` or `"center-top"` puts it
in the middle of the page as a process bar; its width follows the text, up to 440px.

    send_toast(socket, "Deploy **f798c00** is building on **mavorax · master**",
      id: "deploy", status: :run, position: "center-bottom", actions: [[label: "Cancel", event: "cancel"]])
    update_toast(socket, "deploy", status: :ok, message: "Deploy **f798c00** published in **38s**",
      actions: [[label: "Logs", variant: :ghost, href: "/logs"], [label: "Open", href: "/app"]])
    send_toast(socket, "Importing **BB statement**, **412 of 980** lines", id: "imp", status: :run, value: 42)

`status_toast/1` draws the same card in the page.

**This is the default look.** A plain toast (a message and, at most, a `kind`) is drawn as a status card:
`:success`, `:info` and no kind are `:ok`, `:error` and `:warning` are `:err`, `:loading` is `:run`. A
toast with a `description`, an `aura`, a `value`, `steps` or a `template` keeps its own card. To go
back to the classic card for every plain toast:

    config :ledger_ui, :toast_style, :card

### Steps

A batch that goes in stages is a toast with `steps` (how many) and `step` (how many are done): a title with
the `step/steps` counter, one segment per stage (done ones in the primary color, the one in course in
purple, the rest empty) and the `description` below. The id makes the next call update it in place; no
other toast is stacked. It stays until the last step (no timer, no close button unless `close: true`), then
it turns green and leaves by itself after 1.6 s (or its `duration`). `kind: :error` turns it into a plain
failure. It is still a toast: `actions`, `invert`, `position` and `color: :dark` work as in any other.

    socket = send_toast(socket, "Issuing 5 invoices", id: "batch", steps: 5, step: 0, description: "Validating…")
    # later, in handle_info/2
    update_toast(socket, "batch", step: 2, description: "NF-e of PV-1286 at SEFAZ")
    update_toast(socket, "batch", step: 5, title: "Batch issued", description: "5 NF-e authorized")

The toasts of a corner are stacked: the newest is shown in full and the older ones sit behind it,
smaller, as slivers (three at most). With the pointer over the stack it opens, every toast in its own
size, and their timers wait; when the pointer leaves they go on with the time they had left. Set
`stack={false}` on the toaster to keep them always open, one above the other.

The toasts sit on the CSS layer `--ledger-z-toast` (see the README).

### A toast in the page

`toast_card/1` draws the design canvas's toast card (`lu-toast`, light or dark) where it is written, not in
the toaster: for a notice that stays in a panel, or to show what a toast looks like.

    <.toast_card kind="error" icon="huge-cancel-circle" title="Could not issue"
      description="SEFAZ is down. We will retry in 5 min." />

### `<.toaster>`

The place the toasts are drawn. Mount it once per page, inside the LiveView (the layout that
receives `@flash`).

Events: an action with `event` pushes it with its `value` and `%{"toast_id" => id}`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"linea-toaster"` |  |
| `flash` | `:map` | `%{}` | The `@flash`, where `put_toast/3` leaves its toasts. |
| `position` | `:string` | `"center-bottom"` | `left-top`, `left-bottom`, `center-top`, `center-bottom`, `right-top`, `right-bottom` — The default position: centered at the bottom of the screen. |
| `duration` | `:integer` | `5000` | The default duration, in milliseconds. |
| `stack` | `:boolean` | `true` | Pile the toasts of a corner behind the newest and open the pile under the pointer. |
| `persist_errors` | `:boolean` | `false` | Toasts of `kind: :error` without a `duration` stay until closed. |
| `timer` | `:boolean` | `true` | Draws a thin countdown line on the toasts that leave by themselves; a toast turns it off with `timer: false`. |
| `invert` | `:boolean` | `false` | Draws the toasts with the colors reversed: a dark card on a light page and a light card on a dark one. A toast sets it with `invert: true` or `invert: false`. |
| `close_label` | `:string` | `"Close"` |  |
| `loading_label` | `:string` | `"Loading"` |  |

Any other HTML/phx attribute goes to the root element.

### `<.toast_card>`

The canvas's toast card (`lu-toast`), drawn in place: a 30px icon tile tinted by `kind`, the title and the
description, the `:action` buttons and a muted close button that hides the card (and runs `on_dismiss`).

    <.toast_card tone="dark" icon="huge-delete-02" title="Order #2488 deleted">
      <:action><.button variant="soft" size="sm" phx-click="undo">Undo</.button></:action>
    </.toast_card>

`aura` draws the card inside an `LedgerUI.Components.Aura.aura/1` (`aura_tone`, `aura_width`, `aura_shadow`),
and `busy` puts a spinner at the right: the assistant, or a process outside the page, is working.

    <.toast_card aura="spin" aura_tone="ai" busy dismissible={false} kind="primary" icon="huge-sparkles"
      title="Assistant reading the invoice" description="NF-e 48.211 · 44 items" />

`progress` (0 to 100) makes it a progress toast: the background fills up to that percentage, with a
spinner and the percentage at the right. `progress_state="done"` turns the fill green and keeps it
complete, `"fail"` turns it red and drops the spinner and the percentage (put a retry button in `:action`).
Don't pass `style` along with `progress`.

    <.toast_card progress={42} kind="primary" icon="huge-file-01" title="Issuing the NF-e"
      description="Signing the XML…" dismissible={false} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` |  |
| `tone` | `:string` | `"light"` | `light`, `dark` — `light` is the panel card; `dark` the ink card (the canvas's `lu-toast dark`). |
| `kind` | `:string` | `"neutral"` | `neutral`, `primary`, `success`, `warning`, `error`, `info` — The tint of the icon tile: the sunken gray, the accent, or the canvas's tones. |
| `icon` | `:string` | `nil` | A `LedgerUI.Components.Icon.icon/1` name for the tile. |
| `title` (required) | `:string` |  |  |
| `description` | `:string` | `nil` |  |
| `dismissible` | `:boolean` | `true` | The close button. |
| `close_label` | `:string` | `"Close"` | The `aria-label` of the close button. |
| `on_dismiss` | `:any` | `nil` | A `%JS{}` run (after hiding the card) when the close button is pressed. |
| `busy` | `:boolean` | `false` | A spinner at the right of the text. |
| `busy_label` | `:string` | `"Loading"` | The accessible name of the spinner. |
| `progress` | `:integer` | `nil` | 0 to 100: the card fills up to it and shows the percentage. |
| `progress_state` | `:string` | `"run"` | `run`, `done`, `fail` — `run` spins, `done` is complete and green, `fail` is red, without spinner or percentage. |
| `aura` | `:string` | `nil` | ``, `spin`, `dual`, `glow` — Draws the card inside an aura in this mode. |
| `aura_tone` | `:string` | `"accent"` | `accent`, `ai`, `info`, `pos`, `warn`, `neg`, `violet` |
| `aura_width` | `:string` | `"default"` | `xs`, `sm`, `default`, `lg` |
| `aura_shadow` | `:boolean` | `true` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — Buttons between the text and the close button.
- `<:icon_tile>` — Replaces the `icon` inside the tile.

### `<.status_toast>`

The compact, inverse status card (`lu-toast st`) drawn in place: a circle for the `state`, the message (put
the names in `<b>`) and the buttons at the right. Dark in both themes.

    <.status_toast state="run">
      Deploy <b>f798c00</b> is building on <b>mavorax · master</b>
      <:action>Cancel</:action>
    </.status_toast>

    <.status_toast state="ok">
      Deploy <b>f798c00</b> published in <b>38s</b>
      <:action ghost>Logs</:action>
      <:action>Open</:action>
    </.status_toast>

`state` is `run` (the circle fills while it works), `queue` (dashed), `ok` (green dot) or `err` (red dot);
`percent` (0 to 100) makes a running circle show that real percentage. An action takes `ghost` (plain text) and
`on_click` (a `%JS{}` or an event name). With `href`, `navigate` or `patch` the action is a link (`<.link>`,
so it keeps its semantics and opens in a new tab) instead of a button; `id` goes on it either way.

    <.status_toast state="run">
      Deploy building
      <:action id="toast-logs" patch={~p"/deploys/1/logs"} ghost>Logs</:action>
      <:action id="toast-hide" on_click="hide">Hide</:action>
    </.status_toast>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `state` | `:string` | `"run"` | `run`, `queue`, `ok`, `err` |
| `percent` | `:integer` | `nil` | 0 to 100: the circle of a running toast shows it. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — attrs: `ghost`, `on_click`, `id`, `href`, `navigate`, `patch` — A button at the right.
- `<:inner_block>` (required) — The message; `<b>` highlights a name.
