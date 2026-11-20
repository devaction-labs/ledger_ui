# GlowText

Texto com brilho de gradiente que percorre as letras, para títulos de IA e destaques de lançamento.

**Grupo:** 14 · Temas e marca  
**Resumo visual:** tone default · warm · as span/h1/h2/h3/p

## Uso (Phoenix / HEEx)

```heex
<.glow_text as="h1">Assistente Signetum</.glow_text>
<.glow_text tone="warm">Black Friday</.glow_text>
```

## Regras

- Use em uma palavra ou título curto; nunca em texto corrido.
- Respeita `prefers-reduced-motion` desacelerando o brilho.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: glow_text)

Todos os function components, atributos, valores e slots que este componente cobre.

Text with a living gradient: the colors drift across the letters. The animation slows down
under `prefers-reduced-motion`.

    <.glow_text as="h1">Signetum</.glow_text>
    <.glow_text tone="warm">New</.glow_text>

### `<.glow_text>`

Renders the gradient text.

    <.glow_text tone="warm" as="h2">Welcome back</.glow_text>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `tone` | `:string` | `"default"` | `default`, `warm` |
| `as` | `:string` | `"span"` | `span`, `h1`, `h2`, `h3`, `p` — The HTML tag. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
