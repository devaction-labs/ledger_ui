# Popover

Painel flutuante ancorado a um gatilho, para detalhes e formulários curtos.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** placement (12) · trigger_on click/hover · com seta opcional

## Uso (Phoenix / HEEx)

```heex
<.popover id="kpi-info"><:trigger>…</:trigger>…</.popover>
```

## Regras

- Fecha ao clicar fora; não use para ações críticas.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: popover)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's popover: a white card with an arrow next to its trigger, for more than a tooltip
holds (text, tags, people, a small form).

    <.popover id="lesson">
      <:trigger><.button color="primary">Lessons</.button></:trigger>
      <:title>Group Lesson</:title>
      <p class="mt-2">Lorem ipsum dolor sit amet.</p>
    </.popover>

    <.popover id="john" trigger_on="hover" placement="top" class="w-48 px-4 py-5 text-center">
      <:trigger><div class="lu-avatar size-8">…</div></:trigger>
      …
    </.popover>

The default placement is Ledger UI's `right-start`, falling back to the bottom and the top when
there is no room. It opens and closes from the browser (`LedgerUI.toggle("lesson")`), from the
server (`LedgerUI.close(socket, "lesson")`) or from `open`; a click outside and Esc close it and
`on_close` runs however it closed.

The card floats above the page: opened, it sits in the browser's top layer (`popover="manual"`,
`position: fixed`, placed from the trigger's rectangle), so a scroll area, a drawer's body or an
ancestor's `z-index` / `transform` neither clip nor cover it. It follows scrolling, flips when
there is no room and closes when its trigger scrolls out of sight; it stays in the LiveView's DOM,
so patches and events inside it work as usual.

The card is 272px wide (`w-68`, at most 90% of the viewport) so text wraps instead of running on one
line; `class` changes it (`w-48`, `w-96`, `w-max`). The panel is a `role="dialog"` named by its
`:title` (`aria-labelledby`), or by `label` when there is no title.

### `<.popover>`

Renders a popover.

Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` |  |
| `placement` | `:string` | `"right-start"` | `bottom-start`, `bottom`, `bottom-end`, `top-start`, `top`, `top-end`, `left-start`, `left`, `left-end`, `right-start`, `right`, `right-end` |
| `fallbacks` | `:list` | `["bottom", "top"]` | The sides tried, in order, when the placement has no room. |
| `offset` | `:integer` | `12` | Pixels between the trigger and the card. |
| `trigger_on` | `:string` | `"click"` | `click`, `hover` |
| `arrow` | `:boolean` | `true` |  |
| `on_open` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_close` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_open` / `on_close` events. |
| `label` | `:string` | `nil` | The dialog's accessible name (`aria-label`) when there is no `:title` slot. |
| `class` | `:any` | `nil` | Merged into the card (`max-w-xs`, `w-72 p-3`...). |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`
- `<:title>` — Ledger UI's card title.
- `<:trigger>` (required)
