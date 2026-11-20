# Sticky

Mantém um cabeçalho ou barra visível enquanto o conteúdo rola por baixo; ganha sombra quando há conteúdo atrás.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** cabeçalho que gruda ao rolar · offset · sombra ao descolar

## Uso (Phoenix / HEEx)

```heex
<.sticky offset="64px">
  <.table_toolbar … />
</.sticky>
```

## Regras

- Fundo translúcido com desfoque para o conteúdo aparecer por trás.
- A sombra só aparece quando o conteúdo passa por baixo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: sticky)

Todos os function components, atributos, valores e slots que este componente cobre.

A block that sticks to the top of the page and takes classes while the page is scrolled: a header that gets an edge, a bar that gets a shadow.

    <.sticky id="page-bar" stuck_class="border-b border-base-300 shadow-xs">
      …
    </.sticky>

The hook `LedgerUI.Sticky` adds `stuck_class` and sets `data-stuck` once the page is scrolled past `offset` pixels and
takes them off when it is back. The block is `sticky top-0`.

### `<.sticky>`

Renders the sticky block.

    <.sticky id="bar" offset={8} stuck_class="shadow-md">…</.sticky>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `offset` | `:integer` | `0` | How many pixels the page scrolls before the block counts as stuck. |
| `stuck_class` | `:string` | `"border-b border-base-300"` | Classes added while stuck. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
