# Container

Limita a largura do conteúdo e centraliza, com respiro lateral que se ajusta à tela.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** max-width sm · md · lg · xl · 2xl · prose · full · padding

## Uso (Phoenix / HEEx)

```heex
<.container size="lg">…</.container>
<.container size="prose" class="py-10">…</.container>
```

## Regras

- `prose` (~68 caracteres) para textos longos; `lg` (1024px) para telas de app.
- O respiro lateral cresce de 16px (celular) a 32px (desktop).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: container)

Todos os function components, atributos, valores e slots que este componente cobre.

The page containers: `container_fixed/1` centers its content up to the `xl` breakpoint,
`container_fluid/1` fills the width. Both keep a 24px gutter, 30px from `xl` on.

    <.container_fixed>
      <h1>Title</h1>
    </.container_fixed>

### `<.container_fixed>`

A centered container, as wide as the `xl` breakpoint at most.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.container_fluid>`

A container as wide as its parent.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
