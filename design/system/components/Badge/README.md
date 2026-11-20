# Badge

Rótulo curto de status ou categoria. Cantos de 6px, nunca pílula.

**Grupo:** 06 · Exibição  
**Resumo visual:** color (10) × variant solid/glow/soft/outline/flat · size xs–lg · shape rounded/pill/square

## Uso (Phoenix / HEEx)

```heex
<.badge tone="neg">−$3,400 MRR</.badge>
<.badge tone="acc" dot live>LIVE</.badge>
```

## Regras

- Tom tem significado: pos/neg para valores, warn para pendência, lime para oportunidade, acc para marca/IA.
- Contorno (`outline`) para status em tabelas densas, como no exemplo de casos.
- `lu-count` é o contador vermelho de navegação (23).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: badge)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's badge (`badge`): filled, glowing, soft, outlined or bare text, with a dot, an icon or a
remove button. The classes are kit CSS's (`badge-primary`, `badge-soft`, `badge-outline`, `badge-sm`…), so the
theme paints it.

    <.badge>Default</.badge>
    <.badge color="success" shape="pill">Paid</.badge>
    <.badge color="primary" variant="soft" dot>Online</.badge>
    <.badge color="error" variant="outline" shape="pill">Error</.badge>
    <.badge on_remove={JS.hide()}>Filter</.badge>
    <.badge color="success" variant="soft" size="sm">UI/UX</.badge>
    <.badge color="white" variant="outline" shape="pill">Tag</.badge>

### `<.badge>`

Renders a badge.

    <.badge color="success" variant="soft" shape="pill" dot>Active</.badge>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `dark`, `light`, `white` — `white` is for badges on colored or gradient cards: `variant="outline"` is a white outline, `soft` a translucent white chip. |
| `variant` | `:string` | `"soft"` | `solid`, `glow`, `soft`, `outline`, `flat` — `soft` (the default, `badge-soft`) is the tinted chip, `solid` the filled badge, `outline` `badge-outline`, `flat` only the colored text. |
| `size` | `:string` | `nil` | ``, `xs`, `sm`, `md`, `lg` — kit CSS's `badge-xs` to `badge-lg`; without it the badge is kit CSS's default (`md`). |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill`, `square` |
| `dot` | `:boolean` | `false` | A dot in the badge's color before the content. |
| `on_remove` | `:any` | `nil` | An event name or a `JS` command: adds a small round remove button after the content. The event's payload is `%{"id" => id}`. |
| `id` | `:string` | `nil` |  |
| `target` | `:any` | `nil` | The `phx-target` of `on_remove` when it is an event name. |
| `remove_label` | `:string` | `"Remove"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
