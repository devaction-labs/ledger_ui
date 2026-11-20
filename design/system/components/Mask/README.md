# Mask

Recorta imagem ou bloco numa forma (logo de loja, avatar especial, selo).

**Grupo:** 06 · Exibição  
**Resumo visual:** shape squircle · reuleaux-triangle · diamond · hexagon · hexagon-2 · octagon · star · star-2 · heart

## Uso (Phoenix / HEEx)

```heex
<.mask shape="hexagon"><img src={@logo} /></.mask>
```

## Regras

- Use em logos e selos; para pessoas prefira o avatar redondo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: mask)

Todos os function components, atributos, valores e slots que este componente cobre.

Crops its content to one of nine mask shapes (kit CSS's `mask mask-squircle`, `mask-hexagon`… where kit CSS has the shape, Ledger UI's for `reuleaux-triangle` and `octagon`): `squircle`, `reuleaux-triangle`,
`diamond`, `hexagon`, `hexagon-2`, `octagon`, `star`, `star-2` and `heart`.

    <.mask shape="heart" src="/images/avatar.jpg" alt="Jane" class="size-36" />
    <.mask shape="hexagon" class="size-20 bg-primary">
      <span>JD</span>
    </.mask>

With `src` it renders the masked image itself; otherwise a block holding the inner content.
The block keeps its inner content readable by screen readers; to name a decorative one, pass
`role="img"` and an `aria-label`.

### `<.mask>`

Renders a masked image (with `src`) or a masked block around the inner content. Size it
with `class`.

    <.mask shape="hexagon" src={@user.photo} alt={@user.name} class="size-20" />

A block mask around text or an icon is plain content; give it a `label` when the shape itself
carries the meaning (a status badge, a rating star) and the text inside does not say it:

    <.mask shape="star" label="Favorite" class="size-8 bg-warning" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `shape` | `:string` | `"squircle"` | `squircle`, `reuleaux-triangle`, `diamond`, `hexagon`, `hexagon-2`, `octagon`, `star`, `star-2`, `heart` |
| `src` | `:string` | `nil` |  |
| `alt` | `:string` | `""` |  |
| `label` | `:string` | `nil` | Names a block mask for assistive technology (`role="img"` and `aria-label`). Without it the block stays plain content, so the text inside is still read; an image mask takes `alt`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`
