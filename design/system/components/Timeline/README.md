# Timeline

Histórico cronológico de eventos de uma conta ou caso.

**Grupo:** 06 · Exibição  
**Resumo visual:** marcador solid · outline · icon · avatar · ponto · size md–2xl · density · color (8) · tone

## Uso (Phoenix / HEEx)

```heex
<.timeline items={@events} />
```

## Regras

- Ícone 32px em caixa tonal; linha de 1px `line-strong` liga os eventos.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: timeline)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's timeline: events down a line, each marked by a filled, outlined or icon point.

    <.timeline class="max-w-sm">
      <.timeline_item title="Video Added" time="1 hour ago" color="primary"
        description="Mores Clarke added new video" />
      <.timeline_item title="Design Completed" time="3 hours ago" color="success" ping>
        <a href="#">File_final.fig</a>
      </.timeline_item>
    </.timeline>

    <.timeline size="lg" line_space>
      <.timeline_item title="Images Added" time="1 hour ago" color="primary" variant="icon">
        <:point><svg class="size-3">…</svg></:point>
      </.timeline_item>
    </.timeline>

An avatar can be the point: give the timeline `size="xl"` (2rem) or `"2xl"` and the item
`variant="avatar"`, with the avatar filling the point:

    <.timeline size="xl">
      <.timeline_item variant="avatar" title="Mores Clarke" time="1 hour ago">
        <:point><.avatar src="/mores.jpg" class="size-full" /></:point>
      </.timeline_item>
    </.timeline>

The line is 2px and stops at the last item. `ping` stops for people who prefer reduced
motion. An avatar point can also be a tinted disc with initials (`<.avatar initials="mc" color="info" class="size-full" />`).

The inner block of an item comes after its description: images, links, tags, members.

A `timeline_day` splits the events by day with a small label, the line running through it:

    <.timeline>
      <.timeline_day label="Today" />
      <.timeline_item title="Out for delivery" time="11:42" color="info" />
    </.timeline>

The items can come from a list or a stream through `rows` and the `:item` slot, which gets
`{dom_id, row}` and renders a `timeline_item` with that `id`:

    <.timeline id="events" rows={@streams.events}>
      <:item :let={{id, event}}>
        <.timeline_item id={id} title={event.title} time={event.ago} color={event.color} />
      </:item>
    </.timeline>

Given a stream, the list renders with `phx-update="stream"` (and needs an `id`).

Both are kit CSS's `timeline timeline-vertical timeline-compact`. `variant="canvas"` is a list of
`timeline_event`s, each with a boxed icon tile, a title over a subtitle and the time at the right. It takes `rows` and the `:item` slot
the same way:

    <.timeline variant="canvas" id="events" rows={@streams.events}>
      <:item :let={{id, event}}>
        <.timeline_event id={id} tone="pos" title={event.title} subtitle={event.by} time={event.at}>
          <:icon><.icon name="hero-check" class="size-4" /></:icon>
        </.timeline_event>
      </:item>
    </.timeline>

### `<.timeline>`

Renders the line the `timeline_item`s hang on, either from its inner block or from `rows`.

    <.timeline line_space class="max-w-sm">
      <.timeline_item title="Video Added" time="1 hour ago" color="primary" />
    </.timeline>

    <.timeline id="events" rows={@streams.events}>
      <:item :let={{id, event}}>
        <.timeline_item id={id} title={event.title} time={event.ago} />
      </:item>
    </.timeline>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `line_space` | `:boolean` | `false` | Leaves a gap between the points and the line. |
| `size` | `:string` | `"md"` | `md`, `lg`, `xl`, `2xl` — The width of the points (and where the line runs): `md` 12px, `lg` 1.5rem for an icon, `xl` 2rem and `2xl` 2.5rem for avatar points. |
| `density` | `:string` | `"default"` | `default`, `compact` — `compact` is the tighter Ledger UI look of the canvas: 22px between items, 14px between the point and the text, a 13px semibold title, a 13px muted description and a 4px gap between a point and the line (as with `line_space`). |
| `variant` | `:string` | `"line"` | `line`, `canvas` — `line` is the vertical line of points; `canvas` the list of `timeline_event`s with icon tiles. |
| `id` | `:string` | `nil` | Required with a stream. |
| `rows` | `:any` | `nil` | A list or a stream of rows rendered by the `:item` slot. |
| `row_id` | `:any` | `nil` | A function from a row to its DOM id, for a plain list (a stream brings its own ids). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`
- `<:item>` — Renders one row; gets `{dom_id, row}`.

### `<.timeline_item>`

Renders one event: its point, title, time and description, then the inner block.

    <.timeline_item title="Images Added" time="1 hour ago" color="primary" variant="icon"
      description="Mores Clarke added new image gallery">
      <:point><svg class="size-3">…</svg></:point>
      <div class="mt-4 grid grid-cols-3 gap-3">…</div>
    </.timeline_item>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` | `:string` | `nil` | The bold first line. |
| `time` | `:string` | `nil` | Shown at the right of the title. |
| `description` | `:string` | `nil` | The line under the title. |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `accent`, `info`, `success`, `warning`, `error` — The color of the point. |
| `variant` | `:string` | `"solid"` | `solid`, `outline`, `icon`, `avatar` — `icon` is a disc tinted 13% with the color and ringed by 1px of it, holding the `:point` slot (an icon of 1rem on a `xl` timeline is the Ledger UI size); `avatar` draws no disc, so the `:point` slot can hold an avatar. |
| `point_class` | `:any` | `nil` | Merged into the point (`size-8` ...). |
| `ping` | `:boolean` | `false` | A pulsing ring around the point. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:details>` — The description with markup (`<b>3 items</b>`); it replaces the `description` text.
- `<:inner_block>`
- `<:point>` — What the point shows, usually an icon.

### `<.timeline_event>`

Renders one event of a `variant="canvas"` timeline: an icon tile, a title over a subtitle and
the time at the right.

    <.timeline_event tone="warn" title="Fatura vencida" subtitle="Cliente Acme" time="10:42">
      <:icon><.icon name="hero-exclamation-triangle" class="size-4" /></:icon>
    </.timeline_event>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` | `:string` | `nil` | The first line. |
| `subtitle` | `:string` | `nil` | The faint line under the title. |
| `time` | `:string` | `nil` | Mono and faint, at the right. |
| `tone` | `:string` | `"default"` | `default`, `acc`, `pos`, `neg`, `warn`, `info` — Tints the icon tile with the primary, success, error, warning or info color. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — The icon inside the tile.
- `<:inner_block>` — Free content after the title and the subtitle.

### `<.timeline_day>`

Renders a label that splits the events by day, with the line running through it.

    <.timeline_day label="Yesterday" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
