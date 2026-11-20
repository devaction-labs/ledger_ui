# Stat

Indicador enxuto para listas e cabeçalhos, sem a bandeja do card.

**Grupo:** 07 · Métricas e gráficos  
**Resumo visual:** tone default/accent · size default/sm · variant default/sunken

## Uso (Phoenix / HEEx)

```heex
<.stat label="ARPA" value="$168" delta={3.1} />
```

## Regras

- Use em grupos de 3–4 separados por linha vertical.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: stat)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's stats (`stats`, `stat`, `stat-title`, `stat-value`): short figures side by side, each with a faint
label over it and a divider between them, in one card.

    <.stat_group>
      <.stat_item label="Subtotal" value="R$ 3.240" />
      <.stat_item label="Desconto" value="− R$ 120" />
      <.stat_item label="Total" value="R$ 3.120" tone="accent" />
    </.stat_group>

`unit` is a smaller suffix beside the figure (`un`, `dias`, `%`). A `stat_item/1` also works on its own, inside any
flex row; `stat_group card={false}` drops the card frame.

### `<.stat_item>`

One figure with its label.

    <.stat_item label="Estoque" value="1.284" unit="un" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `value` (required) | `:string` |  | The figure, already formatted. |
| `unit` | `:string` | `nil` | A smaller faint suffix beside the figure. |
| `tone` | `:string` | `"default"` | `default`, `accent` — `accent` paints the figure in the accent (the total of a strip). |
| `size` | `:string` | `"default"` | `default`, `sm` — `sm` sets the figure at 18px (a word such as `Boleto`). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.stat_group>`

A row of `stat_item/1`: kit CSS's `stats` in a card, the figures side by side.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `card` | `:boolean` | `true` | Draws the card around the row. |
| `variant` | `:string` | `"default"` | `default`, `sunken` — `sunken` fills the row with the grey sunken background. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
