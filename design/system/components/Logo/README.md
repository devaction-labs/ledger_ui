# Logo

Bloco de marca: símbolo num quadrado `inverse` de raio 10, nome em 600 e o contexto em `muted`.

**Grupo:** 14 · Temas e marca  
**Resumo visual:** tone accent · mono

## Uso (Phoenix / HEEx)

```heex
<.logo name="Ledgerly" context="Orbit Cloud · Finance" />
```

## Regras

- Substitua o símbolo pelo do produto; mantenha o quadrado `inverse` para contrastar no shell.
- Versão compacta (só símbolo) no trilho de ícones e na sidebar recolhida.
- Nunca coloque o logo sobre teal: use `inverse` ou `bg-panel`.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: logo)

Todos os function components, atributos, valores e slots que este componente cobre.

The Ledger UI mark: a drop inside a hexagon, after the DevAction Hub logo. The ring follows the page's ink (dark on
light, silver on dark), the body stays near-black and the drop takes the theme's accent, so it changes with
`theme_picker/1`. `tone="mono"` draws the drop in light silver instead, as the Hub does on black.

    <.linea_logo />
    <.linea_logo size={28} wordmark />
    <.linea_logo id="hero-logo" size={96} tone="mono" />

Each logo's gradients are named after its `id`, or a number of its own when it has none, so logos in different
light and dark blocks never borrow each other's gradient.

### `<.linea_logo>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | Names the gradients; without one each logo gets its own (`linea-logo-<n>`). |
| `size` | `:integer` | `32` | The side of the mark, in px. |
| `tone` | `:string` | `"accent"` | `accent`, `mono` — The drop: the theme's accent or silver. |
| `wordmark` | `:boolean` | `false` | Adds "Ledger UI" after the mark. |
| `word_size` | `:integer` | `nil` | The size of the word, in px. Without it the word follows the mark: 0.6 × `size`, at most 30px (17px beside a 28px mark, 24px beside 40px, 30px beside 56px). |
| `label` | `:string` | `"Ledger UI"` | The accessible name. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
