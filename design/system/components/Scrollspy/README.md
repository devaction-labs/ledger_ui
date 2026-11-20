# Scrollspy

Índice lateral que marca a seção em leitura e desliza o indicador conforme a página rola.

**Grupo:** 11 · Navegação  
**Resumo visual:** índice que acompanha a seção visível · indicador deslizando

## Uso (Phoenix / HEEx)

```heex
<.scrollspy target="#doc">
  <:item href="#dados">Dados</:item>
  <:item href="#fiscal">Fiscal</:item>
</.scrollspy>
```

## Regras

- Marca a seção cujo título passou do topo; clique rola suave até ela.
- Indicador de 2px em `ink` à esquerda.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: scrollspy)

Todos os function components, atributos, valores e slots que este componente cobre.

A list of links to the sections of the page that marks the section in view: the
settings pages with their menu of anchors.

    <.scrollspy id="settings-nav">
      <:item href="#profile">Profile</:item>
      <:item href="#security">Security</:item>
    </.scrollspy>

The hook `LedgerUI.Scrollspy` watches the elements the links point at and sets `aria-current` on the link of the one
that is at the top of the view (`offset` pixels from the top, 120 by default). A click scrolls to the section.

### `<.scrollspy>`

Renders the list of anchors.

    <.scrollspy id="nav" offset={96}>
      <:item href="#a">A</:item>
    </.scrollspy>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` | `:string` | `"On this page"` | The accessible name of the navigation. |
| `offset` | `:integer` | `120` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:item>` (required) — attrs: `href`
