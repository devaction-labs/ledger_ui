# Divider

Separador de 1px na cor `line`, horizontal ou vertical, opcionalmente com rótulo central.

**Grupo:** 01 · Fundamentos  
**Resumo visual:** orientation horizontal/vertical · align center/left

## Uso (Phoenix / HEEx)

```heex
<.divider />
<.divider label="ou continue com" />
```

## Regras

- Prefira espaço a divisor: use quando grupos vizinhos têm o mesmo peso visual.
- Em listas dentro de cards (planos, insights), o divisor é `border-top` do item, não um elemento.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: divider)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's divider (`divider`, `divider-horizontal`, `divider-start`): a line between stacked or side-by-side
content, with optional text in the middle.

    <.divider />
    <.divider>OR</.divider>
    <div class="flex">
      <div>…</div>
      <.divider orientation="vertical">OR</.divider>
      <div>…</div>
    </div>

With text, `align="left"` puts it at the start as a small uppercase title, the line running to
the end: the heading of a group of fields.

    <.divider align="left">Entrega</.divider>

`horizontal` is a horizontal line between content stacked vertically (what Ledger UI's page calls
"Divider Vertical"); `vertical` is a vertical line in a row.

### `<.divider>`

Renders a divider, with the inner block as its text when given.

    <.divider>OR</.divider>
    <.divider orientation="vertical" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `orientation` | `:string` | `"horizontal"` | `horizontal`, `vertical` |
| `align` | `:string` | `"center"` | `center`, `left` — Where a horizontal divider's text sits: `center` between two lines, `left` as a small uppercase title before one. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`
