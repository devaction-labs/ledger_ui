# Collapse

Expande e recolhe conteúdo longo no lugar.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** chevron down/right · variant classic/framed/flat/section/canvas

## Uso (Phoenix / HEEx)

```heex
<.collapse id="more" label="Mostrar mais">…</.collapse>
```

## Regras

- Rótulo muda para “Mostrar menos” quando aberto.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: collapse)

Todos os function components, atributos, valores e slots que este componente cobre.

A section that opens and closes under its trigger, with Ledger UI's 200ms height animation. It is
the piece Ledger UI's Collapse and Accordion pages are built from (see `LedgerUI.Components.Accordion`).

    <.collapse id="details">
      <:trigger class="flex items-center justify-between py-4 font-medium">Shipping details</:trigger>
      <p>Ships in two days.</p>
    </.collapse>

`chevron` adds the rotating chevron Ledger UI's panels use at the end of the trigger:

    <.collapse id="files" open chevron="down">
      <:trigger class="px-4 text-xs font-medium uppercase">My files</:trigger>
      …
    </.collapse>

`variant` is the design canvas section by default (see below); `classic` (or `nil`) is the old bare look, and `variant` gives it one of three more looks without writing the trigger's classes: `framed` (a card with a
12px radius and an inset 1px border, a hover fill, 16/14px padding), `flat` (only a rule under it) and
`section` (a small uppercase label):

    <.collapse id="filters" variant="section" chevron="down" open>
      <:trigger>Filters</:trigger>
      …
    </.collapse>

`canvas` is the design canvas section (the look of the canvas accordion): a 14px frame with an inset
line, the title in the ink at 14px 16px, a muted 13.5/21 body.

`collapse_text/1` is the other collapse of the canvas: a text clamped to a few lines with a
"show more" / "show less" link under it.

    <.collapse_text id="desc" lines={2} more="Mostrar mais" less="Mostrar menos">
      Tinta acrílica fosca para paredes internas e externas…
    </.collapse_text>

It is a native `<details>`: the trigger works with the mouse and the keyboard and the browser
owns `open`, which survives patches. When the server changes `open`, the server wins.
`LedgerUI.open/close/toggle("details")` (and their socket forms) open and close it too, and
`on_open` / `on_close` run on every toggle; as event names they push `%{"id" => id}` to the
LiveView (or `target`).

### `<.collapse>`

Renders a collapsible section.

    <.collapse id="faq-1" open on_close="faq-closed">
      <:trigger>Can I pay later?</:trigger>
      Yes, within 30 days.
    </.collapse>

Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` |  |
| `on_open` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_close` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_open` / `on_close` events. |
| `chevron` | `:string` | `nil` | ``, `down`, `right` — Draws a chevron at the end of the trigger (which becomes a flex row with `justify-between`). `down` turns upside down while open, `right` turns down. |
| `variant` | `:string` | `"canvas"` | ``, `classic`, `framed`, `flat`, `section`, `canvas` — A ready-made look; `canvas` (the default) is the design canvas section. `classic` (or `nil`) is the old look, no look at all: the trigger is left to its `class`. Others: `framed` (card with an inset border), `flat` (a rule under it), `section` (an uppercase label), `canvas` (the design canvas section). `nil` leaves the trigger to its `class`. |
| `panel_class` | `:any` | `nil` | Merged into the panel (`.ac-panel`) that holds the content (`px-4 pb-4`...). |
| `chevron_class` | `:any` | `nil` | Merged into the chevron's `<svg>`. |
| `class` | `:any` | `nil` | Merged into the `<details>`. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
- `<:trigger>` (required) — attrs: `class`

### `<.collapse_text>`

A text clamped to `lines` lines, with a link under it that shows the rest ("show more") and
hides it again ("show less"). It works in the browser (no event to the server); the link has
`aria-expanded` and `aria-controls`.

    <.collapse_text id="desc" lines={3} more="Mostrar mais" less="Mostrar menos">
      {@product.description}
    </.collapse_text>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `lines` | `:integer` | `2` | How many lines show while it is closed. |
| `open` | `:boolean` | `false` | Starts with the whole text shown. |
| `more` | `:string` | `"Show more"` | The link while the text is clamped. |
| `less` | `:string` | `"Show less"` | The link while the whole text shows. |
| `class` | `:any` | `nil` | Merged into the wrapper. |
| `text_class` | `:any` | `nil` | Merged into the text. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
