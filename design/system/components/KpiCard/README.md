# KpiCard

Card de indicador do exemplo: número grande tabular, unidade em `subtle`, delta colorido no rodapé.

**Grupo:** 07 · Métricas e gráficos  
**Resumo visual:** trend up/down/flat · delta_tone · color (7) · layout stack/inline · icon_tone · live · sparkline

## Uso (Phoenix / HEEx)

```heex
<.kpi_card label="MRR" value={184_320} unit="$" delta={8.8} compare="vs $169,460 in Sep" live spark={@mrr_series} />
```

## Regras

- A cor do delta segue o significado, não a direção: churn subir é `neg` (▲ vermelho).
- Sparkline ocupa ~46% à direita com degradê `accent-soft`; ponto final com halo.
- Botão redondo teal (→) leva ao relatório; é o único elemento circular do card.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: kpi_card)

Todos os function components, atributos, valores e slots que este componente cobre.

A metric card made of kit CSS's pieces (`card card-border` with a `stat`): the label and the change (a soft
`badge`) on top, the figure with its unit and a sparkline beside it.

    <.kpi_card label="Faturamento" value="R$ 248,6" unit="mil" delta="12,4%" trend="up" spark={[8, 12, 9, 14, 11, 16]} />
    <.kpi_card label="Ticket médio" value="R$ 164" delta="2,3%" trend="down" delta_tone="error" spark={[14, 12, 13, 9]} />

`trend` draws the arrow and `delta_tone` colors the change: a rise is good by default (`success`, the canvas's
`up`) and a fall is bad (`error`, `down`). `color="primary"` draws the sparkline in the accent; any other color in
the ink.

`progress` (0 to 100) swaps the sparkline for kit CSS's `progress`, with `caption` under it:

    <.kpi_card label="Vendas do mês" value="R$ 248,6" unit="mil" delta="12,4%" progress={78}
      caption="78% da meta de R$ 320 mil" />

`<:icon>` puts an icon chip before the label, `icon_tone` colors it. `caption` is a faint line under
the figure, with or without `progress`. `value_id` is the id of the figure:

    <.kpi_card label="Automações" value="12" value_id="kpi-auto" caption="3 pausadas" icon_tone="pos">
      <:icon><.icon name="bolt" /></:icon>
    </.kpi_card>

`gap={false}` drops the 14px space between the top line and the figure (the canvas's single cards).

### `<.kpi_card>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` | `:string` | `nil` |  |
| `value` | `:string` | `nil` | The figure, already formatted. |
| `unit` | `:string` | `nil` | A smaller suffix beside the figure (`mil`, `%`, `dias`). |
| `delta` | `:string` | `nil` | The change since the last period, already formatted. |
| `trend` | `:string` | `"up"` | `up`, `down`, `flat` — Direction of the arrow. |
| `delta_tone` | `:string` | `nil` | ``, `success`, `error`, `neutral` — Colors the change. Defaults from `trend`: up is `success`, down is `error`, flat is `neutral`. |
| `spark` | `:list` | `[]` | Numbers for the sparkline. |
| `color` | `:string` | `"primary"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` — `primary` draws the sparkline in the accent, the others in the ink. |
| `layout` | `:string` | `"inline"` | `stack`, `inline` — Kept for compatibility; the canvas card is one layout. |
| `progress` | `:integer` | `nil` | How much of a goal is done (0 to 100): an accent meter under the figure, in place of the sparkline. |
| `caption` | `:string` | `nil` | A faint line under the figure or the meter (`78% da meta de R$ 320 mil`). |
| `icon_tone` | `:string` | `"acc"` | `acc`, `pos`, `neg`, `warn`, `info` — Colors the `<:icon>` chip. |
| `value_id` | `:string` | `nil` | The `id` of the figure element (`stat-value`). |
| `gap` | `:boolean` | `true` | The 14px space between the top line and the figure; `false` sets the figure right under it. |
| `loading` | `:boolean` | `false` | Placeholder blocks in place of the content. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — An icon shown in a tinted chip before the label.
