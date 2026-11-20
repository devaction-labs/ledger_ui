# Skeleton

Placeholder de carregamento que espelha o layout final.

**Grupo:** 10 · Feedback  
**Resumo visual:** animation wave/pulse/none × shape rounded/pill/circle/square/lg · skeleton_group

## Uso (Phoenix / HEEx)

```heex
<.skeleton class="h-3 w-40" animation="wave" />
<.skeleton_group label="Carregando contas">…</.skeleton_group>
```

## Regras

- Espelhe a forma real (KPI, linha de tabela) para não pular layout.
- `skeleton_group` agrupa com um rótulo acessível.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: skeleton)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's skeleton: placeholder blocks shown while the content loads, with a light wave
passing over them or a pulse.

    <.skeleton class="size-16" shape="circle" />
    <.skeleton class="h-3 w-full" />
    <.skeleton class="h-48 w-full" shape="square" />

The wave and the pulse stop for people who prefer reduced motion.

The blocks are `aria-hidden`; wrap a whole placeholder in `skeleton_group/1` so a screen
reader hears that something is loading:

    <.skeleton_group label="Loading orders">
      <.skeleton class="h-3 w-full" />
      <.skeleton class="h-3 w-8/12" />
    </.skeleton_group>

`variant="canvas"` (the default; `variant="lineone"` is the old slate block) draws the kit CSS `skeleton` in the canvas tint (the warm gray gradient of the Signetum
screens, 8px corners); `shape` still rounds it (`circle` for an avatar):

    <.skeleton variant="canvas" shape="circle" class="size-8" />
    <.skeleton variant="canvas" class="h-2.5 w-1/2" />

For the pulse, put `animation="none"` blocks inside an element with `animate-pulse` (as
Ledger UI does), or give a single block `animation="pulse"`.

### `<.skeleton>`

Renders a placeholder block; its size comes from `class`.

    <.skeleton shape="circle" class="size-16" />
    <.skeleton class="h-3 w-8/12" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `animation` | `:string` | `"wave"` | `wave`, `pulse`, `none` |
| `variant` | `:string` | `"canvas"` | `canvas`, `lineone` — Both draw kit CSS's `skeleton`; kept for compatibility. |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill`, `circle`, `square`, `lg` — `rounded` is the theme's small radius, `lg` the large one, `square` none. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.skeleton_group>`

Wraps the skeleton blocks of one placeholder: `role="status"` and `aria-busy="true"` with
a screen-reader-only `label`.

    <.skeleton_group label="Loading orders" class="space-y-2">
      <.skeleton class="h-3 w-full" />
    </.skeleton_group>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` | `:string` | `"Loading…"` | Read by screen readers; not drawn. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
