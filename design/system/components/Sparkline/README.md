# Sparkline

Mini-gráfico de tendência sem eixos para KPIs e linhas de tabela.

**Grupo:** 07 · Métricas e gráficos  
**Resumo visual:** Linha mínima com degradê e ponto final com halo · desenha em loop

## Uso (Phoenix / HEEx)

```heex
<.sparkline values={@series} />
```

## Regras

- Sem eixos nem rótulos; o número ao lado conta a história.
- Movimento: a linha é traçada, as barras crescem da base, o anel gira até o lugar e as células acendem por linha; repete em loop nos dois temas.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: sparkline)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas's sparkline (`lu-spark`): a line with a soft fill under it, drawn from a list of numbers, the
highest at the top. The one the KPI card has beside its figure, for a card that lays its own figure out
(the balance of a bank account).

    <.sparkline id="bb" values={[8, 12, 9, 14, 11, 16]} />
    <.sparkline id="itau" values={@balances} color="primary" />

`color="primary"` draws it in the accent, any other value in the ink. The SVG stretches to the width of
the box it is in (`preserveAspectRatio="none"`), as the canvas draws it.

### `<.sparkline>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Names the gradient of the fill, so it must be unique. |
| `values` (required) | `:list` |  | Numbers for the line. |
| `color` | `:string` | `"neutral"` | `neutral`, `primary` — `primary` draws the line in the accent, `neutral` in the ink. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
