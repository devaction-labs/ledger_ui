# Tooltip

Dica curta ao passar o mouse ou focar.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** color (9) · placement (12) · trigger hover/click/focus/manual · follow_cursor · atalho

## Uso (Phoenix / HEEx)

```heex
<.tooltip text="Exportar (⌘E)"><.icon_button … /></.tooltip>
```

## Regras

- Até ~8 palavras; nunca coloque ação dentro.
- Atraso de 400ms para abrir, 0 para trocar entre vizinhos.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: tooltip)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's tooltip (its tippy.js look and options): a hint around a trigger, in every theme
color (and `dark`, the design canvas tooltip), on twelve placements, after a delay, on hover, click or focus, following the cursor,
or holding HTML.

    <.tooltip id="save-tip" text="Save the draft">
      <.button>Save</.button>
    </.tooltip>

    <.tooltip id="top-start" text="Top Start" color="success" placement="top-start">
      <.button variant="outline" color="primary">Top Start</.button>
    </.tooltip>

    <.tooltip id="profile" trigger="click">
      <.button>Content</.button>
      <:content>
        <div class="flex space-x-3 p-3">…</div>
      </:content>
    </.tooltip>

A tooltip is an overlay: `LedgerUI.open/close/toggle` show and hide it by `id`, and `open`
drives it from the server (when the assign changes, the server wins).

The hint is shown in the browser's top layer (`popover="manual"`), so a table's scroll area, a
drawer's body or an ancestor's `z-index` / `transform` neither clip nor cover it; it follows
scrolling and hides when its trigger scrolls out of sight.

### `<.tooltip>`

Renders a trigger and its tooltip.

`on_open` and `on_close` take an event name or a `JS` command; an event's payload is
`%{"id" => id}` and it goes to `target` when given.

    <.tooltip id="delete-tip" text="Delete forever" color="error" placement="bottom-end" delay={300}>
      <.button color="error" icon aria-label="Delete">×</.button>
    </.tooltip>

From the server: `LedgerUI.open(socket, "delete-tip")`, or bind `open={@show_tip}`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `text` | `:string` | `nil` | The hint, when there is no `:content`. |
| `color` | `:string` | `"neutral"` | `neutral`, `light`, `dark`, `primary`, `secondary`, `info`, `success`, `warning`, `error` — The hint's color. `dark` is the design canvas tooltip: `#171717` with white 12px text and 8px corners. |
| `placement` | `:string` | `"top"` | `top`, `top-start`, `top-end`, `right`, `right-start`, `right-end`, `bottom`, `bottom-start`, `bottom-end`, `left`, `left-start`, `left-end` |
| `trigger` | `:string` | `"hover"` | `hover`, `click`, `focus`, `manual` — `hover` also shows the hint when the trigger gets the keyboard focus. |
| `delay` | `:integer` | `0` | Milliseconds before the hint shows or hides. |
| `duration` | `:integer` | `300` | Milliseconds the animation lasts. |
| `follow_cursor` | `:string` | `nil` | ``, `both`, `horizontal`, `vertical`, `initial` — `initial` places the hint where the pointer was when it showed. |
| `arrow` | `:boolean` | `true` |  |
| `interactive` | `:boolean` | `nil` | Whether the pointer can move onto the hint; on by default with `:content`. |
| `open` | `:boolean` | `false` |  |
| `on_open` | `:any` | `nil` |  |
| `on_close` | `:any` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |
| `tip_class` | `:any` | `nil` | Classes for the hint's box. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:content>` — HTML content: drawn without padding, Ledger UI's `content` theme.
- `<:inner_block>` (required)
