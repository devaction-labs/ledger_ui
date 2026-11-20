# HeroCard

Cabeçalho de dashboard com saudação, período comparado e ações.

**Grupo:** 06 · Exibição  
**Resumo visual:** size md/lg · variant soft/panel · heading h1/h2/h3

## Uso (Phoenix / HEEx)

```heex
<.hero title="Welcome back, Ikram" subtitle="October 1 – 31, 2026 · compared with September">…</.hero>
```

## Regras

- Ações à direita: período, comparação, filtro e o único botão primário.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: hero_card)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas hero card: the welcome or the insight at the top of a page. The text on the left (an eyebrow
in mono caps with an optional icon, the title, the description and the actions) and a picture on the right,
as tall as the card, fading into it from the left.

    <.hero_card eyebrow="Bem-vindo de volta" title="Metas do ano" description="Alinhamento e metas do trimestre.">
      <:actions>
        <.button color="neutral" size="lg"><.icon name="huge-add-01" /> Nova meta</.button>
        <.button variant="outline" size="lg"><.icon name="huge-view" /> Quadro de visão</.button>
      </:actions>
      <:art><.summit /></:art>
    </.hero_card>

    <.hero_card eyebrow="Sugestão da IA" title="Revisar os pull requests da API v2" src={~p"/images/hero.jpg"}>
      <:icon><.icon name="huge-ai-magic" /></:icon>
      ...
    </.hero_card>

The picture is `src` (an `<img>`, `alt` empty unless it says something) or the `:art` slot (an inline SVG
such as `summit/1`, the package's landscape). `position` moves the crop (`object-position`). `size="lg"`
makes the title and the card taller; `variant="panel"` puts it on the panel color instead of the soft gray.
`summit/1` draws gradients with ids prefixed by its `id` attr (default `"hs"`): when more than one summit
may be on the page (say one hidden on mobile), give each its own, `<.summit id="hero-mobile" />`.
On a phone the picture goes on top and fades down. Styles: `canvas-hero-card.css` (`linea-hero`).

### `<.hero_card>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `eyebrow` | `:string` | `nil` | The small mono caps line above the title. |
| `title` (required) | `:string` |  |  |
| `description` | `:string` | `nil` |  |
| `src` | `:string` | `nil` | The picture on the right. |
| `alt` | `:string` | `""` |  |
| `position` | `:string` | `"center"` | The crop of the picture (`right`, `70% center`...). |
| `size` | `:string` | `"md"` | `md`, `lg` |
| `variant` | `:string` | `"soft"` | `soft`, `panel` |
| `heading` | `:string` | `"h2"` | `h1`, `h2`, `h3` — The tag of the title. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>`
- `<:art>` — The picture as markup (an SVG), instead of `src`.
- `<:icon>` — An icon before the eyebrow.
- `<:inner_block>` — Under the description: a progress bar, a note.
