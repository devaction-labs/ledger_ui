# CashTimer

Cronômetro de tempo faturável ou turno de caixa, com valor acumulado.

**Grupo:** 09 · Fluxo de trabalho  
**Resumo visual:** state open · closed · alert

## Uso (Phoenix / HEEx)

```heex
<.cash_timer started_at={@started} rate={120} />
```

## Regras

- Dígitos em mono grande; play/pause no botão inverso.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: cash_timer)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas status card of a cash register shift: an icon in the color of the state, a title and
a line under it, and at the right the time the register has been open (ticking in the browser),
a difference, or an action.

    <.cash_timer id="register-2" state="open" title="Caixa 2 aberto" subtitle="desde 08:00 · Marina"
      elapsed={24_130} amount="R$ 6.412,30" />

    <.cash_timer id="register-2" state="closed" title="Caixa 2 fechado" subtitle="ontem às 18:04 · Rafael">
      <:action><.button size="sm" color="mono">Abrir caixa</.button></:action>
    </.cash_timer>

    <.cash_timer id="check-2" state="alert" title="Conferência do caixa 2" subtitle="08:00 às 18:00"
      difference="− R$ 12,50">
      <:stat label="Esperado">R$ 6.412,30</:stat>
      <:stat label="Contado">R$ 6.399,80</:stat>
    </.cash_timer>

`state` colors the icon: `open` green, `closed` neutral, `alert` amber (the `difference` takes
the same amber). `elapsed` (seconds) shows the clock, which counts up in the browser with the
`LedgerUI.Timer` hook while `running`; a new `elapsed` from the server resets it. `:stat` slots
add a row of figures under the card's head.

### `<.cash_timer>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `state` | `:string` | `"open"` | `open`, `closed`, `alert` |
| `title` (required) | `:string` |  |  |
| `subtitle` | `:string` | `nil` |  |
| `elapsed` | `:integer` | `nil` | Seconds the register has been open: shows the clock. |
| `running` | `:boolean` | `true` | Whether the clock counts. |
| `amount` | `:string` | `nil` | The balance under the clock. |
| `difference` | `:string` | `nil` | A difference at the right, in the `alert` color. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — A button at the right.
- `<:stat>` — attrs: `label` — A figure in the row under the head.
