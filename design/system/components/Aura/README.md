# Aura

Anel de luz que corre pela borda de qualquer elemento enquanto algo trabalha em segundo plano.

**Grupo:** 10 · Feedback  
**Resumo visual:** mode spin/dual/glow × tone (7) · width xs–lg · radius default/pill/r12 · shadow

## Uso (Phoenix / HEEx)

```heex
<.aura tone="ai"><.toast_card title="Lendo a nota" /></.aura>
<.aura tone="ai" radius="pill" width="sm"><.button>Resumir</.button></.aura>
<.aura mode="glow" tone="warn" shadow>…precisa de você…</.aura>
```

## Regras

- `spin`: uma luz gira enquanto trabalha; `dual`: duas cores para resultado pronto; `glow`: pulsa (precisa da pessoa).
- `tone`: accent, ai (teal + violeta), info, pos, warn, neg, violet. Para de girar com `prefers-reduced-motion`.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: aura)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas's aura: a ring of light that runs along the border of any element while something works in
the background (the assistant, a slow request). The inner content keeps its own look; the aura only
draws the ring around it, over the box's border, and rounds the child to `radius`.

    <.aura tone="ai">
      <.toast_card icon="huge-sparkles" title="Assistant reading the invoice" dismissible={false} />
    </.aura>

    <.aura tone="ai" radius="pill" width="sm"><.button>Summarize</.button></.aura>
    <.aura mode="glow" tone="warn" shadow>…needs you…</.aura>

`mode` is `spin` (a light turns while it works), `dual` (two colors, for a result that is ready) or
`glow` (pulses, without turning, when it needs the person). `tone` picks the light: `ai` (teal and
violet), `info`, `pos`, `warn`, `neg`, `violet`, or the accent by default. The ring stops turning for
people who ask for reduced motion.

### `<.aura>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `mode` | `:string` | `"spin"` | `spin`, `dual`, `glow` — `spin` turns one light, `dual` two colors, `glow` pulses instead of turning. |
| `tone` | `:string` | `"accent"` | `accent`, `ai`, `info`, `pos`, `warn`, `neg`, `violet` — The light: the accent, `ai` (teal and violet), or a status tone. |
| `width` | `:string` | `"default"` | `xs`, `sm`, `default`, `lg` — The thickness of the ring: 0.75px, 1px, 1.25px (default) or 2px. |
| `radius` | `:string` | `"default"` | `default`, `pill`, `r12` — The corner of the child: 16px, a pill or 12px. |
| `shadow` | `:boolean` | `false` | A soft drop shadow under the ring. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
