# CoverCard

Card com capa no topo para projetos, workspaces e relatórios.

**Grupo:** 06 · Exibição  
**Resumo visual:** tone accent · neutral

## Uso (Phoenix / HEEx)

```heex
<.cover_card title="Board pack · Q3" cover={@cover} />
```

## Regras

- Capa 96–140px; sem imagem, use o gradiente teal da marca.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: cover)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas cover: a wide band in the accent gradient (or a quiet dotted surface) that heads a
profile or a page, with a title on it, or a record's avatar overlapping its lower edge.

    <.cover title="Distribuidora Sertão" />

    <.cover height={110} title="Distribuidora Sertão" subtitle="Cliente desde 2021">
      <:avatar><.avatar name="Distribuidora Sertão" tint="#1a7f4b" size="64" shape="rounded" /></:avatar>
    </.cover>

    <.cover tone="neutral" height={120} />

`tone` is `accent` (the teal gradient, white text) or `neutral` (the sunken surface with a dot
pattern). `src` lays a picture over the band. Without `:avatar` the `title` is written on the
band, at the bottom; with it, the avatar overlaps the band's lower edge, ringed in the surface
color, with the `title` and `subtitle` beside it. The inner block goes on the band (actions,
a badge).

### `<.cover>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `tone` | `:string` | `"accent"` | `accent`, `neutral` |
| `height` | `:integer` | `180` | The band's height in pixels. |
| `src` | `:string` | `nil` | A picture that covers the band. |
| `title` | `:string` | `nil` |  |
| `subtitle` | `:string` | `nil` | Under the `title`, beside the `:avatar`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:avatar>` — An avatar that overlaps the band's lower edge.
- `<:inner_block>` — Content on the band.
