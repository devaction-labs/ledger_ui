# Button

Botão de ação com os mesmos eixos da API: `color`, `variant`, `size`, `shape`, ícone, `loading`, `pip` e `disabled`; `button_group` junta botões.

**Grupo:** 02 · Ações  
**Resumo visual:** color × variant (10 × 9) · size xs–xl · shape · icon, loading, pip, disabled · ButtonGroup

## Uso (Phoenix / HEEx)

```heex
<.button color="neutral" variant="solid" size="md" shape="rounded">Export report</.button>
<.button color="primary" variant="soft" icon><.icon name="huge-add-01" /></.button>
<.button loading>Salvando</.button>
<.button pip variant="ghost" icon>…</.button>
<.button_group shape="pill">…</.button_group>
```

## Regras

- Padrão: `color="neutral" variant="solid"` = o botão preto do exemplo (sombra `shadow-btn`).
- `glow` adiciona sombra colorida; `glass` é translúcido com blur, para cima de imagens/gradientes; `dim` é o sólido apagado (ação secundária forte).
- `shape="square"` + `icon` = botão só-ícone; `pill` existe só por API (o padrão do sistema é `rounded`).
- `loading` troca o conteúdo por spinner mantendo a largura; `pip` põe o ponto de notificação no canto.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: button)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's button (`btn`): filled, outlined, soft, ghost and glass, in every theme color.

    <.button>Neutral</.button>
    <.button color="primary">Save</.button>
    <.button color="error" variant="outline">Delete</.button>
    <.button color="info" icon aria-label="Search"><svg>…</svg></.button>
    <.button navigate={~p"/orders"} color="primary" variant="soft">Orders</.button>
    <.button icon variant="flat" color="current" aria-label="Menu"><svg>…</svg></.button>
    <.button variant="glass">On a gradient card</.button>

With `href`, `navigate` or `patch` it renders a link that looks the same.

The classes are kit CSS's: `btn`, its color (`btn-primary`, `btn-error`…), style (`btn-outline`, `btn-soft`,
`btn-ghost`), size (`btn-xs` to `btn-xl`) and shape (`btn-square`, `btn-circle`), so the theme (`data-theme`)
paints it, and any other kit CSS or Tailwind class can be added.

While work runs, `loading` disables the button (no double submit), marks it `aria-busy` and puts kit CSS's
spinner (`loading loading-spinner`) before the label; change the label to the gerund yourself:

    <.button color="primary" loading={@saving}>{if @saving, do: "Saving…", else: "Save"}</.button>

A button and a field of the same `size` have the same height (kit CSS's `--size-field`), so `control` is no longer
needed to line them up; it is kept so existing calls compile. A `disabled` button is faded. An icon button takes
`pip`, the accent dot on its corner (`indicator` and `status`) that tells there is something new:

    <.button icon variant="outline" pip aria-label="Notifications"><svg>…</svg></.button>

### `<.button>`

Renders a button, or a link when `href`, `navigate` or `patch` is given.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `white`, `current`, `mono` — `white` is for buttons on colored or gradient surfaces; `current` takes the parent's text color; `mono` is kit CSS's `btn-neutral`. |
| `variant` | `:string` | `"solid"` | `solid`, `glow`, `outline`, `soft`, `bordered`, `flat`, `glass`, `ghost`, `dim` — `solid` is filled, `glow` adds a colored shadow, `outline` is `btn-outline`, `soft` is `btn-soft` (`bordered` adds a tinted border), `flat` and `ghost` are `btn-ghost`, `dim` is a ghost with muted text that darkens on hover, `glass` is kit CSS's `glass` for gradient and colored cards. |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg`, `xl` |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill`, `square` — `rounded` (the theme's `--radius-field`, the default), `pill` (fully round ends, opt-in; `btn-circle` on an icon button) or `square` (tighter corners). |
| `icon` | `:boolean` | `false` | A square button that holds only an icon (`btn-square`). Always pass `aria-label`. |
| `control` | `:boolean` | `false` | Kept for compatibility: kit CSS's buttons and fields of a `size` already share one height. |
| `type` | `:string` | `"button"` |  |
| `disabled` | `:boolean` | `false` |  |
| `loading` | `:boolean` | `false` | Disables the button, marks it `aria-busy` and shows a spinner before the label. |
| `pip` | `:boolean` | `false` | The accent dot on the corner (an unread notice), as kit CSS's `indicator` with a `status`. |
| `loading_label` | `:string` | `"Loading"` | Read by screen readers for the spinner. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`, `target`, `rel`, `form`, `name`, `value`.

Slots:

- `<:inner_block>` (required)

### `<.button_group>`

Joins buttons side by side into one segmented control (kit CSS's `join`).

    <.button_group>
      <.button variant="outline">Day</.button>
      <.button variant="outline">Week</.button>
    </.button_group>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` — `pill` rounds the outer ends fully. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
